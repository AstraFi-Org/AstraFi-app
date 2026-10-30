import SwiftUI
import Charts

struct REITSimulatorResultView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    let input: REITSimulatorInput

    @State private var selectedStressId: String = "base"
    @State private var currentStress: REITStressScenario = REITStressScenario.standardScenarios[0]
    @State private var showingYearlyBreakdown: Bool = false

    init(input: REITSimulatorInput) {
        self.input = input
    }

    private var result: REITSimulatorResult {
        REITSimulatorEngine.simulate(input: input, appliedStress: currentStress)
    }

    private var planInputModel: InvestmentPlanInputModel {
        InvestmentPlanInputModel(
            investmentType: input.reinvestDistributions ? "REIT with DRIP" : "REIT Cash Flow",
            amount: "\(Int(input.initialLumpSumInvestment))",
            liquidity: "Moderate",
            riskType: "Moderate",
            timePeriod: "\(input.investmentHorizonYears)",
            scheduleInvestmentDate: Date(),
            scheduleSIPDate: Date(),
            purposeOfInvestment: "REIT & Listed Asset Strategy",
            targetAmount: "\(Int(result.totalNetEconomicValue))",
            savedAmount: "\(Int(input.initialLumpSumInvestment))",
            hasEmergencyFund: true
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Top Feasibility Banner
                SimulatorFeasibilityBanner(
                    status: result.feasibility,
                    explanation: result.feasibility == .healthy
                        ? "Viable income-generating allocation. Distributions and capital appreciation project positive total economic value."
                        : "Caution: Heavy stress triggers capital erosion or distribution deficits under current assumptions."
                )

                // Key metrics 2x2 grid
                metricsGrid

                // Scenario Stress Selector
                stressScenarioCard

                // Value Growth Chart
                valueGrowthChartCard

                // Annual Distributions Chart
                distributionsChartCard

                // Reinvestment vs Cash Flow Breakdown
                reinvestmentBreakdownCard

                // Advisory Notes
                notesCard

                // Yearly Breakdown Table
                yearlyBreakdownCard

                // Save & Follow Footer
                SimulatorSaveFooter(
                    planName: "REIT Listed Income Strategy",
                    targetGoal: "Income & Capital Growth",
                    planInput: planInputModel
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(AppTheme.appBackground(for: colorScheme))
        .navigationTitle("REIT Strategy Results")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            SimulatorMetricCard(
                title: "Capital Invested",
                value: result.totalCapitalInvested.toCurrency(compact: true),
                subtitle: "Lump sum + monthly SIP",
                color: AppTheme.auraIndigo,
                icon: "banknote"
            )

            SimulatorMetricCard(
                title: "Portfolio Market Value",
                value: result.finalPortfolioMarketValue.toCurrency(compact: true),
                subtitle: "\(String(format: "%.0f", result.totalUnitsAccumulated)) units held",
                color: AppTheme.auraGreen,
                icon: "building.2.fill"
            )

            SimulatorMetricCard(
                title: "Distributions Received",
                value: result.cumulativeNetDistributions.toCurrency(compact: true),
                subtitle: input.reinvestDistributions ? "Reinvested into units" : "Paid as cash dividends",
                color: AppTheme.vibrantCyan,
                icon: "arrow.triangle.2.circlepath"
            )

            SimulatorMetricCard(
                title: "Annualized CAGR",
                value: String(format: "%.1f%%", result.annualizedCAGR),
                subtitle: "Total return \(String(format: "%.0f%%", result.netAbsoluteReturnPct))",
                color: AppTheme.auraPurple,
                icon: "chart.line.uptrend.xyaxis"
            )
        }
    }

    private var stressScenarioCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SimulatorSectionHeader(
                title: "Commercial Stress-Testing",
                subtitle: "Simulate vacancy shocks and yield expansion risks",
                icon: "bolt.shield.fill"
            )

            Picker("Scenario", selection: $selectedStressId) {
                ForEach(REITStressScenario.standardScenarios) { sc in
                    Text(sc.title).tag(sc.id)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedStressId) { _, newId in
                if let matched = REITStressScenario.standardScenarios.first(where: { $0.id == newId }) {
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

    private var valueGrowthChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SimulatorSectionHeader(
                title: "Portfolio Valuation Over Time",
                subtitle: "Cumulative capital invested vs market value",
                icon: "chart.xyaxis.line"
            )

            Chart {
                ForEach(result.yearlySnapshots) { snap in
                    LineMark(
                        x: .value("Year", "Y\(snap.year)"),
                        y: .value("Value", snap.endingPortfolioMarketValue)
                    )
                    .foregroundStyle(AppTheme.auraGreen)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Year", "Y\(snap.year)"),
                        y: .value("Value", snap.endingPortfolioMarketValue)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.auraGreen.opacity(0.3), AppTheme.auraGreen.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Year", "Y\(snap.year)"),
                        y: .value("Invested", snap.cumulativeContributions)
                    )
                    .foregroundStyle(Color.secondary)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                }
            }
            .frame(height: 220)

            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Circle().fill(AppTheme.auraGreen).frame(width: 8, height: 8)
                    Text("Portfolio Value").font(.system(size: 11)).foregroundStyle(.secondary)
                }
                HStack(spacing: 6) {
                    Circle().fill(Color.secondary).frame(width: 8, height: 8)
                    Text("Invested Principal").font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
        }
        .auraCardStyle(radius: 20)
    }

    private var distributionsChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SimulatorSectionHeader(
                title: "Annual Distributions Trend",
                subtitle: "Cash dividends generated each year",
                icon: "banknote"
            )

            Chart {
                ForEach(result.yearlySnapshots) { snap in
                    BarMark(
                        x: .value("Year", "Y\(snap.year)"),
                        y: .value("Distribution", snap.netDistributionsReceived)
                    )
                    .foregroundStyle(AppTheme.auraIndigo)
                    .cornerRadius(6)
                }
            }
            .frame(height: 180)
        }
        .auraCardStyle(radius: 20)
    }

    private var reinvestmentBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SimulatorSectionHeader(
                title: input.reinvestDistributions ? "DRIP Compounding Effect" : "Cash Distribution Summary",
                subtitle: input.reinvestDistributions ? "Additional units bought via reinvestment" : "Total spendable liquidity harvested",
                icon: "arrow.triangle.2.circlepath"
            )

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ending Units")
                        .font(.auraCaption())
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f", result.totalUnitsAccumulated))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Unit Price at Exit")
                        .font(.auraCaption())
                        .foregroundStyle(.secondary)
                    Text("₹\(String(format: "%.1f", result.finalUnitPrice))")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.auraIndigo)
                }
            }

            Divider()

            HStack {
                Text("Indicative Annual Run-Rate Distribution:")
                    .font(.auraCaption())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(result.finalAnnualRunrateDistribution.toCurrency(compact: true) + " / yr")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.auraGreen)
            }
        }
        .auraCardStyle(radius: 20)
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SimulatorSectionHeader(
                title: "Financial Notes & Methodology",
                subtitle: "Transparent statutory & market conventions",
                icon: "info.circle.fill"
            )

            ForEach(result.summaryNotes, id: \.self) { note in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(AppTheme.auraIndigo)
                        .padding(.top, 6)
                    Text(note)
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
                        title: "Year-by-Year Snapshot",
                        subtitle: "Units, distributions, and portfolio progression",
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
                    ForEach(result.yearlySnapshots) { snap in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Year \(snap.year)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(AppTheme.auraIndigo)
                                Spacer()
                                Text("Value: \(snap.endingPortfolioMarketValue.toCurrency(compact: true))")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                            }

                            HStack {
                                Text("Units: \(String(format: "%.0f", snap.endingUnits))")
                                Spacer()
                                Text("Price: ₹\(String(format: "%.1f", snap.unitPrice))")
                                Spacer()
                                Text("Dist: \(snap.netDistributionsReceived.toCurrency(compact: true))")
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
