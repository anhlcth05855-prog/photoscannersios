import Foundation
#if canImport(UIKit)
import UIKit
#endif
import PDFKit
import Combine

public class ScanRepository: ObservableObject {

    @Published public var scans: [ScanItem] = []

    private let fileManager = FileManager.default
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()

    private var storageDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("PhotoScannerStorage", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private var metadataFileURL: URL {
        return storageDirectory.appendingPathComponent("scans_metadata.json")
    }

    public init() {
        loadMetadata()
    }

    public func loadMetadata() {
        guard fileManager.fileExists(atPath: metadataFileURL.path),
              let data = try? Data(contentsOf: metadataFileURL),
              let list = try? jsonDecoder.decode([ScanItem].self, from: data) else {
            return
        }
        self.scans = list.sorted { $0.timestamp > $1.timestamp }
    }

    public func saveMetadata() {
        if let data = try? jsonEncoder.encode(scans) {
            try? data.write(to: metadataFileURL, options: .atomic)
        }
    }

    public func addScan(_ item: ScanItem) {
        var mutable = scans
        mutable.removeAll { $0.id == item.id }
        mutable.insert(item, at: 0)
        self.scans = mutable
        saveMetadata()
    }

    public func updateScan(_ item: ScanItem) {
        if let idx = scans.firstIndex(where: { $0.id == item.id }) {
            scans[idx] = item
            saveMetadata()
        }
    }

    public func deleteScan(id: String) {
        if let item = scans.first(where: { $0.id == id }) {
            try? fileManager.removeItem(atPath: item.originalImagePath)
            try? fileManager.removeItem(atPath: item.croppedImagePath)
            try? fileManager.removeItem(atPath: item.enhancedImagePath)
        }
        scans.removeAll { $0.id == id }
        saveMetadata()
    }

    public func saveImageToDisk(_ image: UIImage, prefix: String = "scan") -> String {
        let fileName = "\(prefix)_\(UUID().uuidString).jpg"
        let fileURL = storageDirectory.appendingPathComponent(fileName)
        if let data = image.jpegData(compressionQuality: 0.92) {
            try? data.write(to: fileURL)
            return fileURL.path
        }
        return ""
    }

    public func loadImageFromDisk(path: String) -> UIImage? {
        guard !path.isEmpty, fileManager.fileExists(atPath: path) else { return nil }
        return UIImage(contentsOfFile: path)
    }

    public func exportScansToPDF(items: [ScanItem], pdfTitle: String = "Scanned Album") -> URL? {
        let pdfDoc = PDFDocument()
        var pageIndex = 0

        for item in items {
            let path = !item.enhancedImagePath.isEmpty ? item.enhancedImagePath : item.croppedImagePath
            guard let img = loadImageFromDisk(path: path) else { continue }

            let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 format
            let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

            let pdfData = renderer.pdfData { context in
                context.beginPage()
                // Fit image maintaining aspect ratio
                let imgW = img.size.width
                let imgH = img.size.height
                let scale = min((pageRect.width - 40) / imgW, (pageRect.height - 120) / imgH)
                let drawW = imgW * scale
                let drawH = imgH * scale
                let drawX = (pageRect.width - drawW) / 2
                let drawY = (pageRect.height - drawH - 40) / 2

                img.draw(in: CGRect(x: drawX, y: drawY, width: drawW, height: drawH))

                // Footer caption if year/location exists
                if !item.year.isEmpty || !item.location.isEmpty {
                    let caption = "\(item.title) • \(item.year) • \(item.location)"
                    let font = UIFont.systemFont(ofSize: 11, weight: .medium)
                    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.darkGray]
                    caption.draw(at: CGPoint(x: drawX, y: drawY + drawH + 12), withAttributes: attrs)
                }
            }

            if let docPage = PDFDocument(data: pdfData)?.page(at: 0) {
                pdfDoc.insert(docPage, at: pageIndex)
                pageIndex += 1
            }
        }

        let pdfURL = storageDirectory.appendingPathComponent("Album_\(Date().timeIntervalSince1970).pdf")
        if pdfDoc.write(to: pdfURL) {
            return pdfURL
        }
        return nil
    }
}
