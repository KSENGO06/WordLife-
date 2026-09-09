import Foundation

struct GetSentenceChoiceExercisesUseCase {
    let repository: ContentRepository

    func execute() async throws -> [SentenceChoiceExercise] {
        try await repository.loadSentenceChoiceExercises()
    }
}
