import Foundation

struct GetWordsUseCase {
    let repository: ContentRepository
    func execute(categoryId: String) async throws -> [Word] {
        let allWords = try await repository.loadWords()
        print("DEBUG: шукаємо categoryId =", categoryId)
        let filtered = allWords.filter { $0.categoryId == categoryId }
        print("DEBUG: знайдено слів =", filtered.count)
        return filtered
    }
}
