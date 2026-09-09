import Foundation

struct ContentBundle: Codable {
    let categories: [Category]
    let words: [Word]
    let sentences: [SentenceExercise]
    let scenes: [RoomScene]
    let sentenceChoiceExercises: [SentenceChoiceExercise]
}
