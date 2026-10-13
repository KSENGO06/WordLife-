import Foundation
 
struct GetClozeExerciseUseCase {
    let repository: ContentRepository
    func execute(categoryId: String) async throws -> ClozeExercise? {
        try await repository.loadClozeExercises()
            .first { $0.categoryId == categoryId }
    }
}
 
