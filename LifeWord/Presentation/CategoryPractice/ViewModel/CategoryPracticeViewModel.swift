import Observation
import Foundation

@Observable
final class CategoryPracticeViewModel {
    private let getWordsUseCase: GetWordsUseCase
    private let getSentencesUseCase: GetSentenceExercisesUseCase
    private let getSentenceChoicesUseCase: GetSentenceChoiceExercisesUseCase
    let categoryId: String

    var words: [Word] = []
    var sentencesLevel1: [SentenceExercise] = []
    var sentencesLevel2: [SentenceExercise] = []
    var sentenceChoices: [SentenceChoiceExercise] = []
    var isLoading = false
    var completedSections: Set<PracticeSectionType> = []
    var completedLevel1Sections: Set<LevelSectionType> = []
    var completedLevel2Sections: Set<LevelSectionType> = []

    private(set) var sectionProgress: [String: [String]] = [:]
    private var progressDefaultsKey: String { "progress.\(categoryId)" }

    var categoryIconName: String { "\(categoryId)_scene" }

    /// Загальний прогрес по категорії (для шапки екрана) — скільки з усіх вправ пройдено.
    var totalSectionsCount: Int {
        PracticeSectionType.allCases.count + LevelSectionType.level1Cases.count + LevelSectionType.level2Cases.count
    }
    var completedSectionsCount: Int {
        completedSections.count + completedLevel1Sections.count + completedLevel2Sections.count
    }

    init(categoryId: String, getWordsUseCase: GetWordsUseCase, getSentencesUseCase: GetSentenceExercisesUseCase, getSentenceChoicesUseCase: GetSentenceChoiceExercisesUseCase) {
        self.categoryId = categoryId
        self.getWordsUseCase = getWordsUseCase
        self.getSentencesUseCase = getSentencesUseCase
        self.getSentenceChoicesUseCase = getSentenceChoicesUseCase
        loadProgress()
        loadCompleted()
    }

    @MainActor
    func load() async {
        isLoading = true
        words = (try? await getWordsUseCase.execute(categoryId: categoryId)) ?? []
        let wordIds = words.map { $0.id }
        sentencesLevel1 = (try? await getSentencesUseCase.execute(wordIds: wordIds, level: 1)) ?? []
        sentencesLevel2 = (try? await getSentencesUseCase.execute(wordIds: wordIds, level: 2)) ?? []
        sentenceChoices = (try? await getSentenceChoicesUseCase.execute(wordIds: wordIds)) ?? []
        isLoading = false
    }

    func markCompleted(_ section: PracticeSectionType) {
        completedSections.insert(section)
        ActivityManager.shared.recordSectionCompleted(categoryId: categoryId)
        persistCompleted()
    }

    func markCompleted(level: Int, _ section: LevelSectionType) {
        if level == 1 { completedLevel1Sections.insert(section) } else { completedLevel2Sections.insert(section) }
        ActivityManager.shared.recordSectionCompleted(categoryId: categoryId)
        persistCompleted()
    }

    func isCompleted(_ section: FlatSection) -> Bool {
        switch section {
        case .practice(let s): return completedSections.contains(s)
        case .level(let level, let s): return (level == 1 ? completedLevel1Sections : completedLevel2Sections).contains(s)
        }
    }

    private var allPracticeCompleted: Bool { completedSections.count == PracticeSectionType.allCases.count }
    private var allLevel1Completed: Bool { completedLevel1Sections.count == LevelSectionType.level1Cases.count }

    func isUnlocked(_ section: PracticeSectionType) -> Bool {
        #if DEBUG
        return true
        #else
        switch section {
        case .checkNative: return true
        case .checkTarget: return completedSections.contains(.checkNative)
        case .matching: return completedSections.contains(.checkTarget)
        }
        #endif
    }

    func isUnlocked(level: Int, _ section: LevelSectionType) -> Bool {
        #if DEBUG
        return true
        #else
        if level == 1 {
            switch section {
            case .puzzleTarget: return allPracticeCompleted
            case .puzzleNative: return completedLevel1Sections.contains(.puzzleTarget)
            case .listening: return completedLevel1Sections.contains(.puzzleNative)
            case .fillBlank: return completedLevel1Sections.contains(.listening)
            case .sentenceChoice: return false
            }
        } else {
            switch section {
            case .puzzleTarget: return allLevel1Completed
            case .puzzleNative: return completedLevel2Sections.contains(.puzzleTarget)
            case .listening: return completedLevel2Sections.contains(.puzzleNative)
            case .fillBlank: return false
            case .sentenceChoice: return completedLevel2Sections.contains(.listening)
            }
        }
        #endif
    }

    func isUnlocked(_ section: FlatSection) -> Bool {
        switch section {
        case .practice(let s): return isUnlocked(s)
        case .level(let level, let s): return isUnlocked(level: level, s)
        }
    }

    /// Наступна розблокована секція після поточної — для авто-переходу
    func nextUnlockedSection(after current: FlatSection) -> FlatSection? {
        let all = FlatSection.all
        guard let index = all.firstIndex(of: current) else { return nil }
        for candidate in all[(index + 1)...] where isUnlocked(candidate) {
            return candidate
        }
        return nil
    }

    // MARK: - Прогрес (для відновлення "з того самого місця" і відсотка на рядку)

    func remainingIds(for section: FlatSection) -> [String]? {
        sectionProgress[section.progressKey]
    }

    func saveProgress(_ ids: [String], for section: FlatSection) {
        sectionProgress[section.progressKey] = ids
        persistProgress()
    }

    func clearProgress(for section: FlatSection) {
        sectionProgress.removeValue(forKey: section.progressKey)
        persistProgress()
    }

    func totalCount(for section: FlatSection) -> Int {
        switch section {
        case .practice: return words.count
        case .level(1, .sentenceChoice): return 0
        case .level(_, .sentenceChoice): return sentenceChoices.count
        case .level(1, _): return sentencesLevel1.count
        case .level(_, _): return sentencesLevel2.count
        }
    }

    func progressFraction(for section: FlatSection) -> Double? {
        guard let remaining = sectionProgress[section.progressKey] else { return nil }
        let total = totalCount(for: section)
        guard total > 0 else { return nil }
        return Double(total - remaining.count) / Double(total)
    }

    private func loadProgress() {
        if let data = UserDefaults.standard.data(forKey: progressDefaultsKey),
           let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) {
            sectionProgress = decoded
        }
    }

    private func persistProgress() {
        if let data = try? JSONEncoder().encode(sectionProgress) {
            UserDefaults.standard.set(data, forKey: progressDefaultsKey)
        }
    }

    // MARK: - Завершені секції (постійне збереження для % на головному екрані)

    private func loadCompleted() {
        for key in CategoryProgressStore.completedRegularKeys(categoryId) {
            let parts = key.components(separatedBy: ".")
            guard parts.count == 2 else { continue }
            let (group, raw) = (parts[0], parts[1])
            switch group {
            case "practice":
                if let s = PracticeSectionType(rawValue: raw) { completedSections.insert(s) }
            case "level1":
                if let s = LevelSectionType(rawValue: raw) { completedLevel1Sections.insert(s) }
            case "level2":
                if let s = LevelSectionType(rawValue: raw) { completedLevel2Sections.insert(s) }
            default:
                break
            }
        }
    }

    private func persistCompleted() {
        let keys = completedSections.map { FlatSection.practice($0).progressKey }
            + completedLevel1Sections.map { FlatSection.level(1, $0).progressKey }
            + completedLevel2Sections.map { FlatSection.level(2, $0).progressKey }
        CategoryProgressStore.setCompletedRegularKeys(Set(keys), for: categoryId)
    }
}
