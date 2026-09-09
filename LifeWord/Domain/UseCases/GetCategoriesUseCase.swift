import Foundation

struct GetCategoriesUseCase {
    let repository: ContentRepository
    func execute() async throws -> [Category] {
        try await repository.getCategories()
    }
}
