import SwiftUI

enum PastelTheme {
    static let primary = Color(red: 0.420, green: 0.608, blue: 0.949)       // #6B9BF2
    static let light = Color(red: 0.773, green: 0.792, blue: 0.859)         // #C5CADB
    static let dark = Color(red: 0.231, green: 0.463, blue: 0.914)          // #3B76E9
    static let softWhite = Color(red: 0.953, green: 0.957, blue: 0.976)     // #F3F4F9
    static let pinkAccent = Color(red: 0.992, green: 0.655, blue: 0.322)    // #FDA752
    static let green = Color(red: 0.596, green: 0.812, blue: 0.631)        // attended
    static let orange = Color(red: 0.949, green: 0.718, blue: 0.459)       // missed
    static let gray = Color(red: 0.784, green: 0.784, blue: 0.784)         // cancelled

    static let gradient = LinearGradient(
        colors: [primary.opacity(0.35), light.opacity(0.5), softWhite],
        startPoint: .top,
        endPoint: .bottom
    )
}

extension Font {
    static func poppins(_ weight: PoppinsWeight, size: CGFloat) -> Font {
        .custom(weight.fontName, size: size)
    }

    enum PoppinsWeight {
        case regular, medium, semiBold, bold

        var fontName: String {
            switch self {
            case .regular: "Poppins-Regular"
            case .medium: "Poppins-Medium"
            case .semiBold: "Poppins-SemiBold"
            case .bold: "Poppins-Bold"
            }
        }
    }
}

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    func pastelGradientBackground() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(PastelTheme.gradient.ignoresSafeArea())
    }

}

struct PressDownButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct PressableModifier: ViewModifier {
    @GestureState private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .opacity(isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in
                        state = true
                    }
            )
    }
}

extension View {
    func pressable() -> some View {
        modifier(PressableModifier())
    }
}