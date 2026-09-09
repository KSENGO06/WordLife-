import Foundation

enum TranslationDirection {
    case englishToUkrainian
    case ukrainianToEnglish
}

enum PracticeExercise: Identifiable {
    case matchPairs(id: String, words: [Word])
    case chooseTranslation(id: String, word: Word, options: [Word], direction: TranslationDirection)
    
    var id: String {
        switch self {
        case .matchPairs(let id, let words):
            return id
        case .chooseTranslation(let id, let word, let options, let direction):
            return id
        }
    }
}
