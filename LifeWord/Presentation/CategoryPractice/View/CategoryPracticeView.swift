import SwiftUI

extension FlatSection: Identifiable {
    var id: String { progressKey }
}

struct CategoryPracticeView: View {
    @State private var viewModel: CategoryPracticeViewModel
    @State private var activeSection: FlatSection?
    /// Наступна секція, яку треба відкрити вже ПІСЛЯ того як поточний fullScreenCover
    /// повністю закриється (а не через фіксовану затримку, яка може спрацювати
    /// зарано/запізно і спричинити "блимання" наступної вправи).
    @State private var pendingNextSection: FlatSection?
    @State private var showPaywall = false
    private let categoryName: String
    private let audioPlayer: AudioPlayer
    /// Якщо задано (перехід з картки "Продовжити" на головному екрані) —
    /// одразу відкриває цю вправу після завантаження даних категорії,
    /// без очікування на тап по списку.
    private let resumeSection: FlatSection?

    init(categoryId: String, categoryName: String, getWordsUseCase: GetWordsUseCase, getSentencesUseCase: GetSentenceExercisesUseCase, getSentenceChoicesUseCase: GetSentenceChoiceExercisesUseCase, audioPlayer: AudioPlayer, resumeSection: FlatSection? = nil) {
        _viewModel = State(wrappedValue: CategoryPracticeViewModel(categoryId: categoryId, getWordsUseCase: getWordsUseCase, getSentencesUseCase: getSentencesUseCase, getSentenceChoicesUseCase: getSentenceChoicesUseCase))
        self.categoryName = categoryName
        self.audioPlayer = audioPlayer
        self.resumeSection = resumeSection
    }

    private var progress: Double {
        viewModel.totalSectionsCount > 0 ? Double(viewModel.completedSectionsCount) / Double(viewModel.totalSectionsCount) : 0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                if HeartsManager.shared.hearts == 0 {
                    heartsBanner
                }

                sectionBlock(title: "Warm-up") {
                    ForEach(PracticeSectionType.allCases) { section in
                        sectionRow(.practice(section), title: section.title, subtitle: section.subtitle)
                    }
                }
                sectionBlock(title: "Level 1") {
                    ForEach(LevelSectionType.level1Cases) { section in
                        sectionRow(.level(1, section), title: section.title, subtitle: section.subtitle)
                    }
                }
                sectionBlock(title: "Level 2") {
                    ForEach(LevelSectionType.level2Cases) { section in
                        sectionRow(.level(2, section), title: section.title, subtitle: section.subtitle)
                    }
                }
            }
            .padding(.bottom, 28)
        }
        .appScreenBackground()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
            ActivityManager.shared.recordCategoryOpened(id: viewModel.categoryId, name: categoryName, isPhrasal: false)
            if let resumeSection, activeSection == nil {
                activeSection = resumeSection
            }
        }
        .fullScreenCover(item: $activeSection, onDismiss: {
            if let pendingNextSection {
                self.pendingNextSection = nil
                activeSection = pendingNextSection
            }
        }) { section in
            destinationView(for: section)
                .appScreenBackground()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: - Шапка: фото категорії, назва, загальний прогрес

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            ArtworkFallback(fallbackImageNames: [viewModel.categoryIconName], symbolName: "square.grid.2x2.fill")
                .frame(height: 170)
                .clipped()
                .overlay(alignment: .bottomLeading) {
                    LinearGradient(colors: [.black.opacity(0.78), .clear], startPoint: .bottom, endPoint: .top)
                        .frame(height: 100)
                }
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(categoryName)
                            .font(.appTitleM)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .foregroundStyle(.white)
                        Text("\(viewModel.words.count) words")
                            .font(.appBodySmall)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(14)
                }
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .padding(.horizontal, 20)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(.systemGray5))
                        Capsule().fill(Color.appAccent).frame(width: max(6, geo.size.width * progress))
                    }
                }
                .frame(height: 6)
                Text("\(viewModel.completedSectionsCount) / \(viewModel.totalSectionsCount) exercises done")
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
        }
    }

    private var heartsBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "heart.slash.fill").foregroundStyle(.red)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Out of hearts")
                        .font(.appBodySmall)
                    if let interval = HeartsManager.shared.timeUntilNextHeart {
                        TimelineView(.periodic(from: .now, by: 1)) { _ in
                            Text("Next heart in \(formattedCountdown(HeartsManager.shared.timeUntilNextHeart ?? interval))")
                                .font(.appCaption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()
                #if DEBUG
                Button("Reset (DEBUG)") { HeartsManager.shared.debugResetHearts() }
                    .font(.appCaption)
                #endif
            }
            Button("Buy subscription — unlimited hearts") {
                showPaywall = true
            }
            .buttonStyle(.secondary)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.red.opacity(0.1)))
        .padding(.horizontal, 20)
    }

    private func formattedCountdown(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private func sectionBlock<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.appHeadline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 20)
            VStack(spacing: 10) {
                content()
            }
            .padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    private func sectionRow(_ section: FlatSection, title: String, subtitle: String) -> some View {
        let structurallyUnlocked = viewModel.isUnlocked(section) && !viewModel.isLoading
        let completed = viewModel.isCompleted(section)
        let canEnter = structurallyUnlocked && HeartsManager.shared.hearts > 0
        let fraction = viewModel.progressFraction(for: section)

        if canEnter {
            Button { activeSection = section } label: {
                row(section: section, title: title, subtitle: subtitle, completed: completed, unlocked: true, fraction: fraction)
            }
            .buttonStyle(.plain)
        } else {
            row(section: section, title: title, subtitle: subtitle, completed: completed, unlocked: structurallyUnlocked, fraction: fraction)
        }
    }

    private func row(section: FlatSection, title: String, subtitle: String, completed: Bool, unlocked: Bool, fraction: Double?) -> some View {
        HStack(spacing: 14) {
            ZStack {
                ArtworkFallback(preferredImageName: section.iconAssetName, symbolName: section.symbolName)
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .opacity(unlocked ? 1 : 0.45)

                if completed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.green)
                        .background(Color.white, in: Circle())
                        .offset(x: 17, y: 17)
                } else if let fraction, fraction > 0 {
                    Text("\(Int(fraction * 100))%")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 4).padding(.vertical, 2)
                        .background(Color.black.opacity(0.6), in: Capsule())
                        .foregroundStyle(.white)
                        .offset(x: 8, y: 17)
                } else if !unlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.white)
                        .padding(5)
                        .background(Color.black.opacity(0.55), in: Circle())
                        .offset(x: 17, y: 17)
                }
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.appHeadline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(unlocked ? .primary : .secondary)
                Text(subtitle)
                    .font(.appBodySmall)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            if unlocked {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.appAccent)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    @ViewBuilder
    private func destinationView(for section: FlatSection) -> some View {
        switch section {
        case .practice(.checkNative):
            TranslationCheckView(words: viewModel.words, direction: .englishToUkrainian, resumingIds: viewModel.remainingIds(for: section), audioPlayer: audioPlayer, onComplete: { handleComplete(section) }, onExit: { ids in handleExit(section, remainingIds: ids) })
        case .practice(.checkTarget):
            TranslationCheckView(words: viewModel.words, direction: .ukrainianToEnglish, resumingIds: viewModel.remainingIds(for: section), audioPlayer: audioPlayer, onComplete: { handleComplete(section) }, onExit: { ids in handleExit(section, remainingIds: ids) })
        case .practice(.matching):
            MatchingSectionView(words: viewModel.words, audioPlayer: audioPlayer, onComplete: { handleComplete(section) }, onExit: { handleExit(section, remainingIds: nil) })
        case .level(_, .sentenceChoice):
            SentenceChoiceSectionView(exercises: viewModel.sentenceChoices, resumingIds: viewModel.remainingIds(for: section), audioPlayer: audioPlayer, onComplete: { handleComplete(section) }, onExit: { ids in handleExit(section, remainingIds: ids) })
        case .level(let level, let levelSection):
            let sentences = level == 1 ? viewModel.sentencesLevel1 : viewModel.sentencesLevel2
            LevelSectionView(sentences: sentences, sectionType: levelSection, categoryId: viewModel.categoryId, resumingIds: viewModel.remainingIds(for: section), audioPlayer: audioPlayer, onComplete: { handleComplete(section) }, onExit: { ids in handleExit(section, remainingIds: ids) })
        }
    }

    private func handleComplete(_ section: FlatSection) {
        viewModel.clearProgress(for: section)
        switch section {
        case .practice(let s): viewModel.markCompleted(s)
        case .level(let level, let s): viewModel.markCompleted(level: level, s)
        }
        let next = HeartsManager.shared.hearts > 0 ? viewModel.nextUnlockedSection(after: section) : nil
        // Не відкриваємо наступну вправу одразу й не через фіксовану затримку —
        // чекаємо onDismiss у fullScreenCover, щоб анімація закриття встигла довершитись.
        pendingNextSection = next
        activeSection = nil
    }

    private func handleExit(_ section: FlatSection, remainingIds: [String]?) {
        if let remainingIds {
            viewModel.saveProgress(remainingIds, for: section)
        }
        activeSection = nil
    }
}
