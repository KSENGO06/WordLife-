import SwiftUI

/// Головна вкладка: "маршрут" користувача — заголовок, картка дня з
/// талісманом, і вертикальний список вузлів (сьогоднішня ціль, поточна
/// тема з "Продовжити", слово дня), з'єднаних пунктирною лінією.
struct HomeView: View {
    @State private var viewModel: HomeViewModel

    private let getWordsUseCase: GetWordsUseCase
    private let getSceneUseCase: GetSceneUseCase
    private let getSentencesUseCase: GetSentenceExercisesUseCase
    private let getSentenceChoicesUseCase: GetSentenceChoiceExercisesUseCase
    private let getTranslationExercisesUseCase: GetTranslationExercisesUseCase
    private let getClozeExerciseUseCase: GetClozeExerciseUseCase
    private let audioPlayer: AudioPlayer

    // MARK: - Інтерактивний талісман

    @State private var mascotBounce = false
    @State private var showSpeechBubble = false
    @State private var encouragingPhrase = ""
    @State private var speechBubbleTask: Task<Void, Never>?
    @State private var showStreakCelebration = false

    private static let encouragingPhrases = [
        "You're doing great!",
        "One word at a time!",
        "Keep that streak alive!",
        "Learning looks good on you.",
        "Small steps, big progress.",
        "Proud of you for showing up!",
        "Let's learn something new!",
        "Every word counts.",
        "Your future self says thanks."
    ]

    init(getAllWordsUseCase: GetAllWordsUseCase,
         getCategoriesUseCase: GetCategoriesUseCase,
         getWordsUseCase: GetWordsUseCase,
         getSceneUseCase: GetSceneUseCase,
         getSentencesUseCase: GetSentenceExercisesUseCase,
         getSentenceChoicesUseCase: GetSentenceChoiceExercisesUseCase,
         getTranslationExercisesUseCase: GetTranslationExercisesUseCase,
         getClozeExerciseUseCase: GetClozeExerciseUseCase,
         audioPlayer: AudioPlayer) {
        _viewModel = State(wrappedValue: HomeViewModel(getAllWordsUseCase: getAllWordsUseCase, getCategoriesUseCase: getCategoriesUseCase))
        self.getWordsUseCase = getWordsUseCase
        self.getSceneUseCase = getSceneUseCase
        self.getSentencesUseCase = getSentencesUseCase
        self.getSentenceChoicesUseCase = getSentenceChoicesUseCase
        self.getTranslationExercisesUseCase = getTranslationExercisesUseCase
        self.getClozeExerciseUseCase = getClozeExerciseUseCase
        self.audioPlayer = audioPlayer
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                routeHeader

                dayCard

                routeList
            }
            .padding(20)
            .padding(.bottom, 16)
        }
        .appScreenBackground()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
            if ActivityManager.shared.shouldShowStreakCelebration {
                ActivityManager.shared.markStreakScreenShown()
                showStreakCelebration = true
            }
        }
        .fullScreenCover(isPresented: $showStreakCelebration) {
            StreakCelebrationView(streakCount: ActivityManager.shared.streakCount) {
                showStreakCelebration = false
            }
        }
    }

    // MARK: - Талісман-герой: привітання + тижневий стрік + інтерактив

    private var greetingSubtitle: String {
        if ActivityManager.shared.isDailyGoalMet {
            "You crushed today's goal. Nicely done!"
        } else if ActivityManager.shared.streakCount > 0 {
            "Keep it up! Keep learning."
        } else {
            "Ready to learn something new?"
        }
    }

    private var mascotPose: MascotView.Pose {
        .loading
    }

    /// Ім'я (перше слово з displayName) для привітання зверху — порожнє,
    /// якщо користувач ще не задав ім'я при реєстрації.
    private var firstName: String {
        let name = AuthManager.shared.currentUser?.displayName ?? ""
        return name.split(separator: " ").first.map(String.init) ?? ""
    }

    private var routeHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(firstName.isEmpty ? "Small steps that add up to a language." : "Hi, \(firstName)! Small steps that add up to a language.")
                .font(.appTitleL)
        }
    }

    private var dayBadgeText: String {
        let streak = ActivityManager.shared.streakCount
        return streak > 0 ? "Day \(streak)" : "Let's start"
    }

    private var dayCard: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.appAccent.opacity(0.16), Color.appAccent.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 10) {
                Text(dayBadgeText)
                    .font(.appCaption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.appAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.appAccent.opacity(0.16), in: Capsule())

                Text(greetingSubtitle)
                    .font(.appTitleM)
                    .lineLimit(2)

                Text("\(ActivityManager.shared.sectionsCompletedTotal) exercises completed so far")
                    .font(.appBodySmall)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .padding(.trailing, 96)

            mascotButton(size: 96)
                .padding(.top, 28)
                .padding(.trailing, 10)
        }
    }

    private func mascotButton(size: CGFloat = 104) -> some View {
        ZStack(alignment: .top) {
            if showSpeechBubble {
                speechBubble(encouragingPhrase)
                    .offset(y: -size * 0.56)
                    .transition(.scale(scale: 0.75, anchor: .bottom).combined(with: .opacity))
            }

            Button(action: tapMascot) {
                MascotView(pose: mascotPose, size: size)
            }
            .buttonStyle(.plain)
            .scaleEffect(mascotBounce ? 1.14 : 1.0)
            .rotationEffect(.degrees(mascotBounce ? -5 : 0))
        }
    }

    private func speechBubble(_ text: String) -> some View {
        Text(text)
            .font(.appCaption)
            .foregroundStyle(.primary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 140)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.14), radius: 8, y: 3)
            )
    }

    /// Талісман реагує на дотик: підстрибує і показує підбадьорливу фразу у
    /// спливаючій бульбашці на кілька секунд.
    private func tapMascot() {
        encouragingPhrase = Self.encouragingPhrases.randomElement() ?? "You're doing great!"

        withAnimation(.spring(response: 0.3, dampingFraction: 0.45)) {
            mascotBounce = true
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
            showSpeechBubble = true
        }

        speechBubbleTask?.cancel()
        speechBubbleTask = Task {
            try? await Task.sleep(nanoseconds: 220_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { mascotBounce = false }

            try? await Task.sleep(nanoseconds: 2_200_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) { showSpeechBubble = false }
        }
    }

    // MARK: - Маршрут: з'єднувач та статуси вузлів

    private struct DashedVLine: View {
        var height: CGFloat = 24

        var body: some View {
            Path { path in
                path.move(to: CGPoint(x: 1, y: 0))
                path.addLine(to: CGPoint(x: 1, y: height))
            }
            .stroke(Color(.systemGray4), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
            .frame(width: 2, height: height)
        }
    }

    private enum RouteNodeStatus {
        case done
        case active
        case upcoming

        var dotColor: Color {
            switch self {
            case .done: return .green
            case .active: return Color.appAccent
            case .upcoming: return Color(.systemGray3)
            }
        }
    }

    private func routeNode<Content: View>(status: RouteNodeStatus, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(status.dotColor)
                    .frame(width: 14, height: 14)
                if status == .done {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .padding(.top, 4)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Маршрут: сьогоднішня ціль

    @ViewBuilder
    private var goalRouteNode: some View {
        let goal = max(ActivityManager.shared.dailyGoal, 1)
        let done = ActivityManager.shared.sectionsCompletedToday
        let met = ActivityManager.shared.isDailyGoalMet

        routeNode(status: met ? .done : .active) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today's goal")
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
                Text(met ? "Goal reached — nice work!" : "\(done) / \(goal) exercises")
                    .font(.appHeadline)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
        }
    }

    // MARK: - Картка "Продовжити"

    @ViewBuilder
    private func continueCard(_ category: Category) -> some View {
        let progress = CategoryProgressStore.progressFraction(categoryId: category.id, isPhrasal: category.isPhrasalVerbs)
        let displayName = category.name.replacingOccurrences(of: "Phrasal Verbs: ", with: "")
        NavigationLink {
            resumeDestination(for: category)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                ArtworkFallback(
                    fallbackImageNames: ImageAssetResolver.candidates(for: category),
                    symbolName: "text.book.closed.fill"
                )
                .frame(height: 132)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay(alignment: .bottom) {
                    LinearGradient(colors: [.black.opacity(0.78), .clear], startPoint: .bottom, endPoint: .top)
                        .frame(height: 86)
                }
                .overlay(alignment: .topLeading) {
                    Text(ActivityManager.shared.lastCategoryId == nil ? "TRY THIS" : "CONTINUE LEARNING")
                        .font(.appCaption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.35), in: Capsule())
                        .padding(12)
                }
                .overlay(alignment: .bottomLeading) {
                    Text(displayName)
                        .font(.appHeadline)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(12)
                }

                VStack(alignment: .leading, spacing: 10) {
                    if progress > 0 {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color(.systemGray5))
                                Capsule().fill(Color.appAccent).frame(width: max(4, geo.size.width * progress))
                            }
                        }
                        .frame(height: 5)
                    }
                    HStack {
                        Text(progress > 0 ? "\(Int((progress * 100).rounded()))% complete" : "Not started yet")
                            .font(.appCaption)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 8)
                        HStack(spacing: 4) {
                            Text(progress > 0 ? "Resume" : "Start lesson")
                                .font(.appButton)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(Color.appAccent)
                    }
                }
                .padding(14)
            }
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Маршрут: поточна тема

    @ViewBuilder
    private func categoryRouteNode(_ category: Category) -> some View {
        routeNode(status: .active) {
            continueCard(category)
        }
    }

    // MARK: - Слово дня

    @ViewBuilder
    private func wordOfDayCard(_ word: Word) -> some View {
        let category = viewModel.category(for: word)
        NavigationLink {
            if let category {
                destination(for: category)
            } else {
                EmptyView()
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Text("Word of the day")
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(word.term).font(.appTitleM)
                        Text(word.translation).font(.appBodyRegular).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "sparkles").font(.system(size: 22)).foregroundStyle(Color.appAccent)
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.appAccent.opacity(0.08)))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.appAccent.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(category == nil)
    }

    // MARK: - Маршрут: слово дня

    @ViewBuilder
    private func wordOfDayRouteNode(_ word: Word) -> some View {
        routeNode(status: .upcoming) {
            wordOfDayCard(word)
        }
    }

    // MARK: - Маршрут: список вузлів

    @ViewBuilder
    private var routeList: some View {
        VStack(alignment: .leading, spacing: 0) {
            goalRouteNode

            if let category = viewModel.continueCategory {
                DashedVLine()
                    .padding(.leading, 6)
                categoryRouteNode(category)
            }

            if let word = viewModel.wordOfDay {
                DashedVLine()
                    .padding(.leading, 6)
                wordOfDayRouteNode(word)
            }
        }
    }

    // MARK: - Навігація в категорію

    @ViewBuilder
    private func destination(for category: Category) -> some View {
        if category.isPhrasalVerbs {
            PhrasalCategoryOverviewView(
                categoryId: category.id,
                categoryName: category.name.replacingOccurrences(of: "Phrasal Verbs: ", with: ""),
                getWordsUseCase: getWordsUseCase,
                getSceneUseCase: getSceneUseCase,
                getTranslationExercisesUseCase: getTranslationExercisesUseCase,
                getClozeExerciseUseCase: getClozeExerciseUseCase,
                audioPlayer: audioPlayer
            )
        } else {
            CategoryOverviewView(
                categoryId: category.id,
                categoryName: category.name,
                getWordsUseCase: getWordsUseCase,
                getSceneUseCase: getSceneUseCase,
                getSentencesUseCase: getSentencesUseCase,
                getSentenceChoicesUseCase: getSentenceChoicesUseCase,
                audioPlayer: audioPlayer
            )
        }
    }

    // MARK: - "Продовжити" з того самого місця (минаємо сцену, одразу у вправи)

    /// На відміну від `destination(for:)` (яка веде на екран сцени категорії),
    /// це веде ПРЯМО у вправи, одразу відкриваючи першу незавершену секцію —
    /// саме цього очікують від натискання картки "Продовжити".
    @ViewBuilder
    private func resumeDestination(for category: Category) -> some View {
        if category.isPhrasalVerbs {
            ResumePhrasalLoader(
                categoryId: category.id,
                categoryName: category.name.replacingOccurrences(of: "Phrasal Verbs: ", with: ""),
                getWordsUseCase: getWordsUseCase,
                getTranslationExercisesUseCase: getTranslationExercisesUseCase,
                getClozeExerciseUseCase: getClozeExerciseUseCase,
                audioPlayer: audioPlayer
            )
        } else {
            CategoryPracticeView(
                categoryId: category.id,
                categoryName: category.name,
                getWordsUseCase: getWordsUseCase,
                getSentencesUseCase: getSentencesUseCase,
                getSentenceChoicesUseCase: getSentenceChoicesUseCase,
                audioPlayer: audioPlayer,
                resumeSection: CategoryProgressStore.resumeRegularSection(categoryId: category.id)
            )
        }
    }
}

/// Категорія фразових дієслів передає вправам уже завантажені слова/речення
/// (а не use case-и напряму), тож перед переходом з головного екрана їх
/// треба спершу підвантажити — звідси маленький проміжний екран-завантажувач.
private struct ResumePhrasalLoader: View {
    let categoryId: String
    let categoryName: String
    let getWordsUseCase: GetWordsUseCase
    let getTranslationExercisesUseCase: GetTranslationExercisesUseCase
    let getClozeExerciseUseCase: GetClozeExerciseUseCase
    let audioPlayer: AudioPlayer

    @State private var words: [Word] = []
    @State private var translationExercises: [TranslationExercise] = []
    @State private var clozeExercise: ClozeExercise?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                PhrasalCategoryPracticeView(
                    categoryId: categoryId,
                    categoryName: categoryName,
                    words: words,
                    translationExercises: translationExercises,
                    clozeExercise: clozeExercise,
                    audioPlayer: audioPlayer,
                    resumeSection: CategoryProgressStore.resumePhrasalSection(categoryId: categoryId)
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            let loadedWords = (try? await getWordsUseCase.execute(categoryId: categoryId)) ?? []
            words = loadedWords
            translationExercises = (try? await getTranslationExercisesUseCase.execute(categoryId: categoryId, words: loadedWords)) ?? []
            clozeExercise = try? await getClozeExerciseUseCase.execute(categoryId: categoryId)
            isLoading = false
        }
    }
}
