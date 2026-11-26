import SwiftUI
import AVFoundation

private struct CapturedImageItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

public struct CameraView: View {
    @StateObject private var viewModel: CameraViewModel
    @EnvironmentObject var repository: ScanRepository
    @Environment(\.presentationMode) var presentationMode
    var onClose: (() -> Void)? = nil

    @State private var cropReviewItem: CapturedImageItem? = nil
    @State private var showPhotoPicker = false
    @State private var showOptionsSheet = false
    @State private var selectedRecentScan: ScanItem? = nil
    @State private var shutterScale: CGFloat = 1.0

    public init(initialMode: CameraMode = .docs, onClose: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: CameraViewModel(initialMode: initialMode))
        self.onClose = onClose
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Live Camera Preview Feed
            CameraPreviewView(session: viewModel.captureSession)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.focusAt(point: CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY), in: UIScreen.main.bounds.size)
                }

            // Live Animated Laser Scanner Overlay
            if viewModel.isAiLiveScannerOn {
                LiveScannerOverlayView()
            }

            // Tap Focus Ring
            if let focusPt = viewModel.focusPoint {
                FocusRingView(position: focusPt)
                    .allowsHitTesting(false)
            }

            // Spirit Bubble Level for Flat Scanning
            if viewModel.isLevelEnabled {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        BubbleLevelView(pitch: viewModel.pitch, roll: viewModel.roll)
                            .frame(width: 80, height: 80)
                            .padding(.trailing, 20)
                            .padding(.bottom, 160)
                    }
                }
                .allowsHitTesting(false)
            }

            // Camera Permission Denied Fallback
            if viewModel.cameraPermissionDenied {
                VStack(spacing: 14) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.8))
                    Text("Chưa có quyền truy cập Camera")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("Hãy bật quyền Camera trong Cài Đặt hoặc chọn ảnh từ Thư viện bên dưới.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                    #if canImport(UIKit)
                    Button("Mở Cài Đặt") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color(red: 0.0, green: 0.9, blue: 0.46)))
                    #endif
                }
            }

            // PhotoScan 4-Dot Anti-Glare Overlay
            if viewModel.isAntiGlareActive {
                PhotoScanDotOverlayView(
                    onDotReached: { dotIndex in
                        viewModel.captureAngledFrame(dotIndex: dotIndex)
                    },
                    onAllCompleted: {
                        viewModel.finishAntiGlareStitching()
                    }
                )
            }

            // Top Toolbar (Matching Screenshot 1)
            VStack {
                HStack(spacing: 12) {
                    Button(action: {
                        viewModel.stopSession()
                        onClose?()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }

                    Spacer()

                    // Flash Cycle
                    Button(action: { viewModel.cycleFlash() }) {
                        ZStack(alignment: .bottomTrailing) {
                            Image(systemName: viewModel.isTorchOn ? "bolt.fill" : (viewModel.flashMode == .off ? "bolt.slash.fill" : "bolt.fill"))
                                .font(.system(size: 20))
                                .foregroundColor(viewModel.flashMode == .on || viewModel.isTorchOn ? .yellow : .white)

                            if viewModel.flashMode == .auto {
                                Text("A")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .offset(x: 4, y: 4)
                            }
                        }
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                    }

                    // Flip Camera
                    Button(action: { viewModel.flipCamera() }) {
                        Image(systemName: "camera.rotate.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }

                    // Menu Options
                    Button(action: { showOptionsSheet = true }) {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)

                // Single / Multi Pill Switcher (Matching Screenshot 1)
                HStack(spacing: 0) {
                    Button(action: { viewModel.isMultiMode = false }) {
                        Text("Single")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 7)
                            .background(!viewModel.isMultiMode ? Capsule().fill(Color(red: 0.25, green: 0.35, blue: 0.70)) : Capsule().fill(Color.clear))
                    }

                    Button(action: { viewModel.isMultiMode = true }) {
                        Text("Multi")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 7)
                            .background(viewModel.isMultiMode ? Capsule().fill(Color(red: 0.25, green: 0.35, blue: 0.70)) : Capsule().fill(Color.clear))
                    }
                }
                .background(Capsule().fill(Color.black.opacity(0.45)))
                .padding(.top, 14)

                Spacer()

                // Bottom Controls & Mode Selector (Matching Screenshot 1)
                VStack(spacing: 16) {
                    // Modes Carousel (Scan Code | Docs | Book | Anti-Glare | Continuous | Portrait)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 28) {
                            ForEach(CameraMode.allCases, id: \.self) { mode in
                                Button(action: { viewModel.currentMode = mode }) {
                                    VStack(spacing: 4) {
                                        Text(mode.rawValue)
                                            .font(.system(size: 14, weight: viewModel.currentMode == mode ? .bold : .medium))
                                            .foregroundColor(viewModel.currentMode == mode ? Color(red: 1.0, green: 0.88, blue: 0.0) : Color.white.opacity(0.7))

                                        Circle()
                                            .fill(viewModel.currentMode == mode ? Color(red: 0.0, green: 0.9, blue: 0.46) : Color.clear)
                                            .frame(width: 5, height: 5)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 30)
                    }

                    // Shutter Bar (Matching Screenshot 1)
                    HStack(spacing: 36) {
                        // Import Files / Folder Button
                        Button(action: { showPhotoPicker = true }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(red: 0.25, green: 0.35, blue: 0.70).opacity(0.6))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                        }

                        // Import Gallery Button
                        Button(action: { showPhotoPicker = true }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(red: 0.25, green: 0.35, blue: 0.70).opacity(0.6))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                        }

                        // Center Glowing Shutter Button (Matching Screenshot 1)
                        Button(action: {
                            viewModel.capturePhoto()
                            withAnimation(.easeInOut(duration: 0.1)) { shutterScale = 0.88 }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                withAnimation(.easeOut(duration: 0.15)) { shutterScale = 1.0 }
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .stroke(Color(red: 0.0, green: 0.9, blue: 0.65), lineWidth: 4)
                                    .frame(width: 72, height: 72)

                                Circle()
                                    .fill(Color(red: 0.20, green: 0.35, blue: 0.65))
                                    .frame(width: 58, height: 58)
                            }
                            .scaleEffect(shutterScale)
                            .contentShape(Circle())
                        }

                        // Recent Scanned Thumbnail Shortcut
                        if let first = repository.scans.first,
                           let uiImg = repository.loadImageFromDisk(path: !first.enhancedImagePath.isEmpty ? first.enhancedImagePath : first.croppedImagePath) {
                            Button(action: { selectedRecentScan = first }) {
                                Image(uiImage: uiImg)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 48, height: 48)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.6), lineWidth: 1.5))
                                    .clipped()
                            }
                        } else {
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 48, height: 48)
                        }
                    }
                    .padding(.bottom, 24)
                }
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.85)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }

            // Loading / Processing Overlay
            if viewModel.isProcessing {
                ZStack {
                    Color.black.opacity(0.5).ignoresSafeArea()
                    VStack(spacing: 14) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.4)
                        Text(viewModel.processingMessage.isEmpty ? "Đang xử lý ảnh..." : viewModel.processingMessage)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(24)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(white: 0.15)))
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPickerWrapper { selectedImage in
                if let img = selectedImage {
                    viewModel.capturedOriginalImage = img
                }
            }
        }
        .fullScreenCover(item: $cropReviewItem, onDismiss: {
            viewModel.capturedOriginalImage = nil
        }) { item in
            CropReviewView(originalImage: item.image, isMultiMode: viewModel.isMultiMode)
                .environmentObject(repository)
        }
        .sheet(item: $selectedRecentScan) { item in
            EditorView(scanItem: item)
                .environmentObject(repository)
        }
        .actionSheet(isPresented: $showOptionsSheet) {
            ActionSheet(
                title: Text("Tùy chọn Camera"),
                buttons: [
                    .default(Text(viewModel.isAiLiveScannerOn ? "Tắt khung quét Laser" : "Bật khung quét Laser")) {
                        viewModel.isAiLiveScannerOn.toggle()
                    },
                    .default(Text(viewModel.isLevelEnabled ? "Tắt thước cân bằng" : "Bật thước cân bằng")) {
                        viewModel.isLevelEnabled.toggle()
                    },
                    .cancel(Text("Đóng"))
                ]
            )
        }
        .onAppear {
            viewModel.checkPermissionAndSetupSession()
        }
        .onDisappear {
            viewModel.stopSession()
        }
        .onChange(of: viewModel.capturedOriginalImage) { img in
            if let img = img {
                cropReviewItem = CapturedImageItem(image: img)
            }
        }
    }
}

#if canImport(UIKit)
import UIKit

public struct CameraPreviewView: UIViewRepresentable {
    public let session: AVCaptureSession

    public final class PreviewUIView: UIView {
        public override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        public var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }

    public func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.backgroundColor = .black
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    public func updateUIView(_ uiView: PreviewUIView, context: Context) {
        if uiView.previewLayer.session !== session {
            uiView.previewLayer.session = session
        }
    }
}

public struct PhotoPickerWrapper: UIViewControllerRepresentable {
    public let onPick: (UIImage?) -> Void
    @Environment(\.presentationMode) var presentationMode

    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PhotoPickerWrapper
        init(_ parent: PhotoPickerWrapper) { self.parent = parent }

        public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let img = info[.originalImage] as? UIImage
            parent.onPick(img)
            parent.presentationMode.wrappedValue.dismiss()
        }

        public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
#else
public struct CameraPreviewView: View {
    public let session: AVCaptureSession
    public var body: some View {
        Color.black
    }
}

public struct PhotoPickerWrapper: View {
    public let onPick: (UIImage?) -> Void
    public var body: some View {
        Text("Photo Picker")
    }
}
#endif
