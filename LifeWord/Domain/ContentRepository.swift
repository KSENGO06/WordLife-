import Foundation

protocol ContentRepository {
    func loadCategories() async throws -> [Category]
    func loadWords() async throws -> [Word]
    func loadSentenceExercises() async throws -> [SentenceExercise]
    func loadScenes() async throws -> [RoomScene]
    func loadSentenceChoiceExercises() async throws -> [SentenceChoiceExercise]
    func getCategories() async throws -> [Category]
}
