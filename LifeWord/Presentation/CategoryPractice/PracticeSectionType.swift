import Foundation

enum PracticeSectionType: String, Identifiable, CaseIterable {
    case checkNative
    case checkTarget
    case matching

    var id: String { rawValue }

    var title: String {
        switch self {
        case .checkNative: return "Translate to Ukrainian"
        case .checkTarget: return "Translate to English"
        case .matching: return "Matching"
        }
    }

    var subtitle: String { "Expand your vocabulary" }

    /// Custom icon to drop into Assets.xcassets (falls back to an SF Symbol until it's there).
    var iconAssetName: String { "exercise_\(rawValue)" }

    var symbolName: String {
        switch self {
        case .checkNative: return "character.book.closed.fill"
        case .checkTarget: return "textformat.abc"
        case .matching: return "link"
        }
    }
}
