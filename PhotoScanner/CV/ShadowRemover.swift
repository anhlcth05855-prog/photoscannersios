import Foundation
#if canImport(UIKit)
import UIKit
#endif

public class ShadowRemover {

    public init() {}

    /**
     * Adobe Scan-style Shadow Remover:
     * Separates background illumination field from reflectance (Retinex theory)
     * and normalizes hand/phone shadows across the scanned photo.
     */
    public func removeShadows(source: UIImage) -> UIImage {
        guard let cgImage = source.cgImage else { return source }
        let width = cgImage.width
        let height = cgImage.height

        guard let data = cgImage.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return source }

        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow

        var lum = [Int](repeating: 0, count: width * height)
        var totalLum: Int64 = 0

        for y in 0..<height {
            let row = y * bytesPerRow
            for x in 0..<width {
                let off = row + x * bytesPerPixel
                let r = Int(ptr[off])
                let g = Int(ptr[off + 1])
                let b = Int(ptr[off + 2])
                let l = Int(0.299 * Double(r) + 0.587 * Double(g) + 0.114 * Double(b))
                lum[y * width + x] = l
                totalLum += Int64(l)
            }
        }

        let meanLum = min(200.0, max(60.0, Double(totalLum) / Double(width * height)))

        // Downsampled illumination map for fast background estimation
        let ds = max(4, width / 120)
        let dsW = width / ds
        let dsH = height / ds
        var dsLum = [Int](repeating: 0, count: dsW * dsH)

        for dy in 0..<dsH {
            let sy = dy * ds
            let dyOff = dy * dsW
            let syOff = sy * width
            for dx in 0..<dsW {
                let sx = dx * ds
                dsLum[dyOff + dx] = lum[syOff + sx]
            }
        }

        // Apply large 2D smoothing filter on illumination map
        let radius = max(3, dsW / 12)
        var smoothLum = [Int](repeating: 0, count: dsW * dsH)

        for y in 0..<dsH {
            let yOff = y * dsW
            for x in 0..<dsW {
                var sum = 0
                var count = 0
                for ky in max(0, y - radius)...min(dsH - 1, y + radius) {
                    let kyOff = ky * dsW
                    for kx in max(0, x - radius)...min(dsW - 1, x + radius) {
                        sum += dsLum[kyOff + kx]
                        count += 1
                    }
                }
                smoothLum[yOff + x] = count > 0 ? (sum / count) : dsLum[yOff + x]
            }
        }

        // Reconstruct illuminated image
        var outBuffer = [UInt8](repeating: 0, count: height * bytesPerRow)
        memcpy(&outBuffer, ptr, height * bytesPerRow)

        for y in 0..<height {
            let row = y * bytesPerRow
            let dy = min(dsH - 1, y / ds)
            let dyOff = dy * dsW

            for x in 0..<width {
                let off = row + x * bytesPerPixel
                let dx = min(dsW - 1, x / ds)
                let backgroundLight = max(30.0, Double(smoothLum[dyOff + dx]))
                let ratio = min(2.2, max(0.8, meanLum / backgroundLight))

                let r = min(255.0, Double(ptr[off]) * ratio)
                let g = min(255.0, Double(ptr[off + 1]) * ratio)
                let b = min(255.0, Double(ptr[off + 2]) * ratio)

                outBuffer[off] = UInt8(r)
                outBuffer[off + 1] = UInt8(g)
                outBuffer[off + 2] = UInt8(b)
            }
        }

        guard let provider = CGDataProvider(data: Data(outBuffer) as CFData),
              let outCG = CGImage(
                width: width,
                height: height,
                bitsPerComponent: cgImage.bitsPerComponent,
                bitsPerPixel: cgImage.bitsPerPixel,
                bytesPerRow: bytesPerRow,
                space: cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: cgImage.bitmapInfo,
                provider: provider,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
              ) else {
            return source
        }

        return UIImage(cgImage: outCG, scale: source.scale, orientation: .up)
    }
}
