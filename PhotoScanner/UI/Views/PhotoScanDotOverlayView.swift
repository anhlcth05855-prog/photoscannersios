import SwiftUI

public struct PhotoScanDotOverlayView: View {
    public let onDotReached: (Int) -> Void
    public let onAllCompleted: () -> Void

    @State private var dotStates: [DotState] = [.pending, .pending, .pending, .pending]
    @State private var activeIndex: Int = 0
    @State private var reticleOffset: CGSize = .zero
    @State private var dwellProgress: CGFloat = 0.0
    @State private var timer: Timer?

    public enum DotState {
        case pending
        case capturing
        case completed
    }

    public init(onDotReached: @escaping (Int) -> Void, onAllCompleted: @escaping () -> Void) {
        self.onDotReached = onDotReached
        self.onAllCompleted = onAllCompleted
    }

    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            // 4 Target Dot Positions
            let dots = [
                CGPoint(x: w * 0.22, y: h * 0.26), // 0: TL
                CGPoint(x: w * 0.78, y: h * 0.26), // 1: TR
                CGPoint(x: w * 0.78, y: h * 0.74), // 2: BR
                CGPoint(x: w * 0.22, y: h * 0.74)  // 3: BL
            ]

            let centerPos = CGPoint(x: w / 2 + reticleOffset.width, y: h / 2 + reticleOffset.height)

            ZStack {
                // Dimmed background
                Color.black.opacity(0.2)

                // Top Prompt Banner
                VStack {
                    let completed = dotStates.filter { $0 == .completed }.count
                    Text(completed < 4 ? "Di chuyển vòng tròn tới điểm \(completed + 1)/4" : "Đang ghép ảnh khử chói AI...")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.black.opacity(0.65)))
                        .padding(.top, 40)
                    Spacer()
                }

                // 4 Corner Dots
                ForEach(0..<4) { i in
                    let pt = dots[i]
                    let state = dotStates[i]
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.4))
                            .frame(width: 44, height: 44)

                        if state == .completed {
                            Circle()
                                .fill(Color(red: 0.0, green: 0.9, blue: 0.46))
                                .frame(width: 32, height: 32)
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        } else if i == activeIndex {
                            Circle()
                                .fill(Color(red: 0.0, green: 0.85, blue: 1.0))
                                .frame(width: 32, height: 32)

                            if state == .capturing {
                                Circle()
                                    .trim(from: 0, to: dwellProgress)
                                    .stroke(Color(red: 0.0, green: 0.9, blue: 0.46), lineWidth: 4)
                                    .frame(width: 42, height: 42)
                                    .rotationEffect(.degrees(-90))
                            }
                        } else {
                            Circle()
                                .stroke(Color.white.opacity(0.8), lineWidth: 2.5)
                                .frame(width: 28, height: 28)
                        }
                    }
                    .position(pt)
                    .onTapGesture {
                        // Allow tapping dot to quickly align
                        reticleOffset = CGSize(width: pt.x - w/2, height: pt.y - h/2)
                        checkAlignment(centerPos: pt, dots: dots)
                    }
                }

                // Center User Reticle Circle
                ZStack {
                    Circle()
                        .stroke(Color(red: 0.0, green: 0.85, blue: 1.0), lineWidth: 3.5)
                        .frame(width: 64, height: 64)
                    Circle()
                        .fill(Color(red: 0.0, green: 0.85, blue: 1.0).opacity(0.2))
                        .frame(width: 64, height: 64)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 6, height: 6)
                }
                .position(centerPos)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            reticleOffset = value.translation
                            checkAlignment(centerPos: CGPoint(x: w/2 + reticleOffset.width, y: h/2 + reticleOffset.height), dots: dots)
                        }
                )
            }
        }
    }

    private func checkAlignment(centerPos: CGPoint, dots: [CGPoint]) {
        guard activeIndex < dots.count else { return }
        let target = dots[activeIndex]
        let dist = hypot(centerPos.x - target.x, centerPos.y - target.y)

        if dist < 42.0 {
            if dotStates[activeIndex] == .pending {
                startDwell()
            }
        } else {
            if dotStates[activeIndex] == .capturing {
                cancelDwell()
            }
        }
    }

    private func startDwell() {
        dotStates[activeIndex] = .capturing
        dwellProgress = 0.0
        timer?.invalidate()
        let step = 0.05
        let totalTime = 0.65
        timer = Timer.scheduledTimer(withTimeInterval: step, repeats: true) { t in
            dwellProgress += CGFloat(step / totalTime)
            if dwellProgress >= 1.0 {
                t.invalidate()
                completeActiveDot()
            }
        }
    }

    private func cancelDwell() {
        timer?.invalidate()
        dotStates[activeIndex] = .pending
        dwellProgress = 0.0
    }

    private func completeActiveDot() {
        dotStates[activeIndex] = .completed
        onDotReached(activeIndex)

        if let next = dotStates.firstIndex(where: { $0 == .pending }) {
            activeIndex = next
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onAllCompleted()
            }
        }
    }
}
