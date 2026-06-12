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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                // Header Message
                VStack(alignment:.leading,spacing: 16) {
                    //                    let profile = appState.currentProfile
                    //                    let isPortfolioHighRisk = profile.riskProfile == .high
                    //                    let goalCategory = input.goalCategory
                    //
                    //                    VStack(spacing: 8) {
                    //                        Text("Your Investment Profile")
                    //                            .font(.system(size: 28, weight: .bold, design: .rounded))
                    //                        Text("Risk profile: \(profile.riskProfile.rawValue)")
                    //                            .font(.title2)
                    //                            .foregroundColor(isPortfolioHighRisk ? .red : .green)
                    //                            .bold()
                    //                    }
                    //                    .padding()
                    //
                    //                    VStack(spacing: 12) {
                    //                        Text("Investment Goal: \(goalCategory.rawValue)")
                    //                            .font(.title3)
                    //                            .bold()
                    //                        Text("Target Amount: ₹\(input.targetAmount)")
                    //                            .font(.title3)
                    //                    }
                    //
                    //                    Spacer()
                    //
                    //                    Text("Plan Recommendations")
                    //                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    //                        .padding(.bottom, 8)
                    //
                    //                    ForEach(results.planSummaries) { plan in
                    //                        HStack {
                    //                            Text(plan.title)
                    //                                .bold()
                    //                            Spacer()
                    //                            Text(plan.estimatedYield)
                    //                                .foregroundColor(.secondary)
                    //                        }
                    //                        .padding(.horizontal)
                    //                        .padding(.vertical, 8)
                    //                        .background(AppTheme.secondaryBackground)
                    //                        .cornerRadius(12)
                    //                    }
                    //                    .padding(.horizontal)
                    //
                    //                    Spacer()
                    //                        .frame(height: 40)
                    //                }
                    //                .frame(maxWidth: .infinity)
                    //                .background(
                    //                    RoundedRectangle(cornerRadius: 20)
                    //                        .fill(AppTheme.cardBackground)
                    //                        .shadow(color: AppTheme.adaptiveShadow.opacity(0.2), radius: 8)
                    //                )
                    
                    let targetVal = Double(input.targetAmount.replacingOccurrences(of: ",", with: "")) ?? 0
                    Text("Based on your target of ₹\(targetVal >= 100000 ? String(format: "%.1fL", targetVal / 100000) : input.targetAmount), here are educational scenarios to compare possible planning paths.")
                        .font(.system(size: 15, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 24)
                
                // Plan Options
                VStack(spacing: 20) {
                    // Plan 1: SIP
                    NavigationLink(destination: Plan1DetailView(input: input, result: results.plan1)) {
                        StrategySelectionCard(
                            id: 1,
                            title: "SIP with Diversification",
                            subtitle: "Systematic investing across equity, debt & gold.",
                            icon: "chart.line.uptrend.xyaxis.circle.fill",
                            color: .blue,
                            bestFor: "Long-term Wealth",
                            metric: "8–12% CAGR assumption",
                            isRecommended: false
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Plan 3: Loan + Invest stress test
                    if let p3 = results.plan3 {
                        NavigationLink(destination: Plan3DetailView(input: input, result: p3)) {
                            StrategySelectionCard(
                                id: 3,
                                title: "Loan Stress-Test Scenario",
                                subtitle: "Compare debt-funded investing risks.",
                                icon: "arrow.up.right.circle.fill",
                                color: .purple,
                                bestFor: "Efficiency",
                                metric: "High risk simulation",
                                isRecommended: false
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        NavigationLink(destination: noPlanWarning(message: "This stress-test scenario requires higher credit surplus.")) {
                            StrategySelectionCard(
                                id: 3,
                                title: "Loan Stress-Test Scenario",
                                subtitle: "Compare debt-funded investing risks.",
                                icon: "arrow.up.right.circle.fill",
                                color: .purple,
                                bestFor: "Efficiency",
                                metric: "Check Surplus",
                                isRecommended: false
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Plan 2: Traditional Loan
                    if isLoanEligibleGoal {
                        if let p2 = results.plan2 {
                            NavigationLink(destination: Plan2DetailView(input: input, result: p2)) {
                                StrategySelectionCard(
                                    id: 2,
                                    title: "Traditional \(results.goalCategory.rawValue) Loan",
                                    subtitle: "Simple bank loan with flexible EMI options.",
                                    icon: "banknote.fill",
                                    color: .orange,
                                    bestFor: "Immediate Need",
                                    metric: "Bank Fixed",
                                    isRecommended: false
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            NavigationLink(destination: noPlanWarning(message: "This loan scenario is not suitable for your current profile inputs.")) {
                                StrategySelectionCard(
                                    id: 2,
                                    title: "Traditional \(results.goalCategory.rawValue) Loan",
                                    subtitle: "Simple bank loan with flexible EMI options.",
                                    icon: "banknote.fill",
                                    color: .orange,
                                    bestFor: "Immediate Need",
                                    metric: "Not Eligible",
                                    isRecommended: false
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // Compare All Plans Button
//                NavigationLink(destination: PlanComparisonView(input: input, results: results)) {
//                    HStack(spacing: 16) {
//                        ZStack {
//                            Circle()
//                                .fill(.white.opacity(0.2))
//                                .frame(width: 44, height: 44)
//                            Image(systemName: "arrow.left.arrow.right")
//                                .font(.system(size: 18, weight: .bold))
//                                .foregroundStyle(.white)
//                        }
//                        
//                        VStack(alignment: .leading, spacing: 2) {
//                            Text("Compare All Plans")
//                                .font(.system(size: 17, weight: .bold, design: .rounded))
//                            Text("View a side-by-side strategy breakdown")
//                                .font(.system(size: 13, design: .rounded))
//                                .opacity(0.8)
//                        }
//                        
//                        Spacer()
//                        
//                        Image(systemName: "chevron.right")
//                            .font(.system(size: 14, weight: .bold))
//                            .opacity(0.6)
//                    }
//                    .foregroundColor(.white)
//                    .padding(16)
//                    .background(
//                        LinearGradient(
//                            gradient: Gradient(colors: [
//                                .purple,
//                                Color(hex: "#5E5CE6")
//                            ]),
//                            startPoint: .leading,
//                            endPoint: .trailing
//                        )
//                    )
//                    .cornerRadius(20)
//                    .shadow(color: Color.purple.opacity(0.3), radius: 15, x: 0, y: 8)
//                }
                //.buttonStyle(PlainButtonStyle())
                //.padding(.top, 8)
                
                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 20)
        }
        .navigationTitle("\(results.goalCategory.rawValue) Illustration")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.appBackground(for: colorScheme))
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
    
    
    // Redesigned StrategySelectionCard
    struct StrategySelectionCard: View {
        let id: Int
        let title: String
        let subtitle: String
        let icon: String
        let color: Color
        var bestFor: String = ""
        var metric: String = ""
        var isRecommended: Bool = false
        
        @State private var isAnimatingGlow = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                if isRecommended {
                    HStack(spacing: 6) {
//                        Text("ASTRA CHOICE")
//                            .font(.system(size: 10, weight: .black, design: .rounded))
                        Spacer()
                        Text("HIGH RISK")
                            .font(.system(size: 9, weight: .bold))
                            .opacity(0.8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(colors: [Color(hex: "#BF5AF2"), Color(hex: "#5E5CE6")], startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .center, spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(color.opacity(0.1))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: icon)
                                .font(.system(size: 22))
                                .foregroundStyle(color)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                            
                            Text(subtitle)
                                .font(.system(size: 14, design: .rounded))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.secondary.opacity(0.5))
                    }
                    
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(color)
                            Text(bestFor)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(color.opacity(0.08))
                        .clipShape(Capsule())
                        
                        Spacer()
                        
                        Text(metric)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.secondary.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(16)
                .background(AppTheme.cardBackground)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isRecommended ? .purple.opacity(0.5) : .secondary.opacity(0.1), lineWidth: isRecommended ? 2 : 1)
            }
            .shadow(
                color: isRecommended
                ? .purple.opacity(isAnimatingGlow ? 0.25 : 0.15)
                : .black.opacity(0.04),
                radius: isAnimatingGlow ? 16 : 12,
                x: 0,
                y: isAnimatingGlow ? 8 : 6
            )
            .onAppear {
                if isRecommended {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        isAnimatingGlow = true
                    }
                }
            }
        }
    }
    
}
