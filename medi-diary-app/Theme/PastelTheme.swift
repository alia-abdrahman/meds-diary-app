import SwiftUI

enum PastelTheme {
    static let primary = Color(red: 0.655, green: 0.780, blue: 0.906)       // #A7C7E7
    static let light = Color(red: 0.839, green: 0.910, blue: 0.973)         // #D6E8F8
    static let dark = Color(red: 0.392, green: 0.584, blue: 0.776)          // #6495C6
    static let softWhite = Color(red: 0.973, green: 0.980, blue: 0.988)     // #F8FAFC
    static let pinkAccent = Color(red: 0.961, green: 0.816, blue: 0.863)    // #F5D0DC
    static let green = Color(red: 0.596, green: 0.812, blue: 0.631)        // attended
    static let orange = Color(red: 0.949, green: 0.718, blue: 0.459)       // missed
    static let gray = Color(red: 0.784, green: 0.784, blue: 0.784)         // cancelled

    static let gradient = LinearGradient(
        colors: [light, softWhite],
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