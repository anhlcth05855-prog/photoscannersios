import SwiftUI

@main
public struct PhotoScannerApp: App {
    @StateObject private var repository = ScanRepository()

    public init() {}

    public var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(repository)
                .preferredColorScheme(.light)
        }
    }
}
