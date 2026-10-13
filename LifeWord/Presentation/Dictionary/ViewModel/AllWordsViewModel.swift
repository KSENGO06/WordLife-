import Observation
import Foundation

@Observable
final class AllWordsViewModel {
    private let getAllWordsUseCase: GetAllWordsUseCase
    private let getCategoriesUseCase: GetCategoriesUseCase

    var words: [Word] = []
    var categories: [Category] = []
    var isLoading = false
    var searchText = ""

    init(getAllWordsUseCase: GetAllWordsUseCase, getCategoriesUseCase: GetCategoriesUseCase) {
        self.getAllWordsUseCase = getAllWordsUseCase
        self.getCategoriesUseCase = getCategoriesUseCase
    }

    @MainActor
    func load() async {
        isLoading = true
        words = ((try? await getAllWordsUseCase.execute()) ?? []).sorted { $0.term.lowercased() < $1.term.lowercased() }
        categories = (try? await getCategoriesUseCase.execute()) ?? []
        isLoading = false
    }

    var filteredWords: [Word] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return words }
        return words.filter { $0.term.lowercased().contains(query) || $0.translation.lowercased().contains(query) }
    }

    func category(for word: Word) -> Category? {
        categories.first(where: { $0.id == word.categoryId })
    }

    // MARK: - Прогрес по темах (для секції "Topics" у Словнику)

    /// Скільки слів учні зафіксовано живими в content.json на кожну категорію.
    private var wordCountsByCategory: [String: Int] {
        Dictionary(grouping: words, by: { $0.categoryId }).mapValues { $0.count }
    }

    struct TopicProgress: Identifiable {
        let category: Category
        let wordCount: Int
        let learnedCount: Int
        let fraction: Double
        var id: String { category.id }
    }

    /// Усі категорії, у порядку контенту, із приблизною кількістю вивчених слів —
    /// частка пройдених секцій (CategoryProgressStore) помножена на кількість слів
    /// у категорії, бо слова самі по собі не мають індивідуальної позначки "вивчено".
    var topicsProgress: [TopicProgress] {
        let counts = wordCountsByCategory
        return categories
            .sorted { $0.order < $1.order }
            .map { category in
                let count = counts[category.id] ?? 0
                let fraction = min(CategoryProgressStore.progressFraction(categoryId: category.id, isPhrasal: category.isPhrasalVerbs), 1)
                let learned = Int((Double(count) * fraction).rounded())
                return TopicProgress(category: category, wordCount: count, learnedCount: learned, fraction: fraction)
            }
    }

    var totalWordsCount: Int { words.count }

    var learnedWordsCount: Int {
        topicsProgress.reduce(0) { $0 + $1.learnedCount }
    }
}
