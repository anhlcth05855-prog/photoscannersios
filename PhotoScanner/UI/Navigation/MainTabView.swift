import SwiftUI

public struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @State private var showCameraModal: Bool = false
    @EnvironmentObject var repository: ScanRepository

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView(selectedTab: $selectedTab)
                    .tag(0)

                GalleryView()
                    .tag(1)

                // Placeholder for center camera button
                Color.clear
                    .tag(2)

                GalleryView()
                    .tag(3)

                SettingsView()
                    .tag(4)
            }

            // Custom Floating Bottom Navigation Bar (Matching Screenshot 2)
            HStack {
                // Tab 0: Home
                TabBarItem(icon: "house.fill", title: "Home", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }

                Spacer()

                // Tab 1: Docs
                TabBarItem(icon: "doc.text.fill", title: "Docs", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }

                Spacer()

                // Center Large Aperture Scan Button (Matching Screenshot 2)
                Button(action: { showCameraModal = true }) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.20, green: 0.25, blue: 0.35))
                            .frame(width: 60, height: 60)
                            .shadow(color: .black.opacity(0.2), radius: 6, y: 3)

                        // Camera Aperture Icon
                        Image(systemName: "camera.aperture")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)

                        // Top-Right Plus Badge
                        Circle()
                            .fill(Color(red: 0.0, green: 0.78, blue: 0.42))
                            .frame(width: 18, height: 18)
                            .overlay(
                                Image(systemName: "plus")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 18, y: -18)
                    }
                }
                .offset(y: -14)

                Spacer()

                // Tab 3: Tools
                TabBarItem(icon: "square.grid.2x2.fill", title: "Tools", isSelected: selectedTab == 3) {
                    selectedTab = 3
                }

                Spacer()

                // Tab 4: Settings
                TabBarItem(icon: "gearshape.fill", title: "Settings", isSelected: selectedTab == 4) {
                    selectedTab = 4
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 22)
            .background(
                Color.white
                    .shadow(color: .black.opacity(0.08), radius: 10, y: -4)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .fullScreenCover(isPresented: $showCameraModal) {
            CameraView()
                .environmentObject(repository)
        }
    }
}

private struct TabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
            }
            .foregroundColor(isSelected ? Color(red: 0.0, green: 0.78, blue: 0.42) : Color.gray.opacity(0.8))
        }
    }
}
