import Observation
import Foundation

@Observable
final class HomeViewModel {
    private let getAllWordsUseCase: GetAllWordsUseCase
    private let getCategoriesUseCase: GetCategoriesUseCase

    var allWords: [Word] = []
    var categories: [Category] = []
    var isLoading = false

    init(getAllWordsUseCase: GetAllWordsUseCase, getCategoriesUseCase: GetCategoriesUseCase) {
        self.getAllWordsUseCase = getAllWordsUseCase
        self.getCategoriesUseCase = getCategoriesUseCase
    }

    @MainActor
    func load() async {
        isLoading = true
        allWords = (try? await getAllWordsUseCase.execute()) ?? []
        categories = ((try? await getCategoriesUseCase.execute()) ?? []).sorted { $0.order < $1.order }
        isLoading = false
    }

    var wordOfDay: Word? {
        ActivityManager.shared.wordOfDay(from: allWords)
    }

    /// Категорія для картки "Продовжити" — остання відкрита, або перша за
    /// порядком, якщо історії ще немає.
    var continueCategory: Category? {
        if let id = ActivityManager.shared.lastCategoryId, let match = categories.first(where: { $0.id == id }) {
            return match
        }
        return categories.first(where: { !$0.isPhrasalVerbs })
    }

    func category(for word: Word) -> Category? {
        categories.first(where: { $0.id == word.categoryId })
    }
}
