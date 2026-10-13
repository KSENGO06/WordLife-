
import Foundation
 
final class BundledJSONContentRepository: ContentRepository {
    private let bundle: ContentBundle
 
    init() {
        guard let url = Bundle.main.url(forResource: "content", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(ContentBundle.self, from: data) else {
            fatalError("content.json не знайдено або пошкоджено")
        }
        self.bundle = decoded
        print("DEBUG: слів у bundle =", decoded.words.count)
    }
 
    func loadCategories() async throws -> [Category] { bundle.categories }
    func loadWords() async throws -> [Word] { bundle.words }
    func loadSentenceExercises() async throws -> [SentenceExercise] { bundle.sentences }
    func loadScenes() async throws -> [RoomScene] { bundle.scenes }
    func loadSentenceChoiceExercises() async throws -> [SentenceChoiceExercise] { bundle.sentenceChoiceExercises }
    func getCategories() async throws -> [Category] {
        bundle.categories.sorted { $0.order < $1.order }
    }
    func getThemes() async throws -> [Theme] {
        bundle.themes.sorted { $0.order < $1.order }
    }
 
    // MARK: - Фразові дієслова
    func loadTranslationExercises() async throws -> [TranslationExercise] { bundle.translationExercises }
    func loadClozeExercises() async throws -> [ClozeExercise] { bundle.clozeExercises }
}
