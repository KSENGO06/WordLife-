import SwiftUI

enum LearningMode: String, CaseIterable, Identifiable {
    case words = "Слова"
    case phrasalVerbs = "Фразові дієслова"
    var id: String { rawValue }
}

struct CategoriesListView: View {
    @State private var viewModel: CategoriesListViewModel
    @State private var mode: LearningMode = .words

    private let getWordsUseCase: GetWordsUseCase
    private let getSceneUseCase: GetSceneUseCase
    private let getSentencesUseCase: GetSentenceExercisesUseCase
    private let getSentenceChoicesUseCase: GetSentenceChoiceExercisesUseCase
    private let audioPlayer: AudioPlayer

    init(getCategoriesUseCase: GetCategoriesUseCase, getWordsUseCase: GetWordsUseCase, getSceneUseCase: GetSceneUseCase, getSentencesUseCase: GetSentenceExercisesUseCase, getSentenceChoicesUseCase: GetSentenceChoiceExercisesUseCase, audioPlayer: AudioPlayer) {
        _viewModel = State(wrappedValue: CategoriesListViewModel(getCategoriesUseCase: getCategoriesUseCase, getWordsUseCase: getWordsUseCase))
        self.getWordsUseCase = getWordsUseCase
        self.getSceneUseCase = getSceneUseCase
        self.getSentencesUseCase = getSentencesUseCase
        self.getSentenceChoicesUseCase = getSentenceChoicesUseCase
        self.audioPlayer = audioPlayer
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $mode) {
                ForEach(LearningMode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding()

            switch mode {
            case .words: wordsList
            case .phrasalVerbs: comingSoonView
            }
        }
        .navigationTitle("Категорії")
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private var wordsList: some View {
        if viewModel.isLoading {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.errorMessage {
            Text(error)
        } else {
            List(viewModel.categories) { category in
                NavigationLink {
                    CategoryOverviewView(
                        categoryId: category.id,
                        getWordsUseCase: getWordsUseCase,
                        getSceneUseCase: getSceneUseCase,
                        getSentencesUseCase: getSentencesUseCase,
                        getSentenceChoicesUseCase: getSentenceChoicesUseCase,
                        audioPlayer: audioPlayer)
                } label: {
                    HStack(spacing: 12) {
                        Image("\(category.id)_scene")
                            .resizable().scaledToFill()
                            .frame(width: 52, height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.name).font(.headline)
                            Text("\(viewModel.wordCounts[category.id] ?? 0) слів")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
        }
    }

    private var comingSoonView: some View {
        VStack(spacing: 12) {
            Image(systemName: "hourglass").font(.largeTitle).foregroundStyle(.secondary)
            Text("Скоро з'явиться").font(.headline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
