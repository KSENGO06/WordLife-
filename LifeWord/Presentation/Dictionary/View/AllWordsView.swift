import SwiftUI

/// Вкладка "Словник" — пошук, прогрес по темах, список усіх тем і повний
/// перелік слів; вибір слова відкриває картку саме з цим словом (WordCardsView
/// зі startWordId), вибір теми — її огляд вправ, як і раніше.
struct AllWordsView: View {
    @State private var viewModel: AllWordsViewModel

    private let getWordsUseCase: GetWordsUseCase
    private let getSceneUseCase: GetSceneUseCase
    private let getSentencesUseCase: GetSentenceExercisesUseCase
    private let getSentenceChoicesUseCase: GetSentenceChoiceExercisesUseCase
    private let getTranslationExercisesUseCase: GetTranslationExercisesUseCase
    private let getClozeExerciseUseCase: GetClozeExerciseUseCase
    private let audioPlayer: AudioPlayer

    init(getAllWordsUseCase: GetAllWordsUseCase,
         getCategoriesUseCase: GetCategoriesUseCase,
         getWordsUseCase: GetWordsUseCase,
         getSceneUseCase: GetSceneUseCase,
         getSentencesUseCase: GetSentenceExercisesUseCase,
         getSentenceChoicesUseCase: GetSentenceChoiceExercisesUseCase,
         getTranslationExercisesUseCase: GetTranslationExercisesUseCase,
         getClozeExerciseUseCase: GetClozeExerciseUseCase,
         audioPlayer: AudioPlayer) {
        _viewModel = State(wrappedValue: AllWordsViewModel(getAllWordsUseCase: getAllWordsUseCase, getCategoriesUseCase: getCategoriesUseCase))
        self.getWordsUseCase = getWordsUseCase
        self.getSceneUseCase = getSceneUseCase
        self.getSentencesUseCase = getSentencesUseCase
        self.getSentenceChoicesUseCase = getSentenceChoicesUseCase
        self.getTranslationExercisesUseCase = getTranslationExercisesUseCase
        self.getClozeExerciseUseCase = getClozeExerciseUseCase
        self.audioPlayer = audioPlayer
    }

    private var isSearching: Bool {
        !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                screenHeader
                searchField

                if viewModel.isLoading && viewModel.words.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                } else if isSearching {
                    searchResultsSection
                } else {
                    learnedSummaryCard
                    topicsSection
                }
            }
            .padding(20)
        }
        .appScreenBackground()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }

    // MARK: - Заголовок і пошук

    private var screenHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Dictionary").font(.appTitleL)
            Text("\(viewModel.totalWordsCount) words in \(viewModel.categories.count) topics")
                .font(.appBodySmall)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search words", text: $viewModel.searchText)
                .font(.appBodyRegular)
                .autocorrectionDisabled()
            if isSearching {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
    }

    // MARK: - Картка "Learned" (прогрес по всіх темах разом)

    private var learnedSummaryCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("LEARNED")
                    .font(.appLabel)
                    .foregroundStyle(.white.opacity(0.85))
                Text("\(viewModel.learnedWordsCount)")
                    .font(AppFont.playfairBold(36))
                    .foregroundStyle(.white)
                Text("of \(viewModel.totalWordsCount) words")
                    .font(.appCaption)
                    .foregroundStyle(.white.opacity(0.85))
            }
            Spacer(minLength: 0)
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 76, height: 76)
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
                // Сам малюнок героя в mascot_resting.png не займає центр
                // свого квадратного полотна (права рука/лінія тягнеться в
                // порожній простір праворуч) — зсуваємо на кілька пунктів,
                // щоб видима фігурка була по центру кола, а не самe полотно.
                MascotView(pose: .resting, size: 56)
                    .offset(x: 3, y: -4)
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.appAccent))
    }

    // MARK: - Теми

    private var topicsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Topics")
            LazyVStack(spacing: 10) {
                ForEach(viewModel.topicsProgress) { progress in
                    topicRow(progress)
                }
            }
        }
    }

    private func topicRow(_ progress: AllWordsViewModel.TopicProgress) -> some View {
        let category = progress.category
        return NavigationLink {
            destination(for: category)
        } label: {
            HStack(spacing: 12) {
                topicThumbnail(for: category)
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text(category.name.replacingOccurrences(of: "Phrasal Verbs: ", with: ""))
                        .font(.appBodyRegular)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text("\(progress.learnedCount) of \(progress.wordCount) words")
                        .font(.appCaption)
                        .foregroundStyle(.secondary)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(.systemGray5))
                            Capsule().fill(Color.appAccent).frame(width: max(4, geo.size.width * progress.fraction))
                        }
                    }
                    .frame(height: 5)
                }
                Spacer(minLength: 8)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func topicThumbnail(for category: Category) -> some View {
        if category.isPhrasalVerbs {
            ArtworkFallback(preferredImageName: PhrasalThemeAsset.imageName(for: category.id), symbolName: "text.book.closed.fill")
        } else {
            ArtworkFallback(fallbackImageNames: ImageAssetResolver.candidates(for: category), symbolName: "square.grid.2x2.fill")
        }
    }

    // MARK: - Результати пошуку

    @ViewBuilder
    private var searchResultsSection: some View {
        if viewModel.filteredWords.isEmpty {
            emptyState
        } else {
            LazyVStack(spacing: 10) {
                ForEach(viewModel.filteredWords) { word in
                    wordRow(word)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass").font(.appDisplay).foregroundStyle(.secondary)
            Text("Nothing found").font(.appHeadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    @ViewBuilder
    private func wordRow(_ word: Word) -> some View {
        let category = viewModel.category(for: word)
        NavigationLink {
            if let category {
                WordCardsView(categoryId: category.id, getWordsUseCase: getWordsUseCase, audioPlayer: audioPlayer, startWordId: word.id)
            } else {
                EmptyView()
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(word.term).font(.appHeadline)
                    Text(word.translation).font(.appBodySmall).foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                if let category {
                    Text(category.name.replacingOccurrences(of: "Phrasal Verbs: ", with: ""))
                        .font(.appCaption2)
                        .foregroundStyle(Color.appAccent)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.appAccent.opacity(0.12)))
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
        }
        .buttonStyle(.plain)
        .disabled(category == nil)
    }

    // MARK: - Навігація з теми (просто перелік слів цієї категорії, без сцени/вправ)

    private func destination(for category: Category) -> some View {
        CategoryWordsListView(
            categoryName: category.name.replacingOccurrences(of: "Phrasal Verbs: ", with: ""),
            categoryId: category.id,
            words: viewModel.words.filter { $0.categoryId == category.id },
            getWordsUseCase: getWordsUseCase,
            audioPlayer: audioPlayer
        )
    }

    // MARK: - Спільне

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.appLabel)
            .foregroundStyle(.secondary)
    }
}

/// Перелік слів однієї теми (без сцени/вправ) — відкривається з рядка теми у
/// Словнику; вибір слова веде у WordCardsView одразу на ньому (startWordId).
private struct CategoryWordsListView: View {
    let categoryName: String
    let categoryId: String
    let words: [Word]
    let getWordsUseCase: GetWordsUseCase
    let audioPlayer: AudioPlayer

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(words) { word in
                    wordRow(word)
                }
            }
            .padding(20)
        }
        .appScreenBackground()
        .navigationTitle(categoryName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func wordRow(_ word: Word) -> some View {
        NavigationLink {
            WordCardsView(categoryId: categoryId, getWordsUseCase: getWordsUseCase, audioPlayer: audioPlayer, startWordId: word.id)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(word.term).font(.appHeadline)
                    Text(word.translation).font(.appBodySmall).foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.appAccent)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
        }
        .buttonStyle(.plain)
    }
}
