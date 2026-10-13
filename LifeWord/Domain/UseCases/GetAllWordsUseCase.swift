import Foundation

/// Усі слова застосунку одразу (без фільтра по категорії) — для екрана
/// "Словник" і для вибору "слова дня" на головній.
struct GetAllWordsUseCase {
    let repository: ContentRepository
    func execute() async throws -> [Word] {
        try await repository.loadWords()
    }
}
