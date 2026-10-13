import SwiftUI

/// Спільний декоративний фон застосунку — м'які форми (рожеве коло,
/// шавлієва дуга) на кремовому тлі, з асета "lifeword-shapes-background".
/// Використовується як фон практично для всіх екранів: списків, карток
/// категорій, вправ тощо — щоб застосунок виглядав цілісно.
struct AppBackgroundView: View {
    var body: some View {
        Image("lifeword-shapes-background")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }
}

extension View {
    /// Кладе спільний фон застосунку (`AppBackgroundView`) позаду вмісту
    /// екрана, на весь простір, включно з safe area.
    func appScreenBackground() -> some View {
        background(AppBackgroundView())
    }
}
