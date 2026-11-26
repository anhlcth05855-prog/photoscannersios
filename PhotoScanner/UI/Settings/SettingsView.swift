import SwiftUI

public struct SettingsView: View {
    @AppStorage("cloud_ai_endpoint_url") private var cloudAiUrl: String = ""
    @AppStorage("cloud_ai_enabled") private var cloudAiEnabled: Bool = false
    @AppStorage("high_quality_export") private var highQualityExport: Bool = true
    @AppStorage("auto_flash_level") private var autoFlashLevel: Bool = true

    @EnvironmentObject var repository: ScanRepository

    public init() {}

    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("AI Cloud Restoration Engine")) {
                    Toggle("Bật GPU Cloud AI (DeOldify / GFPGAN)", isOn: $cloudAiEnabled)
                    if cloudAiEnabled {
                        TextField("Endpoint URL (VD: https://ai.server.com/api)", text: $cloudAiUrl)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    Text("Khi bật, ảnh sẽ được chuyển đến máy chủ GPU để phục hồi độ nét khuôn mặt và tô màu chi tiết.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }

                Section(header: Text("Cài Đặt Quét & Xuất File")) {
                    Toggle("Xuất PDF & Ảnh Chất Lượng Cao", isOn: $highQualityExport)
                    Toggle("Tự động cân bằng sáng khi quét", isOn: $autoFlashLevel)
                }

                Section(header: Text("Bộ Nhớ & Dữ Liệu")) {
                    HStack {
                        Text("Tổng số ảnh đã scan")
                        Spacer()
                        Text("\(repository.scans.count)")
                            .foregroundColor(.gray)
                    }

                    Button("Xóa Toàn Bộ Dữ Liệu Scan") {
                        for item in repository.scans {
                            repository.deleteScan(id: item.id)
                        }
                    }
                    .foregroundColor(.red)
                }

                Section(header: Text("Thông Tin Ứng Dụng")) {
                    HStack {
                        Text("Phiên bản")
                        Spacer()
                        Text("2.0.0 (Flagship Edition)")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Cài Đặt")
        }
    }
}
