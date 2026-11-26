import Foundation
import CoreGraphics

public enum GeometryUtils {

    /**
     * Orders 4 arbitrary points in clockwise order: Top-Left, Top-Right, Bottom-Right, Bottom-Left
     */
    public static func orderPointsClockwise(_ pts: [CGPoint]) -> Quad {
        guard pts.count == 4 else {
            return Quad(topLeft: .zero, topRight: .zero, bottomRight: .zero, bottomLeft: .zero)
        }

        // Center of mass
        let cx = pts.map { $0.x }.reduce(0, +) / 4.0
        let cy = pts.map { $0.y }.reduce(0, +) / 4.0

        // Sort by polar angle around centroid
        let sorted = pts.sorted {
            atan2($0.y - cy, $0.x - cx) < atan2($1.y - cy, $1.x - cx)
        }

        // Top-left has smallest (x + y), Bottom-right has largest (x + y)
        // Top-right has smallest (y - x), Bottom-left has largest (y - x)
        let sumPts = pts.sorted { ($0.x + $0.y) < ($1.x + $1.y) }
        let diffPts = pts.sorted { ($0.y - $0.x) < ($1.y - $1.x) }

        let tl = sumPts.first ?? sorted[0]
        let br = sumPts.last ?? sorted[2]
        let tr = diffPts.first ?? sorted[1]
        let bl = diffPts.last ?? sorted[3]

        return Quad(topLeft: tl, topRight: tr, bottomRight: br, bottomLeft: bl)
    }

    /**
     * Checks if 4 points form a reasonably convex quad
     */
    public static func isConvexQuad(_ quad: Quad) -> Bool {
        let pts = quad.points
        var hasPositive = false
        var hasNegative = false

        for i in 0..<4 {
            let p1 = pts[i]
            let p2 = pts[(i + 1) % 4]
            let p3 = pts[(i + 2) % 4]

            let cross = (p2.x - p1.x) * (p3.y - p2.y) - (p2.y - p1.y) * (p3.x - p2.x)
            if cross > 0 { hasPositive = true }
            if cross < 0 { hasNegative = true }
            if hasPositive && hasNegative { return false }
        }
        return true
    }

    /**
     * Calculates IoU (Intersection over Union) of two quads' bounding boxes
     */
    public static func calculateIoU(_ q1: Quad, _ q2: Quad) -> CGFloat {
        let r1 = q1.boundingBox
        let r2 = q2.boundingBox
        let intersection = r1.intersection(r2)
        if intersection.isNull || intersection.isEmpty { return 0 }

        let interArea = intersection.width * intersection.height
        let unionArea = (r1.width * r1.height) + (r2.width * r2.height) - interArea
        return unionArea > 0 ? (interArea / unionArea) : 0
    }
}
