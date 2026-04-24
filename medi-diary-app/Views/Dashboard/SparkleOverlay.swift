import SwiftUI

struct SparkleOverlay: View {
    @State private var pieces: [ConfettiConfig] = []

    var body: some View {
        ZStack {
            ForEach(pieces) { piece in
                FallingConfettiPiece(config: piece)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .onAppear {
            guard pieces.isEmpty else { return }
            let w = UIScreen.main.bounds.width
            let colors: [Color] = [
                Color(red: 0.596, green: 0.812, blue: 0.631),
                Color(red: 0.694, green: 0.788, blue: 0.906),
                Color(red: 0.949, green: 0.718, blue: 0.459),
                Color(red: 0.886, green: 0.733, blue: 0.835),
                Color(red: 0.949, green: 0.878, blue: 0.506),
                Color(red: 0.753, green: 0.659, blue: 0.878),
                Color(red: 0.839, green: 0.910, blue: 0.973),
            ]
            pieces = (0..<70).map { i in
                ConfettiConfig(
                    id: i,
                    startX: CGFloat.random(in: 10...(w - 10)),
                    width: CGFloat.random(in: 8...14),
                    height: CGFloat.random(in: 14...22),
                    color: colors[i % colors.count],
                    delay: Double(i) * 0.025 + Double.random(in: 0...0.4),
                    duration: Double.random(in: 2.2...3.5),
                    drift: CGFloat.random(in: -70...70),
                    spin: Double.random(in: 200...720) * (Bool.random() ? 1 : -1),
                    isCircle: i % 5 == 0
                )
            }
        }
    }
}

/// Each piece is its own View with its own @State so SwiftUI animates it independently.
private struct FallingConfettiPiece: View {
    let config: ConfettiConfig
    @State private var fallen = false
    @State private var faded = false

    private let screenHeight = UIScreen.main.bounds.height

    var body: some View {
        Group {
            if config.isCircle {
                Circle()
                    .fill(config.color)
                    .frame(width: config.width, height: config.width)
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .fill(config.color)
                    .frame(width: config.width, height: config.height)
            }
        }
        .rotationEffect(.degrees(fallen ? config.spin : 0))
        .position(
            x: config.startX + (fallen ? config.drift : 0),
            y: fallen ? screenHeight + 40 : -20
        )
        .opacity(faded ? 0 : 1)
        .onAppear {
            withAnimation(.easeIn(duration: config.duration).delay(config.delay)) {
                fallen = true
            }
            withAnimation(.easeOut(duration: config.duration * 0.3).delay(config.delay + config.duration * 0.7)) {
                faded = true
            }
        }
    }
}

private struct ConfettiConfig: Identifiable {
    let id: Int
    let startX: CGFloat
    let width: CGFloat
    let height: CGFloat
    let color: Color
    let delay: Double
    let duration: Double
    let drift: CGFloat
    let spin: Double
    let isCircle: Bool
}
