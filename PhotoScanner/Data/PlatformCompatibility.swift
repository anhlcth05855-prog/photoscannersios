import Foundation

#if canImport(UIKit)
import UIKit

#elseif canImport(AppKit)
import AppKit

public typealias UIImage = NSImage
public typealias UIColor = NSColor
public typealias UIFont = NSFont

extension NSImage {
    public var cgImage: CGImage? {
        var rect = CGRect(origin: .zero, size: self.size)
        return self.cgImage(forProposedRect: &rect, context: nil, hints: nil)
    }

    public var scale: CGFloat {
        return 1.0
    }

    public convenience init(cgImage: CGImage, scale: CGFloat, orientation: Any? = nil) {
        self.init(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }

    public func jpegData(compressionQuality: CGFloat) -> Data? {
        guard let tiffRepresentation = self.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
    }
}
#endif

#if canImport(SwiftUI)
import SwiftUI

#if canImport(AppKit) && !canImport(UIKit)
extension Image {
    public init(uiImage: NSImage) {
        self.init(nsImage: uiImage)
    }
}
#endif
#endif
