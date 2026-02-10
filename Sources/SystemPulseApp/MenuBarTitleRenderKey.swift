import AppKit

@MainActor
enum MenuBarTitleRenderKey {
    static func make(contentCacheKey: String, appearance: NSAppearance?) -> String {
        "\(contentCacheKey)|\(appearanceToneKey(for: appearance))"
    }

    static func appearanceToneKey(for appearance: NSAppearance?) -> String {
        appearanceTone(for: appearance) == .dark ? "dark" : "light"
    }

    private enum AppearanceTone {
        case dark
        case light
    }

    private static func appearanceTone(for appearance: NSAppearance?) -> AppearanceTone {
        let sourceAppearance = appearance
            ?? NSApp?.effectiveAppearance
            ?? NSAppearance.currentDrawing()
        let match = sourceAppearance.bestMatch(from: [
            .darkAqua,
            .vibrantDark,
            .accessibilityHighContrastDarkAqua,
            .accessibilityHighContrastVibrantDark,
            .aqua,
            .vibrantLight,
            .accessibilityHighContrastAqua,
            .accessibilityHighContrastVibrantLight
        ])

        switch match {
        case .darkAqua, .vibrantDark, .accessibilityHighContrastDarkAqua, .accessibilityHighContrastVibrantDark:
            return .dark
        default:
            return .light
        }
    }
}
