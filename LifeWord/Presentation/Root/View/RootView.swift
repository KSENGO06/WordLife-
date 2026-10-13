import SwiftUI

/// Коренева розв'язка: спершу екран завантаження з талісманом, далі —
/// екран входу/реєстрації, якщо користувач не увійшов, інакше — головний
/// каркас застосунку з нижньою панеллю вкладок.
struct RootView: View {
    private let contentRepository: ContentRepository
    @State private var showSplash = true

    init(contentRepository: ContentRepository) {
        self.contentRepository = contentRepository
    }

    var body: some View {
        if showSplash {
            SplashView {
                withAnimation(.easeInOut(duration: 0.4)) {
                    showSplash = false
                }
            }
        } else if AuthManager.shared.isSignedIn {
            MainTabView(contentRepository: contentRepository)
        } else {
            AuthFlowView()
        }
    }
}
