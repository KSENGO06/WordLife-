//
//  LifeWordWidget.swift
//  LifeWordWidget
//
//  Показує слово дня/години — картинка, саме слово і переклад; слово
//  міняється з часом, обходячи весь словник по колу.
//

import WidgetKit
import SwiftUI
import UIKit

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WordWidgetEntry {
        WordWidgetEntry(date: Date(), word: WidgetWordsStore.load().first)
    }

    func getSnapshot(in context: Context, completion: @escaping (WordWidgetEntry) -> ()) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WordWidgetEntry>) -> ()) {
        let words = WidgetWordsStore.load()
        guard !words.isEmpty else {
            let retryDate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
            completion(Timeline(entries: [WordWidgetEntry(date: Date(), word: nil)], policy: .after(retryDate)))
            return
        }

        let calendar = Calendar.current
        let now = Date()
        var entries: [WordWidgetEntry] = []
        for hourOffset in 0..<12 {
            let entryDate = calendar.date(byAdding: .hour, value: hourOffset, to: now) ?? now
            let index = wordIndex(for: entryDate, count: words.count)
            entries.append(WordWidgetEntry(date: entryDate, word: words[index]))
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func currentEntry() -> WordWidgetEntry {
        let words = WidgetWordsStore.load()
        guard !words.isEmpty else { return WordWidgetEntry(date: Date(), word: nil) }
        return WordWidgetEntry(date: Date(), word: words[wordIndex(for: Date(), count: words.count)])
    }

    /// Детерміновано обирає слово за абсолютною годиною від початку епохи —
    /// однакова година дає те саме слово, а з часом перелік просувається по колу.
    private func wordIndex(for date: Date, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let hours = Int(date.timeIntervalSince1970 / 3600)
        return ((hours % count) + count) % count
    }
}

struct WordWidgetEntry: TimelineEntry {
    let date: Date
    let word: WidgetWordEntry?
}

private extension Color {
    /// Той самий акцентний колір, що й у головному застосунку (#E96A3A) —
    /// віджет-розширення не бачить DesignSystem головної цілі, тож дублюємо значення тут.
    static let lwAccent = Color(red: 0.9137, green: 0.4157, blue: 0.2275)
}

struct LifeWordWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: Provider.Entry

    var body: some View {
        if let word = entry.word {
            switch family {
            case .systemMedium:
                mediumLayout(word)
            default:
                smallLayout(word)
            }
        } else {
            emptyState
        }
    }

    private func smallLayout(_ word: WidgetWordEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            wordImage(word.imageAsset)
                .frame(maxWidth: .infinity)
                .frame(height: 76)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(word.term)
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(word.translation)
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
    }

    private func mediumLayout(_ word: WidgetWordEntry) -> some View {
        HStack(spacing: 14) {
            wordImage(word.imageAsset)
                .frame(width: 90, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text("WORD")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.lwAccent)
                Text(word.term)
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(word.translation)
                    .font(.system(size: 21))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "character.book.closed.fill")
                .font(.system(size: 22))
                .foregroundStyle(Color.lwAccent)
            Text("Open LifeWord")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Фото слова — зменшуємо перед показом, бо оригінали зроблені для
    /// повноекранних карток у застосунку (до ~1536×1024px) і завеликі для
    /// пам'яті віджета без цього.
    @ViewBuilder
    private func wordImage(_ name: String) -> some View {
        ZStack {
            Color.lwAccent.opacity(0.08)
            if let uiImage = UIImage(named: name) {
                Image(uiImage: Self.downsampled(uiImage, maxDimension: 200))
                    .resizable()
                    .scaledToFit()
                    .padding(4)
            } else {
                Image(systemName: "text.book.closed.fill")
                    .foregroundStyle(Color.lwAccent.opacity(0.6))
            }
        }
    }

    /// Картинки слів зроблені для повноекранних карток у застосунку (до
    /// ~1536×1024 px) — для віджета це занадто багато пам'яті при архівації
    /// (SendProcessControlEvent: "image being too large"), тож зменшуємо до
    /// невеликого розміру, якого достатньо для маленького віджета.
    private static func downsampled(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longestSide = max(size.width, size.height)
        guard longestSide > maxDimension else { return image }
        let scale = maxDimension / longestSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}

struct LifeWordWidget: Widget {
    let kind: String = "LifeWordWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            LifeWordWidgetEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("LifeWord")
        .description("Word of the hour — picture, word and translation.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    LifeWordWidget()
} timeline: {
    WordWidgetEntry(date: .now, word: WidgetWordEntry(id: "1", term: "Apple", translation: "Яблуко", imageAsset: "apple"))
    WordWidgetEntry(date: .now, word: WidgetWordEntry(id: "2", term: "Window", translation: "Вікно", imageAsset: "window"))
}
