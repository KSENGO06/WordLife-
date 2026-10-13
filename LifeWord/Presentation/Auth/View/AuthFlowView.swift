import SwiftUI

/// Екран входу/реєстрації — перемикання між "Створити акаунт" і "Увійти".
/// Реальна автентифікація через Firebase Auth (AuthManager): email/пароль
/// і Google вже працюють по-справжньому; кнопка "Увійти через Apple" поки
/// що заглушка (потребує Apple Developer ID, якого ще немає).
///
/// Дизайн за макетом Ксені: теплий кремовий фон з ледь помітними словами
/// на фоні (ті ж слова, що й "падають" на сплеш-екрані — тематична єдність),
/// талісман, що махає рукою, заголовок-вітання, прості пласкі поля й
/// компактні круглі кнопки Google/Apple замість широких.
struct AuthFlowView: View {
    private enum Mode: Hashable {
        case signUp
        case signIn
    }

    private enum Field: Hashable {
        case name, email, password
    }

    @State private var mode: Mode = .signUp
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var infoMessage: String?
    @State private var isSubmitting = false
    @State private var showForm = false
    @FocusState private var focusedField: Field?

    private let cream = Color(red: 0xFB / 255, green: 0xF8 / 255, blue: 0xF3 / 255)
    private let ink = Color(red: 27.0 / 255, green: 27.0 / 255, blue: 27.0 / 255)

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("LifeWord")
                    .font(.appTitleL)
                    .foregroundStyle(ink)
                    .padding(.top, 20)

                modeSwitcher

                header

                VStack(spacing: 24) {
                    VStack(spacing: 10) {
                        if mode == .signUp {
                            field("Name", text: $name)
                                .focused($focusedField, equals: .name)
                                .textContentType(.name)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        field("Email", text: $email)
                            .focused($focusedField, equals: .email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textContentType(.emailAddress)
                        secureField("Password", text: $password)
                            .focused($focusedField, equals: .password)
                            .textContentType(mode == .signUp ? .newPassword : .password)

                        if mode == .signIn {
                            HStack {
                                Spacer()
                                Button {
                                    submitForgotPassword()
                                } label: {
                                    Text("Forgot password?")
                                        .font(.appCaption)
                                        .foregroundStyle(.secondary)
                                }
                                .disabled(isSubmitting)
                            }
                        }
                    }
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: mode)

                    if let errorMessage {
                        errorBanner(errorMessage)
                    }
                    if let infoMessage {
                        infoBanner(infoMessage)
                    }

                    VStack(spacing: 16) {
                        Button {
                            submit()
                        } label: {
                            if isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Text(mode == .signUp ? "Create account" : "Log in")
                            }
                        }
                        .buttonStyle(.primary)
                        .disabled(isSubmitting)

                        orDivider

                        HStack(spacing: 16) {
                            socialIconButton(assetName: "google", action: submitGoogle)
                            socialIconButton(assetName: "icon-apple", action: submitApple)
                        }
                    }

                    Text("Your login details are stored in Firebase and synced across devices.")
                        .font(.appCaption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(showForm ? 1 : 0)
                .offset(y: showForm ? 0 : 14)
            }
            .padding(24)
            .padding(.top, 12)
        }
        .background(backgroundLayer)
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: mode) { errorMessage = nil; infoMessage = nil }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.35)) {
                showForm = true
            }
        }
    }

    // MARK: - Фон

    /// Кремовий фон із ледь помітними словами по всьому периметру — ті самі
    /// слова, що й падають на сплеш-екрані, тому відчувається як одна
    /// візуальна мова. Кільце з 8 слів, а не лише 4 кути.
    private static let perimeterWords: [(text: String, x: CGFloat, y: CGFloat)] = [
        ("home", 0.16, 0.055),
        ("study", 0.5, 0.04),
        ("speak", 0.84, 0.055),
        ("focus", 0.91, 0.38),
        ("grow", 0.84, 0.95),
        ("write", 0.5, 0.975),
        ("learn", 0.16, 0.95),
        ("travel", 0.09, 0.38),
    ]

    private var backgroundLayer: some View {
        ZStack {
            cream
            GeometryReader { geo in
                ForEach(Self.perimeterWords, id: \.text) { word in
                    cornerWord(word.text, x: geo.size.width * word.x, y: geo.size.height * word.y)
                }
            }
        }
        .ignoresSafeArea()
    }

    private func cornerWord(_ text: String, x: CGFloat, y: CGFloat) -> some View {
        Text(text)
            .font(AppFont.playfairSemiBold(34))
            .foregroundStyle(ink.opacity(0.22))
            .position(x: x, y: y)
    }

    // MARK: - Шапка

    private var header: some View {
        VStack(spacing: 14) {
            MascotView(pose: .waving, size: 190, animateWave: true)

            VStack(spacing: 4) {
                Text(heroTitle)
                    .font(.appTitleM)
                    .foregroundStyle(ink)
                Text(heroSubtitle)
                    .font(.appBodyRegular)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var heroTitle: String {
        mode == .signUp ? "Let's get started" : "Welcome back"
    }

    private var heroSubtitle: String {
        mode == .signUp ? "Learn words for real life." : "Let's pick up where you left off."
    }

    // MARK: - Перемикач режиму

    /// Явний перемикач "Sign up / Log in" зверху екрана — дві вкладки з
    /// підкресленням активної, а не лише текстове посилання знизу.
    private var modeSwitcher: some View {
        HStack(spacing: 28) {
            modeTab("Sign up", .signUp)
            modeTab("Log in", .signIn)
        }
    }

    private func modeTab(_ title: String, _ value: Mode) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                mode = value
            }
        } label: {
            VStack(spacing: 6) {
                Text(title)
                    .font(.appButton)
                    .foregroundStyle(mode == value ? ink : Color.secondary)
                Rectangle()
                    .fill(mode == value ? Color.appAccent : Color.clear)
                    .frame(width: 40, height: 2)
                    .clipShape(Capsule())
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Поля вводу

    private func field(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .font(.appBodyRegular)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color(.systemGray5), lineWidth: 1))
    }

    private func secureField(_ title: String, text: Binding<String>) -> some View {
        SecureField(title, text: text)
            .font(.appBodyRegular)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color(.systemGray5), lineWidth: 1))
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.appBodySmall)
                .foregroundStyle(.red)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.red.opacity(0.1)))
    }

    private func infoBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.appAccent)
            Text(message)
                .font(.appBodySmall)
                .foregroundStyle(Color.appAccent)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.appAccent.opacity(0.1)))
    }

    private var orDivider: some View {
        HStack(spacing: 10) {
            Rectangle().fill(Color(.systemGray4)).frame(height: 1)
            Text("or")
                .font(.appCaption)
                .foregroundStyle(.secondary)
            Rectangle().fill(Color(.systemGray4)).frame(height: 1)
        }
    }

    /// Кнопка Google/Apple — квадратна іконка з обводкою (власні асети
    /// Ксені "google" / "icon-apple"), за макетом. Вхід через Apple свідомо
    /// лишається заглушкою (детальніше в AuthManager.signInWithApple).
    private func socialIconButton(assetName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .frame(width: 58, height: 58)
        }
        .background(Color.clear, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(ink, lineWidth: 1.5))
        .disabled(isSubmitting)
    }

    private func submit() {
        errorMessage = nil
        infoMessage = nil
        focusedField = nil
        isSubmitting = true
        Task {
            do {
                if mode == .signUp {
                    try await AuthManager.shared.signUp(name: name, email: email, password: password)
                } else {
                    try await AuthManager.shared.signIn(email: email, password: password)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }

    private func submitApple() {
        errorMessage = nil
        infoMessage = nil
        focusedField = nil
        Task {
            do {
                try await AuthManager.shared.signInWithApple()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func submitForgotPassword() {
        errorMessage = nil
        infoMessage = nil
        focusedField = nil
        isSubmitting = true
        Task {
            do {
                try await AuthManager.shared.sendPasswordReset(email: email)
                infoMessage = "Password reset email sent — check your inbox."
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }

    private func submitGoogle() {
        errorMessage = nil
        infoMessage = nil
        focusedField = nil
        isSubmitting = true
        Task {
            do {
                try await AuthManager.shared.signInWithGoogle()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}
