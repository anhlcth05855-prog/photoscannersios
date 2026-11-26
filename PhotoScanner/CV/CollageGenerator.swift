import Foundation
#if canImport(UIKit)
import UIKit
#endif

public enum CollageTemplate: String, CaseIterable {
    case grid = "GRID"
    case polaroids = "POLAROIDS"
    case vintagePage = "VINTAGE_PAGE"

    public var title: String {
        switch self {
        case .grid: return "Lưới Cân Đối"
        case .polaroids: return "Polaroid Xếp Lớp"
        case .vintagePage: return "Trang Sổ Kỷ Niệm"
        }
    }
}

public class CollageGenerator {

    public init() {}

    public func createCollage(images: [UIImage], template: CollageTemplate, title: String = "") -> UIImage {
        guard !images.isEmpty else { return UIImage() }
        switch template {
        case .grid:
            return createGridCollage(images: images)
        case .polaroids:
            return createPolaroidCollage(images: images, title: title)
        case .vintagePage:
            return createVintagePageCollage(images: images, title: title)
        }
    }

    private func createGridCollage(images: [UIImage]) -> UIImage {
        let size = CGSize(width: 1600, height: 1600)
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        guard let ctx = UIGraphicsGetCurrentContext() else { return UIImage() }

        // Background
        UIColor(white: 0.12, alpha: 1.0).setFill()
        ctx.fill(CGRect(origin: .zero, size: size))

        let pad: CGFloat = 24.0
        let count = min(images.count, 4)

        if count == 1 {
            images[0].draw(in: CGRect(x: pad, y: pad, width: size.width - pad*2, height: size.height - pad*2))
        } else if count == 2 {
            let itemW = (size.width - pad * 3) / 2.0
            let itemH = size.height - pad * 2
            images[0].draw(in: CGRect(x: pad, y: pad, width: itemW, height: itemH))
            images[1].draw(in: CGRect(x: pad * 2 + itemW, y: pad, width: itemW, height: itemH))
        } else {
            let itemW = (size.width - pad * 3) / 2.0
            let itemH = (size.height - pad * 3) / 2.0
            for (i, img) in images.prefix(4).enumerated() {
                let col = CGFloat(i % 2)
                let row = CGFloat(i / 2)
                let rect = CGRect(
                    x: pad + col * (itemW + pad),
                    y: pad + row * (itemH + pad),
                    width: itemW,
                    height: itemH
                )
                img.draw(in: rect)
            }
        }

        let result = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return result
    }

    private func createPolaroidCollage(images: [UIImage], title: String) -> UIImage {
        let size = CGSize(width: 1600, height: 2000)
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        guard let ctx = UIGraphicsGetCurrentContext() else { return UIImage() }

        // Warm wood/cork table background
        UIColor(red: 0.18, green: 0.15, blue: 0.13, alpha: 1.0).setFill()
        ctx.fill(CGRect(origin: .zero, size: size))

        let angles: [CGFloat] = [-8.0, 6.0, -4.0, 10.0]
        let cardW: CGFloat = 720
        let cardH: CGFloat = 860

        let centers = [
            CGPoint(x: 520, y: 560),
            CGPoint(x: 1080, y: 640),
            CGPoint(x: 580, y: 1380),
            CGPoint(x: 1060, y: 1420)
        ]

        for (i, img) in images.prefix(4).enumerated() {
            let center = (i < centers.count) ? centers[i] : CGPoint(x: 800, y: 1000)
            let angle = ((i < angles.count) ? angles[i] : 0) * .pi / 180.0

            ctx.saveGState()
            ctx.translateBy(x: center.x, y: center.y)
            ctx.rotate(by: angle)

            // Polaroid shadow
            let cardRect = CGRect(x: -cardW/2, y: -cardH/2, width: cardW, height: cardH)
            ctx.setShadow(offset: CGSize(width: 8, height: 16), blur: 24, color: UIColor.black.withAlphaComponent(0.6).cgColor)

            // Polaroid white paper
            UIColor(red: 0.98, green: 0.97, blue: 0.94, alpha: 1.0).setFill()
            let path = UIBezierPath(roundedRect: cardRect, cornerRadius: 12)
            path.fill()

            ctx.setShadow(offset: .zero, blur: 0, color: nil)

            // Inner photo
            let photoPad: CGFloat = 36
            let photoW = cardW - photoPad * 2
            let photoH = cardH - photoPad - 160
            let photoRect = CGRect(x: -cardW/2 + photoPad, y: -cardH/2 + photoPad, width: photoW, height: photoH)
            img.draw(in: photoRect)

            ctx.restoreGState()
        }

        let result = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return result
    }

    private func createVintagePageCollage(images: [UIImage], title: String) -> UIImage {
        let size = CGSize(width: 1600, height: 2200)
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        guard let ctx = UIGraphicsGetCurrentContext() else { return UIImage() }

        // Vintage parchment paper background
        UIColor(red: 0.93, green: 0.89, blue: 0.82, alpha: 1.0).setFill()
        ctx.fill(CGRect(origin: .zero, size: size))

        // Title header
        let pageTitle = title.isEmpty ? "Family Album & Memories" : title
        let titleFont = UIFont.systemFont(ofSize: 52, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor(red: 0.25, green: 0.20, blue: 0.15, alpha: 1.0)
        ]
        let titleStr = NSAttributedString(string: pageTitle, attributes: attrs)
        let titleSize = titleStr.size()
        titleStr.draw(at: CGPoint(x: (size.width - titleSize.width)/2, y: 80))

        let pad: CGFloat = 80
        let itemW: CGFloat = (size.width - pad * 3) / 2.0
        let itemH: CGFloat = 780
        let startY: CGFloat = 200

        for (i, img) in images.prefix(4).enumerated() {
            let col = CGFloat(i % 2)
            let row = CGFloat(i / 2)
            let rect = CGRect(
                x: pad + col * (itemW + pad),
                y: startY + row * (itemH + pad),
                width: itemW,
                height: itemH
            )

            // Subtle photo border
            UIColor.white.setFill()
            ctx.fill(rect.insetBy(dx: -12, dy: -12))
            img.draw(in: rect)
        }

        let result = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return result
    }
}
