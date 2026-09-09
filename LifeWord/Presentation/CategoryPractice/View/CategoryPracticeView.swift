import SwiftUI

extension FlatSection: Identifiable {
    var id: String { progressKey }
}

struct CategoryPracticeView: View {
    @State private var viewModel: CategoryPracticeViewModel
    @State private var activeSection: FlatSection?
    private let audioPlayer: AudioPlayer

    init(categoryId: String, getWordsUseCase: GetWordsUseCase, getSentencesUseCase: GetSentenceExercisesUseCase, getSentenceChoicesUseCase: GetSentenceChoiceExercisesUseCase, audioPlayer: AudioPlayer) {
        _viewModel = State(wrappedValue: CategoryPracticeViewModel(categoryId: categoryId, getWordsUseCase: getWordsUseCase, getSentencesUseCase: getSentencesUseCase, getSentenceChoicesUseCase: getSentenceChoicesUseCase))
        self.audioPlayer = audioPlayer
    }

    var body: some View {
        List {
            if HeartsManager.shared.hearts == 0 {
                Section {
                    HStack {
                        Image(systemName: "heart.slash.fill").foregroundStyle(.red)
                        Text("Серця закінчились. Зачекай, поки відновляться.")
                            .font(.subheadline)
                        Spacer()
                        #if DEBUG
                        Button("Скинути (DEBUG)") { HeartsManager.shared.debugResetHearts() }
                            .font(.caption)
                        #endif
                    }
                }
            }
            Section {
                ForEach(PracticeSectionType.allCases) { section in
                    sectionRow(.practice(section), title: section.title, subtitle: section.subtitle)
                }
            }
            Section("Рівень 1") {
                ForEach(LevelSectionType.level1Cases) { section in
                    sectionRow(.level(1, section), title: section.title, subtitle: section.subtitle)
                }
            }
            Section("Рівень 2") {
                ForEach(LevelSectionType.level2Cases) { section in
                    sectionRow(.level(2, section), title: section.title, subtitle: section.subtitle)
                }
            }
        }
        .navigationTitle("Практика")
        .task { await viewModel.load() }
        .fullScreenCover(item: $activeSection) { section in
            destinationView(for: section)
        }
    }

    @ViewBuilder
    private func sectionRow(_ section: FlatSection, title: String, subtitle: String) -> some View {
        let structurallyUnlocked = viewModel.isUnlocked(section) && !viewModel.isLoading
        let completed = viewModel.isCompleted(section)
        let canEnter = structurallyUnlocked && HeartsManager.shared.hearts > 0 && !completed
        let fraction = viewModel.progressFraction(for: section)

        if canEnter {
            Button { activeSection = section } label: {
                row(title: title, subtitle: subtitle, completed: completed, unlocked: true, fraction: fraction)
            }
        } else {
            row(title: title, subtitle: subtitle, completed: completed, unlocked: structurallyUnlocked, fraction: fraction)
        }
    }

    private func row(title: String, subtitle: String, completed: Bool, unlocked: Bool, fraction: Double?) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Image(viewModel.categoryIconName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .blur(radius: unlocked ? 0 : 4)
                    .opacity(unlocked ? 1 : 0.6)

                if completed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                        .background(Color.white, in: Circle())
                        .offset(x: 15, y: 15)
                } else if let fraction, fraction > 0 {
                    Text("\(Int(fraction * 100))%")
                        .font(.caption2.bold())
                        .padding(.horizontal, 4).padding(.vertical, 2)
                        .background(Color.black.opacity(0.55), in: Capsule())
                        .foregroundStyle(.white)
                } else if !unlocked {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.55), in: Circle())
                }
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
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
            LevelSectionView(sentences: sentences, sectionType: levelSection, resumingIds: viewModel.remainingIds(for: section), audioPlayer: audioPlayer, onComplete: { handleComplete(section) }, onExit: { ids in handleExit(section, remainingIds: ids) })
        }
    }

    private func handleComplete(_ section: FlatSection) {
        viewModel.clearProgress(for: section)
        switch section {
        case .practice(let s): viewModel.markCompleted(s)
        case .level(let level, let s): viewModel.markCompleted(level: level, s)
        }
        let next = HeartsManager.shared.hearts > 0 ? viewModel.nextUnlockedSection(after: section) : nil
        activeSection = nil
        if let next {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                activeSection = next
            }
        }
    }

    private func handleExit(_ section: FlatSection, remainingIds: [String]?) {
        if let remainingIds {
            viewModel.saveProgress(remainingIds, for: section)
        }
        activeSection = nil
    }
}
