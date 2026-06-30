import SwiftUI

struct TrackerGoalsSection: View {
    let goals: [Goal]
    @Environment(AppStateManager.self) var appState

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Goals").font(.auraHeader(size: 22))
                Spacer()
                NavigationLink(destination: GoalListView()) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.auraIndigo)
                }
            }
            .padding(.horizontal, 8)
            if goals.isEmpty {
                TrackerEmptyState(icon: "flag.fill",
                                  message: "No goals set yet. Complete your assessment to start tracking goals.")
            } else {
                VStack(spacing: 12) { 
                    ForEach(Array(goals.prefix(3))) { goal in 
                        NavigationLink(destination: goalDestination(for: goal)) {
                            GoalCard(goal: goal) 
                        }
                        .buttonStyle(PlainButtonStyle())
                    } 
                }
            }
        }
    }

    @ViewBuilder
    private func goalDestination(for trackerGoal: Goal) -> some View {
        if let matchingGoal = appState.currentProfile?.goals.first(where: { $0.goalName == trackerGoal.name }) {
            GoalDetailView(appState: appState, goalID: matchingGoal.id)
        } else {
            Text("Goal not found")
        }
    }
}

struct GoalCard: View {
    let goal: Goal
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.name).font(.auraHeader(size: 17))
                    Text(goal.associatedFund).font(.auraCaption()).foregroundColor(.secondary)
                }
                Spacer()
                Text(goal.targetAmount).font(.auraDigital(size: 18)).foregroundColor(AppTheme.auraIndigo)
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text("Collected").font(.auraCaption()).foregroundColor(.secondary)
                    Spacer()
                    Text(goal.collectedAmount).font(.auraDigital(size: 14)).foregroundColor(AppTheme.auraIndigo)
                }
                
                // Apple-native progress bar
                ProgressView(value: min(max(goal.progress.safeFinite, 0), 1))
                    .progressViewStyle(.linear)
                    .tint(AppTheme.auraIndigo)
            }
        }
        .auraCardStyle(radius: 24)
    }
}

#Preview {
    NavigationStack {
        TrackerGoalsSection(goals: [
            Goal(name: "New Car", associatedFund: "Axis Bluechip", targetAmount: "₹15.0L", collectedAmount: "₹4.5L", timePeriod: "2 Years", progress: 0.3),
            Goal(name: "Home Downpayment", associatedFund: "HDFC Top 100", targetAmount: "₹50.0L", collectedAmount: "₹12.0L", timePeriod: "4 Years", progress: 0.24)
        ])
        .environment(AppStateManager())
        .padding()
    }
}
