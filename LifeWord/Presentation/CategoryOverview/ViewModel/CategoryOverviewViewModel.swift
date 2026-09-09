import Observation

@Observable
final class CategoryOverviewViewModel {
    private let getWordsUseCase: GetWordsUseCase
    private let getSceneUseCase: GetSceneUseCase
    private let categoryId: String

    var words: [Word] = []
    var scene: RoomScene?
    var isLoading = false
    var errorMessage: String?

    init(categoryId: String, getWordsUseCase: GetWordsUseCase, getSceneUseCase: GetSceneUseCase) {
        self.categoryId = categoryId
        self.getWordsUseCase = getWordsUseCase
        self.getSceneUseCase = getSceneUseCase
    }

    @MainActor
    func load() async {
        print("DEBUG: load() запущено")
        isLoading = true
        errorMessage = nil
        do {
            async let wordsResult = getWordsUseCase.execute(categoryId: categoryId)
            async let sceneResult = getSceneUseCase.execute(categoryId: categoryId)
            words = try await wordsResult
            scene = try await sceneResult
        } catch {
            errorMessage = "Failed to load category"
        }
        isLoading = false
    }
}
