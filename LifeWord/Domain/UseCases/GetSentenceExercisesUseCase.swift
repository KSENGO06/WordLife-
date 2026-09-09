import Foundation

struct GetSentenceExercisesUseCase {
    let repository: ContentRepository

    func execute(wordIds: [String], level: Int) async throws -> [SentenceExercise] {
        let all = try await repository.loadSentenceExercises()
        return all.filter { $0.level == level && wordIds.contains($0.wordId) }
    }
}
