import Foundation

struct TranslationExercise: Identifiable, Codable {
    let id: String
    let wordId: String
    let nativeText: String      // речення українською (умова)
    let answerText: String      // правильна відповідь англійською
    let answerTokens: [String]  // answerText, розбитий на слова (для перевірки/підказок)
    let audioAsset: String
}
 
