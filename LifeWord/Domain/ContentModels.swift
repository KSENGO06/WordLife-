import Foundation

// MARK: - Content Models
// Дані про сам контент додатку. Не змінюються користувачем,
// завантажуються з бандла (JSON) при старті.

struct Category: Identifiable, Codable {
    let id: String
    let name: String
    let icon: String
    let order: Int
    let themeId: String
    let type: CategoryType?
    var isPhrasalVerbs: Bool { type == .phrasalVerbs }
}
enum CategoryType: String, Codable {
    case words
    case phrasalVerbs
}
 
struct Word: Identifiable, Codable {
    let id: String
    let term: String
    let translation: String
    let phonetic: String?
    let imageAsset: String
    let audioAsset: String?
    let categoryId: String
}
struct SentenceExercise: Identifiable, Codable {
    let id: String
    let wordId: String
    let sentenceTokens: [String]
    let targetWordIndex: Int
    let targetWordCount: Int
    let nativeText: String
    let targetDecoys: [String]
    let nativeDecoys: [String]
    let blankOptions: [String]
    let level: Int
    let audioAsset: String?
   
}
struct RoomScene: Identifiable, Codable {
    let id: String
    let categoryId: String
    let imageAsset: String
    let hotspots: [Hotspot]
}

struct Hotspot: Codable {
    let wordId: String
    let x: Double
    let y: Double
}
