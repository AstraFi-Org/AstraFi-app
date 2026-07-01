import SwiftUI

struct AppRootView: View {
    @Environment(AppStateManager.self) var appState
    @FocusState private var isAnyFieldFocused: Bool
    @State private var showingMonthlyAssessmentPrompt = false
    @State private var showingMonthlyAssessment = false
    @State private var promptedMonthlyAssessmentKey: String?

    var body: some View {
        Group {
            if appState.isLoading {
                SplashScreenView()

            } else if appState.isLockedByBiometric {
                BiometricLockScreenView()

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
        .sheet(isPresented: $showingMonthlyAssessmentPrompt) {
            MonthlyAssessmentPromptSheet {
                showingMonthlyAssessmentPrompt = false
                showingMonthlyAssessment = true
            }
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showingMonthlyAssessment) {
            StartAssesmentView(
                mode: .update,
                prefilledData: appState.currentProfile.map(CompleteAssessmentData.prefilled(from:))
            )
        }
        .onAppear {
            presentMonthlyAssessmentIfNeeded()
        }
        .onChange(of: appState.showDashboard) { _, _ in
            presentMonthlyAssessmentIfNeeded()
        }
        .onChange(of: appState.currentProfile) { _, _ in
            if appState.hasCompletedMonthlyAssessment() {
                showingMonthlyAssessmentPrompt = false
                showingMonthlyAssessment = false
            } else {
                presentMonthlyAssessmentIfNeeded()
            }
        }
        .animation(.easeInOut(duration: 0.4), value: appState.isLoading)
        .animation(.easeInOut(duration: 0.35), value: appState.isLockedByBiometric)
        .animation(.easeInOut(duration: 0.35), value: appState.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.35), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.35), value: appState.showDashboard)
    }

    private func presentMonthlyAssessmentIfNeeded() {
        guard appState.showDashboard,
              !appState.isLoading,
              !appState.isLockedByBiometric,
              !appState.requiresMFAChallenge,
              !appState.showPostAuthOnboarding,
              appState.shouldPresentMonthlyAssessmentOnLaunch()
        else { return }

        let key = Self.currentMonthKey()
        guard promptedMonthlyAssessmentKey != key else { return }

        promptedMonthlyAssessmentKey = key
        showingMonthlyAssessmentPrompt = true
    }

    private static func currentMonthKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }
}

struct MonthlyAssessmentPromptSheet: View {
    let onStart: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppTheme.auraIndigo.opacity(0.12))
                    .frame(width: 68, height: 68)
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(AppTheme.auraIndigo)
            }

            VStack(spacing: 8) {
                Text("Monthly assessment due")
                    .font(.system(size: 22, weight: .bold))
                Text("Refresh this month's income, expenses, investments, loans, and insurance to keep your health report current.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Text("Later")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(Capsule())
                }

                Button {
                    onStart()
                } label: {
                    Text("Start Assessment")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.auraIndigo)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(24)
    }
}
