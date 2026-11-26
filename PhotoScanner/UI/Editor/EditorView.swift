import SwiftUI

public struct EditorView: View {
    @State public var scanItem: ScanItem
    @EnvironmentObject var repository: ScanRepository
    @Environment(\.presentationMode) var presentationMode

    @State private var baseImage: UIImage? = nil
    @State private var enhancedImage: UIImage? = nil
    @State private var isProcessing: Bool = false
    @State private var processingMsg: String = ""
    @State private var showStoryDialog: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var shareURL: URL? = nil

    private let enhancer = ImageEnhancer()
    private let shadowRemover = ShadowRemover()
    private let warper = PerspectiveWarper()

    public init(scanItem: ScanItem) {
        self._scanItem = State(initialValue: scanItem)
    }

    public var body: some View {
        NavigationView {
            ZStack {
                Color(white: 0.08).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top Toolbar
                    HStack {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }

                        Spacer()

                        Text("AI Restoration Studio")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)

                        Spacer()

                        Button(action: sharePhoto) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .padding(.trailing, 8)
                        }

                        Button(action: saveChanges) {
                            Text("Lưu")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color(red: 0.0, green: 0.9, blue: 0.46)))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    // Before / After Slider Canvas
                    if let orig = baseImage, let enh = enhancedImage {
                        BeforeAfterSliderView(originalImage: orig, enhancedImage: enh)
                            .frame(maxHeight: .infinity)
                            .padding(.vertical, 8)
                    } else {
                        Spacer()
                        ProgressView("Đang nạp & phục hồi ảnh...")
                            .foregroundColor(.white)
                        Spacer()
                    }

                    // AI Restoration Tools Action Bar
                    VStack(spacing: 12) {
                        // Quick 1-Tap Buttons Scroll
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ToolActionButton(title: "Phục Hồi Màu", icon: "sparkles", isActive: scanItem.isColorRevived, color: .blue) {
                                    scanItem.isColorRevived.toggle()
                                    reprocess()
                                }
                                ToolActionButton(title: "Khử Chói", icon: "sun.max.fill", isActive: scanItem.isGlareRemoved, color: .green) {
                                    scanItem.isGlareRemoved.toggle()
                                    reprocess()
                                }
                                ToolActionButton(title: "Khử Bóng Đổ", icon: "circle.righthalf.filled", isActive: scanItem.isShadowRemoved, color: .orange) {
                                    scanItem.isShadowRemoved.toggle()
                                    reprocess()
                                }
                                ToolActionButton(title: "Làm Nét", icon: "face.smiling", isActive: scanItem.isSharpened, color: .purple) {
                                    scanItem.isSharpened.toggle()
                                    reprocess()
                                }
                                ToolActionButton(title: "Tô Màu B&W", icon: "paintpalette.fill", isActive: scanItem.isBWColorized, color: .pink) {
                                    scanItem.isBWColorized.toggle()
                                    reprocess()
                                }
                                ToolActionButton(title: "Dấu Ngày Phim", icon: "calendar", isActive: !scanItem.dateStampText.isEmpty, color: .orange) {
                                    scanItem.dateStampText = scanItem.dateStampText.isEmpty ? "'89 12 25" : ""
                                    reprocess()
                                }
                                ToolActionButton(title: "Hạt Film 35mm", icon: "circle.grid.cross.fill", isActive: scanItem.hasFilmGrain, color: .purple) {
                                    scanItem.hasFilmGrain.toggle()
                                    reprocess()
                                }
                                ToolActionButton(title: "Kỷ Niệm", icon: "note.text", isActive: !scanItem.year.isEmpty || !scanItem.story.isEmpty, color: .green) {
                                    showStoryDialog = true
                                }
                                ToolActionButton(title: "Xoay 90°", icon: "rotate.right", isActive: false, color: .white) {
                                    rotateImage()
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        // Style Filter Chips Scroll
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(FilterType.allCases, id: \.self) { f in
                                    Button(action: {
                                        scanItem.filterType = f
                                        reprocess()
                                    }) {
                                        Text(f.displayName)
                                            .font(.system(size: 12, weight: scanItem.filterType == f ? .bold : .medium))
                                            .foregroundColor(scanItem.filterType == f ? .black : .white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 7)
                                            .background(
                                                Capsule().fill(scanItem.filterType == f ? Color(red: 0.0, green: 0.9, blue: 0.46) : Color(white: 0.20))
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 14)
                    .background(Color(white: 0.12))
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadImage()
            }
            .sheet(isPresented: $showStoryDialog) {
                StoryDialogView(scanItem: $scanItem)
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = shareURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }

    private func loadImage() {
        let path = !scanItem.croppedImagePath.isEmpty ? scanItem.croppedImagePath : scanItem.originalImagePath
        if let img = repository.loadImageFromDisk(path: path) {
            self.baseImage = img
            self.enhancedImage = img
            // Auto apply initial enhancement
            scanItem.isColorRevived = true
            scanItem.isSharpened = true
            reprocess()
        }
    }

    private func reprocess() {
        guard let base = baseImage else { return }
        isProcessing = true

        DispatchQueue.global(qos: .userInitiated).async {
            var current = base

            if scanItem.isGlareRemoved {
                current = enhancer.removeGlare(source: current)
            }
            if scanItem.isShadowRemoved {
                current = shadowRemover.removeShadows(source: current)
            }
            if scanItem.isColorRevived {
                current = enhancer.colorRevive(source: current)
            }
            if scanItem.isSharpened {
                current = enhancer.sharpen(source: current)
            }
            if scanItem.isBWColorized {
                current = enhancer.colorizeBW(source: current)
            }
            if scanItem.filterType != .original {
                current = enhancer.applyFilter(source: current, filterType: scanItem.filterType)
            }
            if !scanItem.dateStampText.isEmpty {
                current = enhancer.applyRetroDateStamp(source: current, dateText: scanItem.dateStampText)
            }
            if scanItem.hasFilmGrain {
                current = enhancer.applyFilmGrain(source: current)
            }

            DispatchQueue.main.async {
                self.enhancedImage = current
                self.isProcessing = false
            }
        }
    }

    private func rotateImage() {
        guard let current = enhancedImage else { return }
        let rotated = warper.rotateImage(current, degrees: 90)
        self.baseImage = rotated
        self.enhancedImage = rotated
        reprocess()
    }

    private func saveChanges() {
        guard let enh = enhancedImage else { return }
        let newPath = repository.saveImageToDisk(enh, prefix: "enhanced")
        scanItem.enhancedImagePath = newPath
        repository.updateScan(scanItem)
        presentationMode.wrappedValue.dismiss()
    }

    private func sharePhoto() {
        guard let enh = enhancedImage else { return }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Scan_\(UUID().uuidString).jpg")
        if let data = enh.jpegData(compressionQuality: 0.92) {
            try? data.write(to: tempURL)
            self.shareURL = tempURL
            self.showShareSheet = true
        }
    }
}

private struct ToolActionButton: View {
    let title: String
    let icon: String
    let isActive: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                Text(title)
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(isActive ? Color.black : Color.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(isActive ? color : Color(white: 0.22))
            )
        }
    }
}

#if canImport(UIKit)
public struct ShareSheet: UIViewControllerRepresentable {
    public let activityItems: [Any]

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#else
public struct ShareSheet: View {
    public let activityItems: [Any]
    public var body: some View {
        Text("Share Sheet")
    }
}
#endif
