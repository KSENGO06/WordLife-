import Foundation

/// Керує лічильником підказок для кожної категорії окремо.
/// Ліміт: 10 підказок на категорію. Коли підказки витрачено, вони
/// поступово поповнюються з часом — так само, як серця (1 підказка на
/// 45 хв від моменту, коли категорія почала їх витрачати) — крім
/// підписки: з isPremium підказки безкінечні й лічильник не витрачається.
final class HintsManager {
    static let shared = HintsManager()

    static let hintsPerCategory = 10
    static let regenInterval: TimeInterval = 30 * 60 // 30 хв на 1 підказку

    private let usedKeyPrefix = "hintsUsed_"
    private let lastUseKeyPrefix = "hintsLastUseAt_"

    private init() {}

    private func usedKey(for categoryId: String) -> String { usedKeyPrefix + categoryId }
    private func lastUseKey(for categoryId: String) -> String { lastUseKeyPrefix + categoryId }

    /// true, поки діє підписка — підказки тоді безкінечні.
    var isUnlimited: Bool { PremiumManager.shared.isPremium }

    private func rawUsed(for categoryId: String) -> Int {
        UserDefaults.standard.integer(forKey: usedKey(for: categoryId))
    }

    private func lastUseDate(for categoryId: String) -> Date? {
        UserDefaults.standard.object(forKey: lastUseKey(for: categoryId)) as? Date
    }

    /// Поповнює підказки цієї категорії на основі часу, що минув відтоді,
    /// як їх почали витрачати — та сама логіка, що й у HeartsManager.
    private func regenerateIfNeeded(for categoryId: String) {
        let used = rawUsed(for: categoryId)
        guard used > 0, let lastUse = lastUseDate(for: categoryId) else { return }
        let elapsed = Date().timeIntervalSince(lastUse)
        let regenerated = Int(elapsed / Self.regenInterval)
        guard regenerated > 0 else { return }
        let newUsed = max(0, used - regenerated)
        UserDefaults.standard.set(newUsed, forKey: usedKey(for: categoryId))
        if newUsed == 0 {
            UserDefaults.standard.removeObject(forKey: lastUseKey(for: categoryId))
        } else {
            let newLastUse = lastUse.addingTimeInterval(Double(regenerated) * Self.regenInterval)
            UserDefaults.standard.set(newLastUse, forKey: lastUseKey(for: categoryId))
        }
    }

    /// Скільки підказок лишилось у цій категорії.
    func remainingHints(for categoryId: String) -> Int {
        regenerateIfNeeded(for: categoryId)
        return max(0, Self.hintsPerCategory - rawUsed(for: categoryId))
    }

    /// Чи можна ще скористатись підказкою в цій категорії.
    func canUseHint(for categoryId: String) -> Bool {
        isUnlimited || remainingHints(for: categoryId) > 0
    }

    /// Використати підказку. Повертає true, якщо вдалось (був залишок або
    /// діє підписка), false — якщо ліміт вже вичерпано і підписки немає.
    @discardableResult
    func useHint(for categoryId: String) -> Bool {
        guard canUseHint(for: categoryId) else { return false }
        guard !isUnlimited else { return true }
        regenerateIfNeeded(for: categoryId)
        let used = rawUsed(for: categoryId)
        if used == 0 {
            UserDefaults.standard.set(Date(), forKey: lastUseKey(for: categoryId))
        }
        UserDefaults.standard.set(used + 1, forKey: usedKey(for: categoryId))
        return true
    }

    /// Час до наступної підказки в цій категорії, якщо їх зараз вичерпано;
    /// nil, якщо є вільні підказки (нема чого чекати).
    func timeUntilNextHint(for categoryId: String) -> TimeInterval? {
        regenerateIfNeeded(for: categoryId)
        guard rawUsed(for: categoryId) > 0, let lastUse = lastUseDate(for: categoryId) else { return nil }
        let elapsed = Date().timeIntervalSince(lastUse)
        return Self.regenInterval - elapsed.truncatingRemainder(dividingBy: Self.regenInterval)
    }

    #if DEBUG
    func debugResetHints(for categoryId: String) {
        UserDefaults.standard.removeObject(forKey: usedKey(for: categoryId))
        UserDefaults.standard.removeObject(forKey: lastUseKey(for: categoryId))
    }
    #endif
}
