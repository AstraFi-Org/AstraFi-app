import SwiftUI

struct PlanComparisonView: View {
    @Environment(\.colorScheme) var colorScheme
    var input: InvestmentPlanInputModel
    var results: FullPlanResult
    @State private var animateCharts = false

    private var isLoanEligibleGoal: Bool {
        results.goalCategory != .retirement && results.goalCategory != .wealthCreation
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                headerSection
                
                // Pillar 1: Crucial Role & Intent
                planRoleSection
                
                // Pillar 2: Financial Battle (The Numbers)
                quickComparisonCard
                
                // Pillar 3: Risk & Commitment
                riskCommitmentSection
                
                // Pillar 4: Growth Timeline
                timelineComparison
                
                prosConsSection
                recommendationSection
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

    private var riskCommitmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Risk & Commitment")
                .font(.headline)
            
            VStack(spacing: 0) {
                ComparisonRow3(label: "Monthly Pres.",
                              v1: "₹\(input.amount)",
                              v2: results.plan2 != nil ? "₹\(formatL_Comp(results.plan2!.totalMonthlyCommitment))" : "N/A",
                              v3: results.plan3 != nil ? "₹\(formatL_Comp(results.plan3!.monthlyEMI))" : "N/A",
                              c1: .blue, c2: .orange, c3: .orange)
                Divider()
                ComparisonRow3(label: "Risk Profile",
                              v1: "Very Low",
                              v2: "Medium",
                              v3: "High",
                              c1: .green, c2: .orange, c3: .red)
                Divider()
                ComparisonRow3(label: "Debt Load",
                              v1: "None",
                              v2: "Fixed",
                              v3: "Leveraged",
                              c1: .secondary, c2: .primary, c3: .primary)
            }
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
            .shadow(color: AppTheme.adaptiveShadow.opacity(0.2), radius: 8)
        }
    }

    private var timelineComparison: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Growth Timeline")
                        .font(.headline)
                    Text("Projected Value at end of tenure")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            let p1 = results.plan1
            let p2 = results.plan2
            let p3 = results.plan3
            let maxV = Swift.max(p1.projectedValue, Swift.max(p2?.sipReturns ?? 0, p3?.moderate.finalValue ?? 0))
            
            VStack(spacing: 24) {
                TimelineBarItem(label: "Plan 1: Pure SIP", value: p1.projectedValue, maxValue: maxV, color: .blue, animate: animateCharts)
                if let p2 = p2 {
                    TimelineBarItem(label: "Plan 2: Debt Opt.", value: p2.sipReturns, maxValue: maxV, color: .purple, animate: animateCharts)
                }
                if let p3 = p3 {
                    TimelineBarItem(label: "Plan 3: Leveraged", value: p3.moderate.finalValue, maxValue: maxV, color: .pink, animate: animateCharts)
                }
            }
        }
        .padding(24)
        .background(AppTheme.cardBackground)
        .cornerRadius(24)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.3), radius: 10, x: 0, y: 4)
    }

    private var prosConsSection: some View {
        VStack(spacing: 20) {
            if let score = results.comparisonScore {
                scoreDimensionsCard(score: score)
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Plan 1").font(.subheadline).fontWeight(.bold)
                    VStack(alignment: .leading, spacing: 8) {
                        ProConItem(icon: "checkmark.circle.fill", text: "No debt/loan",      isPositive: true)
                        ProConItem(icon: "checkmark.circle.fill", text: "Lower risk",        isPositive: true)
                        ProConItem(icon: "xmark.circle.fill",     text: "Delayed Asset",      isPositive: false)
                        ProConItem(icon: "xmark.circle.fill",     text: "Opportunity Cost",   isPositive: false)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .background(AppTheme.cardBackground)
                .cornerRadius(12)

                if isLoanEligibleGoal {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Plan 2").font(.subheadline).fontWeight(.bold)
                        VStack(alignment: .leading, spacing: 8) {
                            ProConItem(icon: "checkmark.circle.fill", text: "Immediate Asset",  isPositive: true)
                            ProConItem(icon: "checkmark.circle.fill", text: "Higher Net Gains",  isPositive: true)
                            ProConItem(icon: "xmark.circle.fill",     text: "EMI Commitment",    isPositive: false)
                            ProConItem(icon: "xmark.circle.fill",     text: "Interest Paid",     isPositive: false)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(12)
                }
            }
        }
    }

    private func scoreDimensionsCard(score: PlanComparisonScore) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "scalemass.fill").foregroundColor(.cyan)
                Text("AI Scoring Dimensions").font(.subheadline).fontWeight(.bold)
            }

            VStack(spacing: 12) {
                let dimensions: [ScoreDimension] = score.dimensions
                ForEach(dimensions) { dim in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(dim.axis).font(.caption).foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(dim.weight * 100))% weight").font(.system(size: 9)).foregroundColor(.secondary)
                        }
                        HStack(spacing: 12) {
                            scoreMiniBar(value: dim.plan1Points, color: .blue)
                            if isLoanEligibleGoal {
                                scoreMiniBar(value: dim.plan2Points, color: .purple)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: AppTheme.adaptiveShadow, radius: 4, x: 0, y: 2)
    }

    private func scoreMiniBar(value: Double, color: Color) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2).fill(color.opacity(0.1)).frame(height: 4)
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 80 * (value / 10), height: 4)
        }
    }

    private var recommendationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow).font(.title3)
                Text("Our Recommendation").font(.headline).fontWeight(.bold)
            }
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.gray).font(.title2)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(results.recommendations.primaryRecommendation)
                            .font(.headline).fontWeight(.bold)
                            .foregroundColor(results.comparisonScore?.winner == "Plan 3" ? .pink : (results.comparisonScore?.winner == "Plan 2" ? .purple : .blue))
                        Text(results.recommendations.reason)
                            .font(.caption).foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Text("Highlights:").font(.caption).fontWeight(.semibold)
                    ForEach(results.recommendations.tips) { tip in
                        InsightBullet(text: "\(tip.title): \(tip.description)")
                    }
                }
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppTheme.adaptiveShadow, radius: 10, x: 0, y: 4)
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
                Text("₹\(formatL_Bare(value))").font(.system(size: 12, weight: .black)).foregroundColor(color)
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
