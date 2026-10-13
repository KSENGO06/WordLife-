import SwiftUI

/// Англійські слова, що падають зверху і поступово накопичуються знизу
/// вгору (як купка) у компактній зоні навколо талісмана, не перекриваючи
/// одне одного — ефект для екрана завантаження.
struct FallingWordsView: View {
    let center: CGPoint
    /// Розмір прямокутної зони навколо `center`, в якій осідають слова.
    let clusterSize: CGSize

    private struct FallingWord: Identifiable {
        let id = UUID()
        let text: String
        let x: CGFloat
        let y: CGFloat
        let delay: Double
        let fontSize: CGFloat
        let dark: Bool
    }

    private static let pool = [
        "hello", "learn", "word", "speak", "study", "dinner", "story", "train",
        "nature", "friend", "weather", "music", "health", "kitchen", "doctor",
        "garden", "family", "book", "travel", "home", "coffee", "practice",
        "remember", "vocabulary", "habit", "focus", "progress", "fluent",
        "smart", "grow", "listen", "write",
    ]

    /// Слова не всі одразу: падають по черзі, розтягнуто на весь час — і
    /// кожне наступне осідає трохи вище за попереднє, формуючи купку знизу вгору.
    private static let spawnWindow: Double = 6

    @State private var items: [FallingWord] = []
    @State private var settled = false

    var body: some View {
        ZStack {
            ForEach(items) { item in
                Text(item.text)
                    .font(AppFont.playfairSemiBold(item.fontSize))
                    .foregroundStyle(item.dark ? Color.primary : Color.secondary)
                    .fixedSize()
                    .position(x: item.x, y: settled ? item.y : -80)
                    .animation(
                        .interpolatingSpring(stiffness: 320, damping: 22).delay(item.delay),
                        value: settled
                    )
            }
        }
        .allowsHitTesting(false)
        .onAppear { spawn() }
    }

    /// Приблизний розмір текстового блоку — для перевірки накладань
    /// використовуємо прямокутник (а не коло), це значно точніше для
    /// широкого короткого тексту.
    private func approxSize(text: String, fontSize: CGFloat) -> CGSize {
        CGSize(width: CGFloat(text.count) * fontSize * 0.56 + 6, height: fontSize * 1.1)
    }

    private func rectsOverlap(
        centerA: CGPoint, sizeA: CGSize,
        centerB: CGPoint, sizeB: CGSize,
        padding: CGFloat
    ) -> Bool {
        let ax0 = centerA.x - sizeA.width / 2 - padding
        let ax1 = centerA.x + sizeA.width / 2 + padding
        let ay0 = centerA.y - sizeA.height / 2 - padding
        let ay1 = centerA.y + sizeA.height / 2 + padding
        let bx0 = centerB.x - sizeB.width / 2
        let bx1 = centerB.x + sizeB.width / 2
        let by0 = centerB.y - sizeB.height / 2
        let by1 = centerB.y + sizeB.height / 2
        return ax0 < bx1 && ax1 > bx0 && ay0 < by1 && ay1 > by0
    }

    private func spawn() {
        guard items.isEmpty, clusterSize.width > 0, clusterSize.height > 0 else { return }
        // Густий "дощ": повторюємо перемішаний список слів, доки не набереться
        // достатньо для ефекту "засипало" — а не лише один прохід по пулу.
        let targetCount = 42
        var chosen: [String] = []
        while chosen.count < targetCount {
            chosen.append(contentsOf: Self.pool.shuffled())
        }
        chosen = Array(chosen.prefix(targetCount))
        let count = chosen.count

        // Купка росте знизу вгору, але лишається у зоні навколо талісмана.
        let yBottom = center.y + clusterSize.height / 2
        let yTop = center.y - clusterSize.height / 2
        let xMin = center.x - clusterSize.width / 2
        let xMax = center.x + clusterSize.width / 2

        var placed: [(point: CGPoint, size: CGSize)] = []

        items = chosen.enumerated().map { index, word in
            let base = Double(index) / Double(max(count - 1, 1)) * Self.spawnWindow
            let jitter = Double.random(in: -0.25...0.25)
            let fontSize = CGFloat.random(in: 14...20)
            let mySize = approxSize(text: word, fontSize: fontSize)

            // Чим пізніше падає слово, тим вище його "рядок" у купці (м'яке зміщення,
            // а не жорстка смуга — щоб завжди було де шукати вільне місце).
            let rowFraction = Double(index) / Double(max(count - 1, 1))
            let targetRowY = yBottom - CGFloat(rowFraction) * (yBottom - yTop)

            var x = CGFloat.random(in: xMin...xMax)
            var y = CGFloat.random(in: (targetRowY - 30)...(targetRowY + 30))
            var point = CGPoint(x: x, y: y)

            var attempts = 0
            var ySpread: CGFloat = 30
            while attempts < 220,
                  placed.contains(where: { rectsOverlap(centerA: point, sizeA: mySize, centerB: $0.point, sizeB: $0.size, padding: 3) }) {
                x = CGFloat.random(in: xMin...xMax)
                let lo = max(yTop, targetRowY - ySpread)
                let hi = min(yBottom, targetRowY + ySpread)
                y = CGFloat.random(in: lo...hi)
                point = CGPoint(x: x, y: y)
                attempts += 1
                if attempts % 12 == 0 { ySpread += 25 }
            }

            placed.append((point, mySize))

            return FallingWord(
                text: word,
                x: x,
                y: y,
                delay: max(0, base + jitter),
                fontSize: fontSize,
                dark: Bool.random()
            )
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            settled = true
        }
    }
}
