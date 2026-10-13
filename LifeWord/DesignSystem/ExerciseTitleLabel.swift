import SwiftUI

/// Уніфікований заголовок вправи — акцентний текст без фону, завжди
/// розташований зліва вгорі вправи, з відступом зліва. Використовується
/// в усіх типах вправ для однакового вигляду (раніше кожна вправа мала
/// свій стиль заголовка — десь по центру, десь дрібним текстом, десь на
/// кольоровій плашці).
struct ExerciseTitleLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.appHeadline)
            .foregroundStyle(Color.appAccent)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 14)
    }
}
