import SwiftUI

public struct CropReviewView: View {
    public let originalImage: UIImage
    public let isMultiMode: Bool

    @EnvironmentObject var repository: ScanRepository
    @Environment(\.presentationMode) var presentationMode

    @State private var detectedQuads: [Quad] = []
    @State private var activeQuadIndex: Int = 0
    @State private var isLoading: Bool = true
    @State private var navigateToEditor: ScanItem? = nil

    private let contourDetector = ContourDetector()
    private let perspectiveWarper = PerspectiveWarper()
    private let faceDetector = FaceDetectorHelper()

    public init(originalImage: UIImage, isMultiMode: Bool = true) {
        self.originalImage = originalImage
        self.isMultiMode = isMultiMode
    }

    public var body: some View {
        NavigationView {
            ZStack {
                Color(white: 0.10).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top Bar
                    HStack {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(10)
                        }

                        Spacer()

                        Text("Nắn Thẳng & Cắt Phối Cảnh")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)

                        Spacer()

                        Button(action: expandActiveQuad) {
                            Text("Mở Rộng Viền")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(red: 0.0, green: 0.9, blue: 0.46))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().stroke(Color(red: 0.0, green: 0.9, blue: 0.46), lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    Spacer()

                    // Center Interactive Image with Quad Crop Overlay
                    if !detectedQuads.isEmpty {
                        ZStack {
                            Image(uiImage: originalImage)
                                .resizable()
                                .scaledToFit()
                                .padding(12)

                            QuadCropOverlayView(
                                quad: $detectedQuads[activeQuadIndex],
                                imageSize: originalImage.size
                            )
                            .padding(12)
                        }
                    } else if isLoading {
                        ProgressView("Đang phát hiện góc ảnh...")
                            .foregroundColor(.white)
                    }

                    Spacer()

                    // Multi-Photo Carousel Thumbnails (if multiple photos found)
                    if detectedQuads.count > 1 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(0..<detectedQuads.count, id: \.self) { idx in
                                    Button(action: { activeQuadIndex = idx }) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(activeQuadIndex == idx ? Color(red: 0.0, green: 0.9, blue: 0.46) : Color.white.opacity(0.3), lineWidth: 2.5)
                                                .frame(width: 72, height: 72)

                                            Text("Ảnh #\(idx + 1)")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(activeQuadIndex == idx ? Color(red: 0.0, green: 0.9, blue: 0.46) : .white)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 10)
                    }

                    // Bottom Confirm Button
                    Button(action: confirmAndSaveAllCrops) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Hoàn Tất Cắt & Nắn Ảnh (\(detectedQuads.count))")
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(red: 0.0, green: 0.9, blue: 0.46)))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                runDetection()
            }
            .sheet(item: $navigateToEditor) { item in
                EditorView(scanItem: item)
                    .environmentObject(repository)
            }
        }
    }

    private func runDetection() {
        isLoading = true
        Task {
            let quads = await contourDetector.detectQuads(sourceImage: originalImage, isMultiPhoto: isMultiMode)
            await MainActor.run {
                self.detectedQuads = quads
                self.activeQuadIndex = 0
                self.isLoading = false
            }
        }
    }

    private func expandActiveQuad() {
        guard activeQuadIndex < detectedQuads.count else { return }
        detectedQuads[activeQuadIndex] = Quad.full(width: originalImage.size.width, height: originalImage.size.height, insetRatio: 0.0)
    }

    private func confirmAndSaveAllCrops() {
        let origPath = repository.saveImageToDisk(originalImage, prefix: "original")
        var firstItem: ScanItem? = nil

        for (idx, q) in detectedQuads.enumerated() {
            var cropped = perspectiveWarper.warpPerspective(source: originalImage, quad: q)

            // Auto-Orientation check via Face Landmarks
            Task {
                let rot = await faceDetector.detectOrientationAngle(source: cropped)
                if rot != 0 {
                    cropped = perspectiveWarper.rotateImage(cropped, degrees: rot)
                }

                let cropPath = repository.saveImageToDisk(cropped, prefix: "crop")
                let scanItem = ScanItem(
                    originalImagePath: origPath,
                    croppedImagePath: cropPath,
                    enhancedImagePath: cropPath,
                    title: "Scan #\(repository.scans.count + 1)",
                    quad: q
                )
                repository.addScan(scanItem)

                if idx == 0 {
                    firstItem = scanItem
                }

                if idx == detectedQuads.count - 1 {
                    await MainActor.run {
                        self.navigateToEditor = firstItem
                    }
                }
            }
        }
    }
}
