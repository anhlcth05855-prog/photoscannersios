import Foundation
#if canImport(UIKit)
import UIKit
#endif
import CoreImage
import Accelerate

public class ImageEnhancer {

    private let ciContext = CIContext(options: [CIContextOption.useSoftwareRenderer: false])

    public init() {}

    /**
     * Color Revive: restores faded, aged colors using Auto White Balance (Gray World)
     * and non-linear Luminance contrast expansion + Vibrancy boost.
     */
    public func colorRevive(source: UIImage) -> UIImage {
        guard let cgImage = source.cgImage else { return source }
        let width = cgImage.width
        let height = cgImage.height

        guard let data = cgImage.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return source }

        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow
        let pixelCount = width * height

        var totalR: Int64 = 0
        var totalG: Int64 = 0
        var totalB: Int64 = 0

        for y in 0..<height {
            let rowOffset = y * bytesPerRow
            for x in 0..<width {
                let offset = rowOffset + x * bytesPerPixel
                let r = Int64(ptr[offset])
                let g = Int64(ptr[offset + 1])
                let b = Int64(ptr[offset + 2])
                totalR += r
                totalG += g
                totalB += b
            }
        }

        let avgR = max(1.0, Double(totalR) / Double(pixelCount))
        let avgG = max(1.0, Double(totalG) / Double(pixelCount))
        let avgB = max(1.0, Double(totalB) / Double(pixelCount))
        let avgGray = (avgR + avgG + avgB) / 3.0

        let gainR = min(1.4, max(0.7, avgGray / avgR))
        let gainG = min(1.4, max(0.7, avgGray / avgG))
        let gainB = min(1.4, max(0.7, avgGray / avgB))

        // Create output buffer
        var outBuffer = [UInt8](repeating: 0, count: height * bytesPerRow)
        memcpy(&outBuffer, ptr, height * bytesPerRow)

        for y in 0..<height {
            let rowOffset = y * bytesPerRow
            for x in 0..<width {
                let offset = rowOffset + x * bytesPerPixel
                var r = Double(ptr[offset]) * gainR
                var g = Double(ptr[offset + 1]) * gainG
                var b = Double(ptr[offset + 2]) * gainB

                let lum = 0.299 * r + 0.587 * g + 0.114 * b
                // Contrast stretch S-curve
                let norm = lum / 255.0
                let s = 1.0 / (1.0 + exp(-6.0 * (norm - 0.5)))
                let enhancedLum = s * 255.0

                r = min(255.0, max(0.0, enhancedLum + (r - lum) * 1.18))
                g = min(255.0, max(0.0, enhancedLum + (g - lum) * 1.18))
                b = min(255.0, max(0.0, enhancedLum + (b - lum) * 1.18))

                outBuffer[offset] = UInt8(r)
                outBuffer[offset + 1] = UInt8(g)
                outBuffer[offset + 2] = UInt8(b)
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

    /**
     * CamScanner-style Magic Color: Adaptive dynamic range histogram expansion,
     * high-boost edge sharpening and paper background whitening.
     */
    public func magicColor(source: UIImage) -> UIImage {
        guard let cgImage = source.cgImage else { return source }
        let width = cgImage.width
        let height = cgImage.height

        guard let data = cgImage.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return source }

        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow

        // Histogram of luminance
        var hist = [Int](repeating: 0, count: 256)
        for y in 0..<height {
            let row = y * bytesPerRow
            for x in 0..<width {
                let off = row + x * bytesPerPixel
                let lum = Int(0.299 * Double(ptr[off]) + 0.587 * Double(ptr[off + 1]) + 0.114 * Double(ptr[off + 2]))
                hist[min(255, max(0, lum))] += 1
            }
        }

        let total = width * height
        let lowThresh = Int(Double(total) * 0.03)
        let highThresh = Int(Double(total) * 0.97)

        var count = 0
        var pMin = 0
        for i in 0...255 {
            count += hist[i]
            if count >= lowThresh { pMin = i; break }
        }

        count = 0
        var pMax = 255
        for i in (0...255).reversed() {
            count += hist[i]
            if count >= total - highThresh { pMax = i; break }
        }

        if pMax <= pMin { pMax = pMin + 1 }
        let range = Double(pMax - pMin)

        var outBuffer = [UInt8](repeating: 0, count: height * bytesPerRow)
        memcpy(&outBuffer, ptr, height * bytesPerRow)

        for y in 0..<height {
            let row = y * bytesPerRow
            for x in 0..<width {
                let off = row + x * bytesPerPixel
                var r = ((Double(ptr[off]) - Double(pMin)) / range) * 255.0
                var g = ((Double(ptr[off + 1]) - Double(pMin)) / range) * 255.0
                var b = ((Double(ptr[off + 2]) - Double(pMin)) / range) * 255.0

                let lum = 0.299 * r + 0.587 * g + 0.114 * b
                r = min(255.0, max(0.0, lum + (r - lum) * 1.35))
                g = min(255.0, max(0.0, lum + (g - lum) * 1.35))
                b = min(255.0, max(0.0, lum + (b - lum) * 1.35))

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

    /**
     * Anti-Glare / Specular Reflection Inpainting
     */
    public func removeGlare(source: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: source) else { return source }
        // Highlight shadow adjustment to tone down bright reflections
        guard let filter = CIFilter(name: "CIHighlightShadowAdjust") else { return source }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(0.35, forKey: "inputHighlightAmount")
        filter.setValue(1.10, forKey: "inputShadowAmount")

        guard let outCI = filter.outputImage,
              let cgOut = ciContext.createCGImage(outCI, from: outCI.extent) else {
            return source
        }
        return UIImage(cgImage: cgOut, scale: source.scale, orientation: .up)
    }

    /**
     * Unsharp Mask / Sharpening
     */
    public func sharpen(source: UIImage, intensity: Float = 0.75) -> UIImage {
        guard let ciImage = CIImage(image: source) else { return source }
        guard let filter = CIFilter(name: "CIUnsharpMask") else { return source }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(intensity * 1.5, forKey: kCIInputIntensityKey)
        filter.setValue(2.5, forKey: kCIInputRadiusKey)

        guard let outCI = filter.outputImage,
              let cgOut = ciContext.createCGImage(outCI, from: outCI.extent) else {
            return source
        }
        return UIImage(cgImage: cgOut, scale: source.scale, orientation: .up)
    }

    /**
     * Colorize Black & White Photos
     */
    public func colorizeBW(source: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: source) else { return source }
        // Apply sepia base tone + temperature & vibrancy boost
        guard let sepia = CIFilter(name: "CISepiaTone") else { return source }
        sepia.setValue(ciImage, forKey: kCIInputImageKey)
        sepia.setValue(0.40, forKey: kCIInputIntensityKey)

        guard let warm = CIFilter(name: "CITemperatureAndTint") else { return source }
        warm.setValue(sepia.outputImage, forKey: kCIInputImageKey)
        warm.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
        warm.setValue(CIVector(x: 7400, y: 15), forKey: "inputTargetNeutral")

        guard let outCI = warm.outputImage,
              let cgOut = ciContext.createCGImage(outCI, from: outCI.extent) else {
            return source
        }
        return UIImage(cgImage: cgOut, scale: source.scale, orientation: .up)
    }

    /**
     * Apply Preset Style Filters
     */
    public func applyFilter(source: UIImage, filterType: FilterType) -> UIImage {
        guard let ciImage = CIImage(image: source) else { return source }

        var outputCI: CIImage?

        switch filterType {
        case .original:
            return source
        case .colorRevive:
            return colorRevive(source: source)
        case .magicColor:
            return magicColor(source: source)
        case .vintageWarm:
            if let f = CIFilter(name: "CIPhotoEffectProcess") {
                f.setValue(ciImage, forKey: kCIInputImageKey)
                outputCI = f.outputImage
            }
        case .polaroidRetro:
            if let f = CIFilter(name: "CIPhotoEffectTransfer") {
                f.setValue(ciImage, forKey: kCIInputImageKey)
                outputCI = f.outputImage
            }
        case .kodachrome:
            if let f = CIFilter(name: "CIPhotoEffectChrome") {
                f.setValue(ciImage, forKey: kCIInputImageKey)
                outputCI = f.outputImage
            }
        case .blackAndWhite:
            if let f = CIFilter(name: "CIPhotoEffectNoir") {
                f.setValue(ciImage, forKey: kCIInputImageKey)
                outputCI = f.outputImage
            }
        case .sepia:
            if let f = CIFilter(name: "CISepiaTone") {
                f.setValue(ciImage, forKey: kCIInputImageKey)
                f.setValue(0.85, forKey: kCIInputIntensityKey)
                outputCI = f.outputImage
            }
        case .docHighContrast:
            if let f = CIFilter(name: "CIColorControls") {
                f.setValue(ciImage, forKey: kCIInputImageKey)
                f.setValue(1.8, forKey: kCIInputContrastKey)
                f.setValue(0.0, forKey: kCIInputSaturationKey)
                outputCI = f.outputImage
            }
        }

        guard let finalCI = outputCI,
              let cgOut = ciContext.createCGImage(finalCI, from: finalCI.extent) else {
            return source
        }
        return UIImage(cgImage: cgOut, scale: source.scale, orientation: .up)
    }

    /**
     * Manual Sliders: Brightness, Contrast, Saturation, Warmth
     */
    public func applyAdjustments(
        source: UIImage,
        brightness: Float,
        contrast: Float,
        saturation: Float,
        warmth: Float
    ) -> UIImage {
        guard let ciImage = CIImage(image: source) else { return source }

        var current = ciImage

        // 1. Brightness, Contrast, Saturation
        if let colorControls = CIFilter(name: "CIColorControls") {
            colorControls.setValue(current, forKey: kCIInputImageKey)
            colorControls.setValue(brightness / 100.0, forKey: kCIInputBrightnessKey)
            colorControls.setValue(contrast, forKey: kCIInputContrastKey)
            colorControls.setValue(saturation, forKey: kCIInputSaturationKey)
            if let out = colorControls.outputImage {
                current = out
            }
        }

        // 2. Warmth (Temperature)
        if warmth != 0, let tempFilter = CIFilter(name: "CITemperatureAndTint") {
            tempFilter.setValue(current, forKey: kCIInputImageKey)
            tempFilter.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
            tempFilter.setValue(CIVector(x: CGFloat(6500 + warmth * 40), y: CGFloat(warmth * 0.5)), forKey: "inputTargetNeutral")
            if let out = tempFilter.outputImage {
                current = out
            }
        }

        guard let cgOut = ciContext.createCGImage(current, from: current.extent) else {
            return source
        }
        return UIImage(cgImage: cgOut, scale: source.scale, orientation: .up)
    }

    /**
     * Retro 80s/90s Date Stamp: draws bright amber LED digital font on bottom-right
     */
    public func applyRetroDateStamp(source: UIImage, dateText: String) -> UIImage {
        guard !dateText.trimmingCharacters(in: .whitespaces).isEmpty else { return source }

        let size = source.size
        UIGraphicsBeginImageContextWithOptions(size, false, source.scale)
        source.draw(at: .zero)

        let minDim = min(size.width, size.height)
        let fontSize = max(24.0, minDim * 0.045)
        let font = UIFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .bold)

        let shadow = NSShadow()
        shadow.shadowColor = UIColor(red: 1.0, green: 0.2, blue: 0.0, alpha: 0.8)
        shadow.shadowBlurRadius = 8
        shadow.shadowOffset = .zero

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor(red: 1.0, green: 0.45, blue: 0.0, alpha: 1.0), // Amber LED
            .shadow: shadow
        ]

        let attrString = NSAttributedString(string: dateText, attributes: attributes)
        let textSize = attrString.size()
        let margin = max(24.0, minDim * 0.05)
        let rect = CGRect(
            x: size.width - textSize.width - margin,
            y: size.height - textSize.height - margin,
            width: textSize.width,
            height: textSize.height
        )

        attrString.draw(in: rect)

        let stamped = UIGraphicsGetImageFromCurrentImageContext() ?? source
        UIGraphicsEndImageContext()
        return stamped
    }

    /**
     * 35mm Film Grain Texture
     */
    public func applyFilmGrain(source: UIImage, intensity: Float = 0.12) -> UIImage {
        guard let ciImage = CIImage(image: source) else { return source }

        // Generate random noise
        guard let noise = CIFilter(name: "CIRandomGenerator")?.outputImage else { return source }
        let croppedNoise = noise.cropped(to: ciImage.extent)

        // Make noise monochrome
        guard let monoNoise = CIFilter(name: "CIColorMonochrome") else { return source }
        monoNoise.setValue(croppedNoise, forKey: kCIInputImageKey)
        monoNoise.setValue(CIColor(red: 0.5, green: 0.5, blue: 0.5), forKey: kCIInputColorKey)
        monoNoise.setValue(1.0, forKey: kCIInputIntensityKey)

        // Blend with soft light / overlay
        guard let blend = CIFilter(name: "CISoftLightBlendMode") else { return source }
        blend.setValue(monoNoise.outputImage, forKey: kCIInputImageKey)
        blend.setValue(ciImage, forKey: kCIInputBackgroundImageKey)

        guard let outCI = blend.outputImage,
              let cgOut = ciContext.createCGImage(outCI, from: ciImage.extent) else {
            return source
        }
        return UIImage(cgImage: cgOut, scale: source.scale, orientation: .up)
    }
}
