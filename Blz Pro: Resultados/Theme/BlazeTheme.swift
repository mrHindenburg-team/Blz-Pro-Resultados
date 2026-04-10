import SwiftUI

extension Color {
    static let blazeBackground  = Color(red: 0.09, green: 0.09, blue: 0.11)
    static let blazeSurface     = Color(red: 0.13, green: 0.13, blue: 0.16)
    static let blazeCard        = Color(red: 0.17, green: 0.17, blue: 0.20)
    static let blazeRed         = Color(red: 1.00, green: 0.18, blue: 0.33)
    static let blazePink        = Color(red: 1.00, green: 0.42, blue: 0.61)
    static let blazeOrange      = Color(red: 1.00, green: 0.50, blue: 0.12)
    static let blazeBorder      = Color(white: 1, opacity: 0.08)
    static let blazeSubtext     = Color(white: 1, opacity: 0.45)
}

extension LinearGradient {
    static let blazeFire = LinearGradient(
        colors: [.blazeRed, .blazePink],
        startPoint: .leading,
        endPoint: .trailing
    )
    static let blazeFireVertical = LinearGradient(
        colors: [.blazePink, .blazeRed],
        startPoint: .top,
        endPoint: .bottom
    )
    static let blazeChartFill = LinearGradient(
        colors: [.blazeRed.opacity(0.45), .blazeRed.opacity(0.0)],
        startPoint: .top,
        endPoint: .bottom
    )
    static let blazeHeat = LinearGradient(
        colors: [.blazeOrange, .blazeRed, .blazePink],
        startPoint: .leading,
        endPoint: .trailing
    )
}
