import Foundation

// MARK: - User State Models
// Дані про прогрес конкретного користувача. Змінюються постійно,
// зберігаються в SwiftData, персональні для кожного юзера.

struct WordProgress: Codable {
    let wordId: String
    var timesCorrect: Int
    var timesWrong: Int
    var lastReviewedAt: Date?
    var difficulty: Difficulty

    enum Difficulty: String, Codable {
        case easy, medium, hard
    }
}

struct HeartsState: Codable {
    var currentHearts: Int
    let maxHearts: Int = 5
    var lastHeartLostAt: Date?
    var hasUnlimitedHearts: Bool
}
