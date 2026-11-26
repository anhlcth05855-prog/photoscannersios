import SwiftUI

public struct CollageView: View {
    public let selectedScans: [ScanItem]
    @EnvironmentObject var repository: ScanRepository
    @Environment(\.presentationMode) var presentationMode

    @State private var currentTemplate: CollageTemplate = .polaroids
    @State private var collageTitle: String = "Family Album"
    @State private var generatedImage: UIImage? = nil
    @State private var showShareSheet: Bool = false
    @State private var shareURL: URL? = nil

    private let generator = CollageGenerator()

    public init(selectedScans: [ScanItem]) {
        self.selectedScans = selectedScans
    }

    public var body: some View {
        NavigationView {
            ZStack {
                Color(white: 0.10).ignoresSafeArea()

                VStack(spacing: 16) {
                    // Preview Canvas
                    if let img = generatedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: .infinity)
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                    } else {
                        Spacer()
                        ProgressView("Đang tạo ảnh ghép nghệ thuật...")
                            .foregroundColor(.white)
                        Spacer()
                    }

                    // Template Selector Chips
                    HStack(spacing: 12) {
                        ForEach(CollageTemplate.allCases, id: \.self) { t in
                            Button(action: {
                                currentTemplate = t
                                generateCollage()
                            }) {
                                Text(t.title)
                                    .font(.system(size: 13, weight: currentTemplate == t ? .bold : .medium))
                                    .foregroundColor(currentTemplate == t ? .black : .white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(currentTemplate == t ? Color(red: 0.0, green: 0.9, blue: 0.46) : Color(white: 0.22)))
                            }
                        }
                    }

                    // Export / Save Button
                    Button(action: exportCollage) {
                        HStack {
                            Image(systemName: "square.and.arrow.down.fill")
                            Text("Lưu & Chia Sẻ Ảnh Ghép")
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(red: 0.0, green: 0.9, blue: 0.46)))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Tạo Ảnh Ghép")
            .navigationBarItems(
                leading: Button("Đóng") { presentationMode.wrappedValue.dismiss() }
                    .foregroundColor(.white)
            )
            .onAppear {
                generateCollage()
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = shareURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }

    private func generateCollage() {
        let images: [UIImage] = selectedScans.compactMap { item in
            let path = !item.enhancedImagePath.isEmpty ? item.enhancedImagePath : item.croppedImagePath
            return repository.loadImageFromDisk(path: path)
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let result = generator.createCollage(images: images, template: currentTemplate, title: collageTitle)
            DispatchQueue.main.async {
                self.generatedImage = result
            }
        }
    }

    private func exportCollage() {
        guard let img = generatedImage else { return }
        let savedPath = repository.saveImageToDisk(img, prefix: "collage")
        let item = ScanItem(
            croppedImagePath: savedPath,
            enhancedImagePath: savedPath,
            title: "Collage • \(currentTemplate.title)"
        )
        repository.addScan(item)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Collage_\(UUID().uuidString).jpg")
        if let data = img.jpegData(compressionQuality: 0.95) {
            try? data.write(to: tempURL)
            self.shareURL = tempURL
            self.showShareSheet = true
        }
    }
}
