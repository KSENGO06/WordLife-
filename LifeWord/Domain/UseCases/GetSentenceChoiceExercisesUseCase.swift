import Foundation

struct GetSentenceChoiceExercisesUseCase {
    let repository: ContentRepository

    func execute(wordIds: [String]) async throws -> [SentenceChoiceExercise] {
        let all = try await repository.loadSentenceChoiceExercises()
        return all.filter { wordIds.contains($0.wordId) }
    }
}
