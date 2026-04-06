import SwiftUI

struct GoalSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedGoal: String? = nil
    @State private var navigateToForm = false

    let goals = [
        GoalOption(name: "Retirement", icon: "person.2.fill", color: .purple),
        GoalOption(name: "Education", icon: "book.fill", color: .blue),
        GoalOption(name: "Home Purchase", icon: "house.fill", color: .green),
        GoalOption(name: "Vehicle", icon: "car.fill", color: .orange),
        GoalOption(name: "Travel / Trip", icon: "airplane", color: .cyan),
        GoalOption(name: "Wedding", icon: "heart.fill", color: .pink),
        GoalOption(name: "Wealth Creation", icon: "crown.fill", color: .indigo),
        GoalOption(name: "Business Fund", icon: "briefcase.fill", color: .teal),
        GoalOption(name: "Other Goal", icon: "star.fill", color: .gray)
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                AppTheme.appBackground(for: colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                            ForEach(goals) { goal in
                                GoalGridItem(goal: goal, isSelected: selectedGoal == goal.name) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedGoal = goal.name
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        if let selection = selectedGoal {
                            timelineHint(for: selection)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        Spacer(minLength: 120)
                    }
                    .padding(.top, 20)
                }

                VStack {
                    Spacer()
                    ZStack(alignment: .bottom) {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .frame(height: 180)
                            .mask(LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom))

                        Button(action: {
                            if selectedGoal != nil {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                navigateToForm = true
                            }
                        }) {
                            HStack(spacing: 8) {
                                Text("Set Up My Plan")
                            }
                            .font(.headline).fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(selectedGoal == nil ? Color.gray : Color.blue)
                            .cornerRadius(16)
                            .shadow(color: (selectedGoal == nil ? Color.clear : Color.blue).opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        .disabled(selectedGoal == nil)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 120)
                    }
                }
                .ignoresSafeArea()
            }
            .navigationTitle("Choose Your Goal")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $navigateToForm) {
                if let selection = selectedGoal {
                    NewInvestmentPlanView(initialGoal: selection)
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What are you investing for?")
                .font(.system(size: 24, weight: .bold))
            Text("We'll tailor your investment plan to your goal.")
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
        case "Home Purchase": return "Long-term (5-15 years)"
        case "Vehicle": return "Typically 1-5 years"
        case "Travel / Trip": return "Short-term (6-24 months)"
        case "Wedding": return "Short-term (1-3 years)"
        case "Wealth Creation": return "Open-ended (5+ years)"
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

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(goal.color.opacity(isSelected ? 1.0 : 0.1))
                        .frame(width: 50, height: 50)

                    Image(systemName: goal.icon)
                        .foregroundColor(isSelected ? .white : goal.color)
                        .font(.title3)
                }

                Text(goal.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .white : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
                    .background(isSelected ? Color.black.opacity(0.3) : AppTheme.cardBackground)
            )
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    GoalSelectionView()
}
