import SwiftUI

/// The app's one standard primary action button — "Перевірити", "Вивчити слова",
/// "Продовжити" and every other main call-to-action use this: full width,
/// accent-orange, white Inter SemiBold label, rounded corners. Dims automatically
/// when the button is `.disabled(...)`.
struct PrimaryButtonStyle: ButtonStyle {
    var font: Font = .appButton
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(isEnabled ? Color.appAccent : Color.appAccent.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    /// `.buttonStyle(.primary)` — the app's standard full-width orange button.
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}
