import SwiftUI

/// The app's secondary action button — paired with `.primary` when a screen
/// has two calls-to-action ("Вивчити слова" primary + "Практикувати слова"
/// secondary, etc). Same shape and sizing as `.primary` (full width, rounded,
/// Inter SemiBold label) but white background with an accent-orange border
/// and text, so it visually steps back behind the primary action.
struct SecondaryButtonStyle: ButtonStyle {
    var font: Font = .appButton
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(isEnabled ? Color.appAccent : Color.appAccent.opacity(0.35))
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isEnabled ? Color.appAccent : Color.appAccent.opacity(0.35), lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    /// `.buttonStyle(.secondary)` — the app's standard full-width white/outline button.
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}
