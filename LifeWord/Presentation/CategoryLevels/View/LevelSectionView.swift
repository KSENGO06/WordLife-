import SwiftUI

struct LevelSectionView: View {
    @State private var viewModel: LevelViewModel
    @State private var didFinishOrExit = false
    let audioPlayer: AudioPlayer
    let onComplete: () -> Void
    let onExit: ([String]) -> Void

    init(sentences: [SentenceExercise], sectionType: LevelSectionType, resumingIds: [String]? = nil, audioPlayer: AudioPlayer, onComplete: @escaping () -> Void, onExit: @escaping ([String]) -> Void) {
        _viewModel = State(wrappedValue: LevelViewModel(sentences: sentences, sectionType: sectionType, resumingIds: resumingIds))
        self.audioPlayer = audioPlayer
        self.onComplete = onComplete
        self.onExit = onExit
    }

    var body: some View {
        let _ = print("🟢 LevelSectionView.body викликано")
        VStack(spacing: 16) {
            HStack {
                Button { exit() } label: { Image(systemName: "xmark") }
                ProgressView(value: viewModel.progress)
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill").foregroundStyle(.red)
                    Text("\(HeartsManager.shared.hearts)")
                }
            }
            .padding(.horizontal)

            if let exercise = viewModel.currentExercise {
                exerciseView(for: exercise)
                    .id(exercise.id)
                Spacer()
            }
        }
        .padding(.top)
        .onDisappear { exit() }
    }

    private func finish() {
        guard !didFinishOrExit else {
            print("🔴 finish() викликано повторно, ігнорую")
            return
        }
        didFinishOrExit = true
        print("🟢 finish() -> onComplete()")
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
            exit()
        }
    }

    @ViewBuilder
    private func exerciseView(for exercise: SentenceExercise) -> some View {
        switch viewModel.sectionType {
        case .puzzleTarget:
            PuzzleExerciseView(exercise: exercise, buildTarget: true, audioPlayer: audioPlayer) { handleAnswer($0) }
        case .puzzleNative:
            PuzzleExerciseView(exercise: exercise, buildTarget: false, audioPlayer: audioPlayer) { handleAnswer($0) }
        case .listening:
            ListeningExerciseView(exercise: exercise, audioPlayer: audioPlayer) { handleAnswer($0) }
        case .fillBlank:
            FillBlankExerciseView(exercise: exercise, audioPlayer: audioPlayer) { handleAnswer($0) }
        case .sentenceChoice:
            EmptyView()
        }
    }
}
