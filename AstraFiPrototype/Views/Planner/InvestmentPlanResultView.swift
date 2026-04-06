import SwiftUI

struct InvestmentPlanResultView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppStateManager.self) var appState
    @State private var animateChart = false
    @State private var showComparison = false

    var input: InvestmentPlanInputModel

    private var results: FullPlanResult {
        InvestmentPlannerEngine.generateFullPlan(
            input: input,
            profile: appState.currentProfile
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                inputSummaryCard

                if let warning = results.feasibility.warning {
                    warningCard(warning: warning)
                }

                planOverviewCards

                if results.plan2 != nil, let score = results.comparisonScore {
                    comparisonScoreSummary(score: score)
                }

                if results.plan2 != nil {
                    comparePlansButton
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .navigationTitle("Investment Plans")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.appBackground(for: colorScheme))
        .navigationDestination(isPresented: $showComparison) {
            PlanComparisonView(input: input, results: results)
        }
    }

    private func warningCard(warning: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(warning)
                .font(.caption)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }

    private var healthGradeColor: Color {
        switch results.financialHealthSummary.healthGrade {
        case "A": return .green
        case "B": return .blue
        case "C": return .orange
        default: return .red
        }
    }

    private func healthMetric(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.secondary)
            VStack(alignment: .leading) {
                Text(label).font(.system(size: 9)).foregroundColor(.secondary)
                Text(value).font(.system(size: 11, weight: .bold))
            }
        }
    }

    private func comparisonScoreSummary(score: PlanComparisonScore) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("AI Recommendation Score")
                    .font(.subheadline)
                    .fontWeight(.bold)
                Spacer()
                Text(score.winner)
                    .font(.headline)
                    .foregroundColor(.cyan)
            }

            HStack(spacing: 12) {
                _scoreBar(label: "Plan 1", score: score.plan1Score, color: .blue)
                _scoreBar(label: "Plan 2", score: score.plan2Score, color: .purple)
                if let p3 = score.plan3Score {
                    _scoreBar(label: "Plan 3", score: p3, color: .pink)
                }
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
    }

    private func _scoreBar(label: String, score: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label).font(.system(size: 10, weight: .bold)).foregroundColor(.secondary)
                Spacer()
                Text("\(Int(score))").font(.system(size: 10, weight: .black)).foregroundColor(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(color.opacity(0.12)).frame(height: 5)
                    RoundedRectangle(cornerRadius: 3).fill(color).frame(width: geo.size.width * (min(100, score) / 100), height: 5)
                }
            }
            .frame(height: 5)
        }
        .padding(10)
        .background(color.opacity(0.04))
        .cornerRadius(10)
    }

    private var headerSection: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.accentGradient)
                    .frame(width: 50, height: 50)

                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Goal: \(results.goalCategory.rawValue)")
                    .font(.headline)
                    .fontWeight(.bold)
                Text(results.recommendations.reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
    }

    private var planOverviewCards: some View {
        VStack(spacing: 20) {

            let p1 = results.plan1
            NavigationLink(destination: Plan1DetailView(input: input, result: p1)) {
                PlanOverviewCard(
                    icon: p1.icon,
                    iconColor: .blue,
                    title: p1.name,
                    subtitle: p1.subtitle,
                    metrics: [
                        ("Total Investment", "₹\(formatL(p1.totalInvested))", .blue),
                        ("Projected Value", "₹\(formatL(p1.projectedValue))", .green),
                        ("Blended CAGR", "\(String(format: "%.1f", p1.portfolio.blendedCAGR))%", .orange),
                        ("Shortfall", p1.reachesGoal ? "₹0" : "₹\(formatL(p1.shortfall))", p1.reachesGoal ? .green : .red)
                    ],
                    highlights: p1.highlights
                )
            }
            .buttonStyle(PlainButtonStyle())

            if let p2 = results.plan2 {
                NavigationLink(destination: Plan2DetailView(input: input, result: p2)) {
                    PlanOverviewCard(
                        icon: p2.icon,
                        iconColor: .green,
                        title: p2.name,
                        subtitle: p2.subtitle,
                        metrics: {
                            var metrics: [(String, String, Color)] = [
                                ("Monthly EMI", "₹\(formatL(p2.monthlyEMI))", .orange),
                                ("Loan Amount", "₹\(formatL(p2.loanAmount))", .blue),
                                ("Net Wealth Gain", "₹\(formatL(p2.netWealthGain))", .green),
                                ("Portfolio ROI", "\(Int(p2.roi))%", .green)
                            ]
                            if !p2.reachesGoal {
                                metrics.append(("Shortfall", "₹\(formatL(p2.shortfall))", .red))
                            }
                            return metrics
                        }(),
                        highlights: p2.highlights
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }

            if let p3 = results.plan3 {
                NavigationLink(destination: Plan3DetailView(input: input, result: p3)) {
                    PlanOverviewCard(
                        icon: p3.icon,
                        iconColor: .purple,
                        title: p3.name,
                        subtitle: p3.subtitle,
                        metrics: [
                            ("Loan Amount", "₹\(formatL(p3.loanAmount))", .blue),
                            ("Monthly EMI", "₹\(Int(p3.monthlyEMI).formatted())", .red),
                            ("Tenure", "\(p3.tenure) Years", .orange),
                            ("Recommendation", p3.recommendedStrategy, .green)
                        ],
                        highlights: ["3-Strategy Comparison", "Survival Analysis", "Arbitrage Potential"]
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private var inputSummaryCard: some View {
        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "text.justify.left")
                        .foregroundColor(.blue)
                    Text("Your Plan Summary")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                }
                Text("An overview of your target goal and how your current budget stacks up against the required commitment.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 20) {
                summaryMetric(label: "Monthly SIP", value: "₹\(input.amount)", icon: "calendar.badge.clock")
                summaryMetric(label: "Target Goal", value: "₹\(formatL(Double(input.targetAmount.replacingOccurrences(of: ",", with: "")) ?? 0))", icon: "flag.fill")
                summaryMetric(label: "Time Horizon", value: "\(input.timePeriod) Yrs", icon: "clock.fill")
            }

            if let mValue = results.mentalityGrowthValue, let mLabel = results.mentalityGrowthLabel {
                Divider()
                HStack(spacing: 12) {
                    Image(systemName: input.investmentMentality.icon)
                        .foregroundColor(.cyan)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mental Projection: \(mLabel)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("₹\(formatL(mValue)) estimated growth")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.cyan)
                    }
                    Spacer()
                }
            }

            Divider()

            HStack(spacing: 8) {
                if let mValue = results.mentalityGrowthValue {
                    let targetAmount = Double(input.targetAmount.replacingOccurrences(of: ",", with: "")) ?? 0
                    let reachesGoal = mValue >= targetAmount
                    let diffAmount = abs(mValue - targetAmount)

                    Image(systemName: reachesGoal ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(reachesGoal ? .green : .orange)

                    Text(reachesGoal ? "Your projection comfortably achieves the target goal of ₹\(formatL(targetAmount))." : "Your estimated growth falls short of the target goal by ₹\(formatL(diffAmount)).")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(reachesGoal ? .green : .orange)
                } else {
                    let reaches = results.plan1.reachesGoal
                    Image(systemName: reaches ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(reaches ? .green : .orange)

                    Text(reaches ? "Plan 1: Your current SIP is enough to achieve this goal!" : "Plan 1: You have a shortfall of ₹\(formatL(results.plan1.shortfall)).")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(reaches ? .green : .orange)
                }
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
    }

    private var loanEligibilityCard: some View {
        guard let p2 = results.plan2 else { return AnyView(EmptyView()) }
        let profile = appState.currentProfile
        let gender = profile?.basicDetails.gender ?? .male
        let income = profile?.basicDetails.monthlyIncomeAfterTax ?? input.monthlyIncome
        let surplus = income * 0.4 
        let emi = p2.monthlyEMI
        let isAffordable = emi < (surplus * 1.5) 

        return AnyView(
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(.green)
                    Text("Loan Eligibility & Schemes")
                        .font(.headline)
                    Spacer()
                    StatusBadge(text: isAffordable ? "Eligible" : "Check Savings", color: isAffordable ? .green : .orange)
                }

                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Limit Required").font(.caption).foregroundColor(.secondary)
                        Text("₹\(formatL(p2.loanAmount))").font(.headline).fontWeight(.bold)
                    }
                    Divider().frame(height: 30)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Est. EMI").font(.caption).foregroundColor(.secondary)
                        Text("₹\(Int(emi).formatted())/mo").font(.headline).fontWeight(.bold).foregroundColor(.red)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Available Schemes & Benefits")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)

                    if gender == .female {
                        SchemeRow(icon: "person.fill.checkmark", text: "Women's Special: 0.1% Interest Waiver", color: .pink)
                    }

                    if results.goalCategory == .education {
                        SchemeRow(icon: "graduationcap.fill", text: "Education Benefit: 100% Tax Deduction (Sec 80E)", color: .blue)
                    } else if results.goalCategory == .homePurchase {
                        SchemeRow(icon: "house.fill", text: "PMAY: Subsidy up to ₹2.67L available", color: .orange)
                    } else {
                        SchemeRow(icon: "star.fill", text: "Pre-approved based on your Astra Score", color: .purple)
                    }
                }
            }
            .padding(20)
            .background(AppTheme.cardBackground)
            .cornerRadius(20)
            .shadow(color: AppTheme.adaptiveShadow, radius: 10, x: 0, y: 4)
        )
    }

    private struct SchemeRow: View {
        let icon: String
        let text: String
        let color: Color
        var body: some View {
            HStack(spacing: 10) {
                Image(systemName: icon).foregroundColor(color).font(.system(size: 12))
                Text(text).font(.system(size: 11, weight: .medium)).foregroundColor(.primary)
            }
        }
    }

    private struct StatusBadge: View {
        let text: String
        let color: Color
        var body: some View {
            Text(text)
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color.opacity(0.1))
                .foregroundColor(color)
                .cornerRadius(6)
        }
    }

    private func summaryMetric(label: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatL(_ value: Double) -> String {
        let v = abs(value)
        if v >= 100000 { return String(format: "%.1fL", value / 100000) }
        if v >= 1000 { return String(format: "%.1fK", value / 1000) }
        return String(format: "%.0f", value)
    }

    private var comparePlansButton: some View {
        Button(action: {
            showComparison = true
        }) {
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
    }
}

struct PlanOverviewCard: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let metrics: [(String, String, Color)]
    let highlights: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.title3)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }

            Divider()

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(Array(metrics.enumerated()), id: \.offset) { _, metric in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(metric.0)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(metric.1)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(metric.2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Highlights")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                ForEach(highlights, id: \.self) { highlight in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(iconColor)
                            .frame(width: 6, height: 6)
                        Text(highlight)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
            }

            HStack {
                Spacer()
                Text("Tap to view details")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .italic()
                Spacer()
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow, radius: 12, x: 0, y: 4)
    }
}

#Preview {
    NavigationStack {
        InvestmentPlanResultView(input: InvestmentPlanInputModel(investmentType: "Monthly", amount: "20,000", liquidity: "High", riskType: "Low", timePeriod: "4", scheduleInvestmentDate: Date(), scheduleSIPDate: Date(), purposeOfInvestment: "Car", targetAmount: "14,80,000", savedAmount: "70000", hasEmergencyFund: true))
    }
}
