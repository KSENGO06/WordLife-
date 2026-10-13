import SwiftUI

/// Що саме скінчилось — серця чи підказки конкретної категорії. Визначає
/// текст і відлік нижнього аркуша `LimitReachedSheetView`.
enum ReachedLimitKind {
    case hearts
    case hints(categoryId: String)

    fileprivate var title: String {
        switch self {
        case .hearts: return "Out of hearts"
        case .hints: return "Out of hints"
        }
    }

    fileprivate var subtitle: String {
        switch self {
        case .hearts: return "No worries - take a short break, or keep going without limits."
        case .hints: return "You've got this without them. Or unlock unlimited hints with Plus."
        }
    }

    fileprivate var countdownLabel: String {
        switch self {
        case .hearts: return "Next heart in"
        case .hints: return "Next hint in"
        }
    }

    fileprivate var timeUntilNext: TimeInterval? {
        switch self {
        case .hearts: return HeartsManager.shared.timeUntilNextHeart
        case .hints(let categoryId): return HintsManager.shared.timeUntilNextHint(for: categoryId)
        }
    }
}

/// Нижній аркуш "скінчились серця" / "скінчились підказки" — з'являється
/// саме в момент, коли ліміт вичерпано: сумний талісман (`mascot_sad`),
/// живий відлік до наступного поповнення, і вибір — почекати чи перейти
/// на Plus. Займає лише половину екрана (`.medium`), а не весь, як у
/// звичайного Paywall.
struct LimitReachedSheetView: View {
    let kind: ReachedLimitKind

    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false
    @State private var bounce = false
    /// Наближена анімація "опускає ручки": mascot_sad — один цілий PNG
    /// (рука не окремий шар, як у .waving), тож справжнього обертання
    /// руки тут не зробити. Замість цього весь талісман трохи "осідає" —
    /// з'являється дещо вищим/напруженим і м'яко опускається в спокійну
    /// позу, що читається як "опустив плечі/руки".
    @State private var slumped = false

    var body: some View {
        VStack(spacing: 10) {
            MascotView(pose: .sad, size: 180)
                .scaleEffect(y: slumped ? 1.0 : 1.07, anchor: .top)
                .offset(y: slumped ? 0 : -8)
                .padding(.top, 8)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.15)) {
                        slumped = true
                    }
                }

            VStack(spacing: 6) {
                Text(kind.title)
                    .font(.custom("PlayfairDisplay-Bold", size: 30))
                    .multilineTextAlignment(.center)
                Text(kind.subtitle)
                    .font(.custom("Inter-Regular", size: 18))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
            
            if let interval = kind.timeUntilNext {
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    let remaining = kind.timeUntilNext ?? interval
                    HStack(spacing: 6) {
                        Text(kind.countdownLabel)
                            .font(.custom("Inter-Medium", size: 16))
                            .foregroundStyle(.secondary)
                        Text(formattedCountdown(remaining))
                            .font(.custom("Inter-SemiBold", size: 22))
                    }
                }
            }

            VStack(spacing: 10) {
                Button("Upgrade to LifeWord Plus") {
                    showPaywall = true
                }
                .buttonStyle(PrimaryButtonStyle(font: .custom("Inter-Bold", size: 20)))
                
                Button(waitButtonTitle) {
                    dismiss()
                }
                .buttonStyle(SecondaryButtonStyle(font: .custom("Inter-Bold", size: 20)))
            }
           
            .padding(.horizontal, 24)
            .padding(.top, 4)

        }
        .frame(maxWidth: .infinity)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear {
            bounce = true
            scheduleRestoreNotificationIfNeeded()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    /// Планує "відновилось" сповіщення саме в момент, коли ліміт
    /// показано користувачу — щоб прийшло навіть якщо застосунок закритий.
    private func scheduleRestoreNotificationIfNeeded() {
        guard let interval = kind.timeUntilNext else { return }
        switch kind {
        case .hearts:
            NotificationManager.scheduleHeartsRestored(after: interval)
        case .hints(let categoryId):
            NotificationManager.scheduleHintsRestored(after: interval, categoryId: categoryId)
        }
    }

    private var waitButtonTitle: String {
        guard let interval = kind.timeUntilNext else { return "Wait" }
        let minutes = max(1, Int((interval / 60).rounded(.up)))
        return "Wait \(minutes) min"
    }

    private func formattedCountdown(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            LimitReachedSheetView(kind: .hearts)
        }
}
