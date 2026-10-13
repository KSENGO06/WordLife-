import Foundation

/// Секції екрану "Закріплення" для категорії фразових дієслів: спершу ті самі
/// три вправи, що й у звичайних словах (переклад в обидва боки, мечинг —
/// вони працюють з масивом Word напряму, тож переносяться без змін),
/// а потім дві вправи, специфічні для фразових дієслів.
enum PhrasalSectionType: String, CaseIterable, Identifiable {
    case checkNative
    case checkTarget
    case matching
    case translateBuild
    case clozeText

    var id: String { rawValue }

    var title: String {
        switch self {
        case .checkNative: return "Translate to Ukrainian"
        case .checkTarget: return "Translate to English"
        case .matching: return "Matching"
        case .translateBuild: return "Translate Sentences"
        case .clozeText: return "Fill in the Blanks"
        }
    }

    var subtitle: String {
        switch self {
        case .translateBuild: return "Build the sentence from the words"
        case .clozeText: return "Fill in the correct words"
        default: return "Expand your vocabulary"
        }
    }

    /// Custom icon to drop into Assets.xcassets (falls back to an SF Symbol until it's there).
    var iconAssetName: String { "exercise_\(rawValue)" }

    var symbolName: String {
        switch self {
        case .checkNative: return "character.book.closed.fill"
        case .checkTarget: return "textformat.abc"
        case .matching: return "link"
        case .translateBuild: return "puzzlepiece.fill"
        case .clozeText: return "square.and.pencil"
        }
    }
}
