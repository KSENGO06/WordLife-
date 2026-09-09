import Foundation

struct GetSceneUseCase {
    let repository: ContentRepository

    func execute(categoryId: String) async throws -> RoomScene? {
        let allScenes = try await repository.loadScenes()
        return allScenes.first { $0.categoryId == categoryId }
    }
}
