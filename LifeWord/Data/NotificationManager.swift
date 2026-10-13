import Foundation
import UserNotifications

/// Локальні сповіщення — плануються наперед через `UNUserNotificationCenter`
/// і виконуються самою системою, навіть якщо застосунок закритий. Жодного
/// серверу не треба.
///
/// Три випадки:
/// 1. "Серця відновились" — одноразове сповіщення через `timeUntilNextHeart`
///    секунд від моменту, коли показано `LimitReachedSheetView(kind: .hearts)`.
/// 2. "Підказки відновились" — те саме, для підказок конкретної категорії.
/// 3. "Не втрачай стрік" — наперед плануємо на вечір (20:00) на кілька днів
///    вперед; якщо користувач встигає позайматись сьогодні,
///    `cancelTodayStreakReminder()` знімає заплановане на сьогодні.
enum NotificationManager {

    private static let center = UNUserNotificationCenter.current()

    private enum Identifier {
        static let heartsRestored = "hearts-restored"
        static let hintsRestoredPrefix = "hints-restored-"
        static let streakReminderPrefix = "streak-reminder-"
    }

    /// Година, коли має прийти нагадування про стрік, якщо за день ще не
    /// позайматись.
    private static let streakReminderHour = 20

    /// На скільки днів вперед тримаємо заплановані нагадування про стрік —
    /// локальні сповіщення не можна додати "з сервера", тож тримаємо
    /// невеликий запас наперед і освіжаємо його при кожному запуску.
    private static let streakLookaheadDays = 5

    // MARK: - Дозвіл

    /// За замовчуванням iOS НЕ показує банер сповіщення, якщо застосунок
    /// в цей момент відкритий (на екрані) — для тестування в симуляторі
    /// це треба увімкнути явно через делегата. Викликати один раз, напр.
    /// в `init()` `LifeWordApp`.
    static func configureForegroundPresentation() {
        center.delegate = ForegroundPresenter.shared
    }

    /// Питає дозвіл лише якщо користувач ще не відповідав — повторний
    /// виклик при вже прийнятому/відхиленому рішенні нічого не питає.
    static func requestAuthorizationIfNeeded() {
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }

    #if DEBUG
    /// Лише для перевірки дизайну під час розробки — надсилає всі три
    /// типи сповіщень через кілька секунд, щоб відразу побачити, як вони
    /// виглядають, не чекаючи реального таймера чи 20:00. Викликати з
    /// кнопки в UI, доступної тільки в DEBUG-збірці.
    static func sendTestNotifications() {
        scheduleHeartsRestored(after: 3)

        let hintsContent = UNMutableNotificationContent()
        hintsContent.title = "Підказки знову доступні! 💡"
        hintsContent.body = "У цій категорії знову можна користуватись підказками."
        hintsContent.sound = .default
        schedule(identifier: "test-hints-restored", content: hintsContent, after: 6)

        let streakContent = UNMutableNotificationContent()
        streakContent.title = "Не втрачай серію 🔥"
        streakContent.body = "Ще трохи часу, щоб позайматись сьогодні і не перервати серію днів поспіль."
        streakContent.sound = .default
        schedule(identifier: "test-streak-reminder", content: streakContent, after: 9)
    }
    #endif

    // MARK: - Серця / підказки

    /// Планує сповіщення "серця відновились" рівно через `interval` секунд.
    /// Фіксований ідентифікатор — повторний виклик замінює старе
    /// сповіщення, а не дублює його.
    static func scheduleHeartsRestored(after interval: TimeInterval) {
        guard interval > 0 else { return }
        let content = UNMutableNotificationContent()
        content.title = "Серця відновились! ❤️"
        content.body = "Можеш повертатись і вивчати нові слова."
        content.sound = .default
        schedule(identifier: Identifier.heartsRestored, content: content, after: interval)
    }

    /// Планує сповіщення "підказки відновились" для конкретної категорії.
    static func scheduleHintsRestored(after interval: TimeInterval, categoryId: String) {
        guard interval > 0 else { return }
        let content = UNMutableNotificationContent()
        content.title = "Підказки знову доступні! 💡"
        content.body = "У цій категорії знову можна користуватись підказками."
        content.sound = .default
        schedule(identifier: Identifier.hintsRestoredPrefix + categoryId, content: content, after: interval)
    }

    private static func schedule(identifier: String, content: UNMutableNotificationContent, after interval: TimeInterval) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, interval), repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Стрік

    /// Освіжає нагадування про стрік на найближчі дні — викликати при
    /// кожному запуску застосунку. Якщо день вже є в `activeDays`
    /// (користувач уже позайматись того дня), нагадування на нього не
    /// ставиться.
    static func refreshStreakReminders(activeDays: Set<String>) {
        let calendar = Calendar.current
        let now = Date()

        var identifiersToCancel: [String] = []
        var requests: [UNNotificationRequest] = []

        for offset in 0..<streakLookaheadDays {
            guard let day = calendar.date(byAdding: .day, value: offset, to: now) else { continue }
            let dayKey = Self.dayFormatter.string(from: day)
            let identifier = Identifier.streakReminderPrefix + dayKey
            identifiersToCancel.append(identifier)

            if activeDays.contains(dayKey) { continue }

            var fireComponents = calendar.dateComponents([.year, .month, .day], from: day)
            fireComponents.hour = streakReminderHour
            fireComponents.minute = 0
            guard let fireDate = calendar.date(from: fireComponents), fireDate > now else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Не втрачай серію 🔥"
            content.body = "Ще трохи часу, щоб позайматись сьогодні і не перервати серію днів поспіль."
            content.sound = .default

            let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            requests.append(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
        }

        center.removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
        requests.forEach { center.add($0) }
    }

    /// Знімає сьогоднішнє нагадування про стрік — викликати щоразу, коли
    /// користувач завершує вправу (сьогоднішній стрік уже не під загрозою).
    static func cancelTodayStreakReminder() {
        let today = Self.dayFormatter.string(from: Date())
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.streakReminderPrefix + today])
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter
    }()
}

/// Дозволяє банеру/звуку показуватись, навіть якщо застосунок відкритий
/// саме зараз — інакше під час тестування в симуляторі сповіщення
/// мовчки "приходить", але нічого не показує на екрані.
private final class ForegroundPresenter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = ForegroundPresenter()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}
