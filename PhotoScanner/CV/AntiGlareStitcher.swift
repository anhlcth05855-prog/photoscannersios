import Foundation
#if canImport(UIKit)
import UIKit
#endif

public class AntiGlareStitcher {

    public init() {}

    /**
     * Google PhotoScan 4-dot non-glare fusion algorithm:
     * Specular reflections move position when the camera angle changes.
     * Non-glare pixels from angled corner frames are blended into the base photo.
     */
    public func blendMultiAngleFrames(
        baseImage: UIImage,
        angledFrames: [UIImage]
    ) -> UIImage {
        guard !angledFrames.isEmpty, let baseCG = baseImage.cgImage else { return baseImage }

        let width = baseCG.width
        let height = baseCG.height
        let pixelCount = width * height
        let bytesPerRow = baseCG.bytesPerRow
        let bytesPerPixel = baseCG.bitsPerPixel / 8

        guard let baseData = baseCG.dataProvider?.data,
              let basePtr = CFDataGetBytePtr(baseData) else { return baseImage }

        var outputBuffer = [UInt8](repeating: 0, count: height * bytesPerRow)
        memcpy(&outputBuffer, basePtr, height * bytesPerRow)

        // Preload pixel pointers for each angled frame
        var frameBuffers = [[UInt8]]()
        for frame in angledFrames {
            if let fCG = frame.cgImage {
                let scaledCG: CGImage
                if fCG.width != width || fCG.height != height {
                    let colorSpace = CGColorSpaceCreateDeviceRGB()
                    guard let ctx = CGContext(
                        data: nil,
                        width: width,
                        height: height,
                        bitsPerComponent: 8,
                        bytesPerRow: width * 4,
                        space: colorSpace,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                    ) else { continue }
                    ctx.draw(fCG, in: CGRect(x: 0, y: 0, width: width, height: height))
                    guard let resized = ctx.makeImage() else { continue }
                    scaledCG = resized
                } else {
                    scaledCG = fCG
                }

                if let fData = scaledCG.dataProvider?.data,
                   let fPtr = CFDataGetBytePtr(fData) {
                    var buf = [UInt8](repeating: 0, count: height * scaledCG.bytesPerRow)
                    memcpy(&buf, fPtr, height * scaledCG.bytesPerRow)
                    frameBuffers.append(buf)
                }
            }
        }

        for y in 0..<height {
            let row = y * bytesPerRow
            for x in 0..<width {
                let off = row + x * bytesPerPixel
                let r = Int(basePtr[off])
                let g = Int(basePtr[off + 1])
                let b = Int(basePtr[off + 2])

                let maxC = max(r, max(g, b))
                let minC = min(r, min(g, b))
                let lum = Int(0.299 * Double(r) + 0.587 * Double(g) + 0.114 * Double(b))

                // Is this a specular glare hotspot? (High brightness & low saturation)
                let isGlare = lum > 215 && (maxC - minC) < 35

                if isGlare {
                    var bestR = r
                    var bestG = g
                    var bestB = b
                    var lowestGlareScore = 999

                    for buf in frameBuffers {
                        let fr = Int(buf[off])
                        let fg = Int(buf[off + 1])
                        let fb = Int(buf[off + 2])
                        let fLum = Int(0.299 * Double(fr) + 0.587 * Double(fg) + 0.114 * Double(fb))

                        if fLum < 205 && fLum < lowestGlareScore {
                            lowestGlareScore = fLum
                            bestR = fr
                            bestG = fg
                            bestB = fb
                        }
                    }

                    if lowestGlareScore < 999 {
                        outputBuffer[off] = UInt8(bestR)
                        outputBuffer[off + 1] = UInt8(bestG)
                        outputBuffer[off + 2] = UInt8(bestB)
                    }
                }
            }
        }

        guard let provider = CGDataProvider(data: Data(outputBuffer) as CFData),
              let outCG = CGImage(
                width: width,
                height: height,
                bitsPerComponent: baseCG.bitsPerComponent,
                bitsPerPixel: baseCG.bitsPerPixel,
                bytesPerRow: bytesPerRow,
                space: baseCG.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: baseCG.bitmapInfo,
                provider: provider,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
              ) else {
            return baseImage
        }

        return UIImage(cgImage: outCG, scale: baseImage.scale, orientation: .up)
    }
}
