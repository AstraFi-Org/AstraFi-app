import SwiftUI
import Charts

struct FixedIncomeLadderResultView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    let input: FixedIncomeLadderInput

    @State private var selectedStressId: String = "baseline"
    @State private var currentStress: LadderStressScenario = LadderStressScenario.standardScenarios[0]
    @State private var showingYearlyBreakdown: Bool = false

    init(input: FixedIncomeLadderInput) {
        self.input = input
    }

    private var result: FixedIncomeLadderResult {
        FixedIncomeLadderEngine.simulate(input: input, appliedStress: currentStress)
    }

    private var planInputModel: InvestmentPlanInputModel {
        InvestmentPlanInputModel(
            investmentType: "Fixed-Income Ladder",
            amount: "\(Int(result.totalCapitalAllocated))",
            liquidity: "High",
            riskType: "Conservative",
            timePeriod: "\(result.yearlySummaries.count)",
            scheduleInvestmentDate: Date(),
            scheduleSIPDate: Date(),
            purposeOfInvestment: "Fixed-Income Ladder & Liquidity Strategy",
            targetAmount: "\(Int(result.endingPortfolioValue + result.endingAvailableCash))",
            savedAmount: "\(Int(result.totalCapitalAllocated))",
            hasEmergencyFund: true
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Top feasibility banner
                SimulatorFeasibilityBanner(
                    status: result.feasibility,
                    explanation: result.feasibilityExplanation
                )

                // Key metrics 2x2 grid
                metricsGrid

                // Scenario Stress Selector
                stressScenarioCard

                // Interactive Cash-Flow Chart
                cashFlowChartCard

                // Maturity Allocation Chart
                maturityTimelineCard

                // Warnings & Gaps
                if !result.concentrationWarnings.isEmpty || !result.liquidityGaps.isEmpty {
                    risksAndGapsCard
                }

                // Yearly Breakdown Table
                yearlyBreakdownCard

                // Save & Follow Footer
                SimulatorSaveFooter(
                    planName: "Fixed-Income Ladder Strategy",
                    targetGoal: "Fixed Income & Liquidity",
                    planInput: planInputModel
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(AppTheme.appBackground(for: colorScheme))
        .navigationTitle("Ladder Strategy Results")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            SimulatorMetricCard(
                title: "Capital Allocated",
                value: result.totalCapitalAllocated.toCurrency(compact: true),
                subtitle: "Across \(input.ladderEntries.count) tranches",
                color: AppTheme.auraIndigo,
                icon: "stairs"
            )

            SimulatorMetricCard(
                title: "Net Interest Earned",
                value: result.totalCumulativeInterestNet.toCurrency(compact: true),
                subtitle: "Post taxes and fees",
                color: AppTheme.auraGreen,
                icon: "percent"
            )

            SimulatorMetricCard(
                title: "Maturity Proceeds",
                value: result.totalMaturityProceedsGross.toCurrency(compact: true),
                subtitle: "Total principal returned",
                color: AppTheme.vibrantCyan,
                icon: "arrow.uturn.down.circle.fill"
            )

            SimulatorMetricCard(
                title: "Ending Available Cash",
                value: result.endingAvailableCash.toCurrency(compact: true),
                subtitle: "Post reinvestment & draws",
                color: AppTheme.vibrantOrange,
                icon: "banknote.fill"
            )
        }
    }

    private var stressScenarioCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SimulatorSectionHeader(
                title: "Scenario Stress-Testing",
                subtitle: "Evaluate ladder resilience against rate drops and market shocks",
                icon: "bolt.shield.fill"
            )

            Picker("Scenario", selection: $selectedStressId) {
                ForEach(LadderStressScenario.standardScenarios) { sc in
                    Text(sc.title).tag(sc.id)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedStressId) { _, newId in
                if let matched = LadderStressScenario.standardScenarios.first(where: { $0.id == newId }) {
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

    private var cashFlowChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SimulatorSectionHeader(
                title: "Annual Cash Flows",
                subtitle: "Interest distributions vs maturity principal receipts",
                icon: "chart.bar.fill"
            )

            Chart {
                ForEach(result.yearlySummaries) { item in
                    BarMark(
                        x: .value("Year", "Y\(item.yearOffset)"),
                        y: .value("Amount", item.totalInterestReceived)
                    )
                    .foregroundStyle(by: .value("Type", "Interest Income"))
                    .position(by: .value("Type", "Interest Income"))

                    BarMark(
                        x: .value("Year", "Y\(item.yearOffset)"),
                        y: .value("Amount", item.totalMaturityProceeds)
                    )
                    .foregroundStyle(by: .value("Type", "Maturity Principal"))
                    .position(by: .value("Type", "Maturity Principal"))
                }
            }
            .chartForegroundStyleScale([
                "Interest Income": AppTheme.auraGreen,
                "Maturity Principal": AppTheme.auraIndigo
            ])
            .chartLegend(position: .top, alignment: .leading)
            .frame(height: 220)
        }
        .auraCardStyle(radius: 20)
    }

    private var maturityTimelineCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SimulatorSectionHeader(
                title: "Instrument Allocation Breakdown",
                subtitle: "Capital distribution across fixed-income instruments",
                icon: "piechart.fill"
            )

            VStack(spacing: 8) {
                ForEach(result.allocationByInstrument.sorted(by: { $0.value > $1.value }), id: \.key) { key, amount in
                    let pct = (amount / max(1.0, result.totalCapitalAllocated)) * 100.0
                    HStack {
                        Text(key)
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Text(amount.toCurrency(compact: true))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                        Text("(\(String(format: "%.1f", pct))%)")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.secondary.opacity(0.15))
                            Capsule()
                                .fill(AppTheme.accentGradient)
                                .frame(width: geo.size.width * CGFloat(pct / 100.0))
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .auraCardStyle(radius: 20)
    }

    private var risksAndGapsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SimulatorSectionHeader(
                title: "Concentration & Liquidity Gaps",
                subtitle: "Risk alerts detected during simulation",
                icon: "exclamationmark.triangle.fill",
                iconColor: AppTheme.vibrantOrange
            )

            ForEach(result.concentrationWarnings, id: \.self) { warning in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(AppTheme.vibrantOrange)
                        .padding(.top, 6)
                    Text(warning)
                        .font(.auraCaption())
                        .foregroundStyle(.primary)
                }
            }

            ForEach(result.liquidityGaps, id: \.self) { gap in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(AppTheme.vibrantCyan)
                        .padding(.top, 6)
                    Text(gap)
                        .font(.auraCaption())
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
                        title: "Year-by-Year Cash-Flow Schedule",
                        subtitle: "Detailed proceeds, reinvestments, and ending balances",
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
                    ForEach(result.yearlySummaries) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Year \(item.yearOffset)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(AppTheme.auraIndigo)
                                Spacer()
                                Text("Available Cash: \(item.availableCashBalance.toCurrency(compact: true))")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                            }

                            HStack {
                                Text("Interest: \(item.totalInterestReceived.toCurrency(compact: true))")
                                Spacer()
                                Text("Maturities: \(item.totalMaturityProceeds.toCurrency(compact: true))")
                                Spacer()
                                Text("Reinvested: \(item.totalReinvested.toCurrency(compact: true))")
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
