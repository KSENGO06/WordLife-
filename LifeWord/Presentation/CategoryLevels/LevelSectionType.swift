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
        case .puzzleTarget: return "Пазл на вивченій мові"
        case .puzzleNative: return "Пазл на рідній мові"
        case .listening: return "Аудіювання"
        case .fillBlank: return "Тест"
        case .sentenceChoice: return "Правильні речення"
        }
    }

    var subtitle: String {
        switch self {
        case .fillBlank: return "Заповніть пропуск"
        case .sentenceChoice: return "Виберіть правильні варіанти"
        default: return "Складіть речення"
        }
    }

    static let level1Cases: [LevelSectionType] = [.puzzleTarget, .puzzleNative, .listening, .fillBlank]
    static let level2Cases: [LevelSectionType] = [.puzzleTarget, .puzzleNative, .listening, .fillBlank, .sentenceChoice]
}
