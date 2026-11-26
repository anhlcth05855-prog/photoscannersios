import SwiftUI

public struct QuadCropOverlayView: View {
    @Binding public var quad: Quad
    public var imageSize: CGSize

    @State private var activeHandle: Int? = nil // 0: TL, 1: TR, 2: BR, 3: BL

    public init(quad: Binding<Quad>, imageSize: CGSize) {
        self._quad = quad
        self.imageSize = imageSize
    }

    public var body: some View {
        GeometryReader { geo in
            let viewSize = geo.size
            let scale = min(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
            let drawW = imageSize.width * scale
            let drawH = imageSize.height * scale
            let offsetX = (viewSize.width - drawW) / 2
            let offsetY = (viewSize.height - drawH) / 2

            // Scale points to screen coordinates
            let tl = toScreen(pt: quad.topLeft, scale: scale, offX: offsetX, offY: offsetY)
            let tr = toScreen(pt: quad.topRight, scale: scale, offX: offsetX, offY: offsetY)
            let br = toScreen(pt: quad.bottomRight, scale: scale, offX: offsetX, offY: offsetY)
            let bl = toScreen(pt: quad.bottomLeft, scale: scale, offX: offsetX, offY: offsetY)
            let screenPts = [tl, tr, br, bl]

            ZStack {
                // Polygon Translucent Fill & Green Stroke
                Path { path in
                    path.move(to: tl)
                    path.addLine(to: tr)
                    path.addLine(to: br)
                    path.addLine(to: bl)
                    path.closeSubpath()
                }
                .fill(Color(red: 0.0, green: 0.9, blue: 0.46).opacity(0.12))

                Path { path in
                    path.move(to: tl)
                    path.addLine(to: tr)
                    path.addLine(to: br)
                    path.addLine(to: bl)
                    path.closeSubpath()
                }
                .stroke(Color(red: 0.0, green: 0.9, blue: 0.46), lineWidth: 2.5)

                // 4 Draggable Corner Handles
                ForEach(0..<4) { i in
                    let pt = screenPts[i]
                    let isActive = (activeHandle == i)
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: isActive ? 34 : 26, height: isActive ? 34 : 26)
                            .shadow(color: .black.opacity(0.5), radius: 4)

                        Circle()
                            .fill(Color(red: 0.0, green: 0.9, blue: 0.46))
                            .frame(width: isActive ? 20 : 14, height: isActive ? 20 : 14)
                    }
                    .position(pt)
                    .gesture(
                        DragGesture()
                            .onChanged { val in
                                activeHandle = i
                                let clampedX = min(drawW, max(0, val.location.x - offsetX))
                                let clampedY = min(drawH, max(0, val.location.y - offsetY))
                                let imagePt = CGPoint(x: clampedX / scale, y: clampedY / scale)

                                var q = quad
                                switch i {
                                case 0: q.topLeft = imagePt
                                case 1: q.topRight = imagePt
                                case 2: q.bottomRight = imagePt
                                case 3: q.bottomLeft = imagePt
                                default: break
                                }
                                quad = q
                            }
                            .onEnded { _ in
                                activeHandle = nil
                            }
                    )
                }
            }
        }
    }

    private func toScreen(pt: CGPoint, scale: CGFloat, offX: CGFloat, offY: CGFloat) -> CGPoint {
        return CGPoint(x: pt.x * scale + offX, y: pt.y * scale + offY)
    }
}
