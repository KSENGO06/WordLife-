import Foundation

enum PracticeSectionType: String, Identifiable, CaseIterable {
    case checkNative
    case checkTarget
    case matching

    var id: String { rawValue }

    var title: String {
        switch self {
        case .checkNative: return "Перевірка слів рідною мовою"
        case .checkTarget: return "Перевірка слів англійською"
        case .matching: return "Мечинг"
        }
    }

    var subtitle: String { "Розширюйте свій словниковий запас" }
    
    
}
