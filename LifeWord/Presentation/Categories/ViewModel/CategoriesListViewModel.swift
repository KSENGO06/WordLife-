import Observation

@Observable
final class CategoriesListViewModel {
    private let getCategoriesUseCase: GetCategoriesUseCase
    private let getWordsUseCase: GetWordsUseCase

    var categories: [Category] = []
    var wordCounts: [String: Int] = [:]
    var isLoading = false
    var errorMessage: String?

    init(getCategoriesUseCase: GetCategoriesUseCase, getWordsUseCase: GetWordsUseCase) {
        self.getCategoriesUseCase = getCategoriesUseCase
        self.getWordsUseCase = getWordsUseCase
    }

    @MainActor
    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            categories = try await getCategoriesUseCase.execute().sorted { $0.order < $1.order }
            for category in categories {
                let words = try await getWordsUseCase.execute(categoryId: category.id)
                wordCounts[category.id] = words.count
            }
        } catch {
            errorMessage = "Не вдалося завантажити категорії"
        }
        isLoading = false
    }
}
