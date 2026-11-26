import SwiftUI

public struct StoryDialogView: View {
    @Binding var scanItem: ScanItem
    @Environment(\.presentationMode) var presentationMode

    @State private var year: String = ""
    @State private var location: String = ""
    @State private var people: String = ""
    @State private var story: String = ""

    public init(scanItem: Binding<ScanItem>) {
        self._scanItem = scanItem
    }

    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Thông Tin Kỷ Niệm")) {
                    TextField("Năm chụp (Ví dụ: 1985)", text: $year)
                        .keyboardType(.numberPad)
                    TextField("Địa điểm (Ví dụ: Hà Nội, Đà Lạt)", text: $location)
                    TextField("Người trong ảnh (Ví dụ: Bố mẹ, Ông bà)", text: $people)
                }

                Section(header: Text("Câu chuyện / Ghi chú")) {
                    TextEditor(text: $story)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Kỷ Niệm Bức Ảnh")
            .navigationBarItems(
                leading: Button("Hủy") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Lưu") {
                    scanItem.year = year
                    scanItem.location = location
                    scanItem.people = people
                    scanItem.story = story
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.headline)
            )
            .onAppear {
                year = scanItem.year
                location = scanItem.location
                people = scanItem.people
                story = scanItem.story
            }
        }
    }
}
