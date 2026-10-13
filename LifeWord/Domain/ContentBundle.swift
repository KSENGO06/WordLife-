import Foundation

struct ContentBundle: Codable {
    let categories: [Category]
    let words: [Word]
    let sentences: [SentenceExercise]
    let scenes: [RoomScene]
    let sentenceChoiceExercises: [SentenceChoiceExercise]
    let themes: [Theme]
    let translationExercises: [TranslationExercise]
    let clozeExercises: [ClozeExercise]
 
    enum CodingKeys: String, CodingKey {
        case categories, words, sentences, scenes, sentenceChoiceExercises, themes
        case translationExercises, clozeExercises
    }
 
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        categories = try c.decode([Category].self, forKey: .categories)
        words = try c.decode([Word].self, forKey: .words)
        sentences = try c.decode([SentenceExercise].self, forKey: .sentences)
        scenes = try c.decode([RoomScene].self, forKey: .scenes)
        sentenceChoiceExercises = try c.decode([SentenceChoiceExercise].self, forKey: .sentenceChoiceExercises)
        themes = try c.decode([Theme].self, forKey: .themes)
        // decodeIfPresent — щоб content.json, у якому ще немає цих двох ключів
        // (усі категорії слів, додані до появи фразових дієслів), спокійно декодувався.
        translationExercises = try c.decodeIfPresent([TranslationExercise].self, forKey: .translationExercises) ?? []
        clozeExercises = try c.decodeIfPresent([ClozeExercise].self, forKey: .clozeExercises) ?? []
    }
}
 
