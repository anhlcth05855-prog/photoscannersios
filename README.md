# 📱 Photo Scanner Plus – Native iOS (SwiftUI & Vision AI)

Ứng dụng quét ảnh và phục hồi ảnh cũ chuẩn Flagship cho nền tảng **iOS (iPhone / iPad)**, được xây dựng 100% bằng **Swift 5.9+**, **SwiftUI**, **Vision.framework**, **AVFoundation**, **CoreImage**, và **CoreGraphics**, tương đương hoàn toàn với phiên bản Android.

---

## 🌟 Các Tính Năng Cốt Lõi Đã Triển Khai (100% Native iOS)

| Chức Năng | Công Nghệ & Thuật Toán iOS | File Mã Nguồn Xử Lý |
| :--- | :--- | :--- |
| **Quét Đa Ảnh (Multi-Photo)** | `VNDetectRectanglesRequest` (Vision.framework) kết hợp thuật toán NMS lọc diện tích $\ge 6\%$ và tỷ lệ khung hình $0.35 \le W/H \le 2.85$. | [`ContourDetector.swift`](PhotoScanner/CV/ContourDetector.swift) |
| **Nắn Thẳng Phối Cảnh (Perspective Warp)** | Biến đổi phối cảnh 4 góc tự do với `CIPerspectiveCorrection` & `CIContext` GPU. | [`PerspectiveWarper.swift`](PhotoScanner/CV/PerspectiveWarper.swift) |
| **Khử Chói 4 Điểm (Google PhotoScan)** | Thuật toán hợp nhất điểm ảnh không chói (Multi-angle Non-Glare Pixel Fusion) kèm lớp phủ định vị 4 điểm và con quay hồi chuyển. | [`AntiGlareStitcher.swift`](PhotoScanner/CV/AntiGlareStitcher.swift), [`PhotoScanDotOverlayView.swift`](PhotoScanner/UI/Views/PhotoScanDotOverlayView.swift) |
| **Khử Bóng Đổ (Adobe Scan)** | Thuật toán Retinex tách trường chiếu sáng nền và độ phản xạ quang phổ triệt tiêu bóng tay / bóng điện thoại. | [`ShadowRemover.swift`](PhotoScanner/CV/ShadowRemover.swift) |
| **Phục Hồi Màu & Magic Color** | Thuật toán Gray World Auto White Balance, tone mapping S-curve và CamScanner Magic Color mở rộng dải tương phản. | [`ImageEnhancer.swift`](PhotoScanner/CV/ImageEnhancer.swift) |
| **Tự Động Xoay Theo Khuôn Mặt (Auto-Orientation)** | Phát hiện vị trí mắt/miệng bằng `VNDetectFaceLandmarksRequest` để tự động xoay ảnh về đúng chiều đứng. | [`FaceDetectorHelper.swift`](PhotoScanner/CV/FaceDetectorHelper.swift) |
| **Đóng Dấu Ngày & Hạt Phim Hoài Cổ** | Đóng dấu số LED cam hổ phách thập niên 80s/90s và tạo texture hạt phim 35mm. | [`ImageEnhancer.swift`](PhotoScanner/CV/ImageEnhancer.swift) |
| **Ghép Ảnh Nghệ Thuật (Collage Maker)** | Mẫu Polaroid xếp lớp 3D, Lưới cân đối và Trang sổ lưu niệm cổ điển. | [`CollageGenerator.swift`](PhotoScanner/CV/CollageGenerator.swift), [`CollageView.swift`](PhotoScanner/UI/Collage/CollageView.swift) |
| **Quản Lý Album & Xuất PDF** | Tìm kiếm thông minh, lọc theo thập niên, xuất album PDF chuẩn A4 bằng `PDFKit`. | [`ScanRepository.swift`](PhotoScanner/Data/ScanRepository.swift), [`GalleryView.swift`](PhotoScanner/UI/Gallery/GalleryView.swift) |

---

## 📂 Cấu Trúc Thư Mục Dự Án iOS

```
photoscanner_ios-main/
├── Package.swift                               # Swift Package Manager Manifest
├── README.md                                   # Tài liệu hướng dẫn
└── PhotoScanner/
    ├── App/
    │   ├── PhotoScannerApp.swift               # Điểm khởi chạy ứng dụng SwiftUI
    │   └── Info.plist                          # Quyền truy cập Camera, Photo Library, Motion
    ├── Data/
    │   ├── ScanItem.swift                      # Data model (Codable, Identifiable)
    │   ├── ScanRepository.swift                # Lưu trữ file, quản lý metadata, xuất PDF
    │   └── CloudAIService.swift                # Client gọi GPU Cloud AI (DeOldify/GFPGAN)
    ├── CV/
    │   ├── Quad.swift                          # Định nghĩa 4 đỉnh đa giác và tính toán hình học
    │   ├── GeometryUtils.swift                 # Sắp xếp điểm thuận chiều kim đồng hồ, tính IoU
    │   ├── ContourDetector.swift               # Nhận diện đa khung ảnh qua Apple Vision
    │   ├── PerspectiveWarper.swift             # Nắn thẳng phối cảnh 2D CoreImage
    │   ├── FaceDetectorHelper.swift            # Nhận diện khuôn mặt & Tự động xoay chiều ảnh
    │   ├── ImageEnhancer.swift                 # Phục hồi màu, Magic Color, Dấu ngày, Hạt phim
    │   ├── AntiGlareStitcher.swift             # Ghép 4 điểm khử lóa đèn flash (Google PhotoScan)
    │   ├── ShadowRemover.swift                 # Khử bóng tay & điện thoại (Adobe Scan Retinex)
    │   └── CollageGenerator.swift              # Bộ sinh ảnh ghép Polaroid & Sổ kỷ niệm
    └── UI/
        ├── Navigation/
        │   └── MainTabView.swift               # Thanh điều hướng 5 tab chuẩn giao diện
        ├── Home/
        │   └── HomeView.swift                  # Màn hình chính (Header, Quick tools, Recents)
        ├── Camera/
        │   ├── CameraView.swift                # Giao diện máy ảnh chuyên nghiệp (Pills, Shutter)
        │   └── CameraViewModel.swift           # Quản lý AVCaptureSession, Cảm biến, Chế độ chụp
        ├── Crop/
        │   ├── CropReviewView.swift            # Màn hình chỉnh 4 góc phối cảnh
        │   └── QuadCropOverlayView.swift       # 4 điểm kéo tương tác trên màn hình cảm ứng
        ├── Editor/
        │   ├── EditorView.swift                # AI Restoration Studio đầy đủ công cụ
        │   ├── BeforeAfterSliderView.swift     # Thanh trượt so sánh Trước / Sau tương tác
        │   └── StoryDialogView.swift           # Hộp thoại ghi chú câu chuyện & năm chụp
        ├── Gallery/
        │   └── GalleryView.swift               # Thư viện ảnh, tìm kiếm, xuất PDF hàng loạt
        ├── Collage/
        │   └── CollageView.swift               # Màn hình tạo ảnh ghép nghệ thuật
        ├── Settings/
        │   └── SettingsView.swift              # Cài đặt ứng dụng & Endpoint Cloud AI
        └── Views/
            ├── LiveScannerOverlayView.swift    # Hiệu ứng tia laser & 4 góc quét động
            ├── PhotoScanDotOverlayView.swift   # Lớp phủ 4 chấm khử chói với cảm biến nghiêng
            ├── BubbleLevelView.swift           # Thước thủy bọt nước cân bằng mặt phẳng
            └── FocusRingView.swift             # Vòng tròn chạm lấy nét (Tap to focus)
```

---

## 🚀 Hướng Dẫn Mở & Chạy Dự Án Trên Xcode

1. Mở **Xcode** trên máy macOS.
2. Chọn **File** > **Open** và duyệt đến thư mục `c:\Users\ASUS\Downloads\photoscanner_ios-main`.
3. Chọn thiết bị đích (**iPhone 15/16 Pro Simulator** hoặc **Thiết bị iOS thật** qua cáp USB).
4. Nhấn tổ hợp phím `Cmd + R` để Build & Run ứng dụng!
