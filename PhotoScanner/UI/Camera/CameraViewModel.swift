import Foundation
#if canImport(UIKit)
import UIKit
#endif
import AVFoundation
import CoreMotion
import Combine

public enum CameraMode: String, CaseIterable {
    case scanCode = "Scan Code"
    case docs = "Docs"
    case book = "Book"
    case antiGlare = "Khử Chói"
    case continuous = "Quét Liên Tục"
    case portrait = "Chân Dung"
}

public class CameraViewModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {

    @Published public var isMultiMode: Bool = true
    @Published public var currentMode: CameraMode = .docs
    @Published public var flashMode: AVCaptureDevice.FlashMode = .auto
    @Published public var isTorchOn: Bool = false
    @Published public var isHdrOn: Bool = false
    @Published public var isAiLiveScannerOn: Bool = true
    @Published public var isLevelEnabled: Bool = true
    @Published public var zoomRatio: CGFloat = 1.0

    // Sensor Spirit Level
    @Published public var pitch: CGFloat = 0.0
    @Published public var roll: CGFloat = 0.0

    // Focus point
    @Published public var focusPoint: CGPoint? = nil

    // Captured output
    @Published public var capturedOriginalImage: UIImage? = nil
    @Published public var isProcessing: Bool = false
    @Published public var processingMessage: String = ""

    // Anti-Glare 4-Dot
    @Published public var isAntiGlareActive: Bool = false
    private var antiGlareBaseImage: UIImage? = nil
    private var antiGlareAngledImages: [UIImage] = []
    private let antiGlareStitcher = AntiGlareStitcher()

    // Continuous counter
    @Published public var continuousPageCount: Int = 0

    // AVFoundation Session
    public let captureSession = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var activeDevice: AVCaptureDevice?
    private let motionManager = CMMotionManager()

    public override init() {
        super.init()
        setupSession()
        startMotionTracking()
    }

    public func setupSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            captureSession.commitConfiguration()
            return
        }

        self.activeDevice = device

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
        }

        captureSession.commitConfiguration()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    public func startMotionTracking() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
                guard let data = data else { return }
                let x = data.acceleration.x
                let y = data.acceleration.y
                let z = data.acceleration.z

                let pitchDeg = atan2(y, sqrt(x*x + z*z)) * 180.0 / .pi
                let rollDeg = atan2(-x, z) * 180.0 / .pi

                self?.pitch = CGFloat(pitchDeg)
                self?.roll = CGFloat(rollDeg)
            }
        }
    }

    public func cycleFlash() {
        switch flashMode {
        case .off:
            flashMode = .auto
            isTorchOn = false
        case .auto:
            flashMode = .on
            isTorchOn = false
        case .on:
            flashMode = .off
            isTorchOn = true
            setTorch(enabled: true)
        @unknown default:
            flashMode = .off
            isTorchOn = false
            setTorch(enabled: false)
        }
    }

    public func setTorch(enabled: Bool) {
        guard let device = activeDevice, device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = enabled ? .on : .off
        device.unlockForConfiguration()
    }

    public func setZoom(ratio: CGFloat) {
        guard let device = activeDevice else { return }
        try? device.lockForConfiguration()
        device.videoZoomFactor = max(1.0, min(ratio, device.activeFormat.videoMaxZoomFactor))
        zoomRatio = ratio
        device.unlockForConfiguration()
    }

    public func flipCamera() {
        captureSession.beginConfiguration()
        guard let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput else { return }
        captureSession.removeInput(currentInput)

        let newPosition: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back
        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
              let newInput = try? AVCaptureDeviceInput(device: newDevice) else {
            captureSession.commitConfiguration()
            return
        }

        self.activeDevice = newDevice
        if captureSession.canAddInput(newInput) {
            captureSession.addInput(newInput)
        }
        captureSession.commitConfiguration()
    }

    public func focusAt(point: CGPoint, in viewSize: CGSize) {
        self.focusPoint = point
        guard let device = activeDevice else { return }

        let focusX = point.y / viewSize.height
        let focusY = 1.0 - (point.x / viewSize.width)
        let focusPointDevice = CGPoint(x: focusX, y: focusY)

        try? device.lockForConfiguration()
        if device.isFocusPointOfInterestSupported {
            device.focusPointOfInterest = focusPointDevice
            device.focusMode = .autoFocus
        }
        if device.isExposurePointOfInterestSupported {
            device.exposurePointOfInterest = focusPointDevice
            device.exposureMode = .autoExpose
        }
        device.unlockForConfiguration()
    }

    public func capturePhoto() {
        if currentMode == .antiGlare && !isAntiGlareActive {
            startAntiGlareCapture()
            return
        }

        let settings = AVCapturePhotoSettings()
        settings.flashMode = isTorchOn ? .off : flashMode
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    private func startAntiGlareCapture() {
        isProcessing = true
        processingMessage = "Chụp ảnh khung gốc..."
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    public func captureAngledFrame(dotIndex: Int) {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    public func finishAntiGlareStitching() {
        guard let base = antiGlareBaseImage else { return }
        isProcessing = true
        processingMessage = "Đang kết hợp 4 góc khử chói AI..."

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let fused = self.antiGlareStitcher.blendMultiAngleFrames(
                baseImage: base,
                angledFrames: self.antiGlareAngledImages
            )
            DispatchQueue.main.async {
                self.isAntiGlareActive = false
                self.antiGlareAngledImages.removeAll()
                self.antiGlareBaseImage = nil
                self.isProcessing = false
                self.capturedOriginalImage = fused
            }
        }
    }

    // AVCapturePhotoCaptureDelegate
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            isProcessing = false
            return
        }

        if currentMode == .antiGlare {
            if antiGlareBaseImage == nil {
                antiGlareBaseImage = image
                isProcessing = false
                isAntiGlareActive = true
            } else {
                antiGlareAngledImages.append(image)
            }
        } else if currentMode == .continuous {
            // Instant auto-crop & add to album
            continuousPageCount += 1
            Task {
                let quads = await ContourDetector().detectQuads(sourceImage: image, isMultiPhoto: true)
                for q in quads {
                    let cropped = PerspectiveWarper().warpPerspective(source: image, quad: q)
                    let path = ScanRepository().saveImageToDisk(cropped, prefix: "continuous_page")
                    let scanItem = ScanItem(
                        originalImagePath: path,
                        croppedImagePath: path,
                        enhancedImagePath: path,
                        title: "Trang Album #\(self.continuousPageCount)",
                        quad: q
                    )
                    ScanRepository().addScan(scanItem)
                }
            }
        } else {
            self.capturedOriginalImage = image
            self.isProcessing = false
        }
    }
}
