import SwiftUI

/// Пропозиція підписки — з'являється, коли закінчились серця/підказки, або
/// коли людина сама тисне "Go to LifeWord Plus" у профілі.
///
/// Купівля зараз локальна заглушка (PremiumManager.purchase()) — справжній
/// StoreKit підключимо, коли буде готовий продукт в App Store Connect, тож
/// тут поки нема реальних цін, лише вибір плану (місяць/рік).
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    private enum Plan: Equatable {
        case monthly
        case yearly
    }

    @State private var selectedPlan: Plan = .yearly

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header

                MascotView(pose: .loading, size: 176)
                    .padding(.top, 4)

                VStack(spacing: 10) {
                    Text("Learn without limits")
                        .font(AppFont.playfairBold(30))
                        .multilineTextAlignment(.center)
                    Text("Stay in the flow — no running out of hearts or hints.")
                        .font(.appBodyRegular)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 28)

                featureCard

                planPicker

                // TODO: коли підключимо StoreKit — тут має викликатись реальна
                // покупка і PremiumManager.shared.purchase(). Поки що просто
                // закриває екран назад (без увімкнення преміуму), щоб його
                // можна було відкривати для перевірки дизайну скільки завгодно
                // разів, не скидаючи вручну підписку щоразу.
                Button("Start with LifeWord Plus") {
                    dismiss()
                }
                .buttonStyle(.primary)
                .padding(.horizontal, 20)

                Text("You'll be able to review the subscription terms and price before confirming.")
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 12)
            }
        }
        .appScreenBackground()
    }

    // MARK: - Шапка

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.appAccent)
                    .frame(width: 32, height: 32)
            }

            Spacer(minLength: 0)

            Text("LifeWord Plus")
                .font(.appTitleM)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 0)

            // Порожній простір того ж розміру, що й кнопка зліва — щоб
            // заголовок справді був по центру, а не зміщений праворуч.
            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Переваги підписки

    private var featureCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            benefitRow(icon: "infinity", text: "Unlimited hearts — no waiting to refill")
            benefitRow(icon: "lightbulb.fill", text: "Unlimited hints in every category")
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
        .padding(.horizontal, 20)
    }

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.appAccent)
                .frame(width: 24)
            Text(text)
                .font(.appBodyRegular)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Вибір плану

    // Поки заглушка — реальні ціни (і, можливо, локальна валюта) підтягнуться
    // самі, коли підключимо StoreKit-продукти з App Store Connect.
    private var planPicker: some View {
        HStack(spacing: 12) {
            planCard(title: "Monthly", price: "$4.99", priceSuffix: "/mo", subtitle: "Cancel anytime", isSelected: selectedPlan == .monthly) {
                selectedPlan = .monthly
            }
            planCard(title: "Yearly", price: "$29.99", priceSuffix: "/yr", subtitle: "Best value plan", isSelected: selectedPlan == .yearly) {
                selectedPlan = .yearly
            }
        }
        .padding(.horizontal, 20)
    }

    private func planCard(title: String, price: String, priceSuffix: String, subtitle: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.appCaption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)

                (Text(price).font(AppFont.interBold(20)) + Text(priceSuffix).font(.appCaption))
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(subtitle)
                    .font(.appCaption)
                    .foregroundStyle(isSelected ? .white.opacity(0.85) : .secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? Color.appAccent : Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(isSelected ? Color.clear : Color.appAccent.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
