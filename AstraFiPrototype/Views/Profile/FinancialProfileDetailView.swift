import SwiftUI

struct FinancialProfileDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(AppStateManager.self) var appState

    @State private var showingEditGoal = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                VStack(alignment: .leading, spacing: 8) {
                    Text("Portfolio Strategy")
                        .font(.headline)
                    Text("Your current strategy is Aggressive,")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("focusing on long-term capital appreciation.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(16)
                .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Active Goals")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    if let goals = appState.currentProfile?.goals, !goals.isEmpty {
                        ForEach(goals) { goal in
                            NavigationLink {
                                GoalDetailView(appState: appState, goalID: goal.id)
                            } label: {
                                FinancialProfileGoalRow(goal: goal)
                            }
                        }
                    } else {
                        Text("No active goals found.")
                            .padding()
                            .foregroundColor(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("Settings")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("Risk Tolerance")
                            Spacer()
                            Text("Aggressive")
                                .foregroundColor(.red)
                        }
                        .padding()
                        Divider()
                        HStack {
                            Text("Investment Horizon")
                            Spacer()
                            Text("10+ Years")
                                .foregroundColor(.blue)
                        }
                        .padding()
                    }
                    .background(AppTheme.cardBackground)
                    .cornerRadius(16)
                }
            }
            .padding()
        }
        .navigationTitle("Financial Profile")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.appBackground(for: colorScheme))
    }
}

private struct FinancialProfileGoalRow: View {
    let goal: AstraGoal

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(goal.goalName)
                    .font(.headline)
                Text("Target: ₹\(Int(goal.targetAmount))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            ProgressView(value: Double(goal.currentAmount), total: Double(goal.targetAmount))
                .frame(width: 100)
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        FinancialProfileDetailView()
            .environment(AppStateManager.withSampleData())
    }
}
