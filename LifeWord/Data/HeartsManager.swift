import Foundation
import Observation

@Observable
final class HeartsManager {
    static let shared = HeartsManager()

    static let maxHearts = 5
    static let regenInterval: TimeInterval = 30 * 60 // 30 хв на 1 серце

    private(set) var heartsLost: Int
    private var lastLossAt: Date?

    private let heartsKey = "hearts.lost"
    private let lastLossKey = "hearts.lastLossAt"

    var hearts: Int { Self.maxHearts - heartsLost }

    private init() {
        heartsLost = UserDefaults.standard.integer(forKey: heartsKey)
        lastLossAt = UserDefaults.standard.object(forKey: lastLossKey) as? Date
        regenerateIfNeeded()
    }

    func loseHeart() {
        regenerateIfNeeded()
        guard heartsLost < Self.maxHearts else { return }
        if heartsLost == 0 { lastLossAt = Date() }
        heartsLost += 1
        persist()
    }

    /// Викликати періодично (напр. раз на секунду), щоб UI підхопив відновлення в реальному часі.
    func refresh() { regenerateIfNeeded() }

    var timeUntilNextHeart: TimeInterval? {
        guard heartsLost > 0, let lastLossAt else { return nil }
        let elapsed = Date().timeIntervalSince(lastLossAt)
        return Self.regenInterval - elapsed.truncatingRemainder(dividingBy: Self.regenInterval)
    }

    private func regenerateIfNeeded() {
        guard heartsLost > 0, let lastLossAt else { return }
        let elapsed = Date().timeIntervalSince(lastLossAt)
        let regenerated = Int(elapsed / Self.regenInterval)
        guard regenerated > 0 else { return }
        let newHeartsLost = max(0, heartsLost - regenerated)
        self.lastLossAt = newHeartsLost == 0 ? nil : lastLossAt.addingTimeInterval(Double(regenerated) * Self.regenInterval)
        self.heartsLost = newHeartsLost
        persist()
    }

    private func persist() {
        UserDefaults.standard.set(heartsLost, forKey: heartsKey)
        UserDefaults.standard.set(lastLossAt, forKey: lastLossKey)
    }
#if DEBUG
func debugResetHearts() {
    heartsLost = 0
    lastLossAt = nil
}
#endif
}
