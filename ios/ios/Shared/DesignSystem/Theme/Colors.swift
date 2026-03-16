import SwiftUI

enum PrototypeTheme {
    private static func rgb(_ red: Int, _ green: Int, _ blue: Int) -> Color {
        Color(
            red: Double(red) / 255.0,
            green: Double(green) / 255.0,
            blue: Double(blue) / 255.0
        )
    }

    static let background = rgb(242, 246, 250)
    static let surface = Color(red: 1.0, green: 1.0, blue: 1.0)
    static let surfaceMuted = rgb(232, 238, 244)
    static let surfaceElevated = rgb(222, 230, 238)
    static let textPrimary = rgb(15, 23, 42)
    static let textSecondary = rgb(100, 116, 139)
    static let textTertiary = rgb(148, 163, 184)
    static let accent = rgb(51, 65, 85)
    static let border = rgb(226, 232, 240)
    static let success = rgb(22, 163, 74)
    static let warning = rgb(202, 138, 4)
    static let error = rgb(220, 38, 38)
    static let info = rgb(37, 99, 235)
}
