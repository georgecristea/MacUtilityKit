import SwiftUI

/// Per-app brand identity. The host app sets `MUKTheme.brand` once at launch so every
/// shared component (header icon, level meter, cards, accents) picks up the app's color
/// and symbol while keeping one consistent layout system across utilities.
public struct MUKBrand {
    public var name: String
    public var tagline: String
    public var symbol: String
    public var accent: Color
    public var accentSecondary: Color

    public init(
        name: String,
        tagline: String,
        symbol: String,
        accent: Color,
        accentSecondary: Color)
    {
        self.name = name
        self.tagline = tagline
        self.symbol = symbol
        self.accent = accent
        self.accentSecondary = accentSecondary
    }

    public var gradient: LinearGradient {
        LinearGradient(
            colors: [accent, accentSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing)
    }

    public static let `default` = MUKBrand(
        name: "MacUtility",
        tagline: "",
        symbol: "square.grid.2x2",
        accent: .accentColor,
        accentSecondary: .accentColor)
}

public enum MUKTheme {
    /// Set once by the host app at launch.
    public static var brand: MUKBrand = .default

    // Sizing
    public static let popoverWidth: CGFloat = 420
    public static let popoverHeight: CGFloat = 640
    public static let settingsWidth: CGFloat = 460
    public static let settingsHeight: CGFloat = 360
    public static let rowRadius: CGFloat = 11
    public static let cardRadius: CGFloat = 14
    public static let controlSpacing: CGFloat = 12
    public static let edgePadding: CGFloat = 16

    // Semantic colors
    public static var accent: Color { brand.accent }
    public static var accentGradient: LinearGradient { brand.gradient }
    public static let success = Color.green
    public static let warning = Color.orange
    public static let danger = Color.red
}

public struct MUKStatusMessage: Equatable {
    public enum Tone: Equatable {
        case neutral
        case success
        case warning
        case error
    }

    public let text: String
    public let tone: Tone

    public init(_ text: String, tone: Tone = .neutral) {
        self.text = text
        self.tone = tone
    }

    public var color: Color {
        switch tone {
        case .neutral: .secondary
        case .success: MUKTheme.success
        case .warning: MUKTheme.warning
        case .error: MUKTheme.danger
        }
    }
}
