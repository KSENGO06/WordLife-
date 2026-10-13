import SwiftUI

/// Список вправ "Закріплення" для категорії фразових дієслів — та сама
/// вітрина, що й CategoryPracticeView (фото категорії, прогрес, картки
/// вправ з іконкою/замком/галочкою), але без рівнів 1/2 — тут один плаский
/// список.
struct PhrasalCategoryPracticeView: View {
    @State private var viewModel: PhrasalCategoryPracticeViewModel
    @State private var activeSection: PhrasalSectionType?
    @State private var showPaywall = false
    private let categoryName: String
    let audioPlayer: AudioPlayer

    init(categoryId: String, categoryName: String, words: [Word], translationExercises: [TranslationExercise], clozeExercise: ClozeExercise?, audioPlayer: AudioPlayer, resumeSection: PhrasalSectionType? = nil) {
        _viewModel = State(wrappedValue: PhrasalCategoryPracticeViewModel(
            categoryId: categoryId,
            words: words,
            translationExercises: translationExercises,
            clozeExercise: clozeExercise
        ))
        self.categoryName = categoryName
        self.audioPlayer = audioPlayer
        // Перехід з картки "Продовжити" на головному — одразу відкриваємо
        // вправу, на якій зупинились (дані вже передані готовими, тож не
        // треба чекати на завантаження, як у звичайній категорії).
        _activeSection = State(wrappedValue: resumeSection)
    }

    private var progress: Double {
        Double(viewModel.completedSections.count) / Double(PhrasalSectionType.allCases.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                if HeartsManager.shared.hearts == 0 {
                    heartsBanner
                }

                VStack(spacing: 10) {
                    ForEach(PhrasalSectionType.allCases) { section in
                        sectionRow(section)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 28)
        }
        .appScreenBackground()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            ActivityManager.shared.recordCategoryOpened(id: viewModel.categoryId, name: categoryName, isPhrasal: true)
        }
        .fullScreenCover(item: $activeSection) { section in
            destinationView(for: section)
                .appScreenBackground()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: - Шапка: фото категорії, назва, загальний прогрес

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            ArtworkFallback(fallbackImageNames: [viewModel.categoryIconName], symbolName: "text.book.closed.fill")
                .frame(height: 170)
                .clipped()
                .overlay(alignment: .bottomLeading) {
                    LinearGradient(colors: [.black.opacity(0.78), .clear], startPoint: .bottom, endPoint: .top)
                        .frame(height: 100)
                }
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(categoryName)
                            .font(.appTitleM)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .foregroundStyle(.white)
                        Text("\(viewModel.words.count) verbs")
                            .font(.appBodySmall)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(14)
                }
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .padding(.horizontal, 20)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(.systemGray5))
                        Capsule().fill(Color.appAccent).frame(width: max(6, geo.size.width * progress))
                    }
                }
                .frame(height: 6)
                Text("\(viewModel.completedSections.count) / \(PhrasalSectionType.allCases.count) exercises done")
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
        }
    }

    private var heartsBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "heart.slash.fill").foregroundStyle(.red)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Out of hearts")
                        .font(.appBodySmall)
                    if let interval = HeartsManager.shared.timeUntilNextHeart {
                        TimelineView(.periodic(from: .now, by: 1)) { _ in
                            Text("Next heart in \(formattedCountdown(HeartsManager.shared.timeUntilNextHeart ?? interval))")
                                .font(.appCaption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()
                #if DEBUG
                Button("Reset (DEBUG)") { HeartsManager.shared.debugResetHearts() }
                    .font(.appCaption)
                #endif
            }
            Button("Buy subscription — unlimited hearts") {
                showPaywall = true
            }
            .buttonStyle(.secondary)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.red.opacity(0.1)))
        .padding(.horizontal, 20)
    }

    private func formattedCountdown(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    @ViewBuilder
    private func sectionRow(_ section: PhrasalSectionType) -> some View {
        let structurallyUnlocked = viewModel.isUnlocked(section)
        let completed = viewModel.isCompleted(section)
        // translateBuild і clozeText не витрачають серця (вони не в системі HeartsManager),
        // тож серця блокують вхід тільки в перевірку слів і мечинг.
        let needsHearts = section == .checkNative || section == .checkTarget || section == .matching
        let canEnter = structurallyUnlocked && (!needsHearts || HeartsManager.shared.hearts > 0)

        if canEnter {
            Button { activeSection = section } label: {
                row(section: section, completed: completed, unlocked: true)
            }
            .buttonStyle(.plain)
        } else {
            row(section: section, completed: completed, unlocked: structurallyUnlocked)
        }
    }

    private func row(section: PhrasalSectionType, completed: Bool, unlocked: Bool) -> some View {
        HStack(spacing: 14) {
            ZStack {
                ArtworkFallback(preferredImageName: section.iconAssetName, symbolName: section.symbolName)
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .opacity(unlocked ? 1 : 0.45)

                if completed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.green)
                        .background(Color.white, in: Circle())
                        .offset(x: 17, y: 17)
                } else if !unlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.white)
                        .padding(5)
                        .background(Color.black.opacity(0.55), in: Circle())
                        .offset(x: 17, y: 17)
                }
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(section.title)
                    .font(.appHeadline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(unlocked ? .primary : .secondary)
                Text(section.subtitle)
                    .font(.appBodySmall)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            if unlocked {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.appAccent)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    @ViewBuilder
    private func destinationView(for section: PhrasalSectionType) -> some View {
        switch section {
        case .checkNative:
            TranslationCheckView(
                words: viewModel.words,
                direction: .englishToUkrainian,
                resumingIds: viewModel.remainingIds(for: section),
                audioPlayer: audioPlayer,
                onComplete: { handleComplete(section) },
                onExit: { ids in handleExit(section, remainingIds: ids) }
            )
        case .checkTarget:
            TranslationCheckView(
                words: viewModel.words,
                direction: .ukrainianToEnglish,
                resumingIds: viewModel.remainingIds(for: section),
                audioPlayer: audioPlayer,
                onComplete: { handleComplete(section) },
                onExit: { ids in handleExit(section, remainingIds: ids) }
            )
        case .matching:
            MatchingSectionView(
                words: viewModel.words,
                audioPlayer: audioPlayer,
                onComplete: { handleComplete(section) },
                onExit: { handleExit(section, remainingIds: nil) }
            )
        case .translateBuild:
            TranslationExerciseFlowView(
                exercises: viewModel.translationExercises,
                categoryId: viewModel.categoryId,
                audioPlayer: audioPlayer,
                onComplete: { handleComplete(section) }
            )
        case .clozeText:
            if let clozeExercise = viewModel.clozeExercise {
                ClozeWholeTextView(
                    exercise: clozeExercise,
                    audioPlayer: audioPlayer,
                    onComplete: { handleComplete(section) }
                )
            } else {
                Text("No text available for this category").font(.appBodyRegular)
            }
        }
    }

    private func handleComplete(_ section: PhrasalSectionType) {
        viewModel.clearProgress(for: section)
        viewModel.markCompleted(section)
        activeSection = nil
    }

    private func handleExit(_ section: PhrasalSectionType, remainingIds: [String]?) {
        if let remainingIds {
            viewModel.saveProgress(remainingIds, for: section)
        }
        activeSection = nil
    }
}
