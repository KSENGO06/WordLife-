import Foundation

enum FlatSection: Hashable {
    case practice(PracticeSectionType)
    case level(Int, LevelSectionType)

    static var all: [FlatSection] {
        PracticeSectionType.allCases.map { .practice($0) }
        + LevelSectionType.level1Cases.map { .level(1, $0) }
        + LevelSectionType.level2Cases.map { .level(2, $0) }
    }

    /// Стабільний рядковий ключ — для збереження прогресу в UserDefaults
    var progressKey: String {
        switch self {
        case .practice(let section): return "practice.\(section)"
        case .level(let level, let section): return "level\(level).\(section)"
        }
    }
}
