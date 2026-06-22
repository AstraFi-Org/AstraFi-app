import SwiftUI

struct AppRootView: View {
    @Environment(AppStateManager.self) var appState
    @FocusState private var isAnyFieldFocused: Bool

    var body: some View {
        Group {
            if appState.isLoading {
                SplashScreenView()

            } else if appState.requiresMFAChallenge {
                MFAChallengeView()

            } else if appState.showPostAuthOnboarding {
                PostAuthOnboardingView()

            } else if appState.showDashboard {
                FinalTab()

            } else if appState.isAuthenticated {
                StartAssesmentView()

            } else if appState.hasCompletedOnboarding {
                NavigationStack {
                    AuthenticationFlowView()
                }

            } else {
                OnboardingPagesView()
            }
        }
        .animation(.easeInOut(duration: 0.4), value: appState.isLoading)
        .animation(.easeInOut(duration: 0.35), value: appState.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.35), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.35), value: appState.showDashboard)
    }
}
