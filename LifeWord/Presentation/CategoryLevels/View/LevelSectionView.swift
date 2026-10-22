import SwiftUI

struct LevelSectionView: View {
    @State private var viewModel: LevelViewModel
    @State private var didFinishOrExit = false
    @State private var showHeartsLimitSheet = false
    let categoryId: String
    let audioPlayer: AudioPlayer
    let onComplete: () -> Void
    let onExit: ([String]) -> Void
 
    init(sentences: [SentenceExercise], sectionType: LevelSectionType, categoryId: String, resumingIds: [String]? = nil, audioPlayer: AudioPlayer, onComplete: @escaping () -> Void, onExit: @escaping ([String]) -> Void) {
        _viewModel = State(wrappedValue: LevelViewModel(sentences: sentences, sectionType: sectionType, resumingIds: resumingIds))
        self.categoryId = categoryId
        self.audioPlayer = audioPlayer
        self.onComplete = onComplete
        self.onExit = onExit
    }
 
    var body: some View {
        Group {
            if let exercise = viewModel.currentExercise {
                VStack(spacing: 16) {
                    HStack {
                        Button { exit() } label: { Image(systemName: "xmark") }
                        ProgressView(value: viewModel.progress)
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill").foregroundStyle(.red)
                            Text(HeartsManager.shared.isUnlimited ? "∞" : "\(HeartsManager.shared.hearts)").font(AppFont.interBold(17)).lineLimit(1).minimumScaleFactor(0.7)
                        }
                    }
                    .padding(.horizontal, 20)

                    exerciseView(for: exercise)
                        .id(exercise.id)
                    Spacer()
                }
                .padding(.top, 24)
            } else {
                // Остання вправа вже пройдена — секція завершується і
                // fullScreenCover от-от закриється; показуємо порожній
                // екран замість "голого" заголовка з прогресом/серцями.
                Color.clear
            }
        }
        .onDisappear { exit() }
        .sheet(isPresented: $showHeartsLimitSheet, onDismiss: { exit() }) {
            LimitReachedSheetView(kind: .hearts)
        }
    }
 
    private func finish() {
        guard !didFinishOrExit else {
            return
        }
        didFinishOrExit = true
        onComplete()
    }
 
    private func exit() {
        guard !didFinishOrExit else { return }
        didFinishOrExit = true
        onExit(viewModel.remainingIds)
    }
 
    private func handleAnswer(_ isCorrect: Bool) {
        viewModel.answer(isCorrect: isCorrect)
        if viewModel.isFinished {
            finish()
        } else if HeartsManager.shared.hearts == 0 {
            showHeartsLimitSheet = true
        }
    }
 
    @ViewBuilder
    private func exerciseView(for exercise: SentenceExercise) -> some View {
        switch viewModel.sectionType {
        case .puzzleTarget:
            PuzzleExerciseView(exercise: exercise, buildTarget: true, categoryId: categoryId, audioPlayer: audioPlayer) { handleAnswer($0) }
        case .puzzleNative:
            PuzzleExerciseView(exercise: exercise, buildTarget: false, categoryId: categoryId, audioPlayer: audioPlayer) { handleAnswer($0) }
        case .listening:
            ListeningExerciseView(exercise: exercise, categoryId: categoryId, audioPlayer: audioPlayer) { handleAnswer($0) }
        case .fillBlank:
            FillBlankExerciseView(exercise: exercise, categoryId: categoryId, audioPlayer: audioPlayer) { handleAnswer($0) }
        case .sentenceChoice:
            EmptyView()
        }
    }
}
 
