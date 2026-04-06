import SwiftUI
import Charts

struct TrackerView: View {
    @Environment(TrackerViewModel.self) var viewModel
    @Environment(AppStateManager.self) var appState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
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
                TrackerMoneyFlowSection(moneyFlowData: viewModel.moneyFlowData)
                TrackerFundAllocationSection(allocations: viewModel.fundAllocations)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
        .background(AppTheme.appBackground(for: colorScheme))
        .navigationTitle("Tracker")
        .navigationBarTitleDisplayMode(.large)
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

