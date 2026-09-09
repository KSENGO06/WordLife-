import SwiftUI

@main
struct LifeWordApp: App {
    private let contentRepository = BundledJSONContentRepository()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                CategoriesListView(
                    getCategoriesUseCase: GetCategoriesUseCase(repository: contentRepository),
                    getWordsUseCase: GetWordsUseCase(repository: contentRepository),
                    getSceneUseCase: GetSceneUseCase(repository: contentRepository),
                    getSentencesUseCase: GetSentenceExercisesUseCase(repository: contentRepository),
                    getSentenceChoicesUseCase: GetSentenceChoiceExercisesUseCase(repository: contentRepository),
                    audioPlayer: SpeechAudioPlayer()
                )
            }
        }
    }
}
