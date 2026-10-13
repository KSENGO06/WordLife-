import Foundation

/// Легка модель слова для віджета — тільки те, що потрібно показати на
/// домашньому екрані (не повний Word з Domain-шару, бо віджет-розширення
/// не бачить основну ціль і має свою копію цього файлу).
struct WidgetWordEntry: Codable, Identifiable {
    let id: String
    let term: String
    let translation: String
    let imageAsset: String
}

/// Спільне сховище між застосунком і віджетом через App Group —
/// застосунок пише весь список слів сюди (при старті), а віджет читає й сам
/// вибирає, яке слово показати в кожен момент часу.
enum WidgetWordsStore {
    static let appGroupId = "group.ksengo.LifeWord.widget"
    private static let wordsKey = "widget.words"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    static func save(_ words: [WidgetWordEntry]) {
        guard let data = try? JSONEncoder().encode(words) else { return }
        defaults?.set(data, forKey: wordsKey)
    }

    static func load() -> [WidgetWordEntry] {
        guard let data = defaults?.data(forKey: wordsKey),
              let words = try? JSONDecoder().decode([WidgetWordEntry].self, from: data) else {
            return []
        }
        return words
    }
}
