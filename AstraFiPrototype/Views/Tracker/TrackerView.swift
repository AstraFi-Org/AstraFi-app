import SwiftUI
import Charts

struct TrackerView: View {
    @Environment(TrackerViewModel.self) var viewModel
    @Environment(AppStateManager.self) var appState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                auraHeaderView
                    .padding(.horizontal, AppTheme.auraPadding)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                VStack(spacing: AppTheme.auraInterCardSpacing + 2) {
                    NetWorthCard(
                        netWorth: viewModel.netWorth,
                        growthAmount: viewModel.growthAmount,
                        accounts: viewModel.accounts
                    )

                    TrackerInvestmentsSection(investments: viewModel.investments)

                    if !viewModel.yourPlans.isEmpty {
                        TrackerYourPlansSection(plans: viewModel.yourPlans)
                    }

                    TrackerGoalsSection(goals: viewModel.goals)
                    TrackerLoansSection()
                    TrackerMoneyFlowSection()
                    TrackerFundAllocationSection(allocations: viewModel.fundAllocations)
                }
                .padding(.horizontal, AppTheme.auraPadding)
                .padding(.bottom, 40)
            }
        }
        .background(AppTheme.appBackground(for: colorScheme))
        .navigationBarHidden(true)
        .onAppear {
            viewModel.syncWithProfile(appState.currentProfile)
        }
        .onChange(of: appState.currentProfile) { oldProfile, newProfile in
            viewModel.syncWithProfile(newProfile)
        }
    }

    // MARK: - Header
    private var auraHeaderView: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Tracker")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("Your financial pulse")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Spacer()

        }
    }
}


#Preview {
    NavigationStack {
        TrackerView()
            .environment(TrackerViewModel())
            .environment(AppStateManager())
    }
}
