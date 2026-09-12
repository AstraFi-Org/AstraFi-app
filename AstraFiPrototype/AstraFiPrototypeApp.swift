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
                    #if DEBUG
                    let insuranceCases = InsuranceAnalysisVerification.run()
                    let failed = insuranceCases.filter { !$0.passed }
                    print("=== INSURANCE ANALYSIS VERIFICATION: \(insuranceCases.count) CASES ===")
                    for res in insuranceCases {
                        print("  \(res.passed ? "✅ PASS" : "❌ FAIL"): \(res.name) (\(res.detail))")
                    }
                    assert(failed.isEmpty, "InsuranceAnalysisVerification failed: \(failed.map { "\($0.name): \($0.detail)" })")
                    assert(FinancialHealthScoringVerification.allPassed(), "FinancialHealthScoringVerification failed")
                    #endif
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
