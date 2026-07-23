//
//  PersonSegmentationService.swift
//  Aura Energy Revealed
//
//  Vision person segmentation — the user's real photo stays the hero.
//  Produces (1) the person cut out on transparency and (2) a colored,
//  blurred silhouette glow to layer behind them as the aura.
//
//  IMPORTANT — orientation:
//  Camera and photo-library images almost always carry a non-.up EXIF
//  orientation (portrait selfies are typically .right / .leftMirrored).
//  Vision returns its mask in the *oriented* (visually upright) space, but
//  the raw `cgImage` is in the un-rotated sensor space. Blending the two
//  directly is what produced the tilted, badly-cropped cutout. The fix is
//  to bake the orientation into an upright bitmap ONCE, up front, and do
//  every subsequent step (Vision + cutout + glow) in that single, shared,
//  already-upright coordinate space.
//

import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

struct SegmentationResult {
    /// Upright photo (orientation baked in). The user's identity stays the focus.
    let original: UIImage
    /// Person isolated on transparent background (nil if no person found).
    let personCutout: UIImage?
    /// Soft blurred silhouette tinted with the aura colour, for the glow layer.
    let auraGlow: UIImage?
}

enum PersonSegmentationService {

    static func process(image: UIImage, glowColor: UIColor) async -> SegmentationResult {
        await Task.detached(priority: .userInitiated) {
            processSync(image: image, glowColor: glowColor)
        }.value
    }

    private static func processSync(image: UIImage, glowColor: UIColor) -> SegmentationResult {
        // Step 0 — normalise to an upright image so mask and pixels always agree.
        let upright = image.normalizedUp()

        guard let cgImage = upright.cgImage else {
            return SegmentationResult(original: upright, personCutout: nil, auraGlow: nil)
        }

        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .accurate          // sharper edges around hair/shoulders
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8

        // The image is already upright, so Vision runs with .up — mask now
        // lives in exactly the same coordinate space as `cgImage`.
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
        do {
            try handler.perform([request])
        } catch {
            return SegmentationResult(original: upright, personCutout: nil, auraGlow: nil)
        }

        guard let maskBuffer = request.results?.first?.pixelBuffer else {
            return SegmentationResult(original: upright, personCutout: nil, auraGlow: nil)
        }

        let ciContext = CIContext()
        let inputImage = CIImage(cgImage: cgImage)
        var maskImage = CIImage(cvPixelBuffer: maskBuffer)

        // Scale mask up to the full image size (mask is lower-res).
        let scaleX = inputImage.extent.width / maskImage.extent.width
        let scaleY = inputImage.extent.height / maskImage.extent.height
        maskImage = maskImage.transformed(by: .init(scaleX: scaleX, y: scaleY))

        // Slightly soften the mask edge so the cutout doesn't look cut with scissors.
        maskImage = maskImage
            .clampedToExtent()
            .applyingGaussianBlur(sigma: 1.5)
            .cropped(to: inputImage.extent)

        // 1) Person cutout on transparency
        let blend = CIFilter.blendWithMask()
        blend.inputImage = inputImage
        blend.backgroundImage = CIImage.empty()
        blend.maskImage = maskImage
        var cutout: UIImage?
        if let output = blend.outputImage,
           let cg = ciContext.createCGImage(output, from: inputImage.extent) {
            cutout = UIImage(cgImage: cg, scale: upright.scale, orientation: .up)
        }

        // 2) Aura glow: tinted silhouette, heavily blurred
        var glow: UIImage?
        let tint = CIImage(color: CIColor(color: glowColor)).cropped(to: inputImage.extent)
        let tintBlend = CIFilter.blendWithMask()
        tintBlend.inputImage = tint
        tintBlend.backgroundImage = CIImage.empty()
        tintBlend.maskImage = maskImage
        if let tinted = tintBlend.outputImage {
            let blurred = tinted
                .clampedToExtent()
                .applyingGaussianBlur(sigma: Double(inputImage.extent.width) * 0.045)
                .cropped(to: inputImage.extent.insetBy(dx: -60, dy: -60))
            if let cg = ciContext.createCGImage(blurred, from: blurred.extent) {
                glow = UIImage(cgImage: cg, scale: upright.scale, orientation: .up)
            }
        }

        return SegmentationResult(original: upright, personCutout: cutout, auraGlow: glow)
    }
}

private extension UIImage {
    /// Returns a copy whose pixels are already rotated to the upright (.up)
    /// orientation, with the EXIF orientation flag cleared. This guarantees
    /// that anything derived from `.cgImage` afterwards is in the same
    /// visual space the user actually sees.
    func normalizedUp() -> UIImage {
        if imageOrientation == .up { return self }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
