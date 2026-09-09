import Observation
@Observable
final class LevelViewModel {
    private var queue: [SentenceExercise]
    private let all: [SentenceExercise]
    let sectionType: LevelSectionType

    var isFinished = false

    init(sentences: [SentenceExercise], sectionType: LevelSectionType, resumingIds: [String]? = nil) {
        self.all = sentences
        if let resumingIds {
            let byId = Dictionary(uniqueKeysWithValues: sentences.map { ($0.id, $0) })
            self.queue = resumingIds.compactMap { byId[$0] }
        } else {
            self.queue = sentences.shuffled()
        }
        self.sectionType = sectionType
    }

    var currentExercise: SentenceExercise? { queue.first }
    var remainingIds: [String] { queue.map { $0.id } }

    var progress: Double {
        guard !all.isEmpty else { return 0 }
        return Double(all.count - queue.count) / Double(all.count)
    }

    func answer(isCorrect: Bool) {
        guard !queue.isEmpty else { return }
        let exercise = queue.removeFirst()
        if isCorrect {
            if queue.isEmpty {
                isFinished = true
                print("🔵 LevelViewModel: isFinished = true")
            }
        } else {
            HeartsManager.shared.loseHeart()
            queue.append(exercise)
        }
    }
}
