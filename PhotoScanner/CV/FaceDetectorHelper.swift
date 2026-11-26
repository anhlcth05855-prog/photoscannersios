import Foundation
#if canImport(UIKit)
import UIKit
#endif
import Vision

public struct DetectedFaceCrop: Identifiable {
    public let id = UUID().uuidString
    public let index: Int
    public let bounds: CGRect
    public let faceImage: UIImage

    public init(index: Int, bounds: CGRect, faceImage: UIImage) {
        self.index = index
        self.bounds = bounds
        self.faceImage = faceImage
    }
}

public class FaceDetectorHelper {

    public init() {}

    /**
     * Auto-Orientation: detects if faces in the photo are upside-down or sideways
     * and automatically calculates rotation angle (0, 90, 180, 270) to make it upright.
     */
    public func detectOrientationAngle(source: UIImage) async -> Float {
        guard let cgImage = source.cgImage else { return 0 }

        return await withCheckedContinuation { continuation in
            let request = VNDetectFaceLandmarksRequest { request, error in
                guard error == nil, let faces = request.results as? [VNFaceObservation], !faces.isEmpty else {
                    continuation.resume(returning: 0)
                    return
                }

                let face = faces[0]
                if let leftEye = face.landmarks?.leftEye?.normalizedPoints.first,
                   let rightEye = face.landmarks?.rightEye?.normalizedPoints.first,
                   let mouth = face.landmarks?.outerLips?.normalizedPoints.first {

                    let avgEyeY = (leftEye.y + rightEye.y) / 2.0
                    let avgEyeX = (leftEye.x + rightEye.x) / 2.0

                    // Vision normalized coordinates have origin at bottom-left:
                    // If eyes are below mouth (avgEyeY < mouth.y) -> photo is upside down (180 deg)
                    if avgEyeY < mouth.y - 0.05 {
                        continuation.resume(returning: 180)
                        return
                    }

                    if abs(leftEye.x - rightEye.x) < abs(leftEye.y - rightEye.y) {
                        continuation.resume(returning: avgEyeX > mouth.x ? 90 : 270)
                        return
                    }
                }

                // Fallback check on roll angle if available
                if let roll = face.roll?.floatValue {
                    let deg = roll * 180.0 / .pi
                    if deg > 45 && deg < 135 { continuation.resume(returning: 90); return }
                    if deg < -45 && deg > -135 { continuation.resume(returning: 270); return }
                    if abs(deg) > 135 { continuation.resume(returning: 180); return }
                }

                continuation.resume(returning: 0)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: 0)
            }
        }
    }

    /**
     * Extracts all individual portraits from a group photo with padding
     */
    public func detectAndCropFaces(source: UIImage) async -> [DetectedFaceCrop] {
        guard let cgImage = source.cgImage else { return [] }

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)

        return await withCheckedContinuation { continuation in
            let request = VNDetectFaceRectanglesRequest { request, error in
                guard error == nil, let observations = request.results as? [VNFaceObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                var crops = [DetectedFaceCrop]()

                for (idx, obs) in observations.enumerated() {
                    let bb = obs.boundingBox
                    // Convert to image pixel coordinate space
                    let x = bb.origin.x * width
                    let y = (1.0 - bb.origin.y - bb.height) * height
                    let w = bb.width * width
                    let h = bb.height * height

                    // Add 35% margin around face
                    let padX = w * 0.35
                    let padY = h * 0.40
                    let cropRect = CGRect(
                        x: max(0, x - padX),
                        y: max(0, y - padY),
                        width: min(width - max(0, x - padX), w + padX * 2),
                        height: min(height - max(0, y - padY), h + padY * 2)
                    )

                    if let croppedCG = cgImage.cropping(to: cropRect) {
                        let faceImg = UIImage(cgImage: croppedCG, scale: source.scale, orientation: .up)
                        crops.append(DetectedFaceCrop(index: idx + 1, bounds: cropRect, faceImage: faceImg))
                    }
                }

                continuation.resume(returning: crops)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }
    }
}
