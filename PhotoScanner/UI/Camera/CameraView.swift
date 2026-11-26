import SwiftUI
import AVFoundation

public struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    @EnvironmentObject var repository: ScanRepository
    @Environment(\.presentationMode) var presentationMode

    @State private var showCropReview = false
    @State private var showPhotoPicker = false
    @State private var shutterScale: CGFloat = 1.0

    public init() {}

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Live Camera Preview Feed
            CameraPreviewView(session: viewModel.captureSession)
                .ignoresSafeArea()
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            viewModel.focusAt(point: value.location, in: UIScreen.main.bounds.size)
                        }
                )

            // Live Animated Laser Scanner Overlay
            if viewModel.isAiLiveScannerOn {
                LiveScannerOverlayView()
            }

            // Tap Focus Ring
            if let focusPt = viewModel.focusPoint {
                FocusRingView(position: focusPt)
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
                HStack(spacing: 24) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
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
                    }

                    // Flip Camera
                    Button(action: { viewModel.flipCamera() }) {
                        Image(systemName: "camera.rotate.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }

                    // Menu Options
                    Button(action: {}) {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

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
                            withAnimation(.easeInOut(duration: 0.1)) { shutterScale = 0.88 }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeOut(duration: 0.15)) { shutterScale = 1.0 }
                                viewModel.capturePhoto()
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
                        }

                        // Recent Scanned Thumbnail Shortcut
                        if let first = repository.scans.first,
                           let uiImg = repository.loadImageFromDisk(path: !first.enhancedImagePath.isEmpty ? first.enhancedImagePath : first.croppedImagePath) {
                            Image(uiImage: uiImg)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.6), lineWidth: 1.5))
                                .clipped()
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
        .fullScreenCover(isPresented: $showCropReview) {
            if let img = viewModel.capturedOriginalImage {
                CropReviewView(originalImage: img, isMultiMode: viewModel.isMultiMode)
                    .environmentObject(repository)
            }
        }
        .onChange(of: viewModel.capturedOriginalImage) { img in
            if img != nil {
                showCropReview = true
            }
        }
    }
}

#if canImport(UIKit)
import UIKit

public struct CameraPreviewView: UIViewRepresentable {
    public let session: AVCaptureSession

    public func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            layer.frame = uiView.bounds
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
