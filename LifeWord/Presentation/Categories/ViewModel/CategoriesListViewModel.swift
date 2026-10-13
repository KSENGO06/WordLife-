import Observation
 
@Observable
final class CategoriesListViewModel {
    private let getCategoriesUseCase: GetCategoriesUseCase
    private let getThemesUseCase: GetThemesUseCase
    private let getWordsUseCase: GetWordsUseCase
 
    var categories: [Category] = []
    var themes: [Theme] = []
    var wordCounts: [String: Int] = [:]
    var isLoading = false
    var errorMessage: String?
 
    /// Тільки звичайні категорії слів, згруповані за темою.
    var categoriesByTheme: [(theme: Theme, categories: [Category])] {
        groupedByTheme(categories.filter { !$0.isPhrasalVerbs })
    }
 
    /// Тільки категорії фразових дієслів, згруповані за темою.
    var phrasalCategoriesByTheme: [(theme: Theme, categories: [Category])] {
        groupedByTheme(categories.filter { $0.isPhrasalVerbs })
    }
 
    private func groupedByTheme(_ cats: [Category]) -> [(theme: Theme, categories: [Category])] {
        themes.map { theme in
            (theme: theme, categories: cats.filter { $0.themeId == theme.id })
        }
        .filter { !$0.categories.isEmpty }
    }
 
    init(getCategoriesUseCase: GetCategoriesUseCase, getThemesUseCase: GetThemesUseCase, getWordsUseCase: GetWordsUseCase) {
        self.getCategoriesUseCase = getCategoriesUseCase
        self.getThemesUseCase = getThemesUseCase
        self.getWordsUseCase = getWordsUseCase
    }
 
    @MainActor
    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            categories = try await getCategoriesUseCase.execute().sorted { $0.order < $1.order }
            themes = try await getThemesUseCase.execute().sorted { $0.order < $1.order }
            for category in categories {
                let words = try await getWordsUseCase.execute(categoryId: category.id)
                wordCounts[category.id] = words.count
            }
        } catch {
            errorMessage = "Couldn't load categories"
        }
        isLoading = false
    }
}
