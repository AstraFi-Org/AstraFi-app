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
    
    private var isRetirement: Bool { results.goalCategory == .retirement }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                // Header Message
                VStack(alignment:.leading,spacing: 16) {
                    let targetVal = Double(input.targetAmount.replacingOccurrences(of: ",", with: "")) ?? 0
                    let targetLabel = targetVal >= 10_000_000
                        ? String(format: "%.2fCr", targetVal / 10_000_000)
                        : (targetVal >= 100_000 ? String(format: "%.1fL", targetVal / 100_000) : input.targetAmount)
                    
                    if isRetirement {
                        Text("Based on your inflation-adjusted retirement corpus of ₹\(targetLabel), here are three strategies to build your retirement wealth.")
                            .font(.system(size: 15, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                    } else {
                        Text("Based on your target of ₹\(targetLabel), here are educational scenarios to compare possible illustration paths.")
                            .font(.system(size: 15, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 24)
                
                // Plan Options
                VStack(spacing: 20) {
                    // Plan 1: SIP
                    NavigationLink(destination: Plan1DetailView(input: input, result: results.plan1)) {
                        StrategySelectionCard(
                            id: 1,
                            title: isRetirement ? "Systematic Retirement Corpus (SIP)" : "SIP with Diversification",
                            subtitle: isRetirement
                                ? "Build your retirement corpus through disciplined monthly SIP across equity, debt & gold."
                                : "Systematic investing across equity, debt & gold.",
                            icon: "chart.line.uptrend.xyaxis.circle.fill",
                            color: .blue,
                            bestFor: isRetirement ? "Long-term Compounding" : "Long-term Wealth",
                            metric: "8–12% CAGR assumption",
                            isRecommended: false
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Plan 3: Loan stress test — for Retirement, this means
                    // "Pre-Retirement Debt Leverage Stress-Test"
                    if let plan3 = results.plan3 {
                        NavigationLink(destination: Plan3DetailView(input: input, result: plan3)) {
                            StrategySelectionCard(
                                id: 3,
                                title: isRetirement
                                    ? "Pre-Retirement Loan Stress-Test"
                                    : "Loan Stress-Test Scenario",
                                subtitle: isRetirement
                                    ? "Stress-test debt leverage during your earning years to accelerate corpus growth before retirement."
                                    : "Compare debt-funded investing risks.",
                                icon: "arrow.up.right.circle.fill",
                                color: .purple,
                                bestFor: isRetirement ? "Accelerated Growth" : "Efficiency",
                                metric: "High risk simulation",
                                isRecommended: false
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Plan 2: Traditional Loan — for Retirement, this is
                    // "Pre-Retirement Asset Leverage Strategy"
                    if let plan2 = results.plan2 {
                        NavigationLink(destination: Plan2DetailView(input: input, result: plan2)) {
                            StrategySelectionCard(
                                id: 2,
                                title: isRetirement
                                    ? "Pre-Retirement Asset Leverage"
                                    : "Traditional \(results.goalCategory.rawValue) Loan",
                                subtitle: isRetirement
                                    ? "Use a loan during your earning years to invest and build wealth before retirement begins."
                                    : "Simple bank loan with flexible EMI options.",
                                icon: "banknote.fill",
                                color: .orange,
                                bestFor: isRetirement ? "Wealth Acceleration" : "Immediate Need",
                                metric: isRetirement ? "Pre-Retirement Only" : "Bank Fixed",
                                isRecommended: false
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
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
        .navigationTitle("\(results.goalCategory.rawValue) Plan")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.appBackground(for: colorScheme))
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
