import SwiftUI

/// Facts calculated locally before any optional AI explanation is requested.
/// The AI layer may explain these facts but must not recalculate or change them.
struct FinancialDecisionContext: Codable {
    let financialHealthScore: Int
    let cashReadinessScore: Int
    let debtPressureScore: Int
    let riskCapacityScore: Int
    let riskTolerance: String
    let goalReadinessScore: Int?
    let monthlyIncome: Double
    let monthlyExpenses: Double
    let monthlySurplus: Double
    let emergencyFund: Double
    let emergencyTarget: Double
    let debtAmount: Double
    let monthlyEMI: Double
    let highestDebtRate: Double?
    let investmentValue: Double
    let goalAmount: Double
    let goalCurrentAmount: Double
}

enum FinancialDecisionAIInsight {
    static func fallback(for context: FinancialDecisionContext) -> String {
        if context.emergencyTarget > 0, context.emergencyFund < context.emergencyTarget {
            return "Based on your current information, your emergency reserve is below its six-month target. Building cash may improve flexibility before increasing investment exposure."
        }
        if let rate = context.highestDebtRate, rate >= 8 {
            return "Your recorded debt includes a rate of \(String(format: "%.1f", rate))%. Reviewing higher-cost debt alongside your cash reserve may help guide this month’s allocation."
        }
        return "Your recorded cash reserve and debt data do not currently take priority over goal-based investing. Use Goal-Based Planning to explore how a contribution could affect your existing goals."
    }
}

// MARK: - Decision analysis

struct FinancialDecisionAnalysis {
    struct Readiness: Identifiable {
        let id: String
        let title: String
        let icon: String
        let score: Int?
        let status: String
        let explanation: String
        let color: Color
    }

    let profile: AstraUserProfile?
    let insights: FinancialAssessmentInsights?
    let healthScore: Int?
    let riskCapacityScore: Int?
    let cashReadinessScore: Int?
    let debtPressureScore: Int?
    let goalReadinessScore: Int?
    let monthlyEMI: Double
    let totalDebt: Double
    let highestDebtRate: Double?
    let goalHorizonYears: Double?

    static func build(profile: AstraUserProfile?) -> FinancialDecisionAnalysis {
        guard let profile, profile.basicDetails.monthlyIncome > 0 else {
            return FinancialDecisionAnalysis(profile: profile, insights: nil, healthScore: nil,
                                             riskCapacityScore: nil, cashReadinessScore: nil,
                                             debtPressureScore: nil, goalReadinessScore: nil,
                                             monthlyEMI: 0, totalDebt: 0, highestDebtRate: nil,
                                             goalHorizonYears: nil)
        }

        // Profile presents the latest completed Financial Assessment. Use that
        // identical score here so Health has one user-visible source of truth.
        let latestAssessmentScore = profile.monthlyHealthAssessments
            .filter { (0...100).contains($0.score) }
            .max(by: { $0.date < $1.date })?
            .score
        let healthScore = latestAssessmentScore ?? profile.financialHealthReport?.investmentScore
        guard let healthScore else {
            return FinancialDecisionAnalysis(profile: profile, insights: nil, healthScore: nil,
                                             riskCapacityScore: nil, cashReadinessScore: nil,
                                             debtPressureScore: nil, goalReadinessScore: nil,
                                             monthlyEMI: 0, totalDebt: 0, highestDebtRate: nil,
                                             goalHorizonYears: nil)
        }

        let insights = FinancialAssessmentInsights.build(profile: profile, data: nil)
        let monthlyEMI = profile.loans.reduce(0) { $0 + $1.calculatedEMI.safeFinite }
        let totalDebt = profile.loans.reduce(0) { $0 + $1.loanAmount.safeFinite }
        let highestRate = profile.loans.map(\.interestRate).filter { $0 > 0 }.max()
        let nearestGoalDate = profile.goals.map(\.targetDate).min()
        let horizonYears = nearestGoalDate.map {
            max(0, $0.timeIntervalSinceNow / (365.25 * 24 * 60 * 60))
        }

        let cashScore = min(100, max(0,
            insights.emergencyCoverageRatio * 70 + min(1, insights.savingsRate / 0.30) * 30
        )).rounded().safeInt
        let debtScore = min(100, max(0,
            100 - (insights.debtToIncomeRatio * 140) - (highestRate.map { max(0, $0 - 8) * 2 } ?? 0)
        )).rounded().safeInt
        let horizonScore: Double
        switch profile.basicDetails.investmentHorizon {
        case .longTerm: horizonScore = 100
        case .mediumTerm: horizonScore = 70
        case .shortTerm: horizonScore = 40
        }
        let responsibilityScore = profile.basicDetails.adultDependents + profile.basicDetails.childDependents > 0 ? 70.0 : 100.0
        let exposureScore = max(25, 100 - max(0, insights.investmentBreakdown.highRiskRatio - 0.60) * 125)
        let riskScore = min(100, max(0,
            Double(cashScore) * 0.30
            + Double(debtScore) * 0.25
            + horizonScore * 0.20
            + responsibilityScore * 0.10
            + exposureScore * 0.15
        )).rounded().safeInt

        let goalScore: Int?
        if profile.goals.isEmpty {
            goalScore = nil
        } else {
            let progress = profile.goals.map { goal in
                guard goal.targetAmount > 0 else { return 0.0 }
                return min(1, max(0, goal.currentAmount / goal.targetAmount))
            }.reduce(0, +) / Double(profile.goals.count)
            let timelineFactor = horizonYears.map { min(1, $0 / 3) } ?? 0.5
            goalScore = min(100, max(0, progress * 70 + timelineFactor * 30)).rounded().safeInt
        }

        return FinancialDecisionAnalysis(
            profile: profile, insights: insights, healthScore: healthScore,
            riskCapacityScore: riskScore, cashReadinessScore: cashScore,
            debtPressureScore: debtScore, goalReadinessScore: goalScore,
            monthlyEMI: monthlyEMI, totalDebt: totalDebt, highestDebtRate: highestRate,
            goalHorizonYears: horizonYears
        )
    }

    var isAvailable: Bool { healthScore != nil && insights != nil }

    var decisionContext: FinancialDecisionContext? {
        guard let insights, let healthScore, let cashReadinessScore,
              let debtPressureScore, let riskCapacityScore else { return nil }
        return FinancialDecisionContext(
            financialHealthScore: healthScore,
            cashReadinessScore: cashReadinessScore,
            debtPressureScore: debtPressureScore,
            riskCapacityScore: riskCapacityScore,
            riskTolerance: riskTolerance,
            goalReadinessScore: goalReadinessScore,
            monthlyIncome: insights.monthlyIncome,
            monthlyExpenses: insights.monthlyExpenses,
            monthlySurplus: insights.monthlySavings,
            emergencyFund: insights.emergencyFundAmount,
            emergencyTarget: insights.emergencyFundTarget,
            debtAmount: totalDebt,
            monthlyEMI: monthlyEMI,
            highestDebtRate: highestDebtRate,
            investmentValue: insights.investmentBreakdown.totalAmount,
            goalAmount: profile?.goals.reduce(0) { $0 + $1.targetAmount } ?? 0,
            goalCurrentAmount: profile?.goals.reduce(0) { $0 + $1.currentAmount } ?? 0
        )
    }

    var healthStatus: String { status(for: healthScore) }
    var riskCapacity: String { level(for: riskCapacityScore) }
    var riskTolerance: String { profile?.basicDetails.riskTolerance.rawValue ?? "Not set" }

    var readinessCards: [Readiness] {
        [
            Readiness(id: "risk", title: "Risk Readiness", icon: "shield.lefthalf.filled",
                      score: riskCapacityScore, status: riskCapacity,
                      explanation: riskExplanation, color: AppTheme.vibrantCyan),
            Readiness(id: "cash", title: "Cash Readiness", icon: "banknote.fill",
                      score: cashReadinessScore, status: status(for: cashReadinessScore),
                      explanation: cashExplanation, color: AppTheme.auraGreen),
            Readiness(id: "debt", title: "Debt Pressure", icon: "creditcard.fill",
                      score: debtPressureScore, status: debtStatus,
                      explanation: debtExplanation, color: Color(hex: "#FF9F0A")),
            Readiness(id: "goals", title: "Goal Readiness", icon: "target",
                      score: goalReadinessScore, status: goalReadinessScore == nil ? "No goals" : status(for: goalReadinessScore),
                      explanation: goalExplanation, color: AppTheme.auraIndigo)
        ]
    }

    var riskExplanation: String {
        guard let insights else { return "Complete your assessment to unlock this insight." }
        if insights.emergencyCoverageRatio < 1 { return "Cash reserves are the main constraint on taking more volatility." }
        if insights.debtToIncomeRatio > 0.30 { return "Debt commitments reduce the amount of investment risk your cash flow can absorb." }
        return "Your cash flow, emergency reserve, debt, horizon, and exposure support this level of volatility." 
    }

    var cashExplanation: String {
        guard let insights else { return "Complete your assessment to unlock this insight." }
        if insights.emergencyFundTarget <= 0 { return "Add income and expense details to assess your cash reserve." }
        return "Your emergency reserve covers approximately \(String(format: "%.1f", insights.emergencyCoverageRatio * 6)) of a six-month target." 
    }

    var debtStatus: String {
        guard totalDebt > 0 else { return "No debt" }
        guard let score = debtPressureScore else { return "Unavailable" }
        return score >= 75 ? "Low" : score >= 50 ? "Moderate" : "High"
    }

    var debtExplanation: String {
        guard totalDebt > 0 else { return "No active debt is recorded in your profile." }
        if let rate = highestDebtRate, rate >= 10 { return "A recorded debt rate of \(String(format: "%.1f", rate))% may deserve priority before taking additional risk." }
        return "Your debt and monthly EMI are evaluated against your income and available surplus." 
    }

    var goalExplanation: String {
        guard let score = goalReadinessScore else { return "Add a financial goal to compare progress against its target and timeline." }
        return score >= 70 ? "Your recorded goal progress and timelines are broadly aligned." : "Your recorded goal progress or timeline may need more attention." 
    }

    func status(for score: Int?) -> String {
        guard let score else { return "Unavailable" }
        switch score {
        case 80...: return "Excellent"
        case 65...: return "Strong"
        case 50...: return "Good"
        case 35...: return "Needs Attention"
        default: return "Critical"
        }
    }

    func level(for score: Int?) -> String {
        guard let score else { return "Unavailable" }
        switch score {
        case 70...: return "High"
        case 45...: return "Moderate"
        default: return "Low"
        }
    }
}

// MARK: - Planner entry card

struct FinancialDecisionCenterSection: View {
    @Environment(AppStateManager.self) private var appState

    private var analysis: FinancialDecisionAnalysis {
        FinancialDecisionAnalysis.build(profile: appState.currentProfile)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.vibrantCyan)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.vibrantCyan.opacity(0.14), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Financial Decision Center")
                        .font(.system(size: 19, weight: .bold))
                    Text("Turn your financial health into better decisions.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if analysis.isAvailable, let score = analysis.healthScore {
                HStack(alignment: .lastTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Financial Health")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(score) / 100")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text(analysis.healthStatus)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.auraIndigo)
                    }
                    Spacer()
                    Text("Your financial health is the foundation for every financial decision.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 180)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(analysis.readinessCards) { card in
                        FinancialReadinessMiniCard(card: card)
                    }
                }

                NavigationLink {
                    FinancialDecisionCenterView()
                } label: {
                    Label("Check My Financial Readiness", systemImage: "arrow.right.circle.fill")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.auraIndigo, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                        .foregroundStyle(.white)
                }
                NavigationLink {
                    WhyThisResultView(focus: "risk")
                } label: {
                    Label("Ask Why", systemImage: "questionmark.circle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.auraIndigo)
                        .frame(maxWidth: .infinity)
                }
            } else {
                Text("Complete your Financial Assessment to unlock readiness insights based on your own information.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                NavigationLink { StartAssesmentView(mode: .update) } label: {
                    Label("Complete Assessment", systemImage: "checklist")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.auraIndigo, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(18)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 14, x: 0, y: 5)
    }
}

private struct FinancialReadinessMiniCard: View {
    let card: FinancialDecisionAnalysis.Readiness

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: card.icon).foregroundStyle(card.color)
            Text(card.title).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Text(card.status).font(.subheadline.weight(.bold)).foregroundStyle(.primary)
            ProgressView(value: Double(card.score ?? 0), total: 100)
                .tint(card.color)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(card.color.opacity(0.09), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Decision center detail

struct FinancialDecisionCenterView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppStateManager.self) private var appState
    @State private var aiInsight: String?
    @State private var isLoadingAIInsight = false

    private var analysis: FinancialDecisionAnalysis { FinancialDecisionAnalysis.build(profile: appState.currentProfile) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Financial Decision Center")
                    .font(.title2.bold())
                Text("Readiness insights are calculated from your existing assessment and portfolio data. They are educational, not personalised investment advice.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let score = analysis.healthScore {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Financial Health")
                                .font(.caption).foregroundStyle(.secondary)
                            Text("\(score) / 100 · \(analysis.healthStatus)")
                                .font(.title3.bold())
                        }
                        Spacer()
                        Image(systemName: "heart.text.square.fill")
                            .font(.title).foregroundStyle(AppTheme.auraIndigo)
                    }
                    .padding(16)
                    .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                AIInsightCard(insight: aiInsight, isLoading: isLoadingAIInsight) {
                    Task { await loadAIInsight() }
                }

                ForEach(analysis.readinessCards) { card in
                    NavigationLink {
                        destination(for: card.id)
                    } label: {
                        FinancialReadinessRow(card: card)
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink { DecisionAdvisorView() } label: {
                    decisionAction(title: "Decision Advisor", subtitle: "Compare debt, cash, and investment priorities", icon: "arrow.triangle.branch")
                }
                .buttonStyle(.plain)

                NavigationLink { DecisionImpactView() } label: {
                    decisionAction(title: "Decision Impact", subtitle: "Simulate an increase in monthly investing", icon: "slider.horizontal.3")
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .navigationTitle("Decision Center")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.appBackground(for: colorScheme).ignoresSafeArea())
        .task { await loadAIInsight() }
    }

    @ViewBuilder private func destination(for id: String) -> some View {
        switch id {
        case "risk": RiskReadinessView()
        case "cash", "debt", "goals": WhyThisResultView(focus: id)
        default: EmptyView()
        }
    }

    private func decisionAction(title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.title3).foregroundStyle(AppTheme.auraIndigo).frame(width: 36)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline).foregroundStyle(.primary)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func loadAIInsight() async {
        guard aiInsight == nil, !isLoadingAIInsight,
              let context = analysis.decisionContext else { return }
        isLoadingAIInsight = true
        defer { isLoadingAIInsight = false }
        aiInsight = (try? await AIIntelligenceService().generateFinancialDecisionInsight(from: context))
            ?? FinancialDecisionAIInsight.fallback(for: context)
    }
}

private struct AIInsightCard: View {
    let insight: String?
    let isLoading: Bool
    let refresh: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("AI Financial Insight", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(AppTheme.auraIndigo)
                Spacer()
                Button("Refresh", action: refresh).font(.caption)
            }
            if isLoading { ProgressView().controlSize(.small) }
            else { Text(insight ?? "A fact-based explanation will appear here.").font(.subheadline).foregroundStyle(.secondary) }
            Text("Educational explanation only — not a recommendation to buy, sell, or choose a specific financial product.")
                .font(.caption2).foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct FinancialReadinessRow: View {
    let card: FinancialDecisionAnalysis.Readiness
    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: card.icon).font(.title3).foregroundStyle(card.color).frame(width: 30)
            VStack(alignment: .leading, spacing: 6) {
                HStack { Text(card.title).font(.headline); Spacer(); Text(card.status).font(.subheadline.weight(.semibold)).foregroundStyle(card.color) }
                Text(card.explanation).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                ProgressView(value: Double(card.score ?? 0), total: 100).tint(card.color)
                if let score = card.score { Text("\(score) / 100").font(.caption2).foregroundStyle(.secondary) }
            }
            Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(.tertiary).padding(.top, 4)
        }
        .padding(16)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - Risk readiness and transparency

struct RiskReadinessView: View {
    @Environment(AppStateManager.self) private var appState
    private var analysis: FinancialDecisionAnalysis { FinancialDecisionAnalysis.build(profile: appState.currentProfile) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Can I really take this much risk?").font(.title2.bold())
                riskMetric(title: "Risk Capacity", value: analysis.riskCapacity, score: analysis.riskCapacityScore,
                           detail: "Calculated from cash flow, emergency reserves, debt, time horizon, responsibilities, and current exposure.")
                riskMetric(title: "Risk Tolerance", value: analysis.riskTolerance, score: toleranceScore,
                           detail: "Your selected preference from the financial assessment.")

                VStack(alignment: .leading, spacing: 8) {
                    Text("Risk Alignment").font(.headline)
                    Text(alignmentText).font(.subheadline).foregroundStyle(.secondary)
                    NavigationLink { WhyThisResultView(focus: "risk") } label: { Label("Why am I seeing this?", systemImage: "questionmark.circle") }
                        .font(.subheadline.weight(.semibold))
                }
                .padding(16).background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                Text("Risk factor breakdown").font(.headline)
                ForEach(factors, id: \.title) { factor in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack { Text(factor.title).font(.subheadline.weight(.medium)); Spacer(); Text("\(factor.score)/100").font(.caption).foregroundStyle(.secondary) }
                        ProgressView(value: Double(factor.score), total: 100).tint(factor.color)
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Risk Readiness")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var toleranceScore: Int? {
        switch analysis.profile?.basicDetails.riskTolerance {
        case .low: 30
        case .medium: 60
        case .high: 90
        case nil: nil
        }
    }
    private var alignmentText: String {
        guard let toleranceScore, let capacity = analysis.riskCapacityScore else { return "Complete your assessment to compare risk preference with financial capacity." }
        if toleranceScore - capacity >= 20 { return "Your willingness to take risk is currently higher than your financial capacity." }
        if capacity - toleranceScore >= 20 { return "Your financial capacity is higher than your selected risk preference." }
        return "Your risk preference is broadly aligned with your current financial capacity." 
    }
    private var factors: [(title: String, score: Int, color: Color)] {
        guard let insights = analysis.insights else { return [] }
        let income = insights.hasFixedIncome ? 95 : 65
        let emergency = min(100, (insights.emergencyCoverageRatio * 100).rounded().safeInt)
        let horizon: Int = analysis.profile?.basicDetails.investmentHorizon == .longTerm ? 100 : analysis.profile?.basicDetails.investmentHorizon == .mediumTerm ? 70 : 40
        let exposure = max(0, 100 - (insights.investmentBreakdown.highRiskRatio * 100).rounded().safeInt)
        return [("Income Stability", income, AppTheme.auraGreen), ("Emergency Readiness", emergency, AppTheme.auraIndigo), ("Debt Position", analysis.debtPressureScore ?? 0, Color(hex: "#FF9F0A")), ("Goal Horizon", horizon, AppTheme.vibrantCyan), ("Current Exposure", exposure, Color(hex: "#BF5AF2")), ("Savings Strength", min(100, (insights.savingsRate / 0.30 * 100).rounded().safeInt), AppTheme.auraGreen)]
    }
    private func riskMetric(title: String, value: String, score: Int?, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 7) { Text(title).font(.caption).foregroundStyle(.secondary); Text(value).font(.title3.bold()); if let score { ProgressView(value: Double(score), total: 100).tint(AppTheme.auraIndigo) }; Text(detail).font(.caption).foregroundStyle(.secondary) }
            .padding(16).background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct WhyThisResultView: View {
    @Environment(AppStateManager.self) private var appState
    let focus: String
    private var analysis: FinancialDecisionAnalysis { FinancialDecisionAnalysis.build(profile: appState.currentProfile) }
    var body: some View {
        List {
            Section("Why this result?") {
                ForEach(reasons, id: \.self) { reason in
                    Label(reason, systemImage: reason.hasPrefix("⚠") ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(reason.hasPrefix("⚠") ? Color(hex: "#FF9F0A") : AppTheme.auraGreen)
                }
            }
            Section { Text(summary).foregroundStyle(.secondary) }
        }
        .navigationTitle("Why this result")
        .navigationBarTitleDisplayMode(.inline)
    }
    private var reasons: [String] {
        guard let insights = analysis.insights else { return ["⚠ Complete your Financial Assessment to unlock this insight."] }
        var result: [String] = []
        result.append(insights.hasFixedIncome ? "✓ Stable monthly income is recorded" : "⚠ Income is marked as variable")
        result.append(insights.savingsRate >= 0.30 ? "✓ Savings rate meets the 30% benchmark" : "⚠ Savings rate is below the 30% benchmark")
        result.append(insights.emergencyCoverageRatio >= 1 ? "✓ Emergency reserve meets the six-month target" : "⚠ Emergency reserve is below the six-month target")
        if analysis.totalDebt > 0 { result.append(analysis.debtPressureScore ?? 0 >= 70 ? "✓ Debt pressure is manageable against income" : "⚠ Debt commitments are affecting financial flexibility") }
        if focus == "goals" { result.append(analysis.goalReadinessScore == nil ? "⚠ No goals are recorded yet" : "✓ Goal progress and timeline are included") }
        return result
    }
    private var summary: String { "These are the recorded factors AstraFi uses for this readiness result. Values are calculated from your current profile, not assumed." }
}

// MARK: - Decision advisor and impact

struct DecisionAdvisorView: View {
    @Environment(AppStateManager.self) private var appState
    @State private var availableSurplus: Double = 0
    private var analysis: FinancialDecisionAnalysis { FinancialDecisionAnalysis.build(profile: appState.currentProfile) }
    var body: some View {
        Form {
            Section("Available this month") {
                TextField("Surplus amount", value: $availableSurplus, format: .number).keyboardType(.decimalPad)
                Text("Use an amount you can allocate after essential expenses and EMIs.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Your priority") { ForEach(priorities, id: \.self) { Text($0) } }
            Section("Why this recommendation?") { Text(explanation).foregroundStyle(.secondary) }
            Section { NavigationLink("See impact on my goals →") { GoalSelectionView() } }
        }
        .navigationTitle("Decision Advisor")
        .onAppear { availableSurplus = max(0, analysis.insights?.monthlySavings ?? 0) }
    }
    private var priorities: [String] {
        guard let insights = analysis.insights else { return ["Complete your Financial Assessment first."] }
        var results: [String] = []
        if insights.emergencyCoverageRatio < 1 { results.append("1. Build Emergency Cash") }
        if analysis.totalDebt > 0 && ((analysis.highestDebtRate ?? 0) >= 8 || insights.debtToIncomeRatio > 0.30) { results.append("\(results.count + 1). Reduce High-Cost Debt") }
        results.append("\(results.count + 1). Increase Goal-Based Investment")
        return results
    }
    private var explanation: String {
        guard let insights = analysis.insights else { return "No financial assessment data is available." }
        if insights.emergencyCoverageRatio < 1 { return "Your emergency reserve is below its six-month target. Based on your current information, strengthening cash may improve flexibility before increasing investment exposure." }
        if analysis.totalDebt > 0, let rate = analysis.highestDebtRate, rate >= 8 { return "A recorded debt rate of \(String(format: "%.1f", rate))% is included before recommending more investment risk." }
        return "Your cash reserve and debt data do not currently take priority over goal-based investing. Consider directing this amount through your existing goal plan." 
    }
}

struct DecisionImpactView: View {
    @Environment(AppStateManager.self) private var appState
    @State private var additionalInvestment: Double = 0
    private var analysis: FinancialDecisionAnalysis { FinancialDecisionAnalysis.build(profile: appState.currentProfile) }
    private var maximum: Double { max(0, analysis.insights?.monthlySavings ?? 0) }
    var body: some View {
        Form {
            Section("Increase monthly investment") {
                Slider(value: $additionalInvestment, in: 0...max(maximum, 500), step: 500).tint(AppTheme.auraIndigo)
                LabeledContent("Additional contribution", value: additionalInvestment.toCurrency())
            }
            Section("Decision Impact") {
                LabeledContent("Monthly surplus after change", value: max(0, maximum - additionalInvestment).toCurrency())
                LabeledContent("Cash readiness", value: cashImpact)
                LabeledContent("Goal impact", value: analysis.goalReadinessScore == nil ? "Add a goal to measure" : additionalInvestment > 0 ? "May improve contributions" : "No change")
                Text("This comparison uses your current monthly surplus. Goal projections remain managed by Goal-Based Planning.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section { NavigationLink("See impact on my goals →") { GoalSelectionView() } }
        }
        .navigationTitle("Decision Impact")
        .onAppear { additionalInvestment = min(5_000, maximum) }
    }
    private var cashImpact: String {
        guard maximum > 0 else { return "No surplus available" }
        let remaining = max(0, maximum - additionalInvestment)
        return remaining < maximum * 0.25 ? "Decreases significantly" : remaining < maximum * 0.60 ? "Decreases" : "Limited change"
    }
}
