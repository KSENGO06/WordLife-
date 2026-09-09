import Foundation

struct FillBlankExercise: Identifiable, Codable {
    let id: String
    let sentenceWithBlank: String   // "He really impressed me ___ his knowledge"
    let options: [String]           // ["with", "for", "of"]
    let answer: String              // "with"
}
