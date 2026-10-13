import Foundation

protocol ContentRepository {
    func loadCategories() async throws -> [Category]
    func loadWords() async throws -> [Word]
    func loadSentenceExercises() async throws -> [SentenceExercise]
    func loadScenes() async throws -> [RoomScene]
    func loadSentenceChoiceExercises() async throws -> [SentenceChoiceExercise]
    func getCategories() async throws -> [Category]
    func getThemes() async throws -> [Theme]
    // MARK: - Фразові дієслова
    func loadTranslationExercises() async throws -> [TranslationExercise]
    func loadClozeExercises() async throws -> [ClozeExercise]
}
