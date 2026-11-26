import Foundation
#if canImport(UIKit)
import UIKit
#endif
import Vision
import CoreImage

public class ContourDetector {

    public init() {}

    /**
     * Multi-photo / Single-photo detection using Vision framework VNDetectRectanglesRequest
     * with strict geometric constraints (aspect ratio 0.35..2.85, area >= 6% total, IoU suppression).
     */
    public func detectQuads(
        sourceImage: UIImage,
        isMultiPhoto: Bool = true
    ) async -> [Quad] {
        guard let cgImage = sourceImage.cgImage else { return [] }

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let totalArea = width * height

        return await withCheckedContinuation { continuation in
            let request = VNDetectRectanglesRequest { request, error in
                guard error == nil, let observations = request.results as? [VNRectangleObservation], !observations.isEmpty else {
                    // Fallback to full frame inset
                    let fallback = Quad.full(width: width, height: height, insetRatio: 0.04)
                    continuation.resume(returning: [fallback])
                    return
                }

                var candidateQuads = [Quad]()

                for obs in observations {
                    // Convert Vision normalized coordinates (origin at bottom-left) to UIKit/CoreGraphics (origin at top-left)
                    let tl = CGPoint(x: obs.topLeft.x * width, y: (1.0 - obs.topLeft.y) * height)
                    let tr = CGPoint(x: obs.topRight.x * width, y: (1.0 - obs.topRight.y) * height)
                    let br = CGPoint(x: obs.bottomRight.x * width, y: (1.0 - obs.bottomRight.y) * height)
                    let bl = CGPoint(x: obs.bottomLeft.x * width, y: (1.0 - obs.bottomLeft.y) * height)

                    let quad = GeometryUtils.orderPointsClockwise([tl, tr, br, bl])
                    let area = quad.area
                    let ratio = quad.aspectRatio

                    // Filter out clutter (cables, keyboards, tiny shadows)
                    let minAreaRatio: CGFloat = isMultiPhoto ? 0.05 : 0.12
                    let isReasonableArea = (area / totalArea) >= minAreaRatio && (area / totalArea) <= 0.98
                    let isReasonableRatio = ratio >= 0.35 && ratio <= 2.85
                    let isConvex = GeometryUtils.isConvexQuad(quad)

                    if isReasonableArea && isReasonableRatio && isConvex {
                        candidateQuads.append(quad)
                    }
                }

                // Non-Maximum Suppression (NMS) by IoU overlap
                var filtered = [Quad]()
                let sortedByArea = candidateQuads.sorted { $0.area > $1.area }

                for candidate in sortedByArea {
                    let overlaps = filtered.contains { existing in
                        GeometryUtils.calculateIoU(candidate, existing) > 0.40
                    }
                    if !overlaps {
                        filtered.append(candidate)
                    }
                }

                if isMultiPhoto {
                    // Return detected quads up to 4 photos per album page
                    if filtered.isEmpty {
                        filtered = [Quad.full(width: width, height: height, insetRatio: 0.04)]
                    }
                    continuation.resume(returning: Array(filtered.prefix(4)))
                } else {
                    // Return single largest dominant quad
                    let best = filtered.first ?? Quad.full(width: width, height: height, insetRatio: 0.04)
                    continuation.resume(returning: [best])
                }
            }

            request.minimumAspectRatio = 0.35
            request.maximumAspectRatio = 2.85
            request.minimumSize = 0.20
            request.minimumConfidence = 0.55
            request.maximumObservations = isMultiPhoto ? 8 : 1

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
            do {
                try handler.perform([request])
            } catch {
                let fallback = Quad.full(width: width, height: height, insetRatio: 0.04)
                continuation.resume(returning: [fallback])
            }
        }
    }
}
