import Foundation

enum LevelSectionType: String, CaseIterable, Identifiable {
    case puzzleTarget
    case puzzleNative
    case listening
    case fillBlank
    case sentenceChoice

    var id: String { rawValue }

    var title: String {
        switch self {
        case .puzzleTarget: return "Puzzle in English"
        case .puzzleNative: return "Puzzle in Ukrainian"
        case .listening: return "Listening"
        case .fillBlank: return "Quiz"
        case .sentenceChoice: return "Correct Sentences"
        }
    }

    var subtitle: String {
        switch self {
        case .fillBlank: return "Fill in the blank"
        case .sentenceChoice: return "Choose the correct options"
        default: return "Build the sentence"
        }
    }

    /// Custom icon to drop into Assets.xcassets (falls back to an SF Symbol until it's there).
    var iconAssetName: String { "exercise_\(rawValue)" }

    var symbolName: String {
        switch self {
        case .puzzleTarget, .puzzleNative: return "puzzlepiece.fill"
        case .listening: return "headphones"
        case .fillBlank: return "square.and.pencil"
        case .sentenceChoice: return "checklist"
        }
    }

    static let level1Cases: [LevelSectionType] = [.puzzleTarget, .puzzleNative, .listening, .fillBlank]
    static let level2Cases: [LevelSectionType] = [.puzzleTarget, .puzzleNative, .listening, .sentenceChoice]
}
