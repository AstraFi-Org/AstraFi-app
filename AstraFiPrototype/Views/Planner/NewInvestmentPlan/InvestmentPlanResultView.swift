import SwiftUI

struct InvestmentPlanResultView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppStateManager.self) var appState
    
    var input: InvestmentPlanInputModel
    
    private var results: FullPlanResult {
        InvestmentPlannerEngine.generateFullPlan(
            input: input,
            profile: appState.currentProfile
        )
    }
    
    private var isLoanEligibleGoal: Bool {
        let excluded = ["Retirement", "Wealth Creation"]
        return !excluded.contains(input.purposeOfInvestment)
    }
    
    var body: some View {
        selectionView
            .navigationTitle("\(results.goalCategory.rawValue) Strategy")
            .navigationBarTitleDisplayMode(.inline)
            .background(AppTheme.appBackground(for: colorScheme))
    }
    
    private var selectionView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Message
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 32))
                        .foregroundStyle(.purple)
                    
                    Text("We've Analyzed Your Path")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    
                    let targetVal = Double(input.targetAmount.replacingOccurrences(of: ",", with: "")) ?? 0
                    Text("Based on your target of ₹\(targetVal >= 100000 ? String(format: "%.1fL", targetVal / 100000) : input.targetAmount), we've identified distinct financial strategies. Which one would you like to explore?")
                        .font(.system(size: 15, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                }
                .padding(.top, 30)
                
                // Plan Options
                VStack(spacing: 16) {
                    // Plan 1: SIP
                    NavigationLink(destination: Plan1DetailView(input: input, result: results.plan1)) {
                        StrategySelectionCard(
                            id: 1,
                            title: "SIP with Diversification",
                            subtitle: "Build your corpus through systematic investing across diversified assets.",
                            icon: "chart.line.uptrend.xyaxis.circle.fill",
                            color: .blue,
                            isRecommended: false
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Plan 3: Loan + Invest (Arbitrage)
                    if isLoanEligibleGoal {
                        if let p3 = results.plan3 {
                            NavigationLink(destination: Plan3DetailView(input: input, result: p3)) {
                                StrategySelectionCard(
                                    id: 3,
                                    title: "Loan & Arbitrage Strategy",
                                    subtitle: "Take a loan and invest the principal such that returns cover the EMI while building long-term wealth.",
                                    icon: "arrow.up.right.circle.fill",
                                    color: .purple,
                                    isRecommended: true
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            NavigationLink(destination: noPlanWarning(message: "Arbitrage strategy requires a higher credit surplus.")) {
                                StrategySelectionCard(
                                    id: 3,
                                    title: "Loan & Arbitrage Strategy",
                                    subtitle: "Take a loan and invest the principal such that returns cover the EMI while building long-term wealth.",
                                    icon: "arrow.up.right.circle.fill",
                                    color: .purple,
                                    isRecommended: true
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Plan 2: Traditional Loan
                        if let p2 = results.plan2 {
                            NavigationLink(destination: Plan2DetailView(input: input, result: p2)) {
                                StrategySelectionCard(
                                    id: 2,
                                    title: "Traditional \(results.goalCategory.rawValue) Loan",
                                    subtitle: "A straightforward loan with flexible repayment options tailored for your goal.",
                                    icon: "banknote.fill",
                                    color: .orange,
                                    isRecommended: false
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            NavigationLink(destination: noPlanWarning(message: "Traditional loan not recommended for your current profile.")) {
                                StrategySelectionCard(
                                    id: 2,
                                    title: "Traditional \(results.goalCategory.rawValue) Loan",
                                    subtitle: "A straightforward loan with flexible repayment options tailored for your goal.",
                                    icon: "banknote.fill",
                                    color: .orange,
                                    isRecommended: false
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // Compare All Plans Button
                NavigationLink(destination: PlanComparisonView(input: input, results: results)) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.left.arrow.right.circle.fill")
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Compare All Plans")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("See a detailed 3-way side-by-side comparison")
                                .font(.caption)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.subheadline)
                    }
                    .foregroundColor(.white)
                    .padding(16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .purple,
                                .purple.opacity(0.8)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: Color.purple.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(PlainButtonStyle())
                
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func noPlanWarning(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .padding()
        .navigationTitle("Plan Unavailable")
    }
}

// Global StrategySelectionCard
struct StrategySelectionCard: View {
    let id: Int
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    var isRecommended: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        if isRecommended {
                            Text("Astra Choice")
                                .font(.system(size: 10, weight: .black))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.purple, in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }
                    Text(subtitle)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.secondary.opacity(0.5))
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .overlay {
            if isRecommended {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(LinearGradient(colors: [.purple.opacity(0.5), .blue.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
            }
        }
        .shadow(color: isRecommended ? .purple.opacity(0.1) : .black.opacity(0.02), radius: 10, x: 0, y: 4)
    }
}
