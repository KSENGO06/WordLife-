import SwiftUI

struct TranslationCheckView: View {
    @State private var viewModel: TranslationCheckViewModel
    @State private var didFinishOrExit = false
    let audioPlayer: AudioPlayer
    let onComplete: () -> Void
    let onExit: ([String]) -> Void

    init(words: [Word], direction: TranslationDirection, resumingIds: [String]? = nil, audioPlayer: AudioPlayer, onComplete: @escaping () -> Void, onExit: @escaping ([String]) -> Void) {
        _viewModel = State(wrappedValue: TranslationCheckViewModel(words: words, direction: direction, resumingIds: resumingIds))
        self.audioPlayer = audioPlayer
        self.onComplete = onComplete
        self.onExit = onExit
    }

    var body: some View {
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

            if let word = viewModel.currentWord {
                ChooseTranslationExerciseView(
                    word: word,
                    options: viewModel.currentOptions,
                    direction: viewModel.direction,
                    audioPlayer: audioPlayer
                ) { isCorrect in
                    viewModel.answer(isCorrect: isCorrect)
                    if viewModel.isFinished {
                        finish()
                    } else if HeartsManager.shared.hearts == 0 {
                        exit()
                    }
                }
                .id(word.id)
                Spacer()
            }
        }
        .padding(.top)
        .onDisappear { exit() }
    }

    private func finish() {
        guard !didFinishOrExit else { return }
        didFinishOrExit = true
        onComplete()
    }

    private func exit() {
        guard !didFinishOrExit else { return }
        didFinishOrExit = true
        onExit(viewModel.remainingIds)
    }
}
