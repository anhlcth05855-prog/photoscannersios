import SwiftUI

public struct BeforeAfterSliderView: View {
    public var originalImage: UIImage
    public var enhancedImage: UIImage
    @State private var splitRatio: CGFloat = 0.5

    public init(originalImage: UIImage, enhancedImage: UIImage) {
        self.originalImage = originalImage
        self.enhancedImage = enhancedImage
    }

    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let dividerX = w * splitRatio

            ZStack {
                // Background Enhanced Photo (Right side / Full)
                Image(uiImage: enhancedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: w, height: h)

                // Clipped Original Photo (Left side)
                Image(uiImage: originalImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: w, height: h)
                    .clipShape(
                        Path { path in
                            path.addRect(CGRect(x: 0, y: 0, width: dividerX, height: h))
                        }
                    )

                // Vertical Divider Line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2.5, height: h)
                    .position(x: dividerX, y: h / 2)
                    .shadow(color: .black.opacity(0.5), radius: 3)

                // Divider Circular Handle
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 38, height: 38)
                        .shadow(color: .black.opacity(0.4), radius: 4)

                    HStack(spacing: 3) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.black)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
                .position(x: dividerX, y: h / 2)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            splitRatio = min(0.98, max(0.02, value.location.x / w))
                        }
                )

                // "GỐC" and "ĐÃ PHỤC HỒI" Floating Badges
                VStack {
                    HStack {
                        Text("GỐC")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.black.opacity(0.6)))
                            .padding(.leading, 12)

                        Spacer()

                        Text("AI RESTORED")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color(red: 0.0, green: 0.9, blue: 0.46)))
                            .padding(.trailing, 12)
                    }
                    .padding(.top, 12)
                    Spacer()
                }
            }
        }
    }
}
