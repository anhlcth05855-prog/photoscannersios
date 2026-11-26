import Foundation
import CoreGraphics

public struct Quad: Codable, Hashable {
    public var topLeft: CGPoint
    public var topRight: CGPoint
    public var bottomRight: CGPoint
    public var bottomLeft: CGPoint

    public init(topLeft: CGPoint, topRight: CGPoint, bottomRight: CGPoint, bottomLeft: CGPoint) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomRight = bottomRight
        self.bottomLeft = bottomLeft
    }

    public var points: [CGPoint] {
        return [topLeft, topRight, bottomRight, bottomLeft]
    }

    public var widthTop: CGFloat {
        return hypot(topRight.x - topLeft.x, topRight.y - topLeft.y)
    }

    public var widthBottom: CGFloat {
        return hypot(bottomRight.x - bottomLeft.x, bottomRight.y - bottomLeft.y)
    }

    public var heightLeft: CGFloat {
        return hypot(bottomLeft.x - topLeft.x, bottomLeft.y - topLeft.y)
    }

    public var heightRight: CGFloat {
        return hypot(bottomRight.x - topRight.x, bottomRight.y - topRight.y)
    }

    public var averageWidth: CGFloat {
        return (widthTop + widthBottom) / 2.0
    }

    public var averageHeight: CGFloat {
        return (heightLeft + heightRight) / 2.0
    }

    public var aspectRatio: CGFloat {
        let h = averageHeight
        return h > 0 ? (averageWidth / h) : 1.0
    }

    public var area: CGFloat {
        // Shoelace formula for polygon area
        let x1 = topLeft.x, y1 = topLeft.y
        let x2 = topRight.x, y2 = topRight.y
        let x3 = bottomRight.x, y3 = bottomRight.y
        let x4 = bottomLeft.x, y4 = bottomLeft.y
        let a = abs(x1*y2 + x2*y3 + x3*y4 + x4*y1 - (y1*x2 + y2*x3 + y3*x4 + y4*x1)) / 2.0
        return a
    }

    public var boundingBox: CGRect {
        let xs = [topLeft.x, topRight.x, bottomRight.x, bottomLeft.x]
        let ys = [topLeft.y, topRight.y, bottomRight.y, bottomLeft.y]
        let minX = xs.min() ?? 0
        let maxX = xs.max() ?? 0
        let minY = ys.min() ?? 0
        let maxY = ys.max() ?? 0
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    public static func full(width: CGFloat, height: CGFloat, insetRatio: CGFloat = 0.0) -> Quad {
        let dx = width * insetRatio
        let dy = height * insetRatio
        return Quad(
            topLeft: CGPoint(x: dx, y: dy),
            topRight: CGPoint(x: width - dx, y: dy),
            bottomRight: CGPoint(x: width - dx, y: height - dy),
            bottomLeft: CGPoint(x: dx, y: height - dy)
        )
    }

    public static func == (lhs: Quad, rhs: Quad) -> Bool {
        return lhs.topLeft == rhs.topLeft &&
               lhs.topRight == rhs.topRight &&
               lhs.bottomRight == rhs.bottomRight &&
               lhs.bottomLeft == rhs.bottomLeft
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(topLeft.x)
        hasher.combine(topLeft.y)
        hasher.combine(topRight.x)
        hasher.combine(topRight.y)
        hasher.combine(bottomRight.x)
        hasher.combine(bottomRight.y)
        hasher.combine(bottomLeft.x)
        hasher.combine(bottomLeft.y)
    }
}

