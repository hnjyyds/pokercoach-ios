import SwiftUI

enum PokerTheme {
    static let background = Color(hex: "#F8FAFD")
    static let surface = Color.white.opacity(0.90)
    static let felt = Color(hex: "#13C8A6")
    static let ink = Color(hex: "#071226")
    static let muted = Color(hex: "#697386")
    static let amber = Color(hex: "#F59E0B")
    static let coral = Color(hex: "#EF4444")
    static let violet = Color(hex: "#8B5CF6")
    static let border = Color(hex: "#E7ECF4")
}

enum PokerLayout {
    static let floatingTabBarClearance: CGFloat = 180
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let red: UInt64
        let green: UInt64
        let blue: UInt64
        let alpha: UInt64

        switch cleaned.count {
        case 3:
            red = (value >> 8) * 17
            green = (value >> 4 & 0xF) * 17
            blue = (value & 0xF) * 17
            alpha = 255
        case 6:
            red = value >> 16
            green = value >> 8 & 0xFF
            blue = value & 0xFF
            alpha = 255
        case 8:
            red = value >> 16 & 0xFF
            green = value >> 8 & 0xFF
            blue = value & 0xFF
            alpha = value >> 24
        default:
            red = 31
            green = 41
            blue = 51
            alpha = 255
        }

        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: Double(alpha) / 255
        )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = PokerTheme.ink

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.black))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(tint.opacity(configuration.isPressed ? 0.86 : 1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: tint.opacity(configuration.isPressed ? 0.12 : 0.22), radius: 16, y: 10)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.black))
            .foregroundStyle(PokerTheme.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(.white.opacity(configuration.isPressed ? 0.70 : 0.90), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color(hex: "#121A2C").opacity(configuration.isPressed ? 0.03 : 0.07), radius: 14, y: 8)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

extension View {
    @ViewBuilder
    func pokerPageTabStyle() -> some View {
        #if os(iOS)
        tabViewStyle(.page(indexDisplayMode: .never))
        #else
        self
        #endif
    }

    @ViewBuilder
    func pokerNoAutocapitalization() -> some View {
        #if os(iOS)
        textInputAutocapitalization(.never)
        #else
        self
        #endif
    }

    @ViewBuilder
    func pokerCharactersAutocapitalization() -> some View {
        #if os(iOS)
        textInputAutocapitalization(.characters)
        #else
        self
        #endif
    }

    @ViewBuilder
    func pokerEmailKeyboard() -> some View {
        #if os(iOS)
        keyboardType(.emailAddress)
        #else
        self
        #endif
    }
}
