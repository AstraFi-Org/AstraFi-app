import SwiftUI

struct FinancialProfileDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(AppStateManager.self) var appState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let basic = appState.currentProfile?.basicDetails {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Portfolio Strategy")
                            .font(.headline)
                        Text("Your current strategy is \(basic.riskTolerance.rawValue),")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("with a \(basic.investmentHorizon.rawValue) investment horizon.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(16)
                    .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("Active Goals")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    if let goals = appState.currentProfile?.goals, !goals.isEmpty {
                        ForEach(goals) { goal in
                            // FIXED BUG 2: GoalDetailView does not exist in the project.
                            // Replaced with a non-crashing plain row until GoalDetailView is built.
                            FinancialProfileGoalRow(goal: goal)
                        }
                    } else {
                        Text("No active goals found.")
                            .padding()
                            .foregroundColor(.secondary)
                    }
                }

                // FIXED BUG 3: Was hardcoded "Aggressive" / "10+ Years" — now reads live from profile
                if let basic = appState.currentProfile?.basicDetails {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Settings")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text("Risk Tolerance")
                                Spacer()
                                Text(basic.riskTolerance.rawValue)
                                    .foregroundColor(riskColor(for: basic.riskTolerance))
                            }
                            .padding()
                            Divider()
                            HStack {
                                Text("Investment Horizon")
                                Spacer()
                                Text(basic.investmentHorizon.rawValue)
                                    .foregroundColor(.blue)
                            }
                            .padding()
                        }
                        .background(AppTheme.cardBackground)
                        .cornerRadius(16)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Financial Profile")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.appBackground(for: colorScheme))
    }

    // FIXED BUG 3 (helper): Dynamic color based on actual risk level
    private func riskColor(for tolerance: AstraRiskTolerance) -> Color {
        switch tolerance {
        case .low:    return .green
        case .medium: return .orange
        case .high:   return .red
        }
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
            // FIXED BUG 4: ProgressView crashes when targetAmount is 0 (division by zero).
            // Guard added so progress only shows when targetAmount > 0.
            if goal.targetAmount > 0 {
                ProgressView(value: min(goal.currentAmount, goal.targetAmount),
                             total: goal.targetAmount)
                    .frame(width: 100)
            }
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
