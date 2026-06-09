import SwiftUI

struct PlanComparisonView: View {
    @Environment(\.colorScheme) var colorScheme
    var input: InvestmentPlanInputModel
    var results: FullPlanResult
    @State private var animateCharts = false
    @State private var selectedComparisonRisk: AstraRiskLevel = .mid

    init(input: InvestmentPlanInputModel, results: FullPlanResult) {
        self.input = input
        self.results = results
        let initialRisk = AstraRiskLevel(rawValue: input.riskType.lowercased()) ?? .mid
        _selectedComparisonRisk = State(initialValue: initialRisk)
    }

    private var isLoanEligibleGoal: Bool {
        results.goalCategory != .retirement && results.goalCategory != .wealthCreation
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                headerSection
                
                // Risk Selection
                riskTypeSection
                
                // Pillar 1: Crucial Role & Intent
                planRoleSection
                
                // Pillar 2: Financial Battle (The Numbers)
                quickComparisonCard
                
                // Pillar 3: Stability & Commitment
                stabilityCommitmentSection
                
                // Pillar 4: Growth Battle (Dynamic Chart)
                growthBattleSection
                
                battleSummarySection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .navigationTitle("Battle of Strategies")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.appBackground(for: colorScheme))
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animateCharts = true
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accentGradient)
                        .frame(width: 48, height: 48)
                    Image(systemName: "swords")
                        .foregroundColor(.white)
                        .font(.title3)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Side-by-Side Analysis")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                    Text("Find Your Perfect Match")
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(.primary)
                }
                Spacer()
            }
            
            Text("We've evaluated 3 distinct strategies for your \(input.purposeOfInvestment) goal. Compare the risk, cost, and efficiency below.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
    }

    private var planRoleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Crucial Role of Each Plan")
                .font(.headline)
            
            VStack(spacing: 12) {
                roleCard(title: "Plan 1: Pure SIP", role: "Steady Wealth Builder", intent: "Builds assets purely from savings. No debt, but slower results.", color: .blue, icon: "hourglass")
                
                if isLoanEligibleGoal {
                    roleCard(title: "Plan 2: Debt Optimization", role: "Time Saver", intent: "Buy today, pay later. Best for immediate needs but adds interest cost.", color: .purple, icon: "bolt.fill")
                }
                
                roleCard(title: "Plan 3: Leveraged Arbitrage", role: "The Multiplier", intent: "Uses debt to grow capital. High efficiency, requires risk appetite.", color: .pink, icon: "chart.line.uptrend.xyaxis")
            }
        }
    }

    private func roleCard(title: String, role: String, intent: String, color: Color, icon: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.subheadline)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(color)
                Text(role)
                    .font(.system(size: 14, weight: .bold))
                Text(intent)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.1), radius: 4)
    }

    private var quickComparisonCard: some View {
        let p1 = results.plan1
        let p2 = isLoanEligibleGoal ? results.plan2 : nil
        let p3 = results.plan3
        let score = results.comparisonScore

        return VStack(spacing: 0) {
            HStack {
                Text("Metrics").font(.system(size: 10, weight: .bold)).foregroundColor(.secondary).frame(width: 80, alignment: .leading)
                planHeader(label: "Plan 1", points: score?.plan1Score, color: .blue, icon: "star.fill")
                if p2 != nil {
                    planHeader(label: "Plan 2", points: score?.plan2Score, color: .purple, icon: "creditcard.fill")
                }
                if p3 != nil {
                    planHeader(label: "Plan 3", points: score?.plan3Score, color: .pink, icon: "bolt.fill")
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(Color.secondary.opacity(0.05))

            VStack(spacing: 0) {
                ComparisonRow3(label: "Total Outflow",
                              v1: "₹\(formatL_Comp(p1.totalInvested))",
                              v2: p2 != nil ? "₹\(formatL_Comp((p2?.totalAmountPaid ?? 0)))" : "N/A",
                              v3: p3 != nil ? "₹\(formatL_Comp(p3!.moderate.totalEMIPaid))" : "N/A",
                              c1: .primary, c2: .red, c3: .red)
                Divider()
                ComparisonRow3(label: "Net Profit",
                              v1: "₹\(formatL_Comp(p1.projectedValue - p1.totalInvested))",
                              v2: p2 != nil ? "₹\(formatL_Comp(p2!.netWealthGain))" : "N/A",
                              v3: p3 != nil ? "₹\(formatL_Comp(p3!.moderate.netProfit))" : "N/A",
                              c1: .green, c2: .green, c3: .green, isHighlight: true)
                Divider()
                ComparisonRow3(label: "Asset Ownership",
                              v1: "End of \(input.timePeriod)Y",
                              v2: p2 != nil ? "Immediate" : "N/A",
                              v3: p3 != nil ? "Immediate" : "N/A",
                              c1: .secondary, c2: .blue, c3: .blue)
            }
        }
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.3), radius: 10, x: 0, y: 4)
    }

    private func planHeader(label: String, points: Double?, color: Color, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundColor(color).font(.body)
            Text(label).font(.caption).fontWeight(.bold)
            if let pts = points {
                Text("\(Int(pts)) pts").font(.system(size: 9)).foregroundColor(.secondary)
            }
        }.frame(maxWidth: .infinity)
    }

    private var riskTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Simulate Risk Scenario")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                RiskOptionCard(title: "Low", icon: "shield.fill", color: .green, isSelected: selectedComparisonRisk == .low) {
                    withAnimation { selectedComparisonRisk = .low }
                }
                RiskOptionCard(title: "Mid", icon: "chart.bar.fill", color: .orange, isSelected: selectedComparisonRisk == .mid) {
                    withAnimation { selectedComparisonRisk = .mid }
                }
                RiskOptionCard(title: "High", icon: "flame.fill", color: .red, isSelected: selectedComparisonRisk == .high) {
                    withAnimation { selectedComparisonRisk = .high }
                }
            }
        }
    }

    private var stabilityCommitmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Stability & Monthly Commitment")
                .font(.system(size: 18, weight: .bold, design: .rounded))
            
            HStack(spacing: 12) {
                // Monthly Load Card
                VStack(alignment: .leading, spacing: 12) {
                    Label("Monthly Load", systemImage: "creditcard.fill")
                        .font(.caption).fontWeight(.bold).foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        commitmentRow(plan: "Plan 1", val: "₹\(InvestmentPlannerEngine.parseAmount(input.amount).toCurrency(compact: true))", color: .blue)
                        if results.plan2 != nil {
                            commitmentRow(plan: "Plan 2", val: "₹\(results.plan2!.totalMonthlyCommitment.toCurrency(compact: true))", color: .purple)
                        }
                        if results.plan3 != nil {
                            commitmentRow(plan: "Plan 3", val: "₹\(results.plan3!.monthlyEMI.toCurrency(compact: true))", color: .pink)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.05))
                .cornerRadius(16)
                
                // Stability Card
                VStack(alignment: .leading, spacing: 12) {
                    Label("Stability", systemImage: "shield.checkered")
                        .font(.caption).fontWeight(.bold).foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        commitmentRow(plan: "Plan 1", val: "Highest", color: .green)
                        if results.plan2 != nil {
                            commitmentRow(plan: "Plan 2", val: p2Stability, color: .orange)
                        }
                        if results.plan3 != nil {
                            commitmentRow(plan: "Plan 3", val: p3Stability, color: .red)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.05))
                .cornerRadius(16)
            }
        }
    }

    private var p2Stability: String {
        switch selectedComparisonRisk {
        case .low: return "High"
        case .mid: return "Medium"
        case .high: return "Moderate"
        }
    }

    private var p3Stability: String {
        switch selectedComparisonRisk {
        case .low: return "Medium"
        case .mid: return "Low"
        case .high: return "Aggressive"
        }
    }

    private func commitmentRow(plan: String, val: String, color: Color) -> some View {
        HStack {
            Text(plan).font(.system(size: 9)).foregroundColor(.secondary)
            Spacer()
            Text(val).font(.system(size: 11, weight: .bold)).foregroundColor(color)
        }
    }

    private var growthBattleSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Growth Potential")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text("Comparison under \(selectedComparisonRisk.rawValue.capitalized) Risk scenario")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            let val1 = getDynamicValue(for: 1)
            let val2 = getDynamicValue(for: 2)
            let val3 = getDynamicValue(for: 3)
            let maxV = Swift.max(val1, Swift.max(val2, val3))
            
            VStack(spacing: 20) {
                TimelineBarItem(label: "Plan 1: Pure SIP", value: val1, maxValue: maxV, color: .blue, animate: animateCharts)
                if results.plan2 != nil {
                    TimelineBarItem(label: "Plan 2: Debt Optimization", value: val2, maxValue: maxV, color: .purple, animate: animateCharts)
                }
                if results.plan3 != nil {
                    TimelineBarItem(label: "Plan 3: Leveraged Arbitrage", value: val3, maxValue: maxV, color: .pink, animate: animateCharts)
                }
            }
        }
        .padding(24)
        .background(AppTheme.cardBackground)
        .cornerRadius(24)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.3), radius: 10, x: 0, y: 4)
    }

    private func getDynamicValue(for planIndex: Int) -> Double {
        switch planIndex {
        case 1:
            let labelMap: [AstraRiskLevel: String] = [.low: "Conservative", .mid: "Moderate", .high: "Bull Market"]
            let targetLabel = labelMap[selectedComparisonRisk] ?? "Moderate"
            let matchingScenario = results.plan1.scenarios.first { $0.name.contains(targetLabel) }
            return matchingScenario?.finalValue ?? results.plan1.projectedValue
        case 2:
            guard let p2 = results.plan2 else { return 0 }
            let riskFactor: Double = {
                switch selectedComparisonRisk {
                case .low: return 0.85
                case .mid: return 1.0
                case .high: return 1.25
                }
            }()
            return p2.loanAmount + (p2.sipReturns * riskFactor)
        case 3:
            guard let p3 = results.plan3 else { return 0 }
            switch selectedComparisonRisk {
            case .low: return p3.conservative.finalValue
            case .mid: return p3.moderate.finalValue
            case .high: return p3.aggressive.finalValue
            }
        default: return 0
        }
    }

    private var battleSummarySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Color.blue.gradient).frame(width: 44, height: 44)
                    Image(systemName: "crown.fill").foregroundColor(.white).font(.system(size: 20))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Battle Summary").font(.headline).fontWeight(.bold)
                    Text("The best fit for your profile").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 20) {
                let winner = results.comparisonScore?.winner ?? "Plan 1"
                HStack {
                    Text("Primary Recommendation:")
                        .font(.subheadline).foregroundColor(.secondary)
                    Text(winner)
                        .font(.headline).fontWeight(.black).foregroundColor(.blue)
                }
                
                Text(results.recommendations.reason)
                    .font(.system(size: 13))
                    .foregroundColor(.primary.opacity(0.8))
                    .lineSpacing(4)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Strategic Insights").font(.caption).fontWeight(.bold).foregroundColor(.primary)
                    ForEach(results.recommendations.tips) { tip in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "sparkles").foregroundColor(.blue).font(.caption)
                            Text(tip.description).font(.caption).foregroundColor(.secondary).lineSpacing(3)
                        }
                    }
                }
            }
            .padding(24)
            .background(
                ZStack {
                    AppTheme.cardBackground
                    LinearGradient(colors: [Color.blue.opacity(0.07), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                }
            )
            .cornerRadius(24)
            .shadow(color: AppTheme.adaptiveShadow.opacity(0.2), radius: 12)
        }
    }

    private func formatL_Comp(_ value: Double) -> String {
        let v = abs(value)
        if v >= 10000000 { return String(format: "%.1fCr", value / 10000000) }
        if v >= 100000 { return String(format: "%.1fL", value / 100000) }
        if v >= 1000 { return String(format: "%.1fK", value / 1000) }
        return String(format: "%.0f", value)
    }
}

struct ComparisonRow: View {
    let label: String
    let value1: String
    let value2: String
    var subtitle2: String = ""
    var value1Color: Color
    var value2Color: Color
    var isHighlight: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption).foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(value1)
                .font(isHighlight ? .subheadline : .caption)
                .fontWeight(isHighlight ? .bold : .semibold)
                .foregroundColor(value1Color)
                .frame(maxWidth: .infinity)
            VStack(spacing: 2) {
                Text(value2)
                    .font(isHighlight ? .subheadline : .caption)
                    .fontWeight(isHighlight ? .bold : .semibold)
                    .foregroundColor(value2Color)
                if !subtitle2.isEmpty {
                    Text(subtitle2).font(.system(size: 9)).foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, isHighlight ? 12 : 10)
        .padding(.horizontal, 16)
        .background(isHighlight ? Color.green.opacity(0.05) : Color.clear)
    }
}

struct ComparisonRow3: View {
    let label: String; let v1: String; let v2: String; let v3: String
    let c1: Color; let c2: Color; let c3: Color
    var isHighlight = false
    var body: some View {
        HStack(spacing: 4) {
            Text(label).font(.system(size: 9)).foregroundColor(.secondary).frame(width: 70, alignment: .leading)
            Group {
                Text(v1).foregroundColor(c1)
                Text(v2).foregroundColor(c2)
                Text(v3).foregroundColor(c3)
            }
            .font(.system(size: 10, weight: isHighlight ? .bold : .medium))
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 12).padding(.horizontal, 16)
        .background(isHighlight ? Color.green.opacity(0.05) : Color.clear)
    }
}

struct TimelineBar3: View {
    let year: String; let v1: Double; let v2: Double; let v3: Double; let maxValue: Double; var animate: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(year).font(.caption).fontWeight(.bold)
            bar(val: v1, color: .blue)
            bar(val: v2, color: .purple)
            bar(val: v3, color: .pink)
        }
    }
    private func bar(val: Double, color: Color) -> some View {
        HStack {
            ZStack(alignment: .leading) {
                Capsule().fill(color.opacity(0.1)).frame(height: 8)
                GeometryReader { geo in
                    Capsule().fill(color).frame(width: animate ? geo.size.width * CGFloat(val/Swift.max(1, maxValue)) : 0, height: 8)
                }
            }.frame(height: 8)
            Text("₹\(formatL_Bare(val))").font(.system(size: 10, weight: .bold)).foregroundColor(color).frame(width: 50, alignment: .trailing)
        }
    }
    private func formatL_Bare(_ value: Double) -> String {
        let v = abs(value)
        if v >= 10000000 { return String(format: "%.1fCr", value / 10000000) }
        if v >= 100000 { return String(format: "%.1fL", value / 100000) }
        return String(format: "%.0f", value)
    }
}

struct ComparisonLegendItem: View {
    let label: String; let color: Color
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.system(size: 9)).foregroundColor(.secondary)
        }
    }
}

struct TimelineBar: View {
    let year: String
    let plan1Value: Double
    let plan2Value: Double
    let maxValue: Double
    var animate: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(year).font(.caption).fontWeight(.semibold)
            HStack(spacing: 8) {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.cyan.opacity(0.2)).frame(height: 12)
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.cyan)
                            .frame(width: animate ? geo.size.width * CGFloat(plan1Value / Swift.max(1, maxValue)) : 0, height: 12)
                            .animation(.spring(response: 1.0, dampingFraction: 0.7), value: animate)
                    }
                }
                .frame(maxWidth: .infinity)
                Text("₹\(formatL_Bare(plan1Value))")
                    .font(.caption).foregroundColor(.cyan)
                    .frame(width: 60, alignment: .trailing)
            }
            HStack(spacing: 8) {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.gray.opacity(0.2)).frame(height: 12)
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.gray)
                            .frame(width: animate ? geo.size.width * CGFloat(plan2Value / Swift.max(1, maxValue)) : 0, height: 12)
                            .animation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.2), value: animate)
                    }
                }
                .frame(maxWidth: .infinity)
                Text("₹\(formatL_Bare(plan2Value))")
                    .font(.caption).foregroundColor(.gray)
                    .frame(width: 60, alignment: .trailing)
            }
        }
    }

    private func formatL_Bare(_ value: Double) -> String {
        let v = abs(value)
        if v >= 10000000 { return String(format: "%.1fCr", value / 10000000) }
        if v >= 100000 { return String(format: "%.1fL", value / 100000) }
        return String(format: "%.0f", value)
    }
}

struct BreakdownItem: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(label).font(.caption).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.caption).fontWeight(.semibold).foregroundColor(color)
        }
    }
}

struct ProConItem: View {
    let icon: String
    let text: String
    let isPositive: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption)
                .foregroundColor(isPositive ? .green : .red)
            Text(text).font(.caption).foregroundColor(.primary)
        }
    }
}

struct InsightBullet: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Circle()
                .fill(.cyan)
                .frame(width: 4, height: 4)
                .padding(.top, 5)
            Text(text).font(.caption).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    let sampleInput = InvestmentPlanInputModel(investmentType: "Monthly", amount: "20,000", liquidity: "High", riskType: "Low", timePeriod: "4", scheduleInvestmentDate: Date(), scheduleSIPDate: Date(), purposeOfInvestment: "Car", targetAmount: "14,80,000", savedAmount: "70,000", hasEmergencyFund: true, preferredLoanTenureYears: 4)
    let sampleResult = InvestmentPlannerEngine.generateFullPlan(input: sampleInput)

    return NavigationStack {
        PlanComparisonView(input: sampleInput, results: sampleResult)
    }
}

struct TimelineBarItem: View {
    let label: String
    let value: Double
    let maxValue: Double
    let color: Color
    let animate: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label).font(.system(size: 12, weight: .bold))
                Spacer()
                Text(value.toCurrency(compact: true)).font(.system(size: 12, weight: .black)).foregroundColor(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.1)).frame(height: 10)
                    Capsule()
                        .fill(LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: animate ? geo.size.width * CGFloat(value / Swift.max(1, maxValue)) : 0, height: 10)
                }
            }
            .frame(height: 10)
        }
    }
    
    private func formatL_Bare(_ value: Double) -> String {
        let v = abs(value)
        if v >= 10000000 { return String(format: "%.1fCr", value / 10000000) }
        if v >= 100000 { return String(format: "%.1fL", value / 100000) }
        return String(format: "%.0f", value)
    }
}
