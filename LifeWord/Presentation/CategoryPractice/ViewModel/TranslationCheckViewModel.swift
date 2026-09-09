import Observation

@Observable
final class TranslationCheckViewModel {
    private var queue: [Word]
    private let allWords: [Word]
    private let totalCount: Int
    let direction: TranslationDirection

    var isFinished = false
    var currentOptions: [Word] = []

    init(words: [Word], direction: TranslationDirection, resumingIds: [String]? = nil) {
        self.allWords = words
        self.direction = direction
        if let resumingIds {
            let byId = Dictionary(uniqueKeysWithValues: words.map { ($0.id, $0) })
            self.queue = resumingIds.compactMap { byId[$0] }
        } else {
            self.queue = words.shuffled()
        }
        self.totalCount = words.count
        updateOptions()
    }

    var currentWord: Word? { queue.first }
    var remainingIds: [String] { queue.map { $0.id } }

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(totalCount - queue.count) / Double(totalCount)
    }

    private func updateOptions() {
        guard let word = currentWord else { currentOptions = []; return }
        let distractors = allWords.filter { $0.id != word.id }.shuffled().prefix(3)
        currentOptions = (Array(distractors) + [word]).shuffled()
    }

    func answer(isCorrect: Bool) {
        guard !queue.isEmpty else { return }
        let word = queue.removeFirst()
        if isCorrect {
            if queue.isEmpty { isFinished = true }
        } else {
            HeartsManager.shared.loseHeart()
            queue.append(word)
        }
        updateOptions()
    }
}
