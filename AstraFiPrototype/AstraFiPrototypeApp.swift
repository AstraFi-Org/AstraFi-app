import SwiftUI

@main
struct AstraFiPrototypeApp: App {
    @State private var appState = AppStateManager()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(appState)
                .task {
                    await InvestmentIntelligenceRepository().warmHomeAssets()
                }
                .onOpenURL { url in
                    Task {
                        await UpstoxViewModel.shared.handleRedirect(url)
                    }
                }
        }
    }
}
