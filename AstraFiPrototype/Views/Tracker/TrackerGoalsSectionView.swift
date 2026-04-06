import SwiftUI

struct TrackerGoalsSection: View {
    let goals: [Goal]
    @Environment(AppStateManager.self) var appState

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Your Goals").font(.system(size: 22, weight: .bold))
                Spacer()
                NavigationLink(destination: GoalsView()) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.accentColor)
                }
            }
            if goals.isEmpty {
                TrackerEmptyState(icon: "flag.fill",
                                  message: "No goals set yet. Complete your assessment to start tracking goals.")
            } else {
                VStack(spacing: 12) { 
                    ForEach(goals) { goal in 
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
        VStack(spacing: 12) {
            HStack {
                Text(goal.name)
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
            }
            VStack(spacing: 8) {
                GoalSummaryDetailedRow(label: "Associated fund", value: goal.associatedFund)
                GoalSummaryDetailedRow(label: "Target Amt", value: goal.targetAmount)
                GoalSummaryDetailedRow(label: "Collected Amt", value: goal.collectedAmount)
                GoalSummaryDetailedRow(label: "Time Period", value: goal.timePeriod)
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: AppTheme.adaptiveShadow, radius: 4, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        TrackerGoalsSection(goals: [
            Goal(name: "New Car", associatedFund: "Axis Bluechip", targetAmount: "₹15.0L", collectedAmount: "₹4.5L", timePeriod: "2 Years"),
            Goal(name: "Home Downpayment", associatedFund: "HDFC Top 100", targetAmount: "₹50.0L", collectedAmount: "₹12.0L", timePeriod: "4 Years")
        ])
        .environment(AppStateManager())
        .padding()
    }
}
