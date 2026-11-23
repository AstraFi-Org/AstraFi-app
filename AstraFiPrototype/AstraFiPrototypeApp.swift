import SwiftUI
import UserNotifications

final class AstraAppDelegate: NSObject, UIApplicationDelegate {
    private let notificationDelegate = AstraNotificationDelegate()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = notificationDelegate
        return true
    }
}

@main
struct AstraFiPrototypeApp: App {
    @UIApplicationDelegateAdaptor(AstraAppDelegate.self) private var appDelegate
    
    @State private var appState: AppStateManager = {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-useSampleData") {
            return AppStateManager.withSampleData()
        }
        return AppStateManager()
        #else
        return AppStateManager()
        #endif
    }()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(appState)
                .task {
                    Secrets.printConfigurationStatus()
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

                    // Request notification permission and schedule real-time reminders
                    _ = await AstraNotificationManager.shared.requestPermission()
                    if let profile = appState.currentProfile {
                        AstraNotificationManager.shared.scheduleAllNotifications(
                            for: profile,
                            assessmentDue: appState.isMonthlyAssessmentDue()
                        )
                    }
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
                    } else if newPhase == .active {
                        if let profile = appState.currentProfile {
                            AstraNotificationManager.shared.scheduleAllNotifications(
                                for: profile,
                                assessmentDue: appState.isMonthlyAssessmentDue()
                            )
                        }
                    }
                }
        }
    }
}
