import Foundation
#if canImport(UIKit)
import UIKit
#endif
import CoreImage

public class PerspectiveWarper {

    private let ciContext = CIContext(options: [CIContextOption.useSoftwareRenderer: false])

    public init() {}

    /**
     * Warps perspective from the 4-corner polygon to a rectangular upright image
     */
    public func warpPerspective(source: UIImage, quad: Quad) -> UIImage {
        guard let ciImage = CIImage(image: source) else { return source }

        let h = ciImage.extent.height

        // CoreImage uses Cartesian coordinates with (0,0) at bottom-left
        let tl = CIVector(cgPoint: CGPoint(x: quad.topLeft.x, y: h - quad.topLeft.y))
        let tr = CIVector(cgPoint: CGPoint(x: quad.topRight.x, y: h - quad.topRight.y))
        let br = CIVector(cgPoint: CGPoint(x: quad.bottomRight.x, y: h - quad.bottomRight.y))
        let bl = CIVector(cgPoint: CGPoint(x: quad.bottomLeft.x, y: h - quad.bottomLeft.y))

        guard let filter = CIFilter(name: "CIPerspectiveCorrection") else { return source }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(tl, forKey: "inputTopLeft")
        filter.setValue(tr, forKey: "inputTopRight")
        filter.setValue(br, forKey: "inputBottomRight")
        filter.setValue(bl, forKey: "inputBottomLeft")

        guard let outputCI = filter.outputImage,
              let cgOut = ciContext.createCGImage(outputCI, from: outputCI.extent) else {
            return source
        }

        return UIImage(cgImage: cgOut, scale: source.scale, orientation: .up)
    }

    /**
     * Rotates image by specified degrees (90, 180, 270)
     */
    public func rotateImage(_ image: UIImage, degrees: Float) -> UIImage {
        let radians = CGFloat(degrees) * .pi / 180.0
        let newSize = CGRect(origin: .zero, size: image.size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .integral.size

        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return image
        }

        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        context.rotate(by: radians)
        image.draw(in: CGRect(x: -image.size.width / 2, y: -image.size.height / 2, width: image.size.width, height: image.size.height))

        let rotated = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        return rotated
    }
}
