import Foundation

struct GetWordsUseCase {
    let repository: ContentRepository
    func execute(categoryId: String) async throws -> [Word] {
        let allWords = try await repository.loadWords()
        let filtered = allWords.filter { $0.categoryId == categoryId }
        return filtered
    }
}
