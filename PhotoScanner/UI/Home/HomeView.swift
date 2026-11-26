import SwiftUI

public struct HomeView: View {
    @EnvironmentObject var repository: ScanRepository
    @Binding var selectedTab: Int
    @State private var searchText = ""
    @State private var selectedScanForEditor: ScanItem?

    public init(selectedTab: Binding<Int>) {
        self._selectedTab = selectedTab
    }

    public var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.97, green: 0.97, blue: 0.98).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Top Header (Matching screenshot 2)
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(Color(red: 0.0, green: 0.78, blue: 0.42))
                                Text("Photo Scanner")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.black)
                            }
                            Spacer()
                            Button(action: {}) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 20))
                                    .foregroundColor(.black)
                            }
                            Button(action: {}) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.0))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)

                        // CamScanner Promo Banner (Matching screenshot 2)
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(red: 0.12, green: 0.22, blue: 0.45))
                                    .frame(width: 46, height: 46)
                                Text("CS")
                                    .font(.system(size: 20, weight: .black))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Photo Scanner Pro")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.black)
                                HStack(spacing: 4) {
                                    Text("4.9 ★")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.orange)
                                    Text("• Miễn phí AI Engine")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            }

                            Spacer()

                            Button(action: { selectedTab = 2 }) {
                                Text("Quét Ngay")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(Color(red: 0.15, green: 0.35, blue: 0.95)))
                            }
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white).shadow(color: .black.opacity(0.04), radius: 6))
                        .padding(.horizontal, 20)

                        // Quick Action Tools Grid (Matching screenshot 2)
                        HStack(spacing: 16) {
                            ToolGridButton(icon: "sparkles.rectangle.stack.fill", title: "AI Scan", color: .orange) {
                                selectedTab = 2
                            }
                            ToolGridButton(icon: "qrcode.viewfinder", title: "Scan QR", color: .blue) {
                                selectedTab = 2
                            }
                            ToolGridButton(icon: "person.text.rectangle.fill", title: "ID Cards", color: .green) {
                                selectedTab = 2
                            }
                            ToolGridButton(icon: "scissors", title: "Split PDF", color: .purple) {
                                selectedTab = 3
                            }
                            ToolGridButton(icon: "doc.on.doc.fill", title: "Merge PDF", color: .red) {
                                selectedTab = 3
                            }
                        }
                        .padding(.horizontal, 20)

                        // Recent Section Header (Matching screenshot 2)
                        HStack {
                            Text("Recent")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.black)
                            Button(action: {}) {
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Button(action: {}) {
                                Image(systemName: "folder.badge.plus")
                                    .font(.system(size: 18))
                                    .foregroundColor(.gray)
                            }
                            Button(action: {}) {
                                Image(systemName: "ellipsis.circle")
                                    .font(.system(size: 18))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // Recent List or Empty State (Matching screenshot 2)
                        if repository.scans.isEmpty {
                            VStack(spacing: 14) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.system(size: 54))
                                    .foregroundColor(Color.gray.opacity(0.5))
                                    .padding(.top, 40)
                                Text("No Document Scanned Yet.")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.gray)
                                Button(action: { selectedTab = 2 }) {
                                    HStack {
                                        Image(systemName: "camera.fill")
                                        Text("Bắt Đầu Quét Ảnh Đầu Tiên")
                                    }
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Capsule().fill(Color(red: 0.0, green: 0.78, blue: 0.42)))
                                }
                                .padding(.top, 10)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 60)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(repository.scans) { item in
                                    ScanCardRow(item: item) {
                                        selectedScanForEditor = item
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 80)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedScanForEditor) { item in
                EditorView(scanItem: item)
                    .environmentObject(repository)
            }
        }
    }
}

private struct ToolGridButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(color.opacity(0.12))
                        .frame(width: 54, height: 54)
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(color)
                }
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.black)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ScanCardRow: View {
    let item: ScanItem
    let onTap: () -> Void
    @EnvironmentObject var repository: ScanRepository

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                let path = !item.enhancedImagePath.isEmpty ? item.enhancedImagePath : item.croppedImagePath
                if let uiImg = repository.loadImageFromDisk(path: path) {
                    Image(uiImage: uiImg)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .cornerRadius(10)
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 64, height: 64)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)
                        .lineLimit(1)

                    if !item.year.isEmpty || !item.location.isEmpty {
                        Text("\(item.year) • \(item.location)")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }

                    HStack(spacing: 6) {
                        if item.isColorRevived {
                            BadgeLabel(title: "Color Revive", color: .blue)
                        }
                        if item.isGlareRemoved {
                            BadgeLabel(title: "Anti-Glare", color: .green)
                        }
                    }
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white).shadow(color: .black.opacity(0.03), radius: 4))
        }
    }
}

private struct BadgeLabel: View {
    let title: String
    let color: Color
    var body: some View {
        Text(title)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.12)))
    }
}
