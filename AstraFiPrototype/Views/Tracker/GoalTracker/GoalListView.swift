import SwiftUI


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
            VStack(alignment: .leading, spacing: 24) {

                // MARK: Summary strip
                if !goals.isEmpty {
                    HStack(spacing: 0) {
                        GoalSummaryCell(label: "Total Goals", value: "\(goals.count)", icon: "flag.fill", color: .orange)
                        Divider().frame(height: 40)
                        GoalSummaryCell(label: "Active", value: "\(goals.filter { $0.targetDate > Date() }.count)", icon: "checkmark.circle.fill", color: .green)
                        Divider().frame(height: 40)
                        GoalSummaryCell(label: "Completed", value: "\(goals.filter { $0.currentAmount >= $0.targetAmount }.count)", icon: "star.fill", color: .yellow)
                    }
                    .padding(.vertical, 14)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: AppTheme.adaptiveShadow, radius: 6, x: 0, y: 2)
                    .padding(.horizontal)
                }

                // MARK: Header + Filter
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(selectedFilter == .active ? "Active Goals" : "Past Goals")
                            .font(.title3).fontWeight(.bold)
                        Spacer()
                        Picker("Filter", selection: $selectedFilter) {
                            ForEach(GoalFilter.allCases, id: \.self) { f in
                                Text(f.rawValue).tag(f)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 160)
                    }
                    .padding(.horizontal)

                    if filteredGoals.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "flag.slash")
                                .font(.system(size: 34))
                                .foregroundStyle(.secondary)
                            Text("No \(selectedFilter.rawValue.lowercased()) goals")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(40)
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal)
                    } else {

                        // MARK: Card Layout (FIXED)
                        LazyVStack(spacing: 16) {
                            ForEach(filteredGoals) { goal in
                                NavigationLink(destination: GoalDetailView(appState: appState, goalID: goal.id)) {

                                    GoalHealthRow(goal: goal)
                                        .background(AppTheme.cardBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                        .shadow(color: AppTheme.adaptiveShadow, radius: 10, x: 0, y: 4)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 40)
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



#Preview {
    NavigationStack {
        GoalListView()
            .environment(AppStateManager.withSampleData())
    }
}
