import SwiftUI

public struct LiveScannerOverlayView: View {
    @State private var laserOffset: CGFloat = 0.0
    @State private var isAnimating = false

    public init() {}

    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let padX = w * 0.08
            let padY = h * 0.16
            let scanRect = CGRect(x: padX, y: padY, width: w - padX * 2, height: h - padY * 2)

            ZStack {
                // Dimmed surrounding background
                Path { path in
                    path.addRect(CGRect(origin: .zero, size: geo.size))
                    path.addRoundedRect(in: scanRect, cornerSize: CGSize(width: 16, height: 16))
                }
                .fill(Color.black.opacity(0.35), style: FillStyle(eoFill: true))

                // 4 Green Corner Brackets
                CornerBracketsShape(rect: scanRect, cornerLen: 32)
                    .stroke(Color(red: 0.0, green: 0.9, blue: 0.46), lineWidth: 4)

                // Laser Beam
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color(red: 0.0, green: 0.9, blue: 0.46).opacity(0.8),
                                Color.white,
                                Color(red: 0.0, green: 0.9, blue: 0.46).opacity(0.8),
                                Color.clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: scanRect.width, height: 3)
                    .position(x: scanRect.midX, y: scanRect.minY + laserOffset * scanRect.height)
            }
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                    laserOffset = 1.0
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct CornerBracketsShape: Shape {
    let rect: CGRect
    let cornerLen: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = self.rect
        let len = self.cornerLen

        // Top-Left
        path.move(to: CGPoint(x: r.minX, y: r.minY + len))
        path.addLine(to: CGPoint(x: r.minX, y: r.minY))
        path.addLine(to: CGPoint(x: r.minX + len, y: r.minY))

        // Top-Right
        path.move(to: CGPoint(x: r.maxX - len, y: r.minY))
        path.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        path.addLine(to: CGPoint(x: r.maxX, y: r.minY + len))

        // Bottom-Right
        path.move(to: CGPoint(x: r.maxX, y: r.maxY - len))
        path.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        path.addLine(to: CGPoint(x: r.maxX - len, y: r.maxY))

        // Bottom-Left
        path.move(to: CGPoint(x: r.minX + len, y: r.maxY))
        path.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        path.addLine(to: CGPoint(x: r.minX, y: r.maxY - len))

        return path
    }
}
