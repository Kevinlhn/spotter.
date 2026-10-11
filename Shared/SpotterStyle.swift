import SwiftUI
import UIKit

/// Shared Spotter palette.
///
/// Counter and Spotter share the same neutral surface system.
/// Spotter's identity comes from its blue brand colors.
enum SpotterStyle {

    // MARK: - Brand

    static let accent = adaptive(
        light: 0x46647E,
        dark: 0x9DB4C8
    )

    static let blueLight = adaptive(
        light: 0x9DB4C8,
        dark: 0xB7CAD8
    )

    static let blueDark = adaptive(
        light: 0x334B64,
        dark: 0x6F8FA7
    )

    static let deepBlue = adaptive(
        light: 0x334B64,
        dark: 0x6F8FA7
    )

    static let iceBlue = adaptive(
        light: 0xD8E5F0,
        dark: 0xB7CAD8
    )

    static let foregroundAccent = adaptive(
        light: 0x46647E,
        dark: 0x9DB4C8
    )

    /// Used by "spotter.", settings, selected controls, etc.
    /// This behaves like Counter's branded red chrome.
    static let headerAccent = adaptive(
        light: 0x46647E,
        dark: 0x9DB4C8
    )

    static let onAccent = adaptive(
        light: 0xFCFBF9,
        dark: 0x211E1D
    )

    static let subtleAccent = adaptiveAlpha(
        light: 0x9DB4C8,
        dark: 0x6F8FA7,
        lightAlpha: 0.20,
        darkAlpha: 0.26
    )

    // MARK: - Training Categories

    static let strength = adaptive(
        light: 0x4E6F8D,
        dark: 0xA7C2D8
    )

    static let cardio = adaptive(
        light: 0x47725F,
        dark: 0x9DBDAD
    )

    static let mobility = adaptive(
        light: 0x7A6AA9,
        dark: 0xC3B4E0
    )

    // MARK: - Status

    static let success = adaptive(
        light: 0x47725F,
        dark: 0x9DBDAD
    )

    static let warning = adaptive(
        light: 0xB79B2E,
        dark: 0xF3E08A
    )

    static let error = adaptive(
        light: 0x9A3939,
        dark: 0xE3A0A0
    )

    // MARK: - Background / Surfaces

    /// Same neutral canvas family as Counter.
    static let background = adaptive(
        light: 0xF7F5F2,
        dark: 0x0D0E10
    )

    static let surface = adaptive(
        light: 0xEEEAE6,
        dark: 0x1B1918
    )

    static let raisedSurface = adaptive(
        light: 0xFCFBF9,
        dark: 0x242120
    )

    static let divider = adaptive(
        light: 0xD8D2CD,
        dark: 0x383330
    )

    /// Very subtle wallpaper atmosphere.
    static let ambient = adaptiveAlpha(
        light: 0x9DB4C8,
        dark: 0x777C84,
        lightAlpha: 0.12,
        darkAlpha: 0.13
    )

    static let highlight = adaptiveAlpha(
        light: 0xFFFFFF,
        dark: 0xFFFFFF,
        lightAlpha: 0.65,
        darkAlpha: 0.12
    )

    static let shadow = adaptiveAlpha(
        light: 0x000000,
        dark: 0x000000,
        lightAlpha: 0.05,
        darkAlpha: 0.16
    )

    static let progressTrack = adaptiveAlpha(
        light: 0x211E1D,
        dark: 0xF4F1EE,
        lightAlpha: 0.08,
        darkAlpha: 0.10
    )

    // MARK: - App Chrome

    /// Settings / glass control background.
    static let chromeFill = adaptiveAlpha(
        light: 0xFFFFFF,
        dark: 0xFFFFFF,
        lightAlpha: 0.50,
        darkAlpha: 0.08
    )

    static let chromeStroke = adaptiveAlpha(
        light: 0x46647E,
        dark: 0xFFFFFF,
        lightAlpha: 0.14,
        darkAlpha: 0.10
    )

    // MARK: - Text

    static let text = adaptive(
        light: 0x211E1D,
        dark: 0xF4F1EE
    )

    static let secondaryText = adaptive(
        light: 0x746D69,
        dark: 0xAFA8A4
    )

    static let muted = secondaryText

    static let ink = blueDark

    // MARK: - Hero Card

    /// IMPORTANT:
    /// These are fixed colors rather than adaptive colors.
    ///
    /// This means the hero card remains the exact same blue gradient
    /// in both light and dark mode, like Counter's main card.
    static let heroStart = fixed(
        0x46647E
    )

    static let heroEnd = fixed(
        0x5F84A5
    )

    static let heroGradient = LinearGradient(
        colors: [
            heroStart,
            heroEnd
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - General Brand Gradient

    static let gradient = LinearGradient(
        colors: [
            accent,
            blueLight
        ],
        startPoint: .bottomLeading,
        endPoint: .topTrailing
    )

    // MARK: - Helpers

    private static func adaptive(
        light: UInt32,
        dark: UInt32
    ) -> Color {
        Color(
            uiColor: UIColor { traits in
                uiColor(
                    traits.userInterfaceStyle == .dark
                        ? dark
                        : light
                )
            }
        )
    }

    private static func adaptiveAlpha(
        light: UInt32,
        dark: UInt32,
        lightAlpha: CGFloat = 1,
        darkAlpha: CGFloat = 1
    ) -> Color {
        Color(
            uiColor: UIColor { traits in
                let isDark =
                    traits.userInterfaceStyle == .dark

                return uiColor(
                    isDark ? dark : light,
                    alpha:
                        isDark
                            ? darkAlpha
                            : lightAlpha
                )
            }
        )
    }

    private static func fixed(
        _ rgb: UInt32
    ) -> Color {
        Color(
            uiColor: uiColor(rgb)
        )
    }

    private static func uiColor(
        _ rgb: UInt32,
        alpha: CGFloat = 1
    ) -> UIColor {
        UIColor(
            red:
                CGFloat(
                    (rgb >> 16) & 0xFF
                ) / 255,
            green:
                CGFloat(
                    (rgb >> 8) & 0xFF
                ) / 255,
            blue:
                CGFloat(
                    rgb & 0xFF
                ) / 255,
            alpha: alpha
        )
    }
}
