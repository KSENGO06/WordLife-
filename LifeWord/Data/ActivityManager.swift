import Foundation
import Observation

/// Стрік, загальна статистика та "де користувач зупинився" — окремий
/// трекер активності. CategoryPracticeViewModel/PhrasalCategoryPracticeViewModel
/// не зберігають прогрес завершення постійно (лише незакінчені спроби),
/// тож головний екран не може покладатись на них напряму.
///
/// Додатково веде денну ціль (скільки вправ сьогодні з `dailyGoal`) і
/// короткий журнал активних днів (`activeDays`, останні 14) — для кільця
/// прогресу й тижневої стрічки стріку на головній.
@Observable
final class ActivityManager {
    static let shared = ActivityManager()

    private let defaults = UserDefaults.standard

    private enum Key {
        static let sectionsCompletedTotal = "activity.sectionsCompletedTotal"
        static let lastCategoryId = "activity.lastCategoryId"
        static let lastCategoryName = "activity.lastCategoryName"
        static let lastCategoryIsPhrasal = "activity.lastCategoryIsPhrasal"
        static let streakCount = "activity.streakCount"
        static let lastActivityDay = "activity.lastActivityDay"
        static let wordOfDayDate = "activity.wordOfDayDate"
        static let wordOfDayWordId = "activity.wordOfDayWordId"
        static let sectionsCompletedToday = "activity.sectionsCompletedToday"
        static let sectionsCompletedTodayDay = "activity.sectionsCompletedTodayDay"
        static let activeDays = "activity.activeDays"
        static let lastStreakScreenShownDay = "activity.lastStreakScreenShownDay"
        static let recentCategories = "activity.recentCategories"
    }

    /// Один запис у короткому журналі останніх відкритих категорій — для
    /// "Останні теми" на екрані профілю. Статус завершення НЕ зберігається
    /// тут (був би застарілим) — читається наживо з CategoryProgressStore
    /// в момент показу.
    struct RecentCategoryEntry: Codable, Identifiable, Equatable {
        let id: String
        let name: String
        let isPhrasal: Bool
    }

    /// Скільки вправ треба сьогодні, щоб "закрити" денну ціль на головній.
    let dailyGoal = 5

    private(set) var sectionsCompletedTotal: Int
    private(set) var streakCount: Int
    private(set) var lastCategoryId: String?
    private(set) var lastCategoryName: String?
    private(set) var lastCategoryIsPhrasal: Bool
    private(set) var sectionsCompletedToday: Int
    private(set) var activeDays: Set<String>
    /// Останні відкриті категорії, найновіша перша — максимум 5.
    private(set) var recentCategories: [RecentCategoryEntry]

    private init() {
        sectionsCompletedTotal = defaults.integer(forKey: Key.sectionsCompletedTotal)
        streakCount = defaults.integer(forKey: Key.streakCount)
        lastCategoryId = defaults.string(forKey: Key.lastCategoryId)
        lastCategoryName = defaults.string(forKey: Key.lastCategoryName)
        lastCategoryIsPhrasal = defaults.bool(forKey: Key.lastCategoryIsPhrasal)
        activeDays = Set(defaults.stringArray(forKey: Key.activeDays) ?? [])
        if let data = defaults.data(forKey: Key.recentCategories),
           let decoded = try? JSONDecoder().decode([RecentCategoryEntry].self, from: data) {
            recentCategories = decoded
        } else {
            recentCategories = []
        }

        let today = Self.dayFormatter.string(from: Date())
        if defaults.string(forKey: Key.sectionsCompletedTodayDay) == today {
            sectionsCompletedToday = defaults.integer(forKey: Key.sectionsCompletedToday)
        } else {
            sectionsCompletedToday = 0
        }
    }

    /// Викликати, коли користувач завершує будь-яку вправу/секцію.
    func recordSectionCompleted(categoryId: String) {
        sectionsCompletedTotal += 1
        defaults.set(sectionsCompletedTotal, forKey: Key.sectionsCompletedTotal)

        let today = todayKey()
        if defaults.string(forKey: Key.sectionsCompletedTodayDay) != today {
            sectionsCompletedToday = 0
        }
        sectionsCompletedToday += 1
        defaults.set(sectionsCompletedToday, forKey: Key.sectionsCompletedToday)
        defaults.set(today, forKey: Key.sectionsCompletedTodayDay)

        bumpStreakIfNeeded()
        NotificationManager.cancelTodayStreakReminder()
    }

    /// Чи закрита денна ціль — визначає, чи святкує талісман на головній.
    var isDailyGoalMet: Bool { sectionsCompletedToday >= dailyGoal }

    /// Чи варто показати повноекранний "N днів поспіль" на Home сьогодні —
    /// раз на день, і лише якщо стрік уже є (день 0 — ще нема чого святкувати).
    var shouldShowStreakCelebration: Bool {
        guard streakCount > 0 else { return false }
        return defaults.string(forKey: Key.lastStreakScreenShownDay) != todayKey()
    }

    /// Викликати одразу, коли вирішили показати екран стріку — щоб він не
    /// з'явився вдруге того самого дня (навіть якщо показ перервався).
    func markStreakScreenShown() {
        defaults.set(todayKey(), forKey: Key.lastStreakScreenShownDay)
    }

    /// Останні 7 днів (сьогодні останній), з позначкою, чи був того дня
    /// активний — для тижневої стрічки стріку на головній.
    func lastSevenDays() -> [(date: Date, isActive: Bool)] {
        let calendar = Calendar.current
        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            let key = Self.dayFormatter.string(from: date)
            return (date, activeDays.contains(key))
        }
    }

    /// Викликати при відкритті категорії — щоб запам'ятати "де зупинились"
    /// для картки "Продовжити" на головній.
    func recordCategoryOpened(id: String, name: String, isPhrasal: Bool) {
        lastCategoryId = id
        lastCategoryName = name
        lastCategoryIsPhrasal = isPhrasal
        defaults.set(id, forKey: Key.lastCategoryId)
        defaults.set(name, forKey: Key.lastCategoryName)
        defaults.set(isPhrasal, forKey: Key.lastCategoryIsPhrasal)
        bumpStreakIfNeeded()
        pushRecentCategory(id: id, name: name, isPhrasal: isPhrasal)
    }

    /// Додає/переносить категорію на початок журналу "Останні теми" і
    /// лишає тільки 5 найновіших.
    private func pushRecentCategory(id: String, name: String, isPhrasal: Bool) {
        var updated = recentCategories.filter { $0.id != id }
        updated.insert(RecentCategoryEntry(id: id, name: name, isPhrasal: isPhrasal), at: 0)
        recentCategories = Array(updated.prefix(5))
        if let data = try? JSONEncoder().encode(recentCategories) {
            defaults.set(data, forKey: Key.recentCategories)
        }
    }

    /// Стабільне "слово дня" — одне й те саме слово протягом усього дня,
    /// обране за детермінованим (не hashValue, він рандомізований щозапуску)
    /// числом з дати.
    func wordOfDay(from words: [Word]) -> Word? {
        guard !words.isEmpty else { return nil }
        let today = todayKey()
        if defaults.string(forKey: Key.wordOfDayDate) == today,
           let savedId = defaults.string(forKey: Key.wordOfDayWordId),
           let saved = words.first(where: { $0.id == savedId }) {
            return saved
        }
        let dayNumber = Int(today.replacingOccurrences(of: "-", with: "")) ?? 0
        let index = dayNumber % words.count
        let word = words[index]
        defaults.set(today, forKey: Key.wordOfDayDate)
        defaults.set(word.id, forKey: Key.wordOfDayWordId)
        return word
    }

    private func bumpStreakIfNeeded() {
        let today = todayKey()
        recordActiveDay(today)

        guard let lastDay = defaults.string(forKey: Key.lastActivityDay) else {
            streakCount = 1
            defaults.set(streakCount, forKey: Key.streakCount)
            defaults.set(today, forKey: Key.lastActivityDay)
            return
        }
        guard lastDay != today else { return }

        let calendar = Calendar.current
        if let lastDate = Self.dayFormatter.date(from: lastDay),
           let todayDate = Self.dayFormatter.date(from: today),
           calendar.dateComponents([.day], from: lastDate, to: todayDate).day == 1 {
            streakCount += 1
        } else {
            streakCount = 1
        }
        defaults.set(streakCount, forKey: Key.streakCount)
        defaults.set(today, forKey: Key.lastActivityDay)
    }

    private func todayKey() -> String { Self.dayFormatter.string(from: Date()) }

    /// Додає день до журналу активних днів і лишає тільки останні 14 —
    /// для тижневої стрічки нам треба лише 7, запас на всяк випадок.
    private func recordActiveDay(_ day: String) {
        guard !activeDays.contains(day) else { return }
        activeDays.insert(day)
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -13, to: Date()) ?? Date()
        activeDays = activeDays.filter { key in
            guard let date = Self.dayFormatter.date(from: key) else { return false }
            return date >= cutoff
        }
        defaults.set(Array(activeDays), forKey: Key.activeDays)
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter
    }()

    #if DEBUG
    func debugReset() {
        sectionsCompletedTotal = 0
        streakCount = 0
        lastCategoryId = nil
        lastCategoryName = nil
        lastCategoryIsPhrasal = false
        sectionsCompletedToday = 0
        activeDays = []
        recentCategories = []
        defaults.removeObject(forKey: Key.recentCategories)
        defaults.removeObject(forKey: Key.sectionsCompletedTotal)
        defaults.removeObject(forKey: Key.streakCount)
        defaults.removeObject(forKey: Key.lastCategoryId)
        defaults.removeObject(forKey: Key.lastCategoryName)
        defaults.removeObject(forKey: Key.lastCategoryIsPhrasal)
        defaults.removeObject(forKey: Key.lastActivityDay)
        defaults.removeObject(forKey: Key.wordOfDayDate)
        defaults.removeObject(forKey: Key.wordOfDayWordId)
        defaults.removeObject(forKey: Key.sectionsCompletedToday)
        defaults.removeObject(forKey: Key.sectionsCompletedTodayDay)
        defaults.removeObject(forKey: Key.activeDays)
        defaults.removeObject(forKey: Key.lastStreakScreenShownDay)
    }
    #endif
}
