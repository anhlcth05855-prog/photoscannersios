import SwiftUI

public struct FocusRingView: View {
    public var position: CGPoint
    @State private var scale: CGFloat = 1.4
    @State private var opacity: Double = 1.0

    public init(position: CGPoint) {
        self.position = position
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(Color(red: 1.0, green: 0.84, blue: 0.0), lineWidth: 1.5)
                .frame(width: 64, height: 64)
            Circle()
                .fill(Color(red: 1.0, green: 0.84, blue: 0.0))
                .frame(width: 4, height: 4)
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .position(position)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) {
                scale = 1.0
            }
            withAnimation(.easeIn(duration: 0.3).delay(1.0)) {
                opacity = 0.0
            }
        }
    }
}
