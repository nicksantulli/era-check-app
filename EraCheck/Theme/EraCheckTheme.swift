import SwiftUI

enum EraTheme {
    static let background = Color(red: 0.03, green: 0.03, blue: 0.08)
    static let accent = Color.white

    static let tumblrRomantic = Color(hex: "#4A1942")
    static let vineChaos = Color(hex: "#FF5722")
    static let vscoNaturalist = Color(hex: "#C8A97A")
    static let darkAesthetic = Color(hex: "#2C1B18")
    static let quietLuxury = Color(hex: "#D4C5B0")

    static func eraColor(for id: EraID) -> Color {
        switch id {
        case .tumblrRomantic: return tumblrRomantic
        case .vineChaosAgent: return vineChaos
        case .vscoNaturalist: return vscoNaturalist
        case .darkAesthetic: return darkAesthetic
        case .quietLuxury: return quietLuxury
        }
    }

    static func textColor(for era: EraID) -> Color {
        switch era {
        case .tumblrRomantic, .darkAesthetic:
            return .white
        case .vineChaosAgent:
            return .black
        case .vscoNaturalist, .quietLuxury:
            return .black
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(red: Double(r) / 255.0,
                  green: Double(g) / 255.0,
                  blue: Double(b) / 255.0)
    }
}

struct CardBackground: ViewModifier {
    var color: Color
    func body(content: Content) -> some View {
        content
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

extension View {
    func cardBackground(_ color: Color) -> some View {
        modifier(CardBackground(color: color))
    }
}
