import SwiftUI

struct EraProfile: Identifiable, Codable, Hashable {
    let id: EraID
    let name: String
    let tagline: String
    let blurb: String
    let colorHex: String?

    var displayColor: Color { EraTheme.eraColor(for: id) }
    var textColor: Color { EraTheme.textColor(for: id) }
    var shareBackgroundColor: Color {
        if let hex = colorHex {
            return Color(hex: hex)
        }
        return displayColor
    }
}
