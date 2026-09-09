import SwiftUI

struct SentenceChoiceSectionView: View {
    @State private var queue: [SentenceChoiceExercise]
    private let totalCount: Int
    let audioPlayer: AudioPlayer
    let onComplete: () -> Void
    let onExit: ([String]) -> Void

    @State private var didFinishOrExit = false

    init(exercises: [SentenceChoiceExercise], resumingIds: [String]? = nil, audioPlayer: AudioPlayer, onComplete: @escaping () -> Void, onExit: @escaping ([String]) -> Void) {
        self.totalCount = exercises.count
        if let resumingIds {
            let byId = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
            _queue = State(initialValue: resumingIds.compactMap { byId[$0] })
        } else {
            _queue = State(initialValue: exercises.shuffled())
        }
        self.audioPlayer = audioPlayer
        self.onComplete = onComplete
        self.onExit = onExit
    }

    private var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(totalCount - queue.count) / Double(totalCount)
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button { exit() } label: { Image(systemName: "xmark") }
                ProgressView(value: progress)
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill").foregroundStyle(.red)
                    Text("\(HeartsManager.shared.hearts)")
                }
            }
            .padding(.horizontal)

            if let exercise = queue.first {
                SentenceChoiceExerciseView(exercise: exercise, audioPlayer: audioPlayer) { isCorrect in
                    handleAnswer(isCorrect)
                }
                .id(exercise.id)
                Spacer()
            }
        }
        .padding(.top)
        .onDisappear { exit() }
    }

    private func handleAnswer(_ isCorrect: Bool) {
        guard !queue.isEmpty else { return }
        queue.removeFirst()
        if !isCorrect {
            HeartsManager.shared.loseHeart()
        }
        if queue.isEmpty {
            finish()
        } else if HeartsManager.shared.hearts == 0 {
            exit()
        }
    }

    private func finish() {
        guard !didFinishOrExit else { return }
        didFinishOrExit = true
        onComplete()
    }
    private func exit() {
        guard !didFinishOrExit else { return }
        didFinishOrExit = true
        onExit(queue.map { $0.id })
    }
}
