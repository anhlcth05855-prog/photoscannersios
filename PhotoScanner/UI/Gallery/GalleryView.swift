import SwiftUI

public struct GalleryView: View {
    @EnvironmentObject var repository: ScanRepository
    @State private var searchText = ""
    @State private var selectedFilter: String = "Tất cả"
    @State private var isMultiSelectMode: Bool = false
    @State private var selectedScanIds: Set<String> = []
    @State private var selectedScanForEditor: ScanItem? = nil
    @State private var showCollageView: Bool = false
    @State private var exportedPDFURL: URL? = nil
    @State private var showShareSheet: Bool = false

    private let filterChips = ["Tất cả", "Đã phục hồi AI", "Có kỷ niệm", "Thập niên 70s-80s", "Thập niên 90s-2000s"]

    public init() {}

    public var filteredScans: [ScanItem] {
        repository.scans.filter { item in
            let matchesSearch = searchText.isEmpty ||
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.year.localizedCaseInsensitiveContains(searchText) ||
                item.location.localizedCaseInsensitiveContains(searchText) ||
                item.people.localizedCaseInsensitiveContains(searchText)

            let matchesChip: Bool
            switch selectedFilter {
            case "Đã phục hồi AI": matchesChip = item.isColorRevived || item.isSharpened
            case "Có kỷ niệm": matchesChip = !item.story.isEmpty || !item.year.isEmpty
            case "Thập niên 70s-80s":
                if let y = Int(item.year) { matchesChip = (y >= 1970 && y < 1990) } else { matchesChip = false }
            case "Thập niên 90s-2000s":
                if let y = Int(item.year) { matchesChip = (y >= 1990 && y < 2010) } else { matchesChip = false }
            default: matchesChip = true
            }

            return matchesSearch && matchesChip
        }
    }

    public var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.97, green: 0.97, blue: 0.98).ignoresSafeArea()

                VStack(spacing: 12) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Tìm theo năm, địa điểm, người thân...", text: $searchText)
                            .font(.system(size: 14))
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white).shadow(color: .black.opacity(0.04), radius: 4))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // Filter Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(filterChips, id: \.self) { chip in
                                Button(action: { selectedFilter = chip }) {
                                    Text(chip)
                                        .font(.system(size: 12, weight: selectedFilter == chip ? .bold : .medium))
                                        .foregroundColor(selectedFilter == chip ? .white : .black)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Capsule().fill(selectedFilter == chip ? Color(red: 0.0, green: 0.78, blue: 0.42) : Color.white))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Scans Grid
                    if filteredScans.isEmpty {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("Chưa có ảnh trong danh mục này")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                                ForEach(filteredScans) { item in
                                    ScanGridCell(
                                        item: item,
                                        isMultiSelect: isMultiSelectMode,
                                        isSelected: selectedScanIds.contains(item.id)
                                    ) {
                                        if isMultiSelectMode {
                                            if selectedScanIds.contains(item.id) {
                                                selectedScanIds.remove(item.id)
                                            } else {
                                                selectedScanIds.insert(item.id)
                                            }
                                        } else {
                                            selectedScanForEditor = item
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 80)
                        }
                    }

                    // Multi-Select Batch Bar (if active)
                    if isMultiSelectMode && !selectedScanIds.isEmpty {
                        HStack(spacing: 16) {
                            Button(action: batchExportPDF) {
                                Label("Xuất PDF (\(selectedScanIds.count))", systemImage: "doc.richtext.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Capsule().fill(Color.blue))
                            }

                            Button(action: { showCollageView = true }) {
                                Label("Ghép Ảnh", systemImage: "square.grid.2x2.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Capsule().fill(Color.purple))
                            }

                            Button(action: batchDelete) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Circle().fill(Color.red))
                            }
                        }
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white).shadow(radius: 6))
                        .padding(.bottom, 60)
                    }
                }
            }
            .navigationTitle("Album & Tài Liệu")
            .navigationBarItems(
                trailing: Button(action: {
                    isMultiSelectMode.toggle()
                    if !isMultiSelectMode { selectedScanIds.removeAll() }
                }) {
                    Text(isMultiSelectMode ? "Hủy" : "Chọn")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(red: 0.0, green: 0.78, blue: 0.42))
                }
            )
            .sheet(item: $selectedScanForEditor) { item in
                EditorView(scanItem: item)
                    .environmentObject(repository)
            }
            .sheet(isPresented: $showCollageView) {
                let selectedItems = repository.scans.filter { selectedScanIds.contains($0.id) }
                CollageView(selectedScans: selectedItems)
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedPDFURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }

    private func batchExportPDF() {
        let items = repository.scans.filter { selectedScanIds.contains($0.id) }
        if let pdfUrl = repository.exportScansToPDF(items: items) {
            self.exportedPDFURL = pdfUrl
            self.showShareSheet = true
        }
    }

    private func batchDelete() {
        for id in selectedScanIds {
            repository.deleteScan(id: id)
        }
        selectedScanIds.removeAll()
        isMultiSelectMode = false
    }
}

private struct ScanGridCell: View {
    let item: ScanItem
    let isMultiSelect: Bool
    let isSelected: Bool
    let onTap: () -> Void
    @EnvironmentObject var repository: ScanRepository

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 6) {
                    let path = !item.enhancedImagePath.isEmpty ? item.enhancedImagePath : item.croppedImagePath
                    if let img = repository.loadImageFromDisk(path: path) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 140)
                            .cornerRadius(10)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 140)
                            .cornerRadius(10)
                    }

                    Text(item.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.black)
                        .lineLimit(1)

                    if !item.year.isEmpty || !item.location.isEmpty {
                        Text("\(item.year) • \(item.location)")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white).shadow(color: .black.opacity(0.04), radius: 4))

                if isMultiSelect {
                    Circle()
                        .fill(isSelected ? Color(red: 0.0, green: 0.78, blue: 0.42) : Color.white.opacity(0.8))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: isSelected ? "checkmark" : "")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .padding(14)
                }
            }
        }
    }
}
