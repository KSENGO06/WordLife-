import Foundation
import Observation

/// Прапорець "є підписка" — розблоковує безкінечні серця й підказки.
///
/// Поки що без реального StoreKit: продукт підписки в App Store Connect ще
/// не налаштований, тож `purchase()` просто вмикає прапорець локально й
/// назавжди (для тестування паволу та решти UI). Коли з'явиться product ID,
/// підміняємо тіло `purchase()` на справжній StoreKit 2 запит — решта коду
/// (HeartsManager, HintsManager, усі екрани) читає тільки `isPremium` і
/// зміниться.
@Observable
final class PremiumManager {
    static let shared = PremiumManager()

    private let key = "premium.isSubscribed"

    private(set) var isPremium: Bool

    private init() {
        isPremium = UserDefaults.standard.bool(forKey: key)
    }

    /// TODO: замінити на реальну StoreKit-покупку, коли буде product ID з App Store Connect.
    func purchase() {
        isPremium = true
        UserDefaults.standard.set(true, forKey: key)
    }

    #if DEBUG
    func debugReset() {
        isPremium = false
        UserDefaults.standard.set(false, forKey: key)
    }
    #endif
}
