import SwiftUI

public struct BubbleLevelView: View {
    public var pitch: CGFloat // Degrees
    public var roll: CGFloat  // Degrees

    public init(pitch: CGFloat = 0, roll: CGFloat = 0) {
        self.pitch = pitch
        self.roll = roll
    }

    public var isLevel: Bool {
        return abs(pitch) < 2.0 && abs(roll) < 2.0
    }

    public var body: some View {
        let size: CGFloat = 88.0
        let maxOffset: CGFloat = 28.0
        let offsetX = (roll / 15.0).clamped(to: -1...1) * maxOffset
        let offsetY = (pitch / 15.0).clamped(to: -1...1) * maxOffset

        ZStack {
            // Outer Ring
            Circle()
                .stroke(isLevel ? Color(red: 0.0, green: 0.9, blue: 0.46) : Color.white.opacity(0.4), lineWidth: 2)
                .frame(width: size, height: size)

            // Center Target Crosshair
            Circle()
                .stroke(isLevel ? Color(red: 0.0, green: 0.9, blue: 0.46) : Color.white.opacity(0.6), lineWidth: 1.5)
                .frame(width: 24, height: 24)

            // Spirit Bubble Ball
            Circle()
                .fill(isLevel ? Color(red: 0.0, green: 0.9, blue: 0.46) : Color.white.opacity(0.85))
                .frame(width: 18, height: 18)
                .offset(x: offsetX, y: offsetY)
                .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.7), value: offsetX)
        }
        .background(Circle().fill(Color.black.opacity(0.35)))
    }
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
