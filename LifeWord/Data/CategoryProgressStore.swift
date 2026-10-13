import Foundation

/// Легкий, синхронний доступ до прогресу секцій категорії — потрібен
/// головному екрану, щоб показати "% пройдено" і перейти одразу в потрібну
/// вправу, без завантаження слів/речень цієї категорії.
///
/// Раніше `completedSections`/`completedLevel1Sections`/`completedLevel2Sections`
/// у CategoryPracticeViewModel/PhrasalCategoryPracticeViewModel жили тільки
/// в пам'яті й губились при виході з екрана вправ — цей файл додає їм
/// постійне збереження (ViewModel-и записують сюди при markCompleted і
/// читають при старті).
enum CategoryProgressStore {
    static let regularTotalSections =
        PracticeSectionType.allCases.count + LevelSectionType.level1Cases.count + LevelSectionType.level2Cases.count
    static let phrasalTotalSections = PhrasalSectionType.allCases.count

    private static func regularKey(_ categoryId: String) -> String { "completedSections.\(categoryId)" }
    private static func phrasalKey(_ categoryId: String) -> String { "completedSectionsPhrasal.\(categoryId)" }

    static func completedRegularKeys(_ categoryId: String) -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: regularKey(categoryId)) ?? [])
    }

    static func completedPhrasalKeys(_ categoryId: String) -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: phrasalKey(categoryId)) ?? [])
    }

    static func setCompletedRegularKeys(_ keys: Set<String>, for categoryId: String) {
        UserDefaults.standard.set(Array(keys), forKey: regularKey(categoryId))
    }

    static func setCompletedPhrasalKeys(_ keys: Set<String>, for categoryId: String) {
        UserDefaults.standard.set(Array(keys), forKey: phrasalKey(categoryId))
    }

    /// Частка завершених секцій (0...1) — для картки "Продовжити" на головному екрані.
    static func progressFraction(categoryId: String, isPhrasal: Bool) -> Double {
        if isPhrasal {
            guard phrasalTotalSections > 0 else { return 0 }
            return Double(completedPhrasalKeys(categoryId).count) / Double(phrasalTotalSections)
        } else {
            guard regularTotalSections > 0 else { return 0 }
            return Double(completedRegularKeys(categoryId).count) / Double(regularTotalSections)
        }
    }

    /// Перша незавершена секція — куди вести користувача по натиску "Продовжити".
    /// nil, якщо категорія повністю пройдена (тоді просто відкриється список секцій).
    static func resumeRegularSection(categoryId: String) -> FlatSection? {
        let done = completedRegularKeys(categoryId)
        return FlatSection.all.first { !done.contains($0.progressKey) }
    }

    static func resumePhrasalSection(categoryId: String) -> PhrasalSectionType? {
        let done = completedPhrasalKeys(categoryId)
        return PhrasalSectionType.allCases.first { !done.contains($0.rawValue) }
    }
}
