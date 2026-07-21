//
//  PersonSegmentationService.swift
//  Aura Energy Revealed
//
//  Vision person segmentation — the user's real photo stays the hero.
//  Produces (1) the person cut out on transparency and (2) a colored,
//  blurred silhouette glow to layer behind them as the aura.
//

import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

struct SegmentationResult {
    /// Original photo, unchanged. The user's identity remains the focus.
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
        guard let cgImage = image.cgImage else {
            return SegmentationResult(original: image, personCutout: nil, auraGlow: nil)
        }

        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .balanced
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: cgOrientation(from: image.imageOrientation))
        do {
            try handler.perform([request])
        } catch {
            return SegmentationResult(original: image, personCutout: nil, auraGlow: nil)
        }

        guard let maskBuffer = request.results?.first?.pixelBuffer else {
            return SegmentationResult(original: image, personCutout: nil, auraGlow: nil)
        }

        let ciContext = CIContext()
        let inputImage = CIImage(cgImage: cgImage)
        var maskImage = CIImage(cvPixelBuffer: maskBuffer)

        // Scale mask to image size
        let scaleX = inputImage.extent.width / maskImage.extent.width
        let scaleY = inputImage.extent.height / maskImage.extent.height
        maskImage = maskImage.transformed(by: .init(scaleX: scaleX, y: scaleY))

        // 1) Person cutout on transparency
        let blend = CIFilter.blendWithMask()
        blend.inputImage = inputImage
        blend.backgroundImage = CIImage.empty()
        blend.maskImage = maskImage
        var cutout: UIImage?
        if let output = blend.outputImage,
           let cg = ciContext.createCGImage(output, from: inputImage.extent) {
            cutout = UIImage(cgImage: cg, scale: image.scale, orientation: .up)
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
                glow = UIImage(cgImage: cg, scale: image.scale, orientation: .up)
            }
        }

        return SegmentationResult(original: image, personCutout: cutout, auraGlow: glow)
    }

    private static func cgOrientation(from ui: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch ui {
        case .up: .up
        case .down: .down
        case .left: .left
        case .right: .right
        case .upMirrored: .upMirrored
        case .downMirrored: .downMirrored
        case .leftMirrored: .leftMirrored
        case .rightMirrored: .rightMirrored
        @unknown default: .up
        }
    }
}
