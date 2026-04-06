import SwiftUI

struct GoalRow: View {
    let goal: AstraGoal
    let isSetuConnected: Bool
    @Environment(AppStateManager.self) var appState
    @Binding var editingGoal: AstraGoal?

    var body: some View {
        HStack(alignment: .top) {
            goalInfo
            if !isSetuConnected {
                editBtn
            }
        }
        .padding(.vertical, 8)
    }

    private var goalInfo: some View {
        let currentAmt = appState.totalCollected(for: goal.id)
        let progress = goal.targetAmount > 0 ? min(1, currentAmt / goal.targetAmount) : 0.0
        let linked = appState.currentProfile?.investments.filter { $0.associatedGoalID == goal.id } ?? []
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(goal.goalName).font(.headline)
                Spacer()
                Text(goal.targetAmount.toCurrency()).font(.subheadline).fontWeight(.bold)
            }
            ProgressView(value: progress).tint(.blue)
            HStack {
                Text("\(currentAmt.toCurrency()) saved")
                Spacer()
                Text("\(Int(progress * 100))%")
            }
            .font(.caption).foregroundColor(.secondary)
            Text("Target: \(goal.targetDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption2).foregroundColor(.secondary)
            if !linked.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 3) {
                    Text("Linked Investments").font(.caption2).fontWeight(.semibold).foregroundColor(.secondary)
                    ForEach(linked) { inv in
                        HStack {
                            Image(systemName: inv.mode == .sip ? "repeat.circle.fill" : "arrow.down.circle.fill")
                                .font(.caption2).foregroundColor(.blue)
                            Text(inv.investmentName)
                                .font(.caption2)
                            Spacer()
                            Text(inv.mode == .sip ? "SIP ₹\(Int(inv.investmentAmount))/mo" : inv.investmentAmount.toCurrency())
                                .font(.caption2).foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var editBtn: some View {
        Button { editingGoal = goal } label: {
            Image(systemName: "pencil.circle.fill").font(.title3).foregroundColor(.blue)
        }
        .buttonStyle(.plain).padding(.leading, 8)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var editingGoal: AstraGoal? = nil
        let goal = AstraGoal(goalName: "New House", targetAmount: 5000000, currentAmount: 1200000, targetDate: Date().addingTimeInterval(86400 * 365 * 5))

        var body: some View {
            List {
                GoalRow(goal: goal, isSetuConnected: false, editingGoal: $editingGoal)
                    .environment(AppStateManager.withSampleData())
            }
        }
    }
    return PreviewWrapper()
}
