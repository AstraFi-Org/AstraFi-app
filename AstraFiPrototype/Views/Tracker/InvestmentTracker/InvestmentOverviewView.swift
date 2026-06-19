import SwiftUI
import Charts

// MARK: - Data Models

/// Monthly bar: Jan → current month (actuals from real investments)
struct MonthlyInvestmentBar: Identifiable {
    let id = UUID()
    let month: Int          // 1–12
    let year: Int
    let label: String       // "Jan", "Feb" … short display
    let totalInvested: Double   // actual ₹ invested in that month (SIP + lumpsum)
    let isCurrent: Bool         // true = this is the ongoing month
    let isPast: Bool            // true = already elapsed (show solid bar)
}

/// Yearly bar: 1 past year + current year + 2 future projected years
struct YearlyInvestmentBar: Identifiable {
    let id = UUID()
    let year: Int
    let label: String
    /// Actual / projected total invested that year
    let totalInvested: Double
    /// How much more we recommend adding (only for future bars)
    let recommendedAdd: Double
    let isPast: Bool
    let isCurrent: Bool
}

// MARK: - Chart Mode
enum ChartMode: String, CaseIterable {
    case monthly = "Monthly"
    case yearly  = "Yearly"
}

// MARK: - Main View
struct InvestmentOverviewView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppStateManager.self) var appState
    @Environment(TrackerViewModel.self) var tracker
    @Environment(\.dismiss) var dismiss

    private var investments: [AstraInvestment] { appState.currentProfile?.investments ?? [] }
    private var insurances:  [AstraInsurance]  { appState.currentProfile?.insurances  ?? [] }

    private var totalInvested:     Double { tracker.portfolioTotalInvested }
    private var totalCurrentValue: Double { tracker.portfolioTotalCurrentValue }
    private var totalGain:         Double { tracker.portfolioNetGain }
    private var returnPct:         Double { tracker.portfolioReturnPct }
    private var cagr:              Double { tracker.portfolioCAGR }
    private var gainers: [InvestmentSummaryItem] { tracker.gainers }
    private var losers:  [InvestmentSummaryItem] { tracker.losers  }

    private var df: DateFormatter {
        let f = DateFormatter(); f.dateStyle = .medium; return f
    }

    @State private var chartMode: ChartMode = .monthly
    @State private var showingAddInvestment = false

    // ── Profile helpers
    private var monthlyIncome:   Double { appState.currentProfile?.basicDetails.monthlyIncomeAfterTax ?? 0 }
    private var monthlyExpenses: Double { appState.currentProfile?.basicDetails.monthlyExpenses ?? 0 }
    private var monthlySurplus:  Double { max(0, monthlyIncome - monthlyExpenses) }

    // ── Monthly SIP commitment currently active (₹/month)
    private var activeSIPMonthly: Double {
        investments.reduce(0) { $0 + ($1.mode == .sip ? $1.investmentAmount : 0) }
    }

    // MARK: Monthly chart data
    // Shows Jan → current month of the current year.
    // Each bar = actual investments that occurred in that month.
    private var monthlyBars: [MonthlyInvestmentBar] {
        let cal   = Calendar.current
        let today = Date()
        let currentMonth = cal.component(.month, from: today)
        let currentYear  = cal.component(.year,  from: today)

        let shortFmt = DateFormatter()
        shortFmt.dateFormat = "MMM"

        var bars: [MonthlyInvestmentBar] = []

        for m in 1...currentMonth {
            // Build the date for first-of-month
            var comps       = DateComponents()
            comps.year      = currentYear
            comps.month     = m
            comps.day       = 1
            guard let monthDate = cal.date(from: comps) else { continue }

            // Sum all investment activity that falls inside this calendar month
            var monthTotal: Double = 0

            for inv in investments {
                // SIP: count how many SIP instalments landed in this month
                if inv.mode == .sip {
                    // Each SIP fires once per month (or per its frequency).
                    // Simple rule: if the SIP startDate <= end of this month, count one instalment.
                    let endOfMonth = cal.date(byAdding: .month, value: 1, to: monthDate)!
                    if inv.startDate < endOfMonth {
                        // Check the SIP was running during this month
                        let sipStart = cal.dateComponents([.year, .month], from: inv.startDate)
                        let barMonth = DateComponents(year: currentYear, month: m)
                        if cal.date(from: sipStart)! <= cal.date(from: barMonth)! {
                            monthTotal += inv.investmentAmount
                        }
                    }
                } else {
                    // Lumpsum / one-time: attribute to the month of startDate
                    let invMonth = cal.component(.month, from: inv.startDate)
                    let invYear  = cal.component(.year,  from: inv.startDate)
                    if invMonth == m && invYear == currentYear {
                        monthTotal += inv.investmentAmount
                    }
                }
            }

            bars.append(MonthlyInvestmentBar(
                month: m,
                year: currentYear,
                label: shortFmt.string(from: monthDate),
                totalInvested: monthTotal,
                isCurrent: m == currentMonth,
                isPast: m < currentMonth
            ))
        }
        return bars
    }

    // MARK: Yearly chart data
    // Shows: previous year (actuals) + current year (actuals so far) + 2 future years (projected).
    private var yearlyBars: [YearlyInvestmentBar] {
        let cal         = Calendar.current
        let today       = Date()
        let currentYear = cal.component(.year, from: today)

        func annualActual(for year: Int) -> Double {
            var total: Double = 0
            for inv in investments {
                let invYear = cal.component(.year, from: inv.startDate)
                if inv.mode == .sip {
                    // Count months active within this year
                    let sipStartYear  = cal.component(.year,  from: inv.startDate)
                    let sipStartMonth = cal.component(.month, from: inv.startDate)

                    let startMonth = (sipStartYear == year) ? sipStartMonth : 1
                    let endMonth   = (year < currentYear)   ? 12            : cal.component(.month, from: today)

                    if sipStartYear <= year {
                        let months = max(0, endMonth - startMonth + 1)
                        total += inv.investmentAmount * Double(months)
                    }
                } else {
                    if invYear == year { total += inv.investmentAmount }
                }
            }
            return total
        }

        // Projected: assume user will invest activeSIPMonthly * 12 + recommended top-up
        let annualSIPBase    = activeSIPMonthly * 12
        let annualCapacity   = monthlySurplus * 12

        var bars: [YearlyInvestmentBar] = []

        let years = [currentYear - 1, currentYear, currentYear + 1, currentYear + 2]
        for year in years {
            let isCurrent = year == currentYear
            let isPast    = year < currentYear

            let invested: Double
            let recAdd:   Double

            if isPast || isCurrent {
                invested = annualActual(for: year)
                recAdd   = 0
            } else {
                // Future: project SIP growing 8% p.a. per year offset
                let offset   = Double(year - currentYear)
                invested     = annualSIPBase * pow(1.08, offset)
                let capacity = annualCapacity * pow(1.08, offset)
                recAdd       = max(0, capacity - invested)
            }

            bars.append(YearlyInvestmentBar(
                year:          year,
                label:         "\(year)",
                totalInvested: invested,
                recommendedAdd: recAdd,
                isPast:        isPast,
                isCurrent:     isCurrent
            ))
        }
        return bars
    }

    // MARK: Body
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                totalValueCard
                investmentChart
                investmentsList
                insuranceSection
            }
            .padding()
        }
        .navigationTitle("Investment Overview")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left").fontWeight(.semibold)
                }
                .buttonStyle(.plain)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAddInvestment = true } label: {
                    Image(systemName: "plus.circle.fill").font(.title3)
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showingAddInvestment) { AddInvestmentView() }
        .background(AppTheme.appBackground(for: colorScheme))
    }

    // MARK: - Total Value Card (unchanged layout)
    private var totalValueCard: some View {
        VStack(spacing: 0) {
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Total Value")
                            .font(.title3).fontWeight(.semibold)
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(totalCurrentValue.toCurrency())
                                .font(.system(size: 36, weight: .bold))
                            HStack(spacing: 4) {
                                Image(systemName: totalGain >= 0 ? "arrow.up.right" : "arrow.down.right")
                                    .font(.caption).foregroundColor(totalGain >= 0 ? .green : .red)
                                Text(String(format: "%.1f%%", abs(returnPct)))
                                    .font(.title3).foregroundColor(totalGain >= 0 ? .green : .red)
                            }
                        }
                        Text(totalGain >= 0 ? "Annual profit rate" : "Annual loss rate")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                }

                HStack(spacing: 12) {
                    metricBox(label: "Invested", value: totalInvested.toCurrency(), valueColor: .primary)
                    metricBox(label: totalGain >= 0 ? "Gain" : "Loss", value: totalGain.toCurrency(), valueColor: totalGain >= 0 ? .green : .red)
                }

                if totalInvested > 0 {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("CAGR (annualised)").font(.caption).foregroundColor(.secondary)
                            Text("\(cagr >= 0 ? "+" : "")\(String(format: "%.2f%%", cagr))")
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundColor(cagr >= 0 ? .green : .red)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Total Returns").font(.caption).foregroundColor(.secondary)
                            Text("\((totalGain >= 0 ? "+" : ""))\(totalGain.toCurrency())")
                                .font(.title).fontWeight(.bold)
                                .foregroundColor(totalGain >= 0 ? .green : .red)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(20)

            if !gainers.isEmpty || !losers.isEmpty {
                Divider().padding(.horizontal, 20)
                portfolioBreakdown
            }
        }
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
    }

    private func metricBox(label: String, value: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.subheadline).foregroundColor(.secondary)
            Text(value).font(.title2).fontWeight(.bold).foregroundColor(valueColor)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var portfolioBreakdown: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Investment Breakdown").font(.subheadline).fontWeight(.semibold)
                Spacer()
                if !gainers.isEmpty {
                    Label("\(gainers.count) Gaining", systemImage: "arrow.up.right")
                        .font(.caption).fontWeight(.semibold).foregroundColor(.green)
                }
                if !losers.isEmpty {
                    Label("\(losers.count) Losing", systemImage: "arrow.down.right")
                        .font(.caption).fontWeight(.semibold).foregroundColor(.red)
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 14)

            if !gainers.isEmpty {
                sectionLabel("Performing Well", color: .green)
                VStack(spacing: 8) { ForEach(gainers) { PortfolioBreakdownRow(item: $0) } }.padding(.horizontal, 20)
            }
            if !losers.isEmpty {
                sectionLabel("Under-performing", color: .red).padding(.top, gainers.isEmpty ? 0 : 14)
                VStack(spacing: 8) { ForEach(losers) { PortfolioBreakdownRow(item: $0) } }.padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 20)
    }

    private func sectionLabel(_ text: String, color: Color) -> some View {
        HStack {
            Text(text).font(.caption).fontWeight(.semibold).foregroundColor(color)
            Spacer()
        }
        .padding(.horizontal, 20).padding(.bottom, 6)
    }

    // MARK: - Investment Chart Card
    private var investmentChart: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Header + Picker
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Investment Overview")
                        .font(.system(size: 16, weight: .semibold))
                    Text(chartMode == .monthly
                         ? "Jan → now · actual investments per month"
                         : "Past year · this year · next 2 years projected")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Picker("", selection: $chartMode) {
                    ForEach(ChartMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }
            .padding(.horizontal, 20)

            // Legend
            HStack(spacing: 16) {
                legendItem(color: AppTheme.auraGreen,   label: chartMode == .monthly ? "Invested" : "Actual")
                legendItem(color: AppTheme.auraIndigo.opacity(0.7), label: chartMode == .monthly ? "Current month" : "Projected")
                if chartMode == .yearly {
                    legendItem(color: .teal.opacity(0.8), label: "Recommended add", dashed: false)
                }
                legendItem(color: .orange, label: "Now", dashed: true)
            }
            .padding(.horizontal, 20)

            // Chart
            Group {
                if chartMode == .monthly {
                    monthlyChart
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                } else {
                    yearlyChart
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: chartMode)

            // Insight
            insightText
                .padding(.horizontal, 20)
                .padding(.top, 4)
        }
        .padding(.vertical, 20)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
    }

    // MARK: Monthly Chart
    // Bars = Jan → current month, height = actual ₹ invested that month
    // Past months: green solid | Current month: indigo (in-progress)
    private var monthlyChart: some View {
        let data = monthlyBars
        let rawMax = data.map { $0.totalInvested.safeFinite }.max() ?? 0
        let maxVal = max(rawMax, 1)
        // Give each bar a 44pt slot
        let chartWidth = CGFloat(max(data.count, 4)) * 52

        return ScrollView(.horizontal, showsIndicators: false) {
            Chart(data) { bar in

                // Main bar — actual investment
                BarMark(
                    x: .value("Month", bar.label),
                    y: .value("Invested", bar.totalInvested),
                    width: 26
                )
                .foregroundStyle(
                    bar.isCurrent
                        ? LinearGradient(colors: [AppTheme.auraIndigo, AppTheme.auraIndigo.opacity(0.7)],
                                         startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [AppTheme.auraGreen, AppTheme.auraGreen.opacity(0.7)],
                                         startPoint: .top, endPoint: .bottom)
                )
                .cornerRadius(6)
                .annotation(position: .top, spacing: 4) {
                    if bar.totalInvested > 0 {
                        Text(bar.totalInvested.toCurrency(compact: true))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(bar.isCurrent ? AppTheme.auraIndigo : AppTheme.auraGreen)
                    }
                }

                // "Now" dashed line on current month
                if bar.isCurrent {
                    RuleMark(x: .value("Now", bar.label))
                        .foregroundStyle(Color.orange.opacity(0.55))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                        .annotation(position: .top, alignment: .center) {
                            Text("Now")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.orange)
                                .cornerRadius(4)
                                .offset(y: -32)
                        }
                }
            }
            .frame(width: chartWidth, height: 220)
            .chartYScale(domain: 0...(maxVal * 1.30))
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { val in
                    AxisGridLine().foregroundStyle(Color.secondary.opacity(0.12))
                    AxisValueLabel {
                        if let v = val.as(Double.self) {
                            Text(v.toCurrency(compact: true)).font(.system(size: 10)).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel().font(.system(size: 11, weight: .medium)).foregroundStyle(Color.secondary)
                }
            }
            .padding(.leading, 20).padding(.trailing, 12)
        }
    }

    // MARK: Yearly Chart
    // Past year (grey/muted) + Current year (green) + 2 future years (blue projected + teal add-on)
    private var yearlyChart: some View {
        let data = yearlyBars

        // Max value for scale: biggest bar including recommended add
        let rawMax = data
            .map { ($0.totalInvested.safeFinite + $0.recommendedAdd.safeFinite).safeFinite }
            .max() ?? 0
        let maxVal = max(rawMax, 1)

        return Chart(data) { bar in

            // ── Actual / projected invested bar
            BarMark(
                x: .value("Year", bar.label),
                y: .value("Invested", bar.totalInvested),
                width: 38
            )
            .foregroundStyle(
                bar.isPast
                    ? LinearGradient(colors: [Color.gray.opacity(0.55), Color.gray.opacity(0.35)],
                                     startPoint: .top, endPoint: .bottom)
                    : bar.isCurrent
                        ? LinearGradient(colors: [AppTheme.auraGreen, AppTheme.auraGreen.opacity(0.75)],
                                         startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [AppTheme.auraIndigo.opacity(0.85), AppTheme.auraIndigo.opacity(0.55)],
                                         startPoint: .top, endPoint: .bottom)
            )
            .cornerRadius(6)

            // ── Recommended top-up stacked on future bars (teal)
            if bar.recommendedAdd > 0 {
                BarMark(
                    x: .value("Year", bar.label),
                    y: .value("Recommended", bar.recommendedAdd),
                    width: 38
                )
                .foregroundStyle(
                    LinearGradient(colors: [Color.teal.opacity(0.85), Color.teal.opacity(0.5)],
                                   startPoint: .top, endPoint: .bottom)
                )
                .cornerRadius(6)
                .annotation(position: .top, spacing: 4) {
                    VStack(spacing: 1) {
                        Text("↑ add").font(.system(size: 8, weight: .bold)).foregroundColor(.secondary)
                        Text(bar.recommendedAdd.toCurrency(compact: true))
                            .font(.system(size: 10, weight: .bold)).foregroundColor(.primary)
                    }
                }
            }

            // ── Label on past + current bars
            if bar.recommendedAdd == 0 && bar.totalInvested > 0 {
                BarMark(
                    x: .value("Year", bar.label),
                    y: .value("Invested", bar.totalInvested),
                    width: 38
                )
                .foregroundStyle(.clear)
                .annotation(position: .top, spacing: 4) {
                    Text(bar.totalInvested.toCurrency(compact: true))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(bar.isPast ? .secondary : AppTheme.auraGreen)
                }
            }

            // "Now" dashed rule on current year
            if bar.isCurrent {
                RuleMark(x: .value("Now", bar.label))
                    .foregroundStyle(Color.orange.opacity(0.50))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                    .annotation(position: .top, alignment: .center) {
                        Text("Now")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(4)
                            .offset(y: -44)
                    }
            }
        }
        .frame(height: 260)
        .chartYScale(domain: 0...(maxVal * 1.25))
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { val in
                AxisGridLine().foregroundStyle(Color.secondary.opacity(0.12))
                AxisValueLabel {
                    if let v = val.as(Double.self) {
                        Text(v.toCurrency(compact: true)).font(.system(size: 10)).foregroundColor(.secondary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel().font(.system(size: 11, weight: .medium)).foregroundStyle(Color.secondary)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: Insight text
    @ViewBuilder private var insightText: some View {
        if chartMode == .monthly {
            let currentBar = monthlyBars.first(where: \.isCurrent)
            let currentMonthInvested = currentBar?.totalInvested ?? 0
            let gap = max(0, monthlySurplus - currentMonthInvested)

            if investments.isEmpty {
                Text("No investments recorded yet. Based on your surplus of \(monthlySurplus.toCurrency(compact: true))/mo you can start a SIP today.")
                    .chartInsightStyle()
            } else if gap > 0 {
                Text("You've invested \(currentMonthInvested.toCurrency(compact: true)) so far this month. You still have \(gap.toCurrency(compact: true)) of monthly surplus you could put to work.")
                    .chartInsightStyle()
            } else {
                Text("Well done — you've fully deployed your surplus this month. Consider increasing your income or reducing expenses to invest even more.")
                    .chartInsightStyle()
            }
        } else {
            let currentActual  = yearlyBars.first(where: \.isCurrent)?.totalInvested ?? 0
            let annualCapacity = monthlySurplus * 12
            let gap = max(0, annualCapacity - currentActual)

            if gap > 0 {
                Text("You've invested \(currentActual.toCurrency(compact: true)) this year so far. Investing an extra \(gap.toCurrency(compact: true)) would fully use your annual savings capacity.")
                    .chartInsightStyle()
            } else {
                Text("You're investing at or above your annual savings capacity. Great discipline — consider reviewing your goals to stay aligned.")
                    .chartInsightStyle()
            }
        }
    }

    // MARK: Investments List
    private var investmentsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Investments").font(.title2).fontWeight(.bold)
                Spacer()
                NavigationLink(destination: FullInvestmentListView()) {
                    Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold)).foregroundColor(.accentColor)
                }
            }

            VStack(spacing: 12) {
                let recent = investments.sorted(by: { $0.createdAt > $1.createdAt }).prefix(3)
                if recent.isEmpty {
                    Text("No investments recorded yet")
                        .font(.subheadline).foregroundColor(.secondary)
                        .frame(maxWidth: .infinity).padding(24)
                        .background(AppTheme.cardBackground).cornerRadius(12)
                } else {
                    ForEach(recent) { inv in
                        NavigationLink(destination: InvestmentDetailView(investmentID: inv.id)) {
                            InvestmentRowView(
                                name: inv.investmentName,
                                category: inv.investmentType.rawValue,
                                risk: riskLabel(for: inv),
                                amount: inv.currentValue.toCurrency(),
                                gain: "\(inv.currentGain >= 0 ? "+" : "")\(inv.currentGain.toCurrency())",
                                startDate: df.string(from: inv.startDate),
                                goal: goalName(for: inv)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .transition(.asymmetric(insertion: .push(from: .top), removal: .opacity))
                    }
                }
            }
            .animation(.easeInOut, value: investments)
        }
    }

    // MARK: Insurance Section
    private var insuranceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Insurance").font(.title2).fontWeight(.bold)
                Spacer()
                NavigationLink(destination: InsuranceListView()) {
                    Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold)).foregroundColor(.accentColor)
                }
            }
            if insurances.isEmpty {
                Text("No insurance policies recorded yet")
                    .font(.subheadline).foregroundColor(.secondary)
                    .frame(maxWidth: .infinity).padding(24)
                    .background(AppTheme.cardBackground).cornerRadius(12)
            } else {
                ForEach(insurances) { ins in
                    NavigationLink(destination: InsuranceDetailView(insurance: ins)) {
                        InsuranceCard(
                            title: ins.insuranceType.rawValue + " Insurance",
                            subtitle: ins.provider,
                            status: ins.status.rawValue,
                            claimedAmount: (ins.claims.first?.amount ?? 0).toCurrency(),
                            sumInsured: ins.sumAssured.toCurrency(),
                            renewalDate: df.string(from: ins.expiryDate ?? ins.startDate)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    // MARK: Helpers
    private func legendItem(color: Color, label: String, dashed: Bool = false) -> some View {
        HStack(spacing: 6) {
            if dashed {
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1).fill(color).frame(width: 5, height: 3)
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 16, height: 4)
            }
            Text(label).font(.system(size: 11)).foregroundColor(.secondary)
        }
    }

    private func riskLabel(for inv: AstraInvestment) -> String {
        switch inv.investmentType {
        case .stocks:        return "High Risk"
        case .mutualFund:    return "Moderate Risk"
        case .cryptocurrency: return "Very High Risk"
        default:             return "Low Risk"
        }
    }

    private func goalName(for inv: AstraInvestment) -> String {
        guard let gid = inv.associatedGoalID,
              let goal = appState.currentProfile?.goals.first(where: { $0.id == gid })
        else { return "General" }
        return goal.goalName
    }
}

// MARK: - Text Style Extension
private extension Text {
    func chartInsightStyle() -> some View {
        self
            .font(.system(size: 11))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Supporting Views (unchanged)

struct InvestmentRowView: View {
    let name, category, risk, amount, gain, startDate, goal: String
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name).font(.headline).foregroundColor(.primary)
                    HStack(spacing: 8) {
                        Text(category).font(.subheadline).foregroundColor(.secondary)
                        Text("•").foregroundColor(.secondary)
                        Text(risk).font(.subheadline).foregroundColor(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(amount).font(.title3).fontWeight(.bold)
                    HStack(spacing: 2) {
                        let isPositive = !gain.contains("-")
                        Text(gain).font(.subheadline).foregroundColor(isPositive ? .green : .red)
                        Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                            .font(.caption).foregroundColor(isPositive ? .green : .red)
                    }
                }
            }
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Started on").font(.caption).foregroundColor(.secondary)
                    Text(startDate).font(.subheadline)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Associated goal").font(.caption).foregroundColor(.secondary)
                    Text(goal).font(.subheadline)
                }
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
    }
}

struct InsuranceCard: View {
    let title, subtitle, status, claimedAmount: String
    var registrationNumber: String? = nil
    var sumInsured: String? = nil
    let renewalDate: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.subheadline).foregroundColor(.secondary)
                }
                Spacer()
                Text(status)
                    .font(.caption).fontWeight(.semibold).foregroundColor(.orange)
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2)).cornerRadius(12)
            }
            VStack(spacing: 8) {
                infoRow("Claimed Amount", claimedAmount)
                if let r = registrationNumber { infoRow("Registration number", r) }
                if let s = sumInsured         { infoRow("Sum Insured", s) }
                infoRow("Renewal Date", renewalDate)
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value)
        }.font(.subheadline)
    }
}

struct PortfolioBreakdownRow: View {
    let item: InvestmentSummaryItem
    var body: some View {
        HStack(spacing: 12) {
            Circle().fill(item.isGainer ? Color.green.opacity(0.8) : Color.red.opacity(0.8)).frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(.subheadline).fontWeight(.medium).lineLimit(1)
                Text(item.category + " · " + item.risk).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(item.currentValue.toCurrency()).font(.subheadline).fontWeight(.semibold)
                HStack(spacing: 3) {
                    Image(systemName: item.isGainer ? "arrow.up" : "arrow.down").font(.system(size: 9, weight: .bold))
                    Text(String(format: "%.1f%%", abs(item.gainLossPct))).font(.caption).fontWeight(.semibold)
                    Text("(\(item.gainLoss >= 0 ? "+" : "")\(item.gainLoss.toCurrency()))").font(.caption)
                }
                .foregroundColor(item.isGainer ? .green : .red)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background((item.isGainer ? Color.green : Color.red).opacity(0.06))
        .cornerRadius(10)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        InvestmentOverviewView()
            .environment(AppStateManager())
            .environment(TrackerViewModel())
    }
}
