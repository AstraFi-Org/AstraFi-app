import SwiftUI

struct GoalSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedGoal: String? = nil
    @State private var navigateToForm = false
    private let reviewJourneyFirst: Bool
    private let initialGoal: String?
    private let initialGoalTitle: String?

    init(reviewJourneyFirst: Bool = true, initialGoal: String? = nil, initialGoalTitle: String? = nil) {
        self.reviewJourneyFirst = reviewJourneyFirst
        self.initialGoal = initialGoal
        self.initialGoalTitle = initialGoalTitle
        self._selectedGoal = State(initialValue: initialGoal)
    }

    let goals = [
        GoalOption(name: "Retirement", icon: "person.2.fill", color: .purple),
        GoalOption(name: "Education", icon: "book.fill", color: .blue),
        GoalOption(name: "Home", icon: "house.fill", color: .green),
        GoalOption(name: "Vehicle", icon: "car.fill", color: .orange),
        GoalOption(name: "Travel", icon: "airplane", color: .cyan),
        GoalOption(name: "Marriage", icon: "heart.fill", color: .pink),
        GoalOption(name: "Children", icon: "figure.2.and.child.holdinghands", color: .orange),
        GoalOption(name: "Build Wealth", icon: "chart.line.uptrend.xyaxis", color: .indigo),
        GoalOption(name: "Family", icon: "figure.2", color: .teal),
        GoalOption(name: "Business Fund", icon: "briefcase.fill", color: .teal),
        GoalOption(name: "Custom Goal", icon: "star.fill", color: .gray)
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.appBackground(for: colorScheme)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3), spacing: 14) {
                        ForEach(goals) { goal in
                            GoalGridItem(goal: goal, isSelected: selectedGoal == goal.name) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedGoal = goal.name
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    if let selection = selectedGoal {
                        timelineHint(for: selection)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 16)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    Button(action: {
                        if selectedGoal != nil {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            navigateToForm = true
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text("Start Plan")
                            Image(systemName: "arrow.right")
                        }
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            selectedGoal == nil ? AnyShapeStyle(Color.gray.opacity(0.4)) : AnyShapeStyle(AppTheme.accentGradient),
                            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                        )
                        .shadow(color: (selectedGoal == nil ? Color.clear : Color.blue).opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                    .disabled(selectedGoal == nil)
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                }
                .background(.ultraThinMaterial)
            }
        }
        .navigationTitle("Choose Your Goal")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToForm) {
            if let selection = selectedGoal {
                NewInvestmentPlanView(
                    initialGoal: selection == initialGoal ? (initialGoalTitle ?? selection) : selection,
                    reviewJourneyFirst: reviewJourneyFirst
                )
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What are you investing for?")
                .font(.system(size: 24, weight: .bold))
            Text("We'll tailor your investment strategy to your goal.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private func timelineHint(for goal: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.fill")
                .foregroundColor(.orange)
            Text(hintText(for: goal))
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(20)
        .padding(.leading, 24)
    }

    private func hintText(for goal: String) -> String {
        switch goal {
        case "Retirement": return "Long-term (15+ years)"
        case "Education": return "Mid-term (3-10 years)"
        case "Home", "Home Purchase": return "Long-term (5-15 years)"
        case "Vehicle": return "Typically 1-5 years"
        case "Travel", "Travel / Trip": return "Short-term (6-24 months)"
        case "Marriage", "Wedding": return "Short-term (1-3 years)"
        case "Build Wealth", "Wealth Creation": return "Open-ended (5+ years)"
        default: return "Flexible Timeline"
        }
    }
}

struct GoalOption: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
}

struct GoalGridItem: View {
    let goal: GoalOption
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(goal.color.opacity(isSelected ? 0.95 : 0.12))
                        .frame(width: 48, height: 48)

                    Image(systemName: goal.icon)
                        .foregroundColor(isSelected ? .white : goal.color)
                        .font(.system(size: 20, weight: .semibold))
                }

                Text(goal.name)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? Color.blue : Color.primary.opacity(0.06), lineWidth: isSelected ? 2 : 1)
                    .background(isSelected ? selectedBackground : AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .shadow(color: isSelected ? Color.blue.opacity(0.15) : Color.black.opacity(0.03), radius: isSelected ? 8 : 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var selectedBackground: Color {
        colorScheme == .dark ? AppTheme.elevatedCardBackground : Color.blue.opacity(0.08)
    }
}

#Preview {
    GoalSelectionView()
}
