import SwiftUI
import Charts

struct Plan3DetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppStateManager.self) var appState

    var input: InvestmentPlanInputModel
    var result: Plan3Result
    var isFromTracker: Bool = false

    @State private var selectedScenario: String = "Moderate"
    @State private var investmentMode: String = "Lumpsum"
    @State private var lumpsumPhases: Int = 5
    @State private var isEMIDeductionOn: Bool = true

    @State private var currentResult: Plan3Result? = nil
    @State private var loanOverride: Double = 0
    @State private var tenureOverride: Int = 5
    @State private var bankName: String = ""
    @State private var interestRate: Double = 10.5
    @State private var emiFrequency: EMIFrequency = .monthly
    @State private var interestType: InterestType = .compounded
    @State private var selectedYearIndex: Int = 0

    private var activeResult: Plan3Result { currentResult ?? result }

    private var currentStrategy: LeveragedStrategyResult {
        switch selectedScenario {
        case "Conservative": return activeResult.conservative
        case "Moderate": return activeResult.moderate
        case "Aggressive": return activeResult.aggressive
        default: return activeResult.moderate
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 24) {
                    summaryCard

                    scenarioComparisonCard

                    leveragedGraphCard

                    interactiveAdjusters

                    bankDetailsCard

                    recommendationCard

                    strategyBuilderCard

                    if let portfolio = activeResult.portfolio {
                        portfolioTableCard(portfolio: portfolio)
                    }

                    investmentBreakdownSection

                    milestonesTableCard

                    finalSummaryCard
                }
                .padding()
                .padding(.bottom, 100)
            }
            .background(AppTheme.appBackground(for: .light))

            if !isFromTracker {
                savePlanFooter
            }
        }
        .onAppear {
            loanOverride = InvestmentPlannerEngine.parseAmount(input.targetAmount)
            tenureOverride = Int(input.timePeriod) ?? 5
            bankName = input.bankName ?? ""
            interestRate = input.interestRate ?? 10.5
            recalculate()
        }
        .navigationTitle("Leveraged Investing")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var savePlanFooter: some View {
        Button(action: {
            let model = InvestmentPlanModel(
                name: "Leveraged: \(activeResult.recommendedStrategy)",
                dateSaved: DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none),
                targetGoal: input.purposeOfInvestment,
                input: input
            )
            appState.savePlan(model)
            appState.showDashboard = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "star.fill")
                Text("Save & Follow Plan")
                    .font(.headline).fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(AppTheme.accentGradient)
            .cornerRadius(16)
            .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .background(
            LinearGradient(colors: [.clear, .white.opacity(0.9), .white], startPoint: .top, endPoint: .bottom)
                .frame(height: 120)
        )
    }

    private func recalculate() {
        let newResult = InvestmentPlannerEngine.recalculatePlan3(
            input: input,
            overridenLoan: loanOverride,
            overridenTenure: tenureOverride,
            overridenBank: bankName.isEmpty ? nil : bankName,
            overridenRate: interestRate > 0 ? interestRate : nil,
            overridenReturn: nil,
            emiFrequency: emiFrequency,
            interestType: interestType,
            investmentMode: investmentMode,
            lumpsumPhases: lumpsumPhases,
            emiFromPocket: !isEMIDeductionOn
        )
        withAnimation {
            currentResult = newResult
        }
    }

    private var summaryCard: some View {
        let healthScore = appState.currentProfile?.financialHealthReport?.investmentScore ?? 50
        let isSafe = healthScore >= 60

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Arbitrage Potential")
                        .font(.headline)
                    Text("Loan interest vs Portfolio growth")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                ZStack {
                    Circle().stroke(Color.blue.opacity(0.1), lineWidth: 6)
                    Circle().trim(from: 0, to: 0.75).stroke(Color.blue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    Text("\(Int(currentStrategy.netProfit > 0 ? 88 : 42))%").font(.system(size: 10, weight: .bold))
                }
                .frame(width: 45, height: 45)
            }

            Divider()

            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Net Wealth").font(.caption).foregroundColor(.secondary)
                    Text("₹\(formatS_Final(currentStrategy.netProfit))").font(.headline).bold().foregroundColor(currentStrategy.netProfit > 0 ? .green : .red)
                }
                VStack(alignment: .leading) {
                    Text("Market ROI").font(.caption).foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", activeResult.portfolio?.blendedCAGR ?? 0))%").font(.headline).bold().foregroundColor(.blue)
                }
                VStack(alignment: .leading) {
                    Text("Total ROI").font(.caption).foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", (currentStrategy.netProfit / (activeResult.loanAmount > 0 ? activeResult.loanAmount : 1)) * 100))%").font(.headline).bold()
                }
            }

            HStack {
                Image(systemName: isSafe ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(isSafe ? .green : .orange)
                Text(isSafe ? "Financial health is strong for leverage." : "Caution: Strategy suggested based on current grade.")
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(10)
            .background((isSafe ? Color.green : Color.orange).opacity(0.1))
            .cornerRadius(10)
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.3), radius: 8)
    }

    private var scenarioComparisonCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Strategy Selection")
                .font(.headline)

            Picker("Strategy Selection", selection: $selectedScenario) {
                ForEach(["Conservative", "Moderate", "Aggressive"], id: \.self) { scenario in
                    Text(scenario).tag(scenario)
                }
            }
            .pickerStyle(.segmented)

            let strat = currentStrategy
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Projected Final Value").font(.caption).foregroundColor(.secondary)
                    Text("₹\(formatL(strat.finalValue))").font(.title3).bold()
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Risk Profile").font(.caption).foregroundColor(.secondary)
                    Text(strat.riskLevel).foregroundColor(strat.riskLevel == "High" ? .red : (strat.riskLevel == "Low" ? .green : .orange)).bold()
                }
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.3), radius: 8)
    }

    private var leveragedGraphCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Growth Projection")
                .font(.headline)

            Chart {
                ForEach(currentStrategy.yearlyBreakdown) { year in
                    LineMark(
                        x: .value("Year", year.year),
                        y: .value("Value", year.monthlySteps.last?.endValue ?? 0)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Year", year.year),
                        y: .value("Value", year.monthlySteps.last?.endValue ?? 0)
                    )
                    .foregroundStyle(Color.blue.opacity(0.1).gradient)
                    .interpolationMethod(.catmullRom)
                }

                RuleMark(y: .value("Loan Principal", activeResult.loanAmount))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    .foregroundStyle(.gray.opacity(0.5))
            }
            .frame(height: 180)
            .chartXScale(domain: 1...Swift.max(2, activeResult.tenure))

            HStack {
                HStack(spacing: 4) {
                    Circle().fill(Color.blue).frame(width: 8, height: 8)
                    Text("Portfolio Value").font(.caption2).foregroundColor(.secondary)
                }
                HStack(spacing: 4) {
                    Rectangle().fill(Color.gray.opacity(0.5)).frame(width: 12, height: 1)
                    Text("Loan Principal").font(.caption2).foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.3), radius: 8)
    }

    private var interactiveAdjusters: some View {
        VStack(spacing: 20) {
            Text("Loan Adjustment")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Loan Amount").font(.footnote).foregroundColor(.secondary)
                    Spacer()
                    Text("₹\(Int(loanOverride).formatted())").font(.subheadline).bold()
                }
                Slider(value: $loanOverride, in: 50000...10000000, step: 50000)
                    .onChange(of: loanOverride) { _, _ in recalculate() }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Duration (Years)").font(.footnote).foregroundColor(.secondary)
                    Spacer()
                    Text("\(tenureOverride)").font(.subheadline).bold()
                }
                Slider(value: Binding(get: { Double(tenureOverride) }, set: { tenureOverride = Int($0) }), in: 1...25, step: 1)
                    .onChange(of: tenureOverride) { _, _ in recalculate() }
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
    }

    private var bankDetailsCard: some View {
        VStack(spacing: 16) {
            Text("Bank & Interest Config")
                .font(.headline).frame(maxWidth: .infinity, alignment: .leading)
            HStack {
                TextField("Bank Name", text: $bankName).textFieldStyle(.roundedBorder)
                TextField("ROI %", value: $interestRate, format: .number).textFieldStyle(.roundedBorder).keyboardType(.decimalPad).frame(width: 80)
            }
            .onChange(of: interestRate) { _, _ in recalculate() }

            Picker("EMI Type", selection: $emiFrequency) {
                Text("Monthly").tag(EMIFrequency.monthly)
                Text("Quarterly").tag(EMIFrequency.quarterly)
            }
            .pickerStyle(.segmented)
            .onChange(of: emiFrequency) { _, _ in recalculate() }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
    }

    private var recommendationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill").foregroundColor(.yellow)
                Text("Astra Recommendation").font(.headline)
            }
            Text(activeResult.recommendationReason)
                .font(.subheadline).foregroundColor(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
    }

    private var strategyBuilderCard: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Strategy Builder").font(.headline)
                Spacer()
                Stepper("\(lumpsumPhases) Phase(s)", value: $lumpsumPhases, in: 1...12)
                    .onChange(of: lumpsumPhases) { _, _ in recalculate() }
            }

            StrategyCircularChart(total: activeResult.loanAmount, phases: lumpsumPhases, mode: "Lumpsum")

            HStack {
                Text("Deduct EMI from Investment").font(.subheadline).foregroundColor(.secondary)
                Spacer()
                Toggle("", isOn: $isEMIDeductionOn)
                    .labelsHidden()
                    .onChange(of: isEMIDeductionOn) { _, _ in recalculate() }
            }
            Text(isEMIDeductionOn ? "EMI is automatically withdrawn from the investment." : "EMI is paid from your surplus monthly.")
                .font(.caption2).foregroundColor(.secondary).italic()
        }
        .padding(24)
        .background(AppTheme.cardBackground)
        .cornerRadius(24)
    }

    private func portfolioTableCard(portfolio: PortfolioBlueprint) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Total Investment : ")
                    .font(.subheadline).foregroundColor(.secondary)
                Text("₹\(formatL(activeResult.loanAmount))")
                    .font(.headline).fontWeight(.bold).foregroundColor(.primary)
                Text("(in \(activeResult.tenure) years)")
                    .font(.caption).foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)

            Divider()

            VStack(spacing: 12) {
                ScenarioHeaderRow()

                let c = activeResult.conservative
                let m = activeResult.moderate
                let a = activeResult.aggressive
                
                let isCons = selectedScenario == "Conservative"
                let isMod = selectedScenario == "Moderate"
                
                let crashImpact = isCons ? 0.15 : (isMod ? 0.25 : 0.35)
                let bullImpact = isCons ? 0.15 : (isMod ? 0.25 : 0.40)
                
                let worstGain = currentStrategy.netProfit - (currentStrategy.finalValue * crashImpact)
                let worstFinal = currentStrategy.finalValue * (1 - crashImpact)
                
                let bestGain = currentStrategy.netProfit + (currentStrategy.finalValue * bullImpact)
                let bestFinal = currentStrategy.finalValue * (1 + bullImpact)
                
                let scenarioSubtext = "(\(selectedScenario))"
                
                ScenarioDataRow(scenario: "Worst case \(scenarioSubtext)", gainLoss: formatG(worstGain), finalValue: formatG(worstFinal), isNegative: worstGain < 0)
                ScenarioDataRow(scenario: "Conservative", gainLoss: formatG(c.netProfit), finalValue: formatG(c.finalValue), isNegative: c.netProfit < 0)
                ScenarioDataRow(scenario: "Moderate", gainLoss: formatG(m.netProfit), finalValue: formatG(m.finalValue), isNegative: m.netProfit < 0)
                ScenarioDataRow(scenario: "Aggressive", gainLoss: formatG(a.netProfit), finalValue: formatG(a.finalValue), isNegative: a.netProfit < 0)
                ScenarioDataRow(scenario: "Bull Market \(scenarioSubtext)", gainLoss: formatG(bestGain), finalValue: formatG(bestFinal), isNegative: bestGain < 0)
            }
            .padding(20)

            Divider()

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    TableHeaderCell(text: "Investment Type", alignment: .leading,  flex: 2.5)
                    TableHeaderCell(text: "Expected Amt",    alignment: .trailing, flex: 1.5)
                    TableHeaderCell(text: "Invested Amt",    alignment: .trailing, flex: 1.5)
                    TableHeaderCell(text: "Risk Type",       alignment: .trailing, flex: 1.2)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(Color(UIColor.systemGray6))

                ForEach(portfolio.allocations) { asset in
                    let invested = activeResult.loanAmount * (asset.percentage / 100)
                    let expected = invested * pow(1 + asset.expectedCAGR / 100, Double(activeResult.tenure))
                    InvestmentTableRow(type: asset.name,
                                       invested: "₹\(formatL(invested))",
                                       expected: "₹\(formatL(expected))",
                                       risk: asset.riskLevel.rawValue.capitalized,
                                       riskColor: asset.riskLevel == .low ? .green : (asset.riskLevel == .mid ? .orange : .red))
                    .padding(.horizontal, 12)
                    
                    if asset.id != portfolio.allocations.last?.id {
                        Divider()
                    }
                }
            }
        }
        .background(AppTheme.cardBackground)
        .cornerRadius(24)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.3), radius: 8)
    }

    private func formatG(_ v: Double) -> String {
        let prefix = v < 0 ? "" : "+"
        let absV = abs(v)
        let formatted: String
        if absV >= 10000000 { formatted = String(format: "%.1fCr", absV / 10000000) }
        else if absV >= 100000 { formatted = String(format: "%.1fL", absV / 100000) }
        else { formatted = String(format: "%.0fK", absV / 1000) }
        
        return v < 0 ? "-\(formatted)" : "\(prefix)\(formatted)"
    }

    private var investmentBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Yearly Breakdown")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 16) {
                    ForEach(0..<currentStrategy.yearlyBreakdown.count, id: \.self) { index in
                        let yearData = currentStrategy.yearlyBreakdown[index]
                        YearlyBarItem(
                            yearLabel: "\(Calendar.current.component(.year, from: Date()) + index)",
                            topValue: formatL(yearData.netYearlyProfit),
                            bottomValue: formatL(yearData.startValue),
                            isSelected: selectedYearIndex == index,
                            height: calculateBarHeight(yearData.startValue)
                        )
                        .onTapGesture { withAnimation { selectedYearIndex = index } }
                    }
                }
            }
        }
        .padding(24)
        .background(AppTheme.cardBackground)
        .cornerRadius(24)
    }

    private var milestonesTableCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly Performance")
                .font(.headline)

            if selectedYearIndex < currentStrategy.yearlyBreakdown.count {
                let year = currentStrategy.yearlyBreakdown[selectedYearIndex]
                VStack(spacing: 0) {
                    HStack {
                        Text("Month").bold().frame(maxWidth: .infinity, alignment: .leading)
                        Text("Start").bold().frame(width: 85, alignment: .trailing)
                        if isEMIDeductionOn {
                            Text("EMI").bold().frame(width: 50, alignment: .trailing)
                        }
                        Text("Growth").bold().frame(width: 60, alignment: .trailing)
                        Text("End").bold().frame(width: 70, alignment: .trailing)
                    }
                    .font(.system(size: 9, weight: .bold)).foregroundColor(.secondary).padding(.bottom, 12)

                    Divider()

                    ForEach(year.monthlySteps) { step in
                        HStack(spacing: 4) {
                            Text(step.month).frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: 1) {
                                if step.investment > 0 && selectedYearIndex == 0 {
                                    Text(formatL(step.startValue)).font(.system(size: 9))
                                    Text("+").foregroundColor(.blue).font(.system(size: 8))
                                    Text(formatL(step.investment)).font(.system(size: 9)).bold()
                                } else {
                                    Text(formatL(step.startValue))
                                }
                            }
                            .frame(width: 85, alignment: .trailing)

                            if isEMIDeductionOn {
                                Text(step.emiFromPocket > 0 ? formatL(step.emiFromPocket) : "-")
                                    .font(.system(size: 10))
                                    .frame(width: 50, alignment: .trailing)
                                    .foregroundColor(.orange)
                            }

                            Text((step.growth >= 0 ? "+" : "") + formatL(step.growth))
                                .font(.system(size: 10))
                                .frame(width: 60, alignment: .trailing)
                                .foregroundColor(step.growth >= 0 ? .green : .red)

                            Text(formatL(step.endValue))
                                .frame(width: 70, alignment: .trailing).bold()
                        }
                        .font(.system(size: 11)).padding(.vertical, 12)
                        Divider()
                    }
                }
            }
        }
        .padding(24)
        .background(AppTheme.cardBackground)
        .cornerRadius(24)
    }

    private var finalSummaryCard: some View {
        let strat = currentStrategy
        let loanAmt = activeResult.loanAmount
        let totalRepayment = strat.totalEMIPaid
        let interestCost = Swift.max(0, totalRepayment - loanAmt)

        return VStack(alignment: .leading, spacing: 20) {
            Text("Outcome Summary")
                .font(.headline)

            VStack(spacing: 16) {
                SummaryRow(label: "Capital Borrowed", value: formatL(loanAmt), color: .primary)
                SummaryRow(label: "Interest Cost", value: formatL(interestCost), color: .red)
                SummaryRow(label: "Total Bank Repayment", value: formatL(totalRepayment), color: .secondary)

                Divider()

                SummaryRow(label: "Final Portfolio Value", value: formatL(strat.finalValue), color: .blue)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Net Wealth Gain").font(.caption).foregroundColor(.secondary)
                        Text("₹\(formatS_Final(strat.netProfit))").font(.title2).bold().foregroundColor(strat.netProfit > 0 ? .green : .red)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Arb. Spread").font(.caption).foregroundColor(.secondary)
                        Text("\(String(format: "%.1f", (strat.netProfit / (loanAmt > 0 ? loanAmt : 1)) * 100))%").font(.title3).bold()
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(12)
            }

            Text(isEMIDeductionOn ?
                "*Results shown with EMI automated from your portfolio. No out-of-pocket costs after initial setup." :
                "*Results shown with EMI paid from your monthly surplus. Maximum capital growth retained.")
                .font(.caption2).foregroundColor(.secondary).italic()
        }
        .padding(24)
        .background(AppTheme.cardBackground)
        .cornerRadius(24)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.3), radius: 8)
    }

    private func formatS_Final(_ v: Double) -> String {
        let absV = abs(v)
        let sign = v < 0 ? "-" : ""
        if absV >= 10000000 { return "\(sign)\(String(format: "%.1fCr", absV / 10000000))" }
        if absV >= 100000 { return "\(sign)\(String(format: "%.1fL", absV / 100000))" }
        return "\(sign)\(String(format: "%.0fK", absV / 1000))"
    }

    struct SummaryRow: View {
        let label: String
        let value: String
        let color: Color
        var body: some View {
            HStack {
                Text(label).font(.subheadline).foregroundColor(.secondary)
                Spacer()
                Text("₹\(value)").font(.subheadline).bold().foregroundColor(color)
            }
        }
    }
    private func formatL(_ v: Double) -> String {
        let absV = abs(v)
        if absV >= 10000000 { return String(format: "%.1fCr", v / 10000000) }
        if absV >= 100000 { return String(format: "%.1fL", v / 100000) }
        if absV >= 1000 { return String(format: "%.1fK", v / 1000) }
        return String(format: "%.0f", v)
    }

    private func calculateBarHeight(_ value: Double) -> CGFloat {
        let maxV = currentStrategy.yearlyBreakdown.map { $0.startValue }.max() ?? 1
        return CGFloat(max(40, (value / (maxV > 0 ? maxV : 1)) * 120))
    }
}

struct YearlyBarItem: View {
    let yearLabel: String
    let topValue: String
    let bottomValue: String
    let isSelected: Bool
    let height: CGFloat

    var body: some View {
        VStack(spacing: 8) {
            Text(topValue).font(.system(size: 9, weight: .bold)).foregroundColor(.green)
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue : Color.blue.opacity(0.15))
                .frame(width: 40, height: height)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue.opacity(0.3), lineWidth: 1))
            Text(yearLabel).font(.caption2).bold().foregroundColor(isSelected ? .primary : .secondary)
            Text(bottomValue).font(.system(size: 8)).foregroundColor(.secondary)
        }
    }
}

struct StrategyCircularChart: View {
    let total: Double
    let phases: Int
    let mode: String

    var body: some View {
        ZStack {

            Circle()
                .stroke(Color.secondary.opacity(0.1), lineWidth: 20)
                .frame(width: 170, height: 170)

            ForEach(0..<12) { i in
                let angle = Angle(degrees: Double(i) * 30 - 90)
                let interval = max(1, 12 / max(1, phases))

                let isHighlighted = mode == "Lumpsum" && (i % interval == 0) && (i / interval < phases)

                Circle()
                    .trim(from: CGFloat(i) * 1/12 + 0.005, to: CGFloat(i+1) * 1/12 - 0.005)
                    .stroke(isHighlighted ? Color.blue.gradient : Color.secondary.opacity(0.15).gradient, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 170, height: 170)
                    .rotationEffect(.degrees(-90))

                Text(monthLabel(for: i).uppercased())
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundColor(isHighlighted ? .blue : .secondary.opacity(0.5))
                    .offset(x: 105 * cos(angle.radians), y: 105 * sin(angle.radians))
            }

            VStack(spacing: 4) {
                Text("TOTAL PRINCIPAL")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(.secondary)
                    .opacity(0.8)

                Text("₹\(formatS(total))")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                if phases >= 1 {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                        Text("\(phases) \(phases == 1 ? "Injection" : "Injections")")
                    }
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(20)
                }
            }
        }
        .frame(height: 240)
    }

    private func formatS(_ v: Double) -> String {
        if v >= 10000000 { return String(format: "%.1fCr", v / 10000000) }
        if v >= 100000 { return String(format: "%.1fL", v / 100000) }
        return String(format: "%.0fK", v / 1000)
    }

    private func monthLabel(for i: Int) -> String {
        ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][i]
    }
}
