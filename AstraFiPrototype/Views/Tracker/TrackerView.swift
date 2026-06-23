import SwiftUI
import Charts

struct TrackerView: View {
    @Environment(TrackerViewModel.self) var viewModel
    @Environment(AppStateManager.self) var appState
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var upstoxViewModel = UpstoxViewModel.shared

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.auraInterCardSpacing + 2) {
                NetWorthCard(
                    netWorth: viewModel.netWorth,
                    growthAmount: viewModel.growthAmount,
                    accounts: viewModel.accounts,
                    annualGrowthRate: viewModel.portfolioCAGR,
                    monthlySurplus: viewModel.monthlySurplus,
                    monthlyEMI: viewModel.totalMonthlyEMI
                )

                if upstoxViewModel.isConnected {
                    UpstoxHoldingsSyncBanner(
                        isSyncing: upstoxViewModel.isSyncingHoldings,
                        holdingsCount: upstoxViewModel.holdings.count + upstoxViewModel.mutualFundHoldings.count,
                        message: upstoxViewModel.holdingsSyncMessage,
                        onRefresh: {
                            Task { await syncUpstoxInvestments() }
                        }
                    )
                }

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
            viewModel.appState = appState
            viewModel.syncWithProfile(appState.currentProfile)
        }
        .task {
            await syncUpstoxInvestments()
        }
        .onChange(of: upstoxViewModel.isConnected) { _, isConnected in
            if isConnected {
                Task { await syncUpstoxInvestments() }
            } else {
                appState.removeUpstoxHoldings()
                viewModel.syncWithProfile(appState.currentProfile)
            }
        }
        .onChange(of: appState.currentProfile) { oldProfile, newProfile in
            viewModel.appState = appState
            viewModel.syncWithProfile(newProfile)
        }
        .onChange(of: appState.savedPlans) { _, newPlans in
            viewModel.yourPlans = newPlans
            viewModel.savedPlanNames = Set(newPlans.map { $0.name })
            viewModel.followedPlanNames = Set(newPlans.filter { $0.isFollowed }.map { $0.name })
        }
    }

    private func syncUpstoxInvestments() async {
        guard upstoxViewModel.isConnected else { return }
        let investments = await upstoxViewModel.fetchConnectedInvestments()
        appState.syncUpstoxHoldings(
            investments.equity,
            mutualFunds: investments.mutualFunds,
            mutualFundOrders: investments.mutualFundOrders,
            mutualFundSIPs: investments.mutualFundSIPs
        )
        viewModel.appState = appState
        viewModel.syncWithProfile(appState.currentProfile)
    }
}

private struct UpstoxHoldingsSyncBanner: View {
    let isSyncing: Bool
    let holdingsCount: Int
    let message: String?
    let onRefresh: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSyncing ? "arrow.triangle.2.circlepath" : "externaldrive.connected.to.line.below")
                .font(.headline)
                .foregroundColor(.green)
                .frame(width: 34, height: 34)
                .background(Color.green.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(isSyncing ? "Syncing Upstox investments" : "Upstox connected")
                    .font(.auraBody(size: 15, weight: .semibold))
                Text(message ?? "\(holdingsCount) connected investment\(holdingsCount == 1 ? "" : "s") ready")
                    .font(.auraCaption(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
                    .font(.headline)
            }
            .buttonStyle(.bordered)
            .disabled(isSyncing)
        }
        .padding(14)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
    }
}


#Preview {
    NavigationStack {
        TrackerView()
            .environment(TrackerViewModel())
            .environment(AppStateManager())
    }
}
