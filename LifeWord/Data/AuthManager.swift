import Foundation
import Observation
import UIKit
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

/// Авторизований користувач — те, що читає решта застосунку.
struct AppUser: Equatable {
    let uid: String
    let email: String
    var displayName: String
}

enum AuthError: LocalizedError {
    case nameEmpty
    case emailEmpty
    case passwordTooShort
    case appleNotConfiguredYet
    case firebase(String)

    var errorDescription: String? {
        switch self {
        case .nameEmpty: return "Enter your name."
        case .emailEmpty: return "Enter your email."
        case .passwordTooShort: return "Password must be at least 6 characters."
        case .appleNotConfiguredYet: return "Apple Sign-In isn't set up yet — coming in a future update."
        case .firebase(let message): return message
        }
    }
}

/// Реальна автентифікація через Firebase Auth (email/пароль). Решта
/// застосунку читає лише `AuthManager.shared.currentUser` / `isSignedIn`,
/// тож усі деталі Firebase залишаються тут, в одному файлі.
///
/// Вхід через Google (`signInWithGoogle`) — реалізований по-справжньому,
/// через GoogleSignIn SDK + Firebase-креденшл.
///
/// Вхід через Apple (`signInWithApple`) поки що НЕ реалізований по суті —
/// кнопка в інтерфейсі вже є, але Ксені спершу потрібен Apple Developer
/// акаунт і ввімкнена можливість "Sign In with Apple" в Xcode. Коли вони
/// з'являться — тут підключається ASAuthorizationAppleIDProvider і
/// Firebase OAuthProvider(providerID: "apple.com").
@Observable
final class AuthManager: NSObject {
    static let shared = AuthManager()

    private(set) var currentUser: AppUser?
    private var handle: AuthStateDidChangeListenerHandle?

    private override init() {
        super.init()
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            self?.currentUser = firebaseUser.map {
                AppUser(uid: $0.uid, email: $0.email ?? "", displayName: $0.displayName ?? "")
            }
        }
    }

    var isSignedIn: Bool { currentUser != nil }

    @MainActor
    func signUp(name: String, email: String, password: String) async throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw AuthError.nameEmpty }
        guard password.count >= 6 else { throw AuthError.passwordTooShort }

        do {
            let result = try await Auth.auth().createUser(withEmail: normalizedEmail, password: password)
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = trimmedName
            try await changeRequest.commitChanges()
            currentUser = AppUser(uid: result.user.uid, email: result.user.email ?? normalizedEmail, displayName: trimmedName)
        } catch {
            throw AuthError.firebase(Self.message(for: error))
        }
    }

    @MainActor
    func signIn(email: String, password: String) async throws {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let result = try await Auth.auth().signIn(withEmail: normalizedEmail, password: password)
            currentUser = AppUser(uid: result.user.uid, email: result.user.email ?? normalizedEmail, displayName: result.user.displayName ?? "")
        } catch {
            throw AuthError.firebase(Self.message(for: error))
        }
    }

    /// Реальне скидання пароля через Firebase: надсилає лист із посиланням
    /// на вказаний email. Викликається з посилання "Forgot password?" на
    /// екрані входу.
    @MainActor
    func sendPasswordReset(email: String) async throws {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedEmail.isEmpty else { throw AuthError.emailEmpty }
        do {
            try await Auth.auth().sendPasswordReset(withEmail: normalizedEmail)
        } catch {
            throw AuthError.firebase(Self.message(for: error))
        }
    }

    /// Заглушка: кнопка "Увійти через Apple" вже показується користувачу,
    /// але сам флоу свідомо не реалізований, поки немає Apple Developer ID.
    func signInWithApple() async throws {
        throw AuthError.appleNotConfiguredYet
    }

    /// Реальний вхід через Google: GoogleSignIn показує системний екран
    /// вибору акаунту, отриманий id-токен віддаємо Firebase, і Firebase
    /// сам створює або підвантажує акаунт.
    @MainActor
    func signInWithGoogle() async throws {
        guard let rootViewController = Self.rootViewController() else {
            throw AuthError.firebase("Couldn't open the sign-in window.")
        }
        do {
            let googleResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            guard let idToken = googleResult.user.idToken?.tokenString else {
                throw AuthError.firebase("Couldn't get a Google token.")
            }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: googleResult.user.accessToken.tokenString
            )
            let authResult = try await Auth.auth().signIn(with: credential)
            currentUser = AppUser(
                uid: authResult.user.uid,
                email: authResult.user.email ?? "",
                displayName: authResult.user.displayName ?? googleResult.user.profile?.name ?? ""
            )
        } catch {
            throw AuthError.firebase(Self.message(for: error))
        }
    }

    private static func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController
    }

    func signOut() {
        try? Auth.auth().signOut()
        currentUser = nil
    }

    /// Остаточне видалення акаунту — вимога Apple (App Store Guideline
    /// 5.1.1(v): будь-який застосунок, що дозволяє створити акаунт, має
    /// дозволяти видалити його з самого застосунку).
    ///
    /// Спершу видаляє користувача у Firebase Auth. Firebase іноді вимагає
    /// "свіжий" вхід перед видаленням (requiresRecentLogin) — у такому
    /// випадку просимо користувача вийти й зайти знову, а не намагаємось
    /// непомітно повторно авторизувати. Після успішного видалення чистимо
    /// всі локальні дані (UserDefaults застосунку + App Group для віджета),
    /// щоб на пристрої не лишилось жодного сліду акаунту.
    @MainActor
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else { return }
        do {
            try await user.delete()
        } catch {
            let nsError = error as NSError
            if let code = AuthErrorCode(rawValue: nsError.code), code == .requiresRecentLogin {
                throw AuthError.firebase("For your security, please sign out, sign in again, and then delete your account.")
            }
            throw AuthError.firebase(Self.message(for: error))
        }
        Self.wipeAllLocalData()
        currentUser = nil
    }

    /// Прибирає геть усі локальні дані застосунку: прогрес, стрік, серця,
    /// підказки, аватарку, акцент озвучки, прапорець підписки — буквально
    /// все, що колись записав UserDefaults.standard (ключі динамічні —
    /// напр. HintsManager/CategoryProgressStore створюють окремий ключ на
    /// кожну категорію, тож перелічувати їх поіменно нереально; натомість
    /// чистимо весь "домен" застосунку одним проходом). Також чистимо
    /// App Group, яким користується віджет домашнього екрана.
    private static func wipeAllLocalData() {
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys {
            defaults.removeObject(forKey: key)
        }
        if let widgetDefaults = UserDefaults(suiteName: WidgetWordsStore.appGroupId) {
            for key in widgetDefaults.dictionaryRepresentation().keys {
                widgetDefaults.removeObject(forKey: key)
            }
        }
    }

    private static func message(for error: Error) -> String {
        let nsError = error as NSError
        guard let code = AuthErrorCode(rawValue: nsError.code) else {
            return "Something went wrong. Please try again."
        }
        switch code {
        case .emailAlreadyInUse:
            return "An account with this email already exists."
        case .invalidEmail:
            return "Enter a valid email address."
        case .weakPassword:
            return "This password is too weak — choose another one."
        case .wrongPassword, .userNotFound, .invalidCredential:
            return "Incorrect email or password."
        case .networkError:
            return "No internet connection."
        default:
            return "Something went wrong. Please try again."
        }
    }
}
