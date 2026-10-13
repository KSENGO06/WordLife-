import Foundation

struct SentenceChoiceExercise: Identifiable, Codable {
    let id: String
    let options: [SentenceChoiceOption]
    let wordId: String
}

struct SentenceChoiceOption: Codable, Identifiable {
    let id: String
    let text: String
    let translation: String
    let isCorrect: Bool
}
