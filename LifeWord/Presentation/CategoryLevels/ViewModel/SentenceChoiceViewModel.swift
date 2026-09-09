import Observation

@Observable
final class SentenceChoiceViewModel {
    private var queue: [SentenceChoiceExercise]
    private let all: [SentenceChoiceExercise]

    var isFinished = false

    init(exercises: [SentenceChoiceExercise], resumingIds: [String]? = nil) {
        self.all = exercises
        if let resumingIds {
            let byId = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
            self.queue = resumingIds.compactMap { byId[$0] }
        } else {
            self.queue = exercises.shuffled()
        }
    }

    var currentExercise: SentenceChoiceExercise? { queue.first }
    var remainingIds: [String] { queue.map { $0.id } }

    var progress: Double {
        guard !all.isEmpty else { return 0 }
        return Double(all.count - queue.count) / Double(all.count)
    }

    func answer(isCorrect: Bool) {
        guard !queue.isEmpty else { return }
        let exercise = queue.removeFirst()
        if isCorrect {
            if queue.isEmpty { isFinished = true }
        } else {
            HeartsManager.shared.loseHeart()
            queue.append(exercise)
        }
    }
}
