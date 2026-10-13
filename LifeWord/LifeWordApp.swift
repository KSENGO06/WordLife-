import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct LifeWordApp: App {
    private let contentRepository = BundledJSONContentRepository()

    init() {
        FontRegistrar.registerBundledFonts()
        FirebaseApp.configure()
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: FirebaseApp.app()?.options.clientID ?? ""
        )
        NotificationManager.configureForegroundPresentation()
    }

    var body: some Scene {
        WindowGroup {
            RootView(contentRepository: contentRepository)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
