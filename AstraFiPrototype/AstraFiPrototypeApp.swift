import SwiftUI

@main
struct AstraFiPrototypeApp: App {
    @State private var appState = AppStateManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(appState)
                .task {
                    Secrets.printConfigurationStatus()
                    await InvestmentIntelligenceRepository().warmHomeAssets()
                }
                .onOpenURL { url in
                    Task {
                        await UpstoxViewModel.shared.handleRedirect(url)
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .background {
                        let biometricEnabled = UserDefaults.standard.bool(forKey: "securityBiometricUnlockEnabled")
                        let requireOnLaunch = UserDefaults.standard.object(forKey: "securityRequireUnlockOnLaunch") as? Bool ?? true

                        if biometricEnabled && requireOnLaunch && appState.showDashboard {
                            appState.isLockedByBiometric = true
                        }
                    }
                }
        }
    }
}
