import SwiftUI
import PhotosUI

/// Вкладка "Профіль": фото (своє або талісман-заглушка), стрік, прогрес
/// (скільки категорій пройдено, скільки слів вивчено), список пройдених
/// категорій, акцент озвучки, перехід на LifeWord Plus, вихід з акаунту.
struct ProfileView: View {
    let getCategoriesUseCase: GetCategoriesUseCase
    let getAllWordsUseCase: GetAllWordsUseCase

    @State private var showSignOutConfirm = false
    @State private var showPaywall = false
    @State private var showDeleteAccountConfirm = false
    @State private var isDeletingAccount = false
    @State private var deleteAccountErrorMessage: String?
    @State private var categories: [Category] = []
    /// categoryId -> скільки слів у цій категорії — для підрахунку
    /// "вивчених слів" (сума слів у повністю пройдених категоріях).
    @State private var wordCountsByCategory: [String: Int] = [:]

    @State private var avatarImage: UIImage?
    @State private var avatarPickerItem: PhotosPickerItem?

    private var user: AppUser? { AuthManager.shared.currentUser }

    /// Категорії, пройдені на 100% (CategoryProgressStore) — рахується
    /// наживо з уже завантажених категорій, не кешується окремо.
    private var completedCategories: [Category] {
        categories.filter {
            CategoryProgressStore.progressFraction(categoryId: $0.id, isPhrasal: $0.isPhrasalVerbs) >= 1
        }
    }

    /// Категорії, в яких уже є хоч якийсь прогрес — і завершені, і ті, що
    /// ще в процесі — відсортовані від найбільш пройдених до щойно
    /// розпочатих. Для списку "Your topics" на екрані профілю.
    private var startedCategories: [(category: Category, progress: Double)] {
        categories
            .map { category in
                (category: category, progress: CategoryProgressStore.progressFraction(categoryId: category.id, isPhrasal: category.isPhrasalVerbs))
            }
            .filter { $0.progress > 0 }
            .sorted { $0.progress > $1.progress }
    }

    /// "Вивчені слова" — поки в додатку нема позначки "вивчено" для
    /// окремого слова, тож рахуємо як суму слів у повністю пройдених
    /// категоріях (найближчий чесний показник без нового шару даних).
    private var wordsLearnedCount: Int {
        completedCategories.reduce(0) { $0 + (wordCountsByCategory[$1.id] ?? 0) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                screenTitle

                avatarHeader

                premiumSection

                accentSection

                activitySection

                progressSection

                topicsProgressSection

                #if DEBUG
                Button {
                    NotificationManager.sendTestNotifications()
                } label: {
                    Text("🔔 Тест сповіщень (DEBUG)")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.secondary)
                #endif

                Button(role: .destructive) {
                    showSignOutConfirm = true
                } label: {
                    Text("Sign out")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.secondary)

                deleteAccountButton
            }
            .padding(20)
        }
        .appScreenBackground()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadProgressDataIfNeeded()
            avatarImage = AvatarStore.photo(for: user?.uid ?? "")
        }
        .onChange(of: avatarPickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                guard let data = try? await newItem.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data) else { return }
                AvatarStore.setPhoto(uiImage, for: user?.uid ?? "")
                avatarImage = AvatarStore.photo(for: user?.uid ?? "")
            }
        }
        .confirmationDialog("Sign out?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) { AuthManager.shared.signOut() }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "Delete account?",
            isPresented: $showDeleteAccountConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Account", role: .destructive) { deleteAccount() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your account and all your progress. This can't be undone.")
        }
        .alert(
            "Couldn't delete account",
            isPresented: Binding(
                get: { deleteAccountErrorMessage != nil },
                set: { if !$0 { deleteAccountErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteAccountErrorMessage ?? "")
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private func loadProgressDataIfNeeded() async {
        guard categories.isEmpty else { return }
        do {
            async let loadedCategories = getCategoriesUseCase.execute()
            async let loadedWords = getAllWordsUseCase.execute()
            let (fetchedCategories, fetchedWords) = try await (loadedCategories, loadedWords)

            var counts: [String: Int] = [:]
            for word in fetchedWords {
                counts[word.categoryId, default: 0] += 1
            }
            categories = fetchedCategories
            wordCountsByCategory = counts
        } catch {
            // Прогрес — лише допоміжна інформація: якщо контент не
            // завантажився, екран просто покаже 0/0, а не впаде.
        }
    }

    // MARK: - Шапка

    private var screenTitle: some View {
        Text("Profile")
            .font(.appTitleL)
            .padding(.top, 8)
    }

    /// Аватар — своє фото, якщо обране, інакше талісман застосунку як
    /// дружня заглушка (не просто порожнє коло чи ініціали). Тап будь-де
    /// по колу одразу відкриває вибір фото з галереї; маленький бейдж з
    /// камерою в кутку підказує, що це клікабельно.
    private var avatarHeader: some View {
        HStack(spacing: 14) {
            PhotosPicker(selection: $avatarPickerItem, matching: .images) {
                ZStack {
                    Circle().fill(Color.appAccent.opacity(0.12))

                    if let avatarImage {
                        Image(uiImage: avatarImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())
                    } else {
                        MascotView(pose: .resting, size: 50)
                    }
                }
                .frame(width: 64, height: 64)
                .overlay(alignment: .bottomTrailing) {
                    ZStack {
                        Circle().fill(Color.appAccent)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 22, height: 22)
                    .overlay(Circle().strokeBorder(Color(.systemBackground), lineWidth: 2))
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(user?.displayName ?? "")
                    .font(.appHeadline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(user?.email ?? "")
                    .font(.appBodySmall)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Активність: стрік

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Activity")

            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.95))
                    Text("\(ActivityManager.shared.streakCount)")
                        .font(AppFont.interBold(32))
                        .foregroundStyle(Color.appAccent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(4)
                }
                .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Day streak")
                        .font(AppFont.interSemiBold(19))
                        .foregroundStyle(.white)
                    Text(ActivityManager.shared.streakCount > 0
                         ? "Today's lesson keeps it going"
                         : "Finish a lesson to start your streak")
                        .font(.appCaption)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                Image(systemName: "flame.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(16)
            .background(Color.appAccent)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    // MARK: - Прогрес: категорії + слова

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Your progress")

            HStack(spacing: 12) {
                statTile(value: "\(wordsLearnedCount)", label: "words learned")
                statTile(value: "\(completedCategories.count)/\(categories.count)", label: "topics completed")
            }
        }
    }

    private func statTile(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(AppFont.playfairBold(30))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(label)
                .font(.appCaption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
    }

    // MARK: - Теми в процесі та пройдені

    /// Усі категорії з прогресом >0 (завершені чи ще в процесі) — видно
    /// одразу ~3 рядки, решта гортається в цій самій картці, не на весь
    /// екран. Завершені зверху (сортування за прогресом), для кожної
    /// незавершеної видно відсоток.
    @ViewBuilder
    private var topicsProgressSection: some View {
        if !startedCategories.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Your topics")

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(startedCategories, id: \.category.id) { entry in
                            topicProgressRow(entry.category, progress: entry.progress)
                        }
                    }
                }
                .frame(maxHeight: 3 * 64)
            }
        }
    }

    private func topicProgressRow(_ category: Category, progress: Double) -> some View {
        let isDone = progress >= 1
        return HStack(spacing: 12) {
            topicThumbnail(for: category)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(category.name)
                .font(.appBodyRegular)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text("\(Int((progress * 100).rounded()))%")
                .font(.appHeadline)
                .foregroundStyle(isDone ? Color.appCorrect : Color.appAccent)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
    }

    /// Та сама логіка пошуку картинки категорії, що й на екрані "Категорії"
    /// (ArtworkFallback/ImageAssetResolver/PhrasalThemeAsset) — щоб заставка
    /// тут виглядала так само, а не окремим, неузгодженим варіантом.
    @ViewBuilder
    private func topicThumbnail(for category: Category) -> some View {
        if category.isPhrasalVerbs {
            ArtworkFallback(
                preferredImageName: PhrasalThemeAsset.imageName(for: category.id),
                symbolName: "text.book.closed.fill"
            )
        } else {
            ArtworkFallback(
                fallbackImageNames: ImageAssetResolver.candidates(for: category),
                symbolName: "square.grid.2x2.fill"
            )
        }
    }

    // MARK: - LifeWord Plus

    @ViewBuilder
    private var premiumSection: some View {
        if PremiumManager.shared.isPremium {
            VStack(alignment: .leading, spacing: 8) {
                // Теж кнопка, не статичний напис — інакше після тестової
                // "покупки" цей екран стає взагалі недосяжним з профілю.
                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.white)
                        Text("LifeWord Plus is active")
                            .font(AppFont.interSemiBold(16))
                            .foregroundStyle(.white)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.appAccent))
                }
                .buttonStyle(.plain)

                #if DEBUG
                // Лише для тестування на пристрої — "покупка" зараз локальна
                // заглушка без StoreKit, тож це єдиний спосіб повернути
                // isPremium=false і знову побачити банер "Go to LifeWord Plus".
                Button("Reset subscription (debug)") {
                    PremiumManager.shared.debugReset()
                }
                .font(.appCaption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
                #endif
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("No limits")

                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle().fill(Color.white.opacity(0.22))
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 38, height: 38)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Go to LifeWord Plus")
                                .font(AppFont.interSemiBold(16))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            // Поки заглушка — реальна ціна з'явиться тут
                            // автоматично, коли підключимо StoreKit-продукт.
                            Text("From $4.99/month")
                                .font(.appCaption)
                                .foregroundStyle(.white.opacity(0.85))
                        }

                        Spacer(minLength: 0)

                        Image(systemName: "chevron.right")
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(16)
                    .background(Color.appAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Акцент озвучки

    /// Вибір акценту озвучки слів і речень (американський/британський) —
    /// дві плитки з прапорцями замість звичайного системного перемикача.
    /// Контент переозвучується поступово — AudioPlayer сам підставляє
    /// потрібний файл і тихо повертається до американської озвучки там, де
    /// британської версії ще нема, тож перемикач можна показувати вже зараз.
    private var accentSection: some View {
        HStack {
            sectionLabel("Audio accent")
            Spacer()
            HStack(spacing: 8) {
                ForEach(AccentManager.Accent.allCases) { accent in
                    accentOptionButton(accent)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
    }

    /// Лише прапорець у колі — компактніше за попередню версію з підписом
    /// "American"/"British" на повну ширину; вибраний варіант підсвічений
    /// кольоровим кільцем, а не суцільною заливкою.
    private func accentOptionButton(_ accent: AccentManager.Accent) -> some View {
        let isSelected = AccentManager.shared.accent == accent
        return Button {
            AccentManager.shared.accent = accent
        } label: {
            Text(accent.flagEmoji)
                .font(.system(size: 22))
                .frame(width: 42, height: 42)
                .background(
                    Circle().fill(isSelected ? Color.appAccent.opacity(0.15) : Color(.tertiarySystemBackground))
                )
                .overlay(
                    Circle().strokeBorder(isSelected ? Color.appAccent : .clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Видалення акаунту

    /// Окрема, навмисно менш помітна за "Sign out" кнопка — так само
    /// `role: .destructive`, але текстова, без фону, щоб випадково не
    /// тицьнути замість виходу з акаунту. Під час запиту показує спінер
    /// замість напису і блокується від повторних натискань.
    private var deleteAccountButton: some View {
        Button(role: .destructive) {
            showDeleteAccountConfirm = true
        } label: {
            if isDeletingAccount {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                Text("Delete account")
                    .font(.appCaption)
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.red.opacity(0.75))
        .padding(.top, 2)
        .disabled(isDeletingAccount)
    }

    private func deleteAccount() {
        isDeletingAccount = true
        Task {
            do {
                try await AuthManager.shared.deleteAccount()
                // currentUser стає nil -> RootView сам поверне на екран входу.
            } catch {
                deleteAccountErrorMessage = error.localizedDescription
            }
            isDeletingAccount = false
        }
    }

    // MARK: - Спільне

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.appLabel)
            .foregroundStyle(.secondary)
    }
}
