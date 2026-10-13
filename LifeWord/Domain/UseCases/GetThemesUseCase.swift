import Foundation
 
struct GetThemesUseCase {
    let repository: ContentRepository
    func execute() async throws -> [Theme] {
        try await repository.getThemes()
    }
}
