import SwiftUI

private extension Color {
}

private func goalGradient(for name: String) -> [Color] {
    let lower = name.lowercased()
    if lower.contains("home") || lower.contains("house") {
        return [.cyan, .indigo]
    } else if lower.contains("car") || lower.contains("vehicle") {
        return [.orange, .red]
    } else if lower.contains("edu") || lower.contains("study") {
        return [.purple, .purple.opacity(0.8)]
    } else if lower.contains("retire") {
        return [.green, .green]
    } else {
        return [.cyan, .indigo]
    }
}

private func goalIcon(for name: String) -> String {
    let lower = name.lowercased()
    if lower.contains("home") || lower.contains("house") { return "house.fill" }
    if lower.contains("car") || lower.contains("vehicle") { return "car.fill" }
    if lower.contains("edu") || lower.contains("study") { return "graduationcap.fill" }
    if lower.contains("retire") { return "beach.umbrella.fill" }
    return "star.fill"
}

struct GoalListView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppStateManager.self) var appState
    @Environment(\.dismiss) var dismiss
    @State private var selectedFilter: GoalFilter = .active

    enum GoalFilter: String, CaseIterable {
        case active = "Active"
        case inactive = "Inactive"
    }

    private var goals: [AstraGoal] { appState.currentProfile?.goals ?? [] }

    private var filteredGoals: [AstraGoal] {

        let now = Date()
        return goals.filter { goal in
            selectedFilter == .active ? goal.targetDate > now : goal.targetDate <= now
        }
    }

    @State private var showingAddGoal = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Track your goals")
                            .font(.subheadline).foregroundColor(.secondary)
                        HStack(spacing: 6) {
                            Image(systemName: "flag.fill")
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            .orange,
                                            .red
                                        ]),
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                            Text("Your Financial Goals")
                                .font(.title3).fontWeight(.bold)
                        }
                    }
                    Spacer()
                    Menu {
                        ForEach(GoalFilter.allCases, id: \.self) { filter in
                            Button(action: { selectedFilter = filter }) {
                                HStack {
                                    Text(filter.rawValue)
                                    if selectedFilter == filter { Image(systemName: "checkmark") }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(selectedFilter.rawValue).font(.subheadline).fontWeight(.semibold)
                            Image(systemName: "chevron.up.chevron.down").font(.caption2)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .orange,
                                    .red
                                ]),
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                VStack(spacing: 16) {
                    if filteredGoals.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "flag.slash").font(.system(size: 36)).foregroundColor(.secondary)
                            Text("No \(selectedFilter.rawValue.lowercased()) goals")
                                .font(.subheadline).foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity).padding(40)
                        .background(AppTheme.cardBackground).cornerRadius(20)
                    } else {
                        ForEach(filteredGoals) { goal in
                            NavigationLink(destination: GoalDetailView(appState: appState, goalID: goal.id)) {
                                EnhancedGoalDetailCard(goal: goal)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 30)
        }
        .navigationTitle("Goals")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left").fontWeight(.semibold)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingAddGoal = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showingAddGoal) {
            AddGoalView()
        }
        .background(AppTheme.appBackground(for: colorScheme).ignoresSafeArea())
    }
}

struct EnhancedGoalDetailCard: View {
    let goal: AstraGoal

    private var gradient: [Color] { goalGradient(for: goal.goalName) }
    private var icon: String       { goalIcon(for: goal.goalName) }
    private var progress: Double   { goal.currentAmount / max(goal.targetAmount, 1) }

    private var df: DateFormatter {
        let f = DateFormatter(); f.dateStyle = .medium; return f
    }

    var body: some View {
        VStack(spacing: 0) {

            ZStack {
                LinearGradient(gradient: Gradient(colors: gradient),
                               startPoint: .leading, endPoint: .trailing)
                    .frame(height: 70)
                    .shadow(color: AppTheme.adaptiveShadow, radius: 10, x: 0, y: 4)

                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.3)).frame(width: 50, height: 50)
                        Image(systemName: icon).font(.title2).foregroundColor(.white)
                    }
                    Text(goal.goalName).font(.title2).fontWeight(.bold).foregroundColor(.white)
                    Spacer()
                    VStack(spacing: 2) {
                        Text("\(Int(min(progress, 1) * 100))%")
                            .font(.title3).fontWeight(.bold).foregroundColor(.white)
                        Text("Complete").font(.caption2).foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Color.white.opacity(0.25)).cornerRadius(12)
                }
                .padding(.horizontal, 20)
            }

            VStack(spacing: 14) {
                EnhancedGoalsDetailRow(label: "Target Amount",   value: goal.targetAmount.toCurrency(), gradient: gradient, isHighlighted: true)
                Divider()
                EnhancedGoalsDetailRow(label: "Collected",       value: goal.currentAmount.toCurrency(),
                                       gradient: [.gray,
                                                  .green])
                Divider()
                EnhancedGoalsDetailRow(label: "Target Date",     value: df.string(from: goal.targetDate), gradient: gradient)
                Divider()

                VStack(spacing: 6) {
                    HStack {
                        Text("Progress").font(.subheadline).foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.1f%%", min(progress, 1) * 100))
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundStyle(LinearGradient(gradient: Gradient(colors: gradient),
                                                            startPoint: .leading, endPoint: .trailing))
                    }
                    ProgressView(value: min(progress, 1))
                        .progressViewStyle(.linear)
                        .tint(gradient.first ?? AppTheme.auraIndigo)
                }
            }
            .padding(20)
            .background(AppTheme.cardBackground)
        }
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow, radius: 15, x: 0, y: 5)
    }
}

struct EnhancedGoalsDetailRow: View {
    let label: String
    let value: String
    let gradient: [Color]
    var isHighlighted: Bool = false

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(LinearGradient(gradient: Gradient(colors: gradient),
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 8, height: 8)
                Text(label).font(.subheadline).foregroundColor(.secondary)
            }
            Spacer()
            Text(value)
                .font(isHighlighted ? .title3 : .subheadline)
                .fontWeight(isHighlighted ? .bold : .semibold)
                .foregroundStyle(
                    isHighlighted
                        ? LinearGradient(gradient: Gradient(colors: gradient), startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(gradient: Gradient(colors: [.primary, .primary]), startPoint: .leading, endPoint: .trailing)
                )
        }
    }
}

#Preview {
    NavigationStack {
        GoalListView()
            .environment(AppStateManager())
    }
}
