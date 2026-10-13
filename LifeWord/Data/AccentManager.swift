import Foundation
import Observation

/// Який акцент озвучки обрав користувач (американський/британський).
/// Аудіофайли для кожного слова/речення мають базове ім'я (напр. "alarm_clock.mp3",
/// завжди американська озвучка) і, якщо вже згенеровано, британський варіант з суфіксом
/// "_uk" (напр. "alarm_clock_uk.mp3"). SpeechAudioPlayer сам підставляє потрібний файл
/// і тихо повертається до базового, якщо британської версії для цього слова ще нема —
/// це дозволяє озвучувати контент поступово, вправа за вправою, без ризику поламати те,
/// що ще не переозвучено.
@Observable
final class AccentManager {
    static let shared = AccentManager()

    enum Accent: String, CaseIterable, Identifiable, Equatable {
        case american = "us"
        case british = "uk"

        var id: String { rawValue }

        var title: String {
            switch self {
            case .american: return "American"
            case .british: return "British"
            }
        }

        /// Прапорець для візуального вибору акценту на екрані профілю.
        var flagEmoji: String {
            switch self {
            case .american: return "\u{1F1FA}\u{1F1F8}"
            case .british: return "\u{1F1EC}\u{1F1E7}"
            }
        }

        /// Суфікс, що додається до імені аудіофайлу для цього акценту.
        /// Американський — це базові файли без суфіксу (існуючий контент).
        var assetSuffix: String {
            switch self {
            case .american: return ""
            case .british: return "_uk"
            }
        }

        /// Мова для системного синтезатора мовлення (fallback, коли аудіофайлу нема зовсім).
        var speechLanguageCode: String {
            switch self {
            case .american: return "en-US"
            case .british: return "en-GB"
            }
        }
    }

    private let accentKey = "accent.selected"

    var accent: Accent {
        didSet { persist() }
    }

    private init() {
        if let raw = UserDefaults.standard.string(forKey: accentKey), let saved = Accent(rawValue: raw) {
            accent = saved
        } else {
            accent = .american
        }
    }

    private func persist() {
        UserDefaults.standard.set(accent.rawValue, forKey: accentKey)
    }
}
