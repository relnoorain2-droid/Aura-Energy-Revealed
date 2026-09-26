//
//  CameraService.swift
//  Aura Energy Revealed
//
//  AVFoundation capture session with a SwiftUI preview layer.
//  Front camera by default, tap-to-capture, flip support.
//

import AVFoundation
import SwiftUI
import UIKit

final class CameraService: NSObject, ObservableObject {

    enum Status {
        case idle, configured, denied, failed
    }

    @Published var status: Status = .idle

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "aura.camera.session")
    private var position: AVCaptureDevice.Position = .front
    private var captureCompletion: ((UIImage?) -> Void)?

    func requestAndConfigure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configure()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    granted ? self?.configure() : (self?.status = .denied)
                }
            }
        default:
            status = .denied
        }
    }

    private func configure() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo
            self.session.inputs.forEach(self.session.removeInput)

            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.position),
                let input = try? AVCaptureDeviceInput(device: device),
                self.session.canAddInput(input)
            else {
                DispatchQueue.main.async { self.status = .failed }
                self.session.commitConfiguration()
                return
            }
            self.session.addInput(input)

            if !self.session.outputs.contains(self.photoOutput), self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }
            self.session.commitConfiguration()
            self.session.startRunning()
            DispatchQueue.main.async { self.status = .configured }
        }
    }

    func flipCamera() {
        position = position == .front ? .back : .front
        configure()
    }

    /// Point the camera the way the chosen subject needs it.
    ///
    /// Reading a person uses the front camera; reading a plant, a pet or a room
    /// obviously needs the rear one. Reconfiguring is not free, so this is a
    /// no-op when the camera is already facing the right way.
    func use(front useFront: Bool) {
        let wanted: AVCaptureDevice.Position = useFront ? .front : .back
        guard wanted != position else { return }
        position = wanted
        // Only rebuild a session that is already live. Before that, the new
        // position is simply picked up by the first configure().
        if status == .configured { configure() }
    }

    var isUsingFrontCamera: Bool { position == .front }

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        captureCompletion = completion
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func stop() {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        var image: UIImage?
        if error == nil, let data = photo.fileDataRepresentation() {
            image = UIImage(data: data)
            // Mirror front-camera captures so the result matches the preview.
            if position == .front, let cg = image?.cgImage {
                image = UIImage(cgImage: cg, scale: image?.scale ?? 1, orientation: .leftMirrored)
            }
        }
        DispatchQueue.main.async { [weak self] in
            self?.captureCompletion?(image)
            self?.captureCompletion = nil
        }
    }
}

// MARK: - SwiftUI preview layer

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    final class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}
}
