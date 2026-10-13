import Foundation
import Observation

@Observable
final class PhrasalCategoryPracticeViewModel {
    let categoryId: String
    var words: [Word]
    var translationExercises: [TranslationExercise]
    var clozeExercise: ClozeExercise?

    var completedSections: Set<PhrasalSectionType> = []
    private(set) var sectionProgress: [String: [String]] = [:]
    private var progressDefaultsKey: String { "phrasalProgress.\(categoryId)" }

    var categoryIconName: String { "\(categoryId)_scene" }

    init(categoryId: String, words: [Word], translationExercises: [TranslationExercise], clozeExercise: ClozeExercise?) {
        self.categoryId = categoryId
        self.words = words
        self.translationExercises = translationExercises
        self.clozeExercise = clozeExercise
        loadProgress()
        completedSections = Set(CategoryProgressStore.completedPhrasalKeys(categoryId).compactMap { PhrasalSectionType(rawValue: $0) })
    }

    func markCompleted(_ section: PhrasalSectionType) {
        completedSections.insert(section)
        ActivityManager.shared.recordSectionCompleted(categoryId: categoryId)
        CategoryProgressStore.setCompletedPhrasalKeys(Set(completedSections.map { $0.rawValue }), for: categoryId)
    }

    func isCompleted(_ section: PhrasalSectionType) -> Bool {
        completedSections.contains(section)
    }

    /// Послідовне розблокування: переклад-рідною → переклад-англійською → мечинг
    /// → зібрати речення → текст із пропусками. У DEBUG усе відкрито одразу.
    func isUnlocked(_ section: PhrasalSectionType) -> Bool {
        #if DEBUG
        return true
        #else
        switch section {
        case .checkNative: return true
        case .checkTarget: return completedSections.contains(.checkNative)
        case .matching: return completedSections.contains(.checkTarget)
        case .translateBuild: return completedSections.contains(.matching)
        case .clozeText: return completedSections.contains(.translateBuild)
        }
        #endif
    }

    func remainingIds(for section: PhrasalSectionType) -> [String]? {
        sectionProgress[section.rawValue]
    }

    func saveProgress(_ ids: [String], for section: PhrasalSectionType) {
        sectionProgress[section.rawValue] = ids
        persistProgress()
    }

    func clearProgress(for section: PhrasalSectionType) {
        sectionProgress.removeValue(forKey: section.rawValue)
        persistProgress()
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
}
