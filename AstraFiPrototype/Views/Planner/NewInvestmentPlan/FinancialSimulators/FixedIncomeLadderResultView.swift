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

    private var endingTotalValue: Double {
        result.endingAvailableCash + result.endingPortfolioValue
    }

    private var principalNotReinvested: Double {
        result.timelineEvents.filter(\.isMaturityPrincipal).reduce(0) { total, event in
            let sourceEntry = entry(for: event)
            let withdrawal = sourceEntry.map { plannedWithdrawal(for: $0, in: event.yearOffset) } ?? 0
            let reinvestedPrincipal = reinvestmentRecord(for: event)?.principalReinvested ?? 0
            return total + max(0, event.netCashInflow - reinvestedPrincipal - withdrawal)
        }
    }

    private var projectedChange: Double {
        endingTotalValue - input.totalCapitalAvailable
    }

    private func interestEvents(in year: Int) -> [LadderCashFlowEvent] {
        result.timelineEvents.filter { $0.yearOffset == year && !$0.isMaturityPrincipal }
    }

    private func principalEvents(in year: Int) -> [LadderCashFlowEvent] {
        result.timelineEvents.filter { $0.yearOffset == year && $0.isMaturityPrincipal }
    }

    private func entry(for event: LadderCashFlowEvent) -> FixedIncomeEntry? {
        let entries = result.simulatedLadderEntries ?? input.ladderEntries
        return entries.first(where: { $0.id == event.entryID }) ?? entries.first {
            $0.instrumentName == event.instrumentName && $0.maturityYearOffset == event.yearOffset
        }
    }

    private func reinvestmentRecord(for event: LadderCashFlowEvent) -> LadderReinvestmentRecord? {
        (result.reinvestmentRecords ?? []).first {
            guard $0.yearOffset == event.yearOffset else { return false }
            if let sourceEntryID = $0.sourceEntryID { return sourceEntryID == event.entryID }
            return $0.sourceTrancheName == event.instrumentName
        }
    }

    private func reinvestmentRecord(forEntryID entryID: UUID?, in year: Int) -> LadderReinvestmentRecord? {
        (result.reinvestmentRecords ?? []).first { $0.sourceEntryID == entryID && $0.yearOffset == year }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "Date unavailable" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    private func plannedWithdrawal(for entry: FixedIncomeEntry, in year: Int) -> Double {
        entry.plannedWithdrawalAtMaturity * pow(
            1.0 + (input.inflationAssumptionPct + currentStress.expenseInflationIncreasePct) / 100.0,
            Double(year)
        )
    }

    private var selectedStressExplanation: String {
        switch currentStress.id {
        case "baseline":
            return "Use the entered rates and inflation assumptions without adding a shock. This is the reference case for comparing the other scenarios."
        case "rate_cut_2pct":
            return "Assume future-starting entries earn 2 percentage points less than their entered rate. For example, 7% becomes 5%. This tests the effect of lower rates when money is reinvested later."
        case "rate_cut_3pct_inflation":
            return "Assume future-starting entries earn 3 percentage points less, while expenses rise 3 percentage points faster. This can reduce future income and increase planned withdrawals."
        case "liquidity_crunch_sale":
            return "Apply an 8% reduction to government-security and corporate-bond principal proceeds. This is a simplified haircut estimate; it does not model the timing or market price of a particular sale."
        case "corp_default":
            return "Assume corporate bonds return 60% of principal at maturity, meaning a 40% principal loss on those bonds. Other investment types are not given this default loss."
        default:
            return currentStress.description
        }
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

                outcomeSummaryCard

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
                title: "Invested at Start",
                value: result.totalCapitalAllocated.toCurrency(compact: true),
                subtitle: "Across \(input.ladderEntries.count) investments",
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
                title: "Cumulative Maturities",
                value: result.totalMaturityProceedsGross.toCurrency(compact: true),
                subtitle: "Includes principal that may be reinvested",
                color: AppTheme.vibrantCyan,
                icon: "arrow.uturn.down.circle.fill"
            )

            SimulatorMetricCard(
                title: "Cash at Plan End",
                value: result.endingAvailableCash.toCurrency(compact: true),
                subtitle: "At year \(result.yearlySummaries.last?.yearOffset ?? 0), including starting unallocated cash",
                color: AppTheme.vibrantOrange,
                icon: "banknote.fill"
            )
        }
    }

    private var outcomeSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("What you may have at the end")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                InfoHintButton(
                    title: "End-of-plan estimate",
                    message: "The end date is the modeled horizon: at least five years, or longer to include destination investments created by configured original tranches. Total value adds cash remaining plus principal still invested, including starting unallocated cash. Each created destination is simulated through its maturity and then transfers to cash; it is not automatically rolled over again. Treat results as estimates, not guarantees."
                )
                Spacer()
            }

            HStack {
                Text("Still invested")
                Spacer()
                Text(result.endingPortfolioValue.toCurrency(compact: true))
                    .fontWeight(.semibold)
            }
            HStack {
                Text("Available as cash")
                Spacer()
                Text(result.endingAvailableCash.toCurrency(compact: true))
                    .fontWeight(.semibold)
            }
            Divider()
            HStack {
                Text("Estimated total at end")
                    .fontWeight(.bold)
                Spacer()
                Text(endingTotalValue.toCurrency(compact: true))
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.auraIndigo)
            }
            HStack {
                Text("Estimated change vs. starting capital")
                Spacer()
                Text(projectedChange.toCurrency(compact: true))
                    .fontWeight(.semibold)
            }
            Text("Modeled period: \(result.yearlySummaries.last?.yearOffset ?? 0) years. About \(principalNotReinvested.toCurrency(compact: true)) of matured principal is not reinvested and is routed to cash or withdrawals. This is principal returned, not extra profit. Interest earned is shown separately above.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .font(.system(size: 14))
        .auraCardStyle(radius: 20)
    }

    private var stressScenarioCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 8) {
                SimulatorSectionHeader(
                    title: "What-if scenarios",
                    subtitle: "Choose a situation to see how the projected cash and invested balance change.",
                    icon: "bolt.shield.fill"
                )
                InfoHintButton(
                    title: "About these scenarios",
                    message: "These are what-if calculations, not predictions. Choose a scenario to recalculate the results using an added assumption. Baseline uses the assumptions you entered. Actual rates, bond prices, taxes, and repayment may differ."
                )
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(LadderStressScenario.standardScenarios) { scenario in
                        let isSelected = selectedStressId == scenario.id
                        Button {
                            selectedStressId = scenario.id
                            currentStress = scenario
                        } label: {
                            VStack(alignment: .leading, spacing: 7) {
                                Text(scenarioTitle(for: scenario))
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(isSelected ? AppTheme.auraIndigo : .primary)
                                    .multilineTextAlignment(.leading)
                                Text(isSelected ? "Selected" : "Tap to compare")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: 150, height: 68, alignment: .leading)
                            .padding(.horizontal, 11)
                            .background(isSelected ? AppTheme.auraIndigo.opacity(0.10) : Color(UIColor.secondarySystemGroupedBackground))
                            .overlay {
                                RoundedRectangle(cornerRadius: 13)
                                    .stroke(isSelected ? AppTheme.auraIndigo : Color.secondary.opacity(0.15), lineWidth: isSelected ? 1.5 : 1)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 13))
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
                .padding(.vertical, 2)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(scenarioTitle(for: currentStress))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                Text(selectedStressExplanation)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                HStack {
                    Label("Projected cash at end", systemImage: "banknote")
                    Spacer()
                    Text(result.endingAvailableCash.toCurrency(compact: true))
                        .fontWeight(.bold)
                }
                .font(.system(size: 13))
                Text("The figures above update when you choose another scenario.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .auraCardStyle(radius: 20)
    }

    private func scenarioTitle(for scenario: LadderStressScenario) -> String {
        switch scenario.id {
        case "baseline": return "Baseline"
        case "rate_cut_2pct": return "Lower reinvestment rates"
        case "rate_cut_3pct_inflation": return "Lower rates + higher inflation"
        case "liquidity_crunch_sale": return "Bond principal haircut"
        case "corp_default": return "Corporate bond default"
        default: return scenario.title
        }
    }

    private var cashFlowChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SimulatorSectionHeader(
                title: "Annual Cash Flows",
                subtitle: "By year: interest paid out and original principal returned when each investment matures",
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
                title: "Starting Allocation by Instrument",
                subtitle: "Starting invested amount: \(result.totalCapitalAllocated.toCurrency(compact: true)). These shares add to 100%; later reinvestments appear in the yearly schedule.",
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

    private func yearCashFlowCard(_ item: LadderYearlySummary) -> some View {
        let interest = interestEvents(in: item.yearOffset)
        let maturities = principalEvents(in: item.yearOffset)
        let reinvestments = (result.reinvestmentRecords ?? []).filter { $0.yearOffset == item.yearOffset }
        let totalInflows = max(0, item.totalInterestReceived + item.totalMaturityProceeds)
        let reinvestedFromInflows = min(totalInflows, max(0, item.totalReinvested))
        let withdrawalsFromInflows = min(max(0, item.plannedWithdrawalsPaid), max(0, totalInflows - reinvestedFromInflows))
        let remainingInflows = max(0, totalInflows - reinvestedFromInflows - withdrawalsFromInflows)

        return VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .firstTextBaseline) {
                Text("Year \(item.yearOffset)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.auraIndigo)
                Spacer()
                Text("Cash balance  \(item.availableCashBalance.toCurrency(compact: true))")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }

            HStack(spacing: 8) {
                AmountPill(title: "Net interest", amount: item.totalInterestReceived, color: AppTheme.auraGreen)
                AmountPill(title: "Principal back", amount: item.totalMaturityProceeds, color: AppTheme.auraIndigo)
            }

            LadderCashFlowAllocationBar(
                reinvested: reinvestedFromInflows,
                withdrawn: withdrawalsFromInflows,
                remainingCash: remainingInflows,
                total: totalInflows
            )
            HStack {
                Text("Reinvested  \(reinvestedFromInflows.toCurrency(compact: true))")
                Spacer()
                Text("Withdrawn  \(withdrawalsFromInflows.toCurrency(compact: true))")
                Spacer()
                Text("Left from this year  \(remainingInflows.toCurrency(compact: true))")
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.secondary)

            Divider()

            Text("Interest by investment")
                .font(.system(size: 12, weight: .bold, design: .rounded))
            if interest.isEmpty {
                Text("No interest paid this year.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(interest) { event in
                        interestEventRow(event, year: item.yearOffset)
                    }
                }
            }

            Text("Maturities")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .padding(.top, 2)
            if maturities.isEmpty {
                Text("No tranche matures this year.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(maturities) { event in
                        maturityEventRow(event, year: item.yearOffset)
                    }
                }
            }

            if !reinvestments.isEmpty {
                Text("New ladder legs")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .padding(.top, 3)
                ForEach(reinvestments) { record in
                    reinvestmentSummaryCard(record, year: item.yearOffset)
                }
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func interestEventRow(_ event: LadderCashFlowEvent, year: Int) -> some View {
        let interestReinvested = reinvestmentRecord(forEntryID: event.entryID, in: year)?.interestReinvested ?? 0
        let matchingMaturity = principalEvents(in: year).first { $0.entryID == event.entryID }
        let sourceEntry = matchingMaturity.flatMap { entry(for: $0) }
        let withdrawal = sourceEntry.map { plannedWithdrawal(for: $0, in: year) } ?? 0
        let withdrawalFromInterest = matchingMaturity.map {
            min(event.netCashInflow, max(0, withdrawal - $0.netCashInflow))
        } ?? 0
        let cashInterest = max(0, event.netCashInflow - interestReinvested - withdrawalFromInterest)

        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(event.instrumentName)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(event.netCashInflow.toCurrency(compact: true))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.auraGreen)
            }
            HStack(spacing: 7) {
                Text(event.eventDescription)
                Text("Gross \(event.grossCashInflow.toCurrency(compact: true))")
                Text("Tax/fees \(event.taxAndFeesDeducted.toCurrency(compact: true))")
            }
            .font(.system(size: 10))
            .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Text("To cash \(cashInterest.toCurrency(compact: true))")
                if interestReinvested > 0 {
                    Text("To new leg \(interestReinvested.toCurrency(compact: true))")
                }
                if withdrawalFromInterest > 0 {
                    Text("Used for withdrawal \(withdrawalFromInterest.toCurrency(compact: true))")
                }
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.primary)
        }
        .padding(9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }

    private func maturityEventRow(_ event: LadderCashFlowEvent, year: Int) -> some View {
        let source = entry(for: event)
        let record = reinvestmentRecord(for: event)
        let withdrawal = source.map { plannedWithdrawal(for: $0, in: year) } ?? 0
        let sameTrancheInterest = interestEvents(in: year)
            .filter { $0.entryID == event.entryID }
            .reduce(0.0) { $0 + $1.netCashInflow }
        let remainingCash = max(0, event.netCashInflow + sameTrancheInterest - (record?.totalAmount ?? 0) - withdrawal)

        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(event.instrumentName)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(event.netCashInflow.toCurrency(compact: true))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.auraIndigo)
            }
            HStack(spacing: 8) {
                Text("Gross \(event.grossCashInflow.toCurrency(compact: true))")
                Text("Charges/loss \(event.taxAndFeesDeducted.toCurrency(compact: true))")
                Text("Net principal \(event.netCashInflow.toCurrency(compact: true))")
            }
            .font(.system(size: 10))
            .foregroundStyle(.secondary)
            if sameTrancheInterest > 0 {
                Text("This tranche's net interest at maturity: \(sameTrancheInterest.toCurrency(compact: true))")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                Text("Reinvested \((record?.totalAmount ?? 0).toCurrency(compact: true))")
                Text("Cash \(remainingCash.toCurrency(compact: true))")
                if withdrawal > 0 { Text("Withdrawal \(withdrawal.toCurrency(compact: true))") }
            }
            .font(.system(size: 10, weight: .medium))
            if let record, record.totalAmount > 0, let source {
                Text(source.reinvestmentAction.rawValue)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(AppTheme.auraIndigo)
            }
        }
        .padding(9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }

    private func reinvestmentSummaryCard(_ record: LadderReinvestmentRecord, year: Int) -> some View {
        let destination = record.destinationTranche
        let futureEvents = result.timelineEvents
            .filter { $0.entryID == destination.id && $0.yearOffset > year }
            .sorted { $0.yearOffset < $1.yearOffset }
        let projectedNetInterest = futureEvents
            .filter { !$0.isMaturityPrincipal }
            .reduce(0.0) { $0 + $1.netCashInflow }
        let returnedPrincipal = futureEvents
            .filter(\.isMaturityPrincipal)
            .reduce(0.0) { $0 + $1.netCashInflow }

        return VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(record.sourceTrancheName) → \(destination.instrumentType.shortName)")
                    .font(.system(size: 11, weight: .bold))
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(record.totalAmount.toCurrency(compact: true))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.auraIndigo)
            }
            HStack(spacing: 8) {
                Text("\(String(format: "%.2f", destination.annualInterestRatePct))% • \(destination.tenureYears)y")
                Text("\(formattedDate(destination.simulatedStartDate)) → \(formattedDate(destination.simulatedMaturityDate))")
            }
            .font(.system(size: 10))
            .foregroundStyle(.secondary)
            Text("From principal \(record.principalReinvested.toCurrency(compact: true)) + interest \(record.interestReinvested.toCurrency(compact: true)) • expected net interest \(projectedNetInterest.toCurrency(compact: true)) • principal at maturity \(returnedPrincipal.toCurrency(compact: true))")
                .font(.system(size: 10))

            if !futureEvents.isEmpty {
                DisclosureGroup("Cash-flow details (\(futureEvents.count))") {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(futureEvents) { futureEvent in
                            HStack {
                                Text("Year \(futureEvent.yearOffset) • \(futureEvent.eventDescription)")
                                Spacer()
                                Text("Net \(futureEvent.netCashInflow.toCurrency(compact: true))")
                                    .fontWeight(.semibold)
                            }
                            .font(.system(size: 10))
                            Text("Gross \(futureEvent.grossCashInflow.toCurrency(compact: true)) • taxes/fees \(futureEvent.taxAndFeesDeducted.toCurrency(compact: true))")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 5)
                }
                .font(.system(size: 10, weight: .medium))
                .tint(AppTheme.auraIndigo)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.auraIndigo.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var yearlyBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation { showingYearlyBreakdown.toggle() }
            } label: {
                HStack {
                    SimulatorSectionHeader(
                        title: "Year-by-Year Cash-Flow Schedule",
                        subtitle: "See when interest and principal arrive, what is reinvested, and cash left after each year",
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
                        yearCashFlowCard(item)
                    }
                }
            }
        }
        .auraCardStyle(radius: 20)
    }
}

private struct AmountPill: View {
    let title: String
    let amount: Double
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(title)
                .foregroundStyle(.secondary)
            Text(amount.toCurrency(compact: true))
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .font(.system(size: 10, design: .rounded))
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(color.opacity(0.09))
        .clipShape(Capsule())
    }
}

private struct LadderCashFlowAllocationBar: View {
    let reinvested: Double
    let withdrawn: Double
    let remainingCash: Double
    let total: Double

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let safeTotal = max(1, total)
            HStack(spacing: 2) {
                segment(width: width * CGFloat(reinvested / safeTotal), color: AppTheme.auraIndigo)
                segment(width: width * CGFloat(withdrawn / safeTotal), color: AppTheme.vibrantOrange)
                segment(width: width * CGFloat(remainingCash / safeTotal), color: AppTheme.auraGreen)
                if total == 0 {
                    Capsule().fill(Color.secondary.opacity(0.15))
                }
            }
            .clipShape(Capsule())
        }
        .frame(height: 9)
        HStack(spacing: 12) {
            legend("Reinvested", color: AppTheme.auraIndigo)
            legend("Withdrawn", color: AppTheme.vibrantOrange)
            legend("Cash", color: AppTheme.auraGreen)
        }
        .font(.system(size: 9, weight: .medium))
        .foregroundStyle(.secondary)
    }

    private func segment(width: CGFloat, color: Color) -> some View {
        Capsule()
            .fill(color)
            .frame(width: max(0, width))
    }

    private func legend(_ title: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 5, height: 5)
            Text(title)
        }
    }
}
