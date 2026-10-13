import SwiftUI
import CoreText

/// Registers the app's bundled custom fonts (Inter, Playfair Display) with the
/// system so `Font.custom` / `AppFont` can find them by PostScript name.
///
/// These fonts are NOT listed in Info.plist's `UIAppFonts` (this project's
/// Info.plist is auto-generated from build settings, which doesn't support
/// array-valued keys like `UIAppFonts` without hand-editing the project file).
/// Registering them at launch via Core Text has the same effect and needs no
/// project-file changes.
enum FontRegistrar {
    private static var didRegister = false

    /// Call once, as early as possible (e.g. from `LifeWordApp.init`).
    static func registerBundledFonts() {
        guard !didRegister else { return }
        didRegister = true

        for name in fontFileNames {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
                print("⚠️ FontRegistrar: missing bundled font \(name).ttf")
                continue
            }
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                if let error = error?.takeRetainedValue() {
                    // errSecDuplicateItem-type failures (already registered, e.g. in SwiftUI
                    // previews reusing a process) are harmless and expected here.
                    print("⚠️ FontRegistrar: could not register \(name).ttf — \(error)")
                }
            }
        }
    }

    private static let fontFileNames = [
        "Inter-Regular", "Inter-Medium", "Inter-SemiBold", "Inter-Bold",
        "PlayfairDisplay-SemiBold", "PlayfairDisplay-Bold",
    ]
}

/// Low-level font accessors, by PostScript name. Prefer the semantic
/// `Font` statics below in views; use these when you need a one-off size.
enum AppFont {
    // Playfair Display — headlines / titles
    static func playfairSemiBold(_ size: CGFloat) -> Font {
        .custom("PlayfairDisplay-SemiBold", size: size)
    }
    static func playfairBold(_ size: CGFloat) -> Font {
        .custom("PlayfairDisplay-Bold", size: size)
    }

    // Inter — body copy / UI
    static func interRegular(_ size: CGFloat) -> Font {
        .custom("Inter-Regular", size: size)
    }
    static func interMedium(_ size: CGFloat) -> Font {
        .custom("Inter-Medium", size: size)
    }
    static func interSemiBold(_ size: CGFloat) -> Font {
        .custom("Inter-SemiBold", size: size)
    }
    static func interBold(_ size: CGFloat) -> Font {
        .custom("Inter-Bold", size: size)
    }
}

/// Semantic type scale matching the design canvas (Main.dc.html style guide):
/// Playfair Display for headings, Inter for everything else.
extension Font {
    // Headings — Playfair Display
    static let appDisplay = AppFont.playfairBold(36)      // Splash wordmark
    static let appTitleL = AppFont.playfairBold(25)        // Screen titles (Welcome back, Add a photo)
    static let appTitleM = AppFont.playfairBold(23)        // Section headers (Settings, Home)

    // Body / UI — Inter
    static let appBodyRegular = AppFont.interRegular(14.5)
    static let appBodySmall = AppFont.interRegular(13.5)
    static let appLabel = AppFont.interSemiBold(13)         // row labels, eyebrow text
    static let appButton = AppFont.interSemiBold(15)        // buttons, links
    static let appCaption = AppFont.interMedium(12)
    static let appCaption2 = AppFont.interSemiBold(10.5)  // drop-in replacement for `.caption2` / `.caption2.bold()`
    static let appHeadline = AppFont.interSemiBold(17)  // drop-in replacement for `.headline`
    static let appSubheadline = AppFont.interRegular(15)  // drop-in replacement for `.subheadline`
}
