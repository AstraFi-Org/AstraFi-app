import SwiftUI
import Charts

struct RetirementSWPResultView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    let input: RetirementSWPInput

    @State private var selectedStressId: String = "baseline"
    @State private var currentStress: RetirementStressScenario = RetirementStressScenario.standardScenarios[0]
    @State private var showingYearlyBreakdown: Bool = false

    init(input: RetirementSWPInput) {
        self.input = input
    }

    private var result: RetirementSWPResult {
        RetirementSWPEngine.simulate(input: input, appliedStress: currentStress)
    }

    private var planInputModel: InvestmentPlanInputModel {
        InvestmentPlanInputModel(
            investmentType: "Retirement SWP",
            amount: "\(Int(input.monthlySIPPreRetirement))",
            liquidity: "High",
            riskType: "Moderate",
            timePeriod: "\(max(1, input.retirementAge - input.currentAge))",
            scheduleInvestmentDate: Date(),
            scheduleSIPDate: Date(),
            purposeOfInvestment: "Retirement Income & Systematic Withdrawal",
            targetAmount: "\(Int(result.requiredCorpusAtRetirement))",
            savedAmount: "\(Int(input.currentRetirementCorpus))",
            hasEmergencyFund: true
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Top Feasibility Banner
                SimulatorFeasibilityBanner(
                    status: result.feasibility,
                    explanation: result.feasibilitySummary
                )

                // Key metrics 2x2 grid
                metricsGrid

                // Scenario Stress Selector
                stressScenarioCard

                // Lifetime Corpus Curve (Accumulation + Decumulation)
                lifetimeCorpusChartCard

                // Monthly Drawdown & Purchasing Power Chart
                drawdownTrendChartCard

                // Actionable Solvency Recommendations
                if !result.actionRecommendations.isEmpty {
                    recommendationsCard
                }

                // Yearly Breakdown Table
                yearlyBreakdownCard

                // Save & Follow Footer
                SimulatorSaveFooter(
                    planName: "Retirement Income & SWP Strategy",
                    targetGoal: "Retirement",
                    planInput: planInputModel
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(AppTheme.appBackground(for: colorScheme))
        .navigationTitle("Retirement SWP Results")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            SimulatorMetricCard(
                title: "Projected Corpus",
                value: result.projectedCorpusAtRetirement.toCurrency(compact: true),
                subtitle: "At age \(input.retirementAge)",
                color: AppTheme.auraIndigo,
                icon: "arrow.up.circle.fill"
            )

            SimulatorMetricCard(
                title: "Required Corpus",
                value: result.requiredCorpusAtRetirement.toCurrency(compact: true),
                subtitle: "Full solvency target",
                color: result.isAdequate ? AppTheme.auraGreen : AppTheme.vibrantRed,
                icon: "target"
            )

            SimulatorMetricCard(
                title: "First-Year Monthly Draw",
                value: result.firstYearMonthlyWithdrawal.toCurrency(compact: true) + " / mo",
                subtitle: "Post-pension net draw",
                color: AppTheme.vibrantCyan,
                icon: "banknote"
            )

            SimulatorMetricCard(
                title: "Solvency Status",
                value: result.depletionAge != nil ? "Depletes at \(result.depletionAge!)" : "Solvent to \(input.lifeExpectancyAge)+",
                subtitle: result.depletionAge != nil ? "\(result.yearsCorpusSustained) years sustained" : "Full life coverage",
                color: result.depletionAge != nil ? AppTheme.vibrantRed : AppTheme.auraGreen,
                icon: result.depletionAge != nil ? "xmark.octagon.fill" : "checkmark.seal.fill"
            )
        }
    }

    private var stressScenarioCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SimulatorSectionHeader(
                title: "Retirement Stress Scenarios",
                subtitle: "Test against sequence crashes, inflation spikes, and super-longevity",
                icon: "bolt.shield.fill"
            )

            Picker("Scenario", selection: $selectedStressId) {
                ForEach(RetirementStressScenario.standardScenarios) { sc in
                    Text(sc.title).tag(sc.id)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedStressId) { _, newId in
                if let matched = RetirementStressScenario.standardScenarios.first(where: { $0.id == newId }) {
                    currentStress = matched
                }
            }

            Text(currentStress.description)
                .font(.auraCaption())
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .auraCardStyle(radius: 20)
    }

    private var lifetimeCorpusChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SimulatorSectionHeader(
                title: "Lifetime Corpus Trajectory",
                subtitle: "Accumulation phase through decumulation",
                icon: "chart.xyaxis.line"
            )

            Chart {
                // Accumulation points
                ForEach(result.accumulationTimeline) { item in
                    LineMark(
                        x: .value("Age", item.age),
                        y: .value("Corpus", item.endingBalance)
                    )
                    .foregroundStyle(AppTheme.auraIndigo)
                }

                // Decumulation points
                ForEach(result.withdrawalTimeline) { item in
                    LineMark(
                        x: .value("Age", item.age),
                        y: .value("Corpus", item.endingCorpus)
                    )
                    .foregroundStyle(item.isDepleted ? AppTheme.vibrantRed : AppTheme.auraGreen)
                }

                if let depAge = result.depletionAge {
                    RuleMark(x: .value("Depletion", depAge))
                        .foregroundStyle(AppTheme.vibrantRed)
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                        .annotation(position: .top, alignment: .leading) {
                            Text("Exhausted: Age \(depAge)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(AppTheme.vibrantRed)
                                .padding(4)
                                .background(AppTheme.cardBackground)
                                .cornerRadius(6)
                        }
                }
            }
            .frame(height: 220)

            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Circle().fill(AppTheme.auraIndigo).frame(width: 8, height: 8)
                    Text("Accumulation (Age \(input.currentAge)–\(input.retirementAge))").font(.system(size: 11)).foregroundStyle(.secondary)
                }
                HStack(spacing: 6) {
                    Circle().fill(AppTheme.auraGreen).frame(width: 8, height: 8)
                    Text("SWP Drawdown").font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
        }
        .auraCardStyle(radius: 20)
    }

    private var drawdownTrendChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SimulatorSectionHeader(
                title: "Monthly Drawdown & Real Purchasing Power",
                subtitle: "Nominal rupee withdrawal vs inflation-adjusted equivalent",
                icon: "arrow.down.right.circle.fill"
            )

            Chart {
                ForEach(result.withdrawalTimeline) { item in
                    BarMark(
                        x: .value("Age", item.age),
                        y: .value("Amount", item.monthlyDrawdownAmount)
                    )
                    .foregroundStyle(AppTheme.vibrantCyan.opacity(0.7))

                    LineMark(
                        x: .value("Age", item.age),
                        y: .value("Real", item.realPurchasingPowerValue / 12.0)
                    )
                    .foregroundStyle(AppTheme.vibrantOrange)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }
            .frame(height: 200)

            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Circle().fill(AppTheme.vibrantCyan).frame(width: 8, height: 8)
                    Text("Nominal Monthly Draw").font(.system(size: 11)).foregroundStyle(.secondary)
                }
                HStack(spacing: 6) {
                    Circle().fill(AppTheme.vibrantOrange).frame(width: 8, height: 8)
                    Text("Purchasing Power in Today's ₹").font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
        }
        .auraCardStyle(radius: 20)
    }

    private var recommendationsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SimulatorSectionHeader(
                title: "Action Recommendations",
                subtitle: "Suggested steps to secure and prolong retirement solvency",
                icon: "lightbulb.fill",
                iconColor: AppTheme.auraGold
            )

            ForEach(result.actionRecommendations, id: \.self) { rec in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.auraGreen)
                        .padding(.top, 2)
                    Text(rec)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.primary)
                }
            }
        }
        .auraCardStyle(radius: 20)
    }

    private var yearlyBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation { showingYearlyBreakdown.toggle() }
            } label: {
                HStack {
                    SimulatorSectionHeader(
                        title: "Annual Drawdown Schedule",
                        subtitle: "Year-by-year corpus progression, draws, and returns",
                        icon: "calendar"
                    )
                    Spacer()
                    Image(systemName: showingYearlyBreakdown ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.auraIndigo)
                }
            }
            .buttonStyle(PlainButtonStyle())

            if showingYearlyBreakdown {
                Divider()
                VStack(spacing: 8) {
                    ForEach(result.withdrawalTimeline) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Age \(item.age)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(item.isDepleted ? AppTheme.vibrantRed : AppTheme.auraIndigo)
                                Spacer()
                                Text("Corpus: \(item.endingCorpus.toCurrency(compact: true))")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                            }

                            HStack {
                                Text("Gross Draw: \(item.grossWithdrawals.toCurrency(compact: true))")
                                Spacer()
                                Text("Pension: \(item.pensionIncome.toCurrency(compact: true))")
                                Spacer()
                                Text("Growth: \(item.investmentReturns.toCurrency(compact: true))")
                            }
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        }
                        .padding(10)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
        .auraCardStyle(radius: 20)
    }
}
