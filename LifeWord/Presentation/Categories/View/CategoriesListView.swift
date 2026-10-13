import SwiftUI

enum LearningMode: String, CaseIterable, Identifiable {
    case words = "Words"
    case phrasalVerbs = "Phrasal verbs"
    var id: String { rawValue }
}

struct CategoriesListView: View {
    @State private var viewModel: CategoriesListViewModel
    @State private var mode: LearningMode = .words

    private let getWordsUseCase: GetWordsUseCase
    private let getSceneUseCase: GetSceneUseCase
    private let getSentencesUseCase: GetSentenceExercisesUseCase
    private let getSentenceChoicesUseCase: GetSentenceChoiceExercisesUseCase
    private let getTranslationExercisesUseCase: GetTranslationExercisesUseCase
    private let getClozeExerciseUseCase: GetClozeExerciseUseCase
    private let audioPlayer: AudioPlayer

    private let gridColumns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible())]

    init(getCategoriesUseCase: GetCategoriesUseCase,
         getThemesUseCase: GetThemesUseCase,
         getWordsUseCase: GetWordsUseCase,
         getSceneUseCase: GetSceneUseCase,
         getSentencesUseCase: GetSentenceExercisesUseCase,
         getSentenceChoicesUseCase: GetSentenceChoiceExercisesUseCase,
         getTranslationExercisesUseCase: GetTranslationExercisesUseCase,
         getClozeExerciseUseCase: GetClozeExerciseUseCase,
         audioPlayer: AudioPlayer) {
        _viewModel = State(wrappedValue: CategoriesListViewModel(getCategoriesUseCase: getCategoriesUseCase, getThemesUseCase: getThemesUseCase, getWordsUseCase: getWordsUseCase))
        self.getWordsUseCase = getWordsUseCase
        self.getSceneUseCase = getSceneUseCase
        self.getSentencesUseCase = getSentencesUseCase
        self.getSentenceChoicesUseCase = getSentenceChoicesUseCase
        self.getTranslationExercisesUseCase = getTranslationExercisesUseCase
        self.getClozeExerciseUseCase = getClozeExerciseUseCase
        self.audioPlayer = audioPlayer
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $mode) {
                ForEach(LearningMode.allCases) { Text($0.rawValue).font(.appBodyRegular).lineLimit(1).minimumScaleFactor(0.7).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding()

            switch mode {
            case .words: wordsGrid
            case .phrasalVerbs: phrasalGrid
            }
        }
        .appScreenBackground()
        .navigationTitle("Categories")
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private var wordsGrid: some View {
        if viewModel.isLoading {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.errorMessage {
            Text(error).font(.appBodyRegular)
        } else {
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 14) {
                    ForEach(viewModel.categoriesByTheme, id: \.theme.id) { group in
                        themeCard(group.theme, group.categories)
                    }
                }
                .padding(16)
            }
        }
    }

    @ViewBuilder
    private var phrasalGrid: some View {
        if viewModel.isLoading {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.errorMessage {
            Text(error).font(.appBodyRegular)
        } else {
            let phrasalCategories = viewModel.phrasalCategoriesByTheme.flatMap(\.categories)
            if phrasalCategories.isEmpty {
                comingSoonView
            } else {
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 14) {
                        ForEach(phrasalCategories) { category in
                            phrasalCategoryCard(category)
                        }
                    }
                    .padding(16)
                }
            }
        }
    }

    private func themeCard(_ theme: Theme, _ categories: [Category]) -> some View {
        let content = ThemeContent.entry(for: theme.id, fallbackName: theme.name)
        let totalWords = categories.reduce(0) { $0 + (viewModel.wordCounts[$1.id] ?? 0) }
        return NavigationLink {
            ThemeDetailView(
                theme: theme,
                categories: categories,
                wordCounts: viewModel.wordCounts,
                getWordsUseCase: getWordsUseCase,
                getSceneUseCase: getSceneUseCase,
                getSentencesUseCase: getSentencesUseCase,
                getSentenceChoicesUseCase: getSentenceChoicesUseCase,
                audioPlayer: audioPlayer
            )
        } label: {
            GridPhotoCard(
                title: content.title,
                subtitle: "\(categories.count) topics · \(totalWords) words",
                preferredImageName: "theme_\(theme.id)",
                // No fallback to an existing category photo here on purpose: those
                // images were made for other screens (some are diagrams, not photos)
                // and mixing them looked inconsistent. Clean placeholder until a
                // dedicated "theme_<id>" hero photo is added.
                symbolName: content.symbolName
            )
        }
        .buttonStyle(.plain)
    }

    private func phrasalCategoryCard(_ category: Category) -> some View {
        NavigationLink {
            PhrasalCategoryOverviewView(
                categoryId: category.id,
                categoryName: category.name.replacingOccurrences(of: "Phrasal Verbs: ", with: ""),
                getWordsUseCase: getWordsUseCase,
                getSceneUseCase: getSceneUseCase,
                getTranslationExercisesUseCase: getTranslationExercisesUseCase,
                getClozeExerciseUseCase: getClozeExerciseUseCase,
                audioPlayer: audioPlayer)
        } label: {
            GridPhotoCard(
                title: category.name.replacingOccurrences(of: "Phrasal Verbs: ", with: ""),
                subtitle: "\(viewModel.wordCounts[category.id] ?? 0) verbs",
                preferredImageName: PhrasalThemeAsset.imageName(for: category.id),
                symbolName: "text.book.closed.fill"
            )
        }
        .buttonStyle(.plain)
    }

    private var comingSoonView: some View {
        VStack(spacing: 12) {
            Image(systemName: "hourglass").font(.appDisplay).foregroundStyle(.secondary)
            Text("Coming soon").font(.appHeadline).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
