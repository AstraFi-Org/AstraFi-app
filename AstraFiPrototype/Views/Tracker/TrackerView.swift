import SwiftUI
import Charts

struct TrackerView: View {
    @Environment(TrackerViewModel.self) var viewModel
    @Environment(AppStateManager.self) var appState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView(showsIndicators: false) {
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
        .navigationTitle("Tracker")
        .navigationBarTitleDisplayMode(.large)
        .background(AppTheme.appBackground(for: colorScheme))
        .onAppear {
            viewModel.syncWithProfile(appState.currentProfile)
        }
        .onChange(of: appState.currentProfile) { oldProfile, newProfile in
            viewModel.syncWithProfile(newProfile)
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
