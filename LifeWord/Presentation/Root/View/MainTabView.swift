import SwiftUI
import WidgetKit

/// Нижня панель вкладок — головний каркас застосунку: Головна, Категорії,
/// Словник, Профіль. Створює всі use case'и один раз і роздає їх вкладкам,
/// так само як раніше це робив LifeWordApp для CategoriesListView.
struct MainTabView: View {
    private let getCategoriesUseCase: GetCategoriesUseCase
    private let getThemesUseCase: GetThemesUseCase
    private let getWordsUseCase: GetWordsUseCase
    private let getAllWordsUseCase: GetAllWordsUseCase
    private let getSceneUseCase: GetSceneUseCase
    private let getSentencesUseCase: GetSentenceExercisesUseCase
    private let getSentenceChoicesUseCase: GetSentenceChoiceExercisesUseCase
    private let getTranslationExercisesUseCase: GetTranslationExercisesUseCase
    private let getClozeExerciseUseCase: GetClozeExerciseUseCase
    private let audioPlayer: AudioPlayer

    init(contentRepository: ContentRepository) {
        self.getCategoriesUseCase = GetCategoriesUseCase(repository: contentRepository)
        self.getThemesUseCase = GetThemesUseCase(repository: contentRepository)
        self.getWordsUseCase = GetWordsUseCase(repository: contentRepository)
        self.getAllWordsUseCase = GetAllWordsUseCase(repository: contentRepository)
        self.getSceneUseCase = GetSceneUseCase(repository: contentRepository)
        self.getSentencesUseCase = GetSentenceExercisesUseCase(repository: contentRepository)
        self.getSentenceChoicesUseCase = GetSentenceChoiceExercisesUseCase(repository: contentRepository)
        self.getTranslationExercisesUseCase = GetTranslationExercisesUseCase(repository: contentRepository)
        self.getClozeExerciseUseCase = GetClozeExerciseUseCase(repository: contentRepository)
        self.audioPlayer = SpeechAudioPlayer()
    }

    var body: some View {
        TabView {
            NavigationStack {
                HomeView(
                    getAllWordsUseCase: getAllWordsUseCase,
                    getCategoriesUseCase: getCategoriesUseCase,
                    getWordsUseCase: getWordsUseCase,
                    getSceneUseCase: getSceneUseCase,
                    getSentencesUseCase: getSentencesUseCase,
                    getSentenceChoicesUseCase: getSentenceChoicesUseCase,
                    getTranslationExercisesUseCase: getTranslationExercisesUseCase,
                    getClozeExerciseUseCase: getClozeExerciseUseCase,
                    audioPlayer: audioPlayer
                )
            }
            .tabItem { Label("Home", systemImage: "house.fill") }

            NavigationStack {
                CategoriesListView(
                    getCategoriesUseCase: getCategoriesUseCase,
                    getThemesUseCase: getThemesUseCase,
                    getWordsUseCase: getWordsUseCase,
                    getSceneUseCase: getSceneUseCase,
                    getSentencesUseCase: getSentencesUseCase,
                    getSentenceChoicesUseCase: getSentenceChoicesUseCase,
                    getTranslationExercisesUseCase: getTranslationExercisesUseCase,
                    getClozeExerciseUseCase: getClozeExerciseUseCase,
                    audioPlayer: audioPlayer
                )
            }
            .tabItem { Label("Categories", systemImage: "square.grid.2x2.fill") }

            NavigationStack {
                AllWordsView(
                    getAllWordsUseCase: getAllWordsUseCase,
                    getCategoriesUseCase: getCategoriesUseCase,
                    getWordsUseCase: getWordsUseCase,
                    getSceneUseCase: getSceneUseCase,
                    getSentencesUseCase: getSentencesUseCase,
                    getSentenceChoicesUseCase: getSentenceChoicesUseCase,
                    getTranslationExercisesUseCase: getTranslationExercisesUseCase,
                    getClozeExerciseUseCase: getClozeExerciseUseCase,
                    audioPlayer: audioPlayer
                )
            }
            .tabItem { Label("Dictionary", systemImage: "character.book.closed.fill") }

            NavigationStack {
                ProfileView(
                    getCategoriesUseCase: getCategoriesUseCase,
                    getAllWordsUseCase: getAllWordsUseCase
                )
            }
            .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
        }
        .tint(Color.appAccent)
        .task {
            await syncWidgetWords()
            NotificationManager.requestAuthorizationIfNeeded()
            NotificationManager.refreshStreakReminders(activeDays: ActivityManager.shared.activeDays)
        }
    }

    /// Раз на сесію передає весь перелік слів у спільне сховище (App Group),
    /// щоб віджет на домашньому екрані міг сам вибирати, яке слово показати
    /// і міняти його з часом, навіть якщо застосунок довго не відкривали.
    private func syncWidgetWords() async {
        guard let words = try? await getAllWordsUseCase.execute(), !words.isEmpty else { return }
        let entries = words.map {
            WidgetWordEntry(id: $0.id, term: $0.term, translation: $0.translation, imageAsset: $0.imageAsset)
        }
        WidgetWordsStore.save(entries)
        WidgetCenter.shared.reloadTimelines(ofKind: "LifeWordWidget")
    }
}
