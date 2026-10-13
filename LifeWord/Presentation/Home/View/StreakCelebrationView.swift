import SwiftUI

/// Повноекранний "привіт на новий день" — з'являється раз на день, коли
/// користувач вперше за сьогодні відкриває Home: талісман (mascot_coveringeyes),
/// число стріку, підбадьорлива репліка і коротка статистика внизу.
/// ActivityManager.shared вирішує, чи варто показати
/// (shouldShowStreakCelebration) і фіксує показ (markStreakScreenShown()) —
/// сам екран лише відображає дані.
struct StreakCelebrationView: View {
    let streakCount: Int
    let onContinue: () -> Void

    private var dayWord: String { streakCount == 1 ? "day" : "days" }

    var body: some View {
        VStack(spacing: 14) {
            Spacer()

            sparkleRow

            MascotView(pose: .coveringEyes, size: 190)
                .padding(.top, 4)

            Text("\(streakCount) \(dayWord) in a row!")
                .font(.custom("PlayfairDisplay-Bold", size: 30))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 8)

            Text("You're coming back to English every day. This is already your little rhythm.")
                .font(.custom("Inter-Regular", size: 16))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)

            Spacer()

            Text("\(ActivityManager.shared.sectionsCompletedTotal) exercises completed so far")
                .font(.appBodySmall)
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            Button("Go to lesson") {
                onContinue()
            }
            .buttonStyle(.primary)
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .appScreenBackground()
    }

    private var sparkleRow: some View {
        HStack(spacing: 14) {
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: "sparkle")
                    .font(.system(size: index == 1 ? 15 : 11, weight: .semibold))
                    .foregroundStyle(Color(.systemGray3))
            }
        }
        .padding(.bottom, 8)
    }
}

#Preview {
    StreakCelebrationView(streakCount: 3) {}
}
