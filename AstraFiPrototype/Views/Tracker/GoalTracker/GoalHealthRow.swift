//
//  GoalHealthRow.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI

private func goalGradient(for name: String) -> [Color] {
    let lower = name.lowercased()
    if lower.contains("home") || lower.contains("house") { return [.cyan, .indigo] }
    else if lower.contains("car") || lower.contains("vehicle") { return [.orange, .red] }
    else if lower.contains("edu") || lower.contains("study") { return [.purple, .purple.opacity(0.8)] }
    else if lower.contains("retire") { return [.green, .teal] }
    else { return [.cyan, .indigo] }
}

private func goalIcon(for name: String) -> String {
    let lower = name.lowercased()
    if lower.contains("home") || lower.contains("house") { return "house.fill" }
    if lower.contains("car") || lower.contains("vehicle") { return "car.fill" }
    if lower.contains("edu") || lower.contains("study") { return "graduationcap.fill" }
    if lower.contains("retire") { return "beach.umbrella.fill" }
    return "star.fill"
}


struct GoalHealthRow: View {
    let goal: AstraGoal

    private var gradient: [Color] { goalGradient(for: goal.goalName) }
    private var icon: String { goalIcon(for: goal.goalName) }
    private var progress: Double {
        let value = goal.currentAmount / max(goal.targetAmount, 1)
        return min(max(value.safeFinite, 0), 1)
    }

    private var df: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Top row
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .foregroundColor(.white)
                }

                Text(goal.goalName)
                    .font(.headline)
                    .foregroundStyle(
                        LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing)
                    )

                Spacer()

                Text(df.string(from: goal.targetDate))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Amount row
            HStack {
                Text(goal.currentAmount.toCurrency())
                    .font(.title2)
                    .fontWeight(.bold)

                Text("of \(goal.targetAmount.toCurrency())")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\((progress * 100).safeInt)%")
                    .foregroundColor(gradient.first)
                    .fontWeight(.semibold)
            }

            // Progress
            ProgressView(value: progress)
                .tint(gradient.first)
                .scaleEffect(x: 1, y: 1.5)
        }
        .padding(16)
    }
}


#Preview {
    GoalHealthRow(
        goal: AstraGoal(
            id: UUID(),
            goalName: "Home Purchase",
            targetAmount: 7200000,
            currentAmount: 34000,
            targetDate: Calendar.current.date(byAdding: .year, value: 3, to: Date())!
        )
    )
    .padding()
    .background(Color(uiColor: .systemGroupedBackground))
}
