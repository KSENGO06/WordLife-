import Foundation
 
struct GetTranslationExercisesUseCase {
    let repository: ContentRepository
    func execute(categoryId: String, words: [Word]) async throws -> [TranslationExercise] {
        let wordIds = Set(words.map(\.id))
        return try await repository.loadTranslationExercises()
            .filter { wordIds.contains($0.wordId) }
    }
}
 
