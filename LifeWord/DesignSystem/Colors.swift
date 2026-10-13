import SwiftUI

extension Color {
    /// The app's global accent color (#E96A3A) — buttons, icons, badges, selection states.
    /// Backed by the "AccentColor" asset, so this is also what SwiftUI's default tint
    /// (Button, Toggle, Picker, links, …) picks up automatically app-wide.
    static let appAccent = Color("AccentColor")

    /// "Correct answer" feedback across all exercises — real green, just dimmed via opacity
    /// (not a custom tint) so it stays recognizably green/red but isn't neon-bright.
    static let appCorrect = Color.green.opacity(0.7)
    /// "Incorrect answer" feedback across all exercises — real red, dimmed via opacity.
    static let appIncorrect = Color.red.opacity(0.7)
}
