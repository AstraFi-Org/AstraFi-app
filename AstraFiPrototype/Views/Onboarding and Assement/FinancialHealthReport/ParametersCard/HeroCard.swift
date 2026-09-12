//
//  HeroCard.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

//
//  HeroCard.swift
//  AstraFiPrototype
//

import SwiftUI

// MARK: - Radar Info Sheet
private struct RadarChartInfoSheet: View {
    let insights: FinancialAssessmentInsights
    var parameters: [FinancialHealthParameterResult] = []
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private func scoreOutOf10(_ parameter: AssessmentParameter, fallback: Double) -> Double {
        parameters.first(where: { $0.parameter == parameter })?.scoreOutOf10 ?? fallback
    }

    private var savingScore: Double    { scoreOutOf10(.vitals, fallback: insights.financialVitalsScore * 10) }
    private var debtScore: Double      { scoreOutOf10(.liabilities, fallback: insights.debtHealthScore * 10) }
    private var emergencyScore: Double { scoreOutOf10(.emergencyFund, fallback: insights.emergencyReadinessScore * 10) }
    private var investScore: Double    { scoreOutOf10(.investment, fallback: insights.investmentHealthScore * 10) }
    private var riskScore: Double      { scoreOutOf10(.insurance, fallback: insights.riskProtectionScore * 10) }

    private var savingsPct: Int        { (insights.savingsRate * 100).rounded().safeInt }
    private var dtiPct: Int            { (insights.debtToIncomeRatio * 100).rounded().safeInt }
    private var coverageMonths: Double { insights.emergencyCoverageRatio * 6 }
    private var highRiskPct: Int       { (insights.investmentBreakdown.highRiskRatio * 100).rounded().safeInt }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // ── Hero header ──
                    headerBanner
                        .padding(.bottom, 24)

                    // ── Parameter cards ──
                    VStack(spacing: 14) {
                        paramCard(
                            title: "Financial Vitals",
                            icon: "banknote",
                            accentHex: "#30D158",
                            score: savingScore,
                            howLabel: insights.monthlySavings > 0
                                ? "\(insights.monthlySavings.toCurrency())/mo saved · \(savingsPct)% of take-home pay"
                                : "₹0 saved · Expenses consume 100% of income",
                            howDetail: "Indian financial benchmark is 30% savings rate. Score scales proportionally up to this target.",
                            insight: savingsPct >= 30
                                ? "Outstanding — saving \(savingsPct)% of take-home income exceeds the Indian 30% benchmark."
                                : savingsPct >= 20
                                    ? "Good discipline saving \(insights.monthlySavings.toCurrency())/mo (\(savingsPct)%). Scaling to 30% (\((insights.monthlyIncome * 0.30).toCurrency())/mo) will maximize your score."
                                    : savingsPct > 0
                                        ? "Currently saving \(insights.monthlySavings.toCurrency())/mo (\(savingsPct)%). Trimming discretionary spends can help reach the recommended 30% target."
                                        : "Zero savings margin. Expenses of \(insights.monthlyExpenses.toCurrency()) match or exceed take-home pay, leaving no room to build wealth."
                        )

                        let totalEMI = insights.debtToIncomeRatio * insights.grossMonthlyIncome
                        paramCard(
                            title: "Debt Health",
                            icon: "creditcard.fill",
                            accentHex: "#BF5AF2",
                            score: debtScore,
                            howLabel: insights.loanCount == 0
                                ? "Debt-free (0 active loans · ₹0 EMI)"
                                : "\(insights.loanCount) active loan\(insights.loanCount == 1 ? "" : "s") · \(totalEMI.toCurrency())/mo EMI (\(dtiPct)% DTI)",
                            howDetail: "Measures EMI burden against gross income. DTI under 20% is ideal, under 35% is healthy (Indian banking standard).",
                            insight: insights.loanCount == 0
                                ? "Outstanding — being completely debt-free gives you maximum disposable cashflow and financial safety."
                                : insights.hasHighRiskDebt
                                    ? "High-interest debt detected (Credit Card or Personal Loan). Paying this off first will yield immediate interest savings and raise your score."
                                    : insights.monthlySavings > 0 && totalEMI > insights.monthlySavings
                                        ? "Warning: Required EMIs (\(totalEMI.toCurrency())) exceed your monthly savings (\(insights.monthlySavings.toCurrency())), creating severe cashflow strain."
                                        : dtiPct <= 20
                                            ? "Very healthy debt load. EMIs take only \(dtiPct)% of monthly income, well within comfortable banking limits."
                                            : dtiPct <= 35
                                                ? "Manageable debt burden within standard Indian bank eligibility limits. Avoid taking on high-interest personal debt."
                                                : "Debt-to-income is elevated at \(dtiPct)%. RBI guidelines view DTI > 50% as high risk. Prioritize loan prepayment."
                        )

                        paramCard(
                            title: "Emergency Readiness",
                            icon: "umbrella.fill",
                            accentHex: "#FF9F0A",
                            score: emergencyScore,
                            howLabel: insights.emergencyFundAmount > 0
                                ? "\(insights.emergencyFundAmount.toCurrency()) saved of \(insights.emergencyFundTarget.toCurrency()) target (\(String(format: "%.1f", insights.emergencyCoverageMonths)) of 6 mo)"
                                : "₹0 saved of \(insights.emergencyFundTarget.toCurrency()) target (0 of 6 months covered)",
                            howDetail: "Target is about 6 months of essential expenses, including EMI when those obligations would continue during an income disruption.",
                            insight: insights.emergencyCoverageMonths >= 6
                                ? "Fully funded — you have a complete \(insights.emergencyFundAmount.toCurrency()) liquid safety buffer for unforeseen contingencies."
                                : insights.emergencyCoverageMonths >= 3
                                    ? "Partial coverage (\(String(format: "%.1f", insights.emergencyCoverageMonths)) months). Build another \((max(0, insights.emergencyFundTarget - insights.emergencyFundAmount)).toCurrency()) to complete your 6-month buffer."
                                    : "Under 3 months covered. Prioritize building an emergency fund of at least \(insights.emergencyFundTarget.toCurrency()) to reduce the need to borrow in emergencies."
                        )

                        let totalInvested = insights.investmentBreakdown.totalAmount
                        paramCard(
                            title: "Investment Health",
                            icon: "chart.pie.fill",
                            accentHex: "#007AFF",
                            score: investScore,
                            howLabel: insights.investmentCount > 0
                                ? "\(totalInvested.toCurrency()) invested · \(insights.investmentCount) instrument\(insights.investmentCount == 1 ? "" : "s") · \(highRiskPct)% high-risk"
                                : "No investments added (₹0 invested)",
                            howDetail: "Score evaluates asset diversification (3+ types), equity/high-risk proportion, and low-risk liquidity.",
                            insight: insights.investmentCount == 0
                                ? "No investments recorded yet. Even a small monthly SIP in mutual funds will activate compounding."
                                : highRiskPct >= 80
                                    ? "Heavy concentration in high-risk assets (\(highRiskPct)%). Adding debt funds, fixed deposits, or PPF will balance your risk profile."
                                    : insights.investmentBreakdown.lowRiskLiquidAmount == 0
                                        ? "Portfolio lacks a liquid low-risk component. Allocating a portion to liquid funds or FDs will improve stability."
                                        : insights.investmentCount >= 3
                                            ? "Well diversified across \(insights.investmentCount) asset classes with a balanced risk allocation."
                                            : "Holding \(insights.investmentCount) asset type\(insights.investmentCount == 1 ? "" : "s"). Adding another instrument type (e.g. mutual funds, gold, or FDs) will maximize your diversification score."
                        )

                        paramCard(
                            title: "Risk Protection",
                            icon: "shield.fill",
                            accentHex: "#FF453A",
                            score: riskScore,
                            howLabel: insights.hasHealthInsurance && insights.hasLifeInsurance
                                ? "Health + Term Life active (\(insights.insuranceCount) policies)"
                                : insights.hasHealthInsurance
                                    ? "Health cover active · No term life (\(insights.insuranceCount) polic\(insights.insuranceCount == 1 ? "y" : "ies"))"
                                    : insights.hasLifeInsurance
                                        ? "Term life active · No health cover (\(insights.insuranceCount) polic\(insights.insuranceCount == 1 ? "y" : "ies"))"
                                        : insights.insuranceCount > 0
                                            ? "General policy active · Health/Life missing (\(insights.insuranceCount) policies)"
                                            : "No insurance detected (0 active policies)",
                            howDetail: "Evaluates essential Health cover for medical emergencies and Term Life to protect family income.",
                            insight: insights.hasHealthInsurance && insights.hasLifeInsurance
                                ? "Comprehensive protection in place. Both hospitalization costs and family life risks are shielded."
                                : insights.hasHealthInsurance
                                    ? (insights.adultDependents > 0
                                        ? "Health insurance is in place, but your \(insights.adultDependents) dependent\(insights.adultDependents == 1 ? "" : "s") need term life cover (target: 10× annual income)."
                                        : "Good health coverage. Since you have no dependents, term life cover is optional.")
                                    : insights.hasLifeInsurance
                                        ? "Term life is active, but lack of health insurance leaves you exposed to out-of-pocket hospital bills."
                                        : "Critical gap: Medical emergencies and loss of income are unhedged. Prioritize securing a base health policy (₹5L–₹10L)."
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("5-Parameter Overview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Header banner
    private var headerBanner: some View {
        VStack(spacing: 10) {
            Image(systemName: "pentagon.fill")
                .font(.system(size: 36))
                .foregroundStyle(
                    LinearGradient(colors: [Color(hex: "#007AFF"), Color(hex: "#BF5AF2")],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .padding(.top, 28)

            Text("How your scores are calculated")
                .font(.title3).bold()

            Text("Each dimension is scored 0 – 10 from your financial inputs and Indian personal finance benchmarks.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 28)
                .padding(.bottom, 8)
        }
    }

    // MARK: - Parameter card builder
    @ViewBuilder
    private func paramCard(
        title: String,
        icon: String,
        accentHex: String,
        score: Double,
        howLabel: String,
        howDetail: String,
        insight: String
    ) -> some View {
        let accent = Color(hex: accentHex)
        let scoreColor: Color = score >= 7 ? Color(hex: "#30D158") : score >= 4.5 ? Color(hex: "#FF9F0A") : Color(hex: "#FF453A")

        VStack(alignment: .leading, spacing: 0) {

            // ── Title row ──
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 36, height: 36)
                    .background(accent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text(title)
                    .font(.headline)

                Spacer()

                // Score badge
                Text(String(format: "%.1f / 10", score))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(scoreColor.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // ── Score bar ──
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.tertiarySystemBackground))
                        .frame(height: 6)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [accent.opacity(0.7), accent],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * (score / 10), height: 6)
                        .animation(.spring(duration: 0.8), value: score)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 16)
            .padding(.top, 10)

            // ── How it's calculated ──
            VStack(alignment: .leading, spacing: 4) {
                Text(howLabel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(accent)
                Text(howDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)

            Divider()
                .padding(.horizontal, 16)

            // ── Personalized insight ──
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: score >= 7
                      ? "checkmark.circle.fill"
                      : score >= 4.5
                          ? "exclamationmark.circle.fill"
                          : "xmark.circle.fill"
                )
                .foregroundStyle(scoreColor)
                .font(.system(size: 14))
                .padding(.top, 1)

                Text(insight)
                    .font(.subheadline)
                    .foregroundStyle(.primary.opacity(0.8))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - HeroCard
struct HeroCard: View {
    let name: String
    let score: Double
    let radarValues: [(String, Double, Double)]
    let insights: FinancialAssessmentInsights
    var parameters: [FinancialHealthParameterResult] = []
    var statusTitle: String? = nil
    var scoreChange: Int? = nil

    @State private var showRadarInfo = false

    private var scoreColor: Color {
        FinancialHealthUIStyle.scoreColor(score.safeInt)
    }
    private var scoreLabel: String {
        statusTitle ?? insights.statusTitle
    }

    var body: some View {
        VStack(spacing: 20) {

            // Greeting + score ring
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.text.square.fill")
                            .foregroundStyle(Color(hex: "#007AFF")).font(.system(size: 15))
                        Text("AstraFi Report")
                            .font(.subheadline).fontWeight(.semibold).foregroundStyle(.secondary)
                    }
                    Text("Hi, \(name)").font(.title2).bold()
                    Text("Your financial health assessment is complete.")
                        .font(.subheadline).foregroundStyle(.secondary).lineSpacing(2)
                    if let scoreChange {
                        Text("\(scoreChange >= 0 ? "+" : "")\(scoreChange) since previous assessment")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(scoreChange >= 0 ? Color(hex: "#30D158") : Color(hex: "#FF453A"))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 6) {
                    ZStack {
                        Circle().trim(from: 0.1, to: 0.9)
                            .stroke(Color(UIColor.systemFill), style: StrokeStyle(lineWidth: 6.5, lineCap: .round))
                            .rotationEffect(.degrees(90))
                        Circle().trim(from: 0.1, to: 0.1 + (score / 100) * 0.8)
                            .stroke(scoreColor, style: StrokeStyle(lineWidth: 6.5, lineCap: .round))
                            .rotationEffect(.degrees(90))
                            .animation(.easeOut(duration: 1.4), value: score)
                        Text("\(score.safeInt)")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundStyle(scoreColor)
                    }
                    .frame(width: 66, height: 66)

                    Text(scoreLabel)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3.5)
                        .background(scoreColor.opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(scoreColor.opacity(0.25), lineWidth: 0.8)
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }

            Divider()

            // Radar chart section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Financial Health Overview").font(.headline)
                    Spacer()
                    Button { showRadarInfo = true } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 20))
                            .foregroundStyle(Color(hex: "#007AFF"))
                    }
                    .buttonStyle(.plain)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .accessibilityLabel("About this chart")
                }
                RadarChart(values: radarValues).frame(height: 230)
            }
        }
        .padding(22)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 14, x: 0, y: 6)
        .sheet(isPresented: $showRadarInfo) {
            RadarChartInfoSheet(insights: insights, parameters: parameters)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}
