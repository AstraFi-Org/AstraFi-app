import SwiftUI
import Charts

struct YearlyData: Identifiable {
    let id = UUID()
    let year: String
    let value: Double
    let recommendedIncrease: Double
    let isCurrent: Bool
}

struct MonthlyChartData: Identifiable {
    let id = UUID()
    /// Short label shown on the X-axis  e.g. "May" / "Jun '26"
    let label: String
    /// What the user *can* save / invest this month (income − expenses, inflation-adjusted)
    let savingsCapacity: Double
    /// SIP amount actually committed each month (already running)
    let actualInvested: Double
    /// Gap the user should fill  = max(0, savingsCapacity − actualInvested)
    var recommendedTop: Double { max(0, savingsCapacity - actualInvested) }
    let isCurrent: Bool
}

enum ChartMode: String, CaseIterable {
    case monthly = "Monthly"
    case yearly  = "Yearly"
}

struct InvestmentOverviewView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppStateManager.self) var appState
    @Environment(TrackerViewModel.self) var tracker
    @Environment(\.dismiss) var dismiss

    private var investments: [AstraInvestment] { appState.currentProfile?.investments ?? [] }
    private var insurances: [AstraInsurance]   { appState.currentProfile?.insurances ?? [] }

    // Live portfolio numbers from TrackerViewModel (always in sync with profile)
    private var totalInvested: Double      { tracker.portfolioTotalInvested }
    private var totalCurrentValue: Double  { tracker.portfolioTotalCurrentValue }
    private var totalGain: Double          { tracker.portfolioNetGain }
    private var returnPct: Double          { tracker.portfolioReturnPct }
    private var cagr: Double               { tracker.portfolioCAGR }
    private var gainers: [InvestmentSummaryItem] { tracker.gainers }
    private var losers:  [InvestmentSummaryItem] { tracker.losers  }

    private var df: DateFormatter {
        let f = DateFormatter(); f.dateStyle = .medium; return f
    }

    private var chartData: [YearlyData] {
        let cal = Calendar.current
        let currentYear = cal.component(.year, from: Date())

        let monthlyIncome = appState.currentProfile?.basicDetails.monthlyIncomeAfterTax ?? 0
        let monthlyExpenses = appState.currentProfile?.basicDetails.monthlyExpenses ?? 0
        let annualSavingsCapacity = max(0, (monthlyIncome - monthlyExpenses) * 12)

        let currentAnnualInvested = investments.reduce(0.0) { total, inv in
            if inv.mode == .sip {
                return total + (inv.investmentAmount * 12)
            } else {
                return total
            }
        }

        var data: [YearlyData] = []
        for offset in 0...2 {
            let year = currentYear + offset
            let isCurrent = offset == 0

            let capacity = annualSavingsCapacity * pow(1.08, Double(offset))
            let currentTrend = currentAnnualInvested * pow(1.05, Double(offset))
            let increase = max(0, capacity - currentTrend)

            data.append(YearlyData(
                year: "\(year)",
                value: capacity,
                recommendedIncrease: increase,
                isCurrent: isCurrent
            ))
        }
        return data
    }

    /// 12-month rolling view: current month + next 11 months.
    /// Each bar shows:
    ///   • savingsCapacity  = monthly (income − expenses), grown by 8 % p.a. step-up per year
    ///   • actualInvested   = monthly SIP commitments already running (grown 5 % p.a.)
    ///   • recommendedTop   = gap the user should fill
    private var monthlyChartData: [MonthlyChartData] {
        let cal = Calendar.current
        let today = Date()
        let monthlyIncome   = appState.currentProfile?.basicDetails.monthlyIncomeAfterTax ?? 0
        let monthlyExpenses = appState.currentProfile?.basicDetails.monthlyExpenses ?? 0
        let baseSavings     = max(0, monthlyIncome - monthlyExpenses)

        // Monthly SIP commitment currently running
        let baseSIPMonthly = investments.reduce(0.0) { total, inv in
            inv.mode == .sip ? total + inv.investmentAmount : total
        }

        var data: [MonthlyChartData] = []
        let shortFmt  = DateFormatter()
        shortFmt.dateFormat = "MMM"          // "Apr"
        let shortFmtY = DateFormatter()
        shortFmtY.dateFormat = "MMM ''yy"    // "Apr '26"

        for offset in 0..<12 {
            guard let date = cal.date(byAdding: .month, value: offset, to: today) else { continue }
            let isCurrent = offset == 0

            // Year fraction from today → apply annual step-up pro-rata per month elapsed
            let yearFraction = Double(offset) / 12.0

            // 8 % p.a. step-up on savings capacity (income growth / expense control)
            let capacity = baseSavings * pow(1.08, yearFraction)

            // 5 % p.a. natural SIP growth (step-up SIPs, new income)
            let actualSIP = baseSIPMonthly * pow(1.05, yearFraction)

            // Label: show year suffix only when month rolls over to a new year
            let currentYear = cal.component(.year, from: today)
            let barYear     = cal.component(.year, from: date)
            let label = barYear == currentYear ? shortFmt.string(from: date)
                                               : shortFmtY.string(from: date)

            data.append(MonthlyChartData(
                label: label,
                savingsCapacity: capacity,
                actualInvested: actualSIP,
                isCurrent: isCurrent
            ))
        }
        return data
    }

    @State private var showingAddInvestment = false
    @State private var chartMode: ChartMode = .monthly

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
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showingAddInvestment) {
            AddInvestmentView()
        }
        .background(AppTheme.appBackground(for: colorScheme))
    }

    private var totalValueCard: some View {
        VStack(spacing: 0) {
            // ── Main summary block ─────────────────────────────────────────
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
                                    .font(.caption)
                                    .foregroundColor(totalGain >= 0 ? .green : .red)
                                Text(String(format: "%.1f%%", abs(returnPct)))
                                    .font(.title3)
                                    .foregroundColor(totalGain >= 0 ? .green : .red)
                            }
                        }
                        Text(totalGain >= 0 ? "Annual profit rate" : "Annual loss rate")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                }

                // Invested / Gain row
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Invested")
                            .font(.subheadline).foregroundColor(.secondary)
                        Text(totalInvested.toCurrency())
                            .font(.title2).fontWeight(.bold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(totalGain >= 0 ? "Gain" : "Loss")
                            .font(.subheadline).foregroundColor(.secondary)
                        Text(totalGain.toCurrency())
                            .font(.title2).fontWeight(.bold)
                            .foregroundColor(totalGain >= 0 ? .green : .red)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }

                // CAGR row
                if totalInvested > 0 {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("CAGR (annualised)")
                                .font(.caption).foregroundColor(.secondary)
                            Text(String(format: "%@%.2f%%", cagr >= 0 ? "+" : "", cagr))
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundColor(cagr >= 0 ? .green : .red)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Total Returns")
                                .font(.caption).foregroundColor(.secondary)
                            Text((totalGain >= 0 ? "+" : "") + totalGain.toCurrency())
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundColor(totalGain >= 0 ? .green : .red)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(20)

            // ── Gainers / Losers breakdown ────────────────────────────────
            if !gainers.isEmpty || !losers.isEmpty {
                Divider().padding(.horizontal, 20)

                VStack(spacing: 0) {
                    // Section header
                    HStack {
                        Text("Investment Breakdown")
                            .font(.subheadline).fontWeight(.semibold)
                        Spacer()
                        if !gainers.isEmpty {
                            Label("\(gainers.count) Gaining", systemImage: "arrow.up.right")
                                .font(.caption).fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                        if !losers.isEmpty {
                            Label("\(losers.count) Losing", systemImage: "arrow.down.right")
                                .font(.caption).fontWeight(.semibold)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)

                    // Gainers
                    if !gainers.isEmpty {
                        HStack {
                            Text("Performing Well")
                                .font(.caption).fontWeight(.semibold)
                                .foregroundColor(.green)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 6)

                        VStack(spacing: 8) {
                            ForEach(gainers) { item in
                                PortfolioBreakdownRow(item: item)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Losers
                    if !losers.isEmpty {
                        HStack {
                            Text("Under-performing")
                                .font(.caption).fontWeight(.semibold)
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, gainers.isEmpty ? 0 : 14)
                        .padding(.bottom, 6)

                        VStack(spacing: 8) {
                            ForEach(losers) { item in
                                PortfolioBreakdownRow(item: item)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
    }

    private var investmentChart: some View {
        VStack(alignment: .leading, spacing: 16) {

            // ── Header + Picker ────────────────────────────────────────────
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Investment Recommendation")
                        .font(.system(size: 16, weight: .semibold))
                    let savings = (appState.currentProfile?.basicDetails.monthlyIncomeAfterTax ?? 0)
                               - (appState.currentProfile?.basicDetails.monthlyExpenses ?? 0)
                    Text("Based on your savings of \(max(0, savings).toCurrency())/mo")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Picker("", selection: $chartMode) {
                    ForEach(ChartMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }
            .padding(.horizontal, 20)

            // ── Legend ─────────────────────────────────────────────────────
            HStack(spacing: 16) {
                ChartLegendItem(color: .green,            label: "Current capacity")
                ChartLegendItem(color: .blue.opacity(0.7), label: "Future capacity")
                ChartLegendItem(color: .orange,            label: "Now", dashed: true)
            }
            .padding(.horizontal, 20)

            // ── Chart (animated swap) ──────────────────────────────────────
            if chartMode == .yearly {
                yearlyChart
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            } else {
                monthlyChart
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }

            // ── Insight text ───────────────────────────────────────────────
            insightText
                .padding(.horizontal, 20)
                .padding(.top, 4)
        }
        .padding(.vertical, 20)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
        .animation(.easeInOut(duration: 0.3), value: chartMode)
    }

    // MARK: Yearly Chart (3 years)
    private var yearlyChart: some View {
        Chart(chartData) { dp in
            BarMark(
                x: .value("Year", dp.year),
                y: .value("Amount", dp.value),
                width: 32
            )
            .foregroundStyle(
                dp.isCurrent
                    ? LinearGradient(colors: [.green, .green],
                                     startPoint: .top, endPoint: .bottom)
                    : LinearGradient(colors: [.blue.opacity(0.8), .blue.opacity(0.5)],
                                     startPoint: .top, endPoint: .bottom)
            )
            .cornerRadius(6)
            .annotation(position: .top, spacing: 4) {
                if dp.recommendedIncrease > 0 {
                    VStack(spacing: 1) {
                        Text("↑ add")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.secondary)
                        Text(dp.recommendedIncrease.toCurrency(compact: true))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.primary)
                    }
                }
            }

            if dp.isCurrent {
                RuleMark(x: .value("Now", dp.year))
                    .foregroundStyle(Color.orange.opacity(0.45))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                    .annotation(position: .top, alignment: .center) {
                        Text("Now")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(4)
                            .offset(y: -40)
                    }
            }
        }
        .frame(height: 240)
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { val in
                AxisGridLine().foregroundStyle(Color.secondary.opacity(0.15))
                AxisValueLabel {
                    if let v = val.as(Double.self) {
                        Text(v.toCurrency(compact: true))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel()
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.secondary)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: Monthly Chart (12 months)
    // Each bar is split into two stacked segments:
    //   • bottom (blue/green) = actualInvested (SIP already committed)
    //   • top    (teal)       = recommendedTop (gap to fill)
    private var monthlyChart: some View {
        // Give each bar ~44 pt of room → 12 months × 44 = 528 pt wide chart content
        let barSlotWidth: CGFloat = 44
        let chartWidth: CGFloat = barSlotWidth * CGFloat(monthlyChartData.count)

        return ScrollView(.horizontal, showsIndicators: false) {
            Chart {
                ForEach(monthlyChartData) { dp in
                    // Segment 1 — already invested (SIP)
                    BarMark(
                        x: .value("Month", dp.label),
                        y: .value("Invested", dp.actualInvested),
                        width: 20
                    )
                    .foregroundStyle(
                        dp.isCurrent
                            ? LinearGradient(colors: [.green, .green.opacity(0.8)],
                                             startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [.blue.opacity(0.85), .blue.opacity(0.55)],
                                             startPoint: .top, endPoint: .bottom)
                    )
                    .cornerRadius(3)

                    // Segment 2 — recommended additional (gap)
                    if dp.recommendedTop > 0 {
                        BarMark(
                            x: .value("Month", dp.label),
                            y: .value("Recommended", dp.recommendedTop),
                            width: 20
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.teal.opacity(dp.isCurrent ? 0.9 : 0.5),
                                         Color.teal.opacity(dp.isCurrent ? 0.6 : 0.3)],
                                startPoint: .top, endPoint: .bottom)
                        )
                        .cornerRadius(3)
                    }

                    // "Now" rule on the current month
                    if dp.isCurrent {
                        RuleMark(x: .value("Now", dp.label))
                            .foregroundStyle(Color.orange.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                            .annotation(position: .top, alignment: .center) {
                                Text("Now")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.orange)
                                    .cornerRadius(4)
                                    .offset(y: -36)
                            }
                    }
                }
            }
            .frame(width: chartWidth, height: 240)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { val in
                    AxisGridLine().foregroundStyle(Color.secondary.opacity(0.15))
                    AxisValueLabel {
                        if let v = val.as(Double.self) {
                            Text(v.toCurrency(compact: true))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine().foregroundStyle(Color.secondary.opacity(0.08))
                    AxisValueLabel(centered: true) {
                        if let label = value.as(String.self) {
                            Text(label)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.secondary)
                        }
                    }
                }
            }
            .padding(.leading, 20)  // room for Y-axis labels
            .padding(.trailing, 12)
        }
    }

    // MARK: Adaptive insight text
    @ViewBuilder
    private var insightText: some View {
        let gap = monthlyChartData.first?.recommendedTop ?? 0
        let sipRunning = monthlyChartData.first?.actualInvested ?? 0

        if chartMode == .monthly {
            if sipRunning == 0 {
                Text("You haven't started any SIPs yet. Based on your savings capacity you can start investing \(gap.toCurrency(compact: true))/mo right away.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else if gap > 0 {
                Text("You can top up your SIPs by \(gap.toCurrency(compact: true))/mo. The teal bars show the untapped savings you could put to work each month.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Great work — your SIP commitments already match or exceed your monthly savings capacity. Consider increasing income or reducing expenses to invest more.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        } else {
            Text("You are currently investing less than your potential saving capacity. Increasing your monthly SIPs can help you reach your goals faster.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var investmentsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Investments").font(.title2).fontWeight(.bold)
                Spacer()
                NavigationLink(destination: FullInvestmentListView()) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.accentColor)
                }
            }
            
            VStack(spacing: 12) {
                let sortedInv = investments.sorted(by: { $0.createdAt > $1.createdAt })
                let recentInv = sortedInv.prefix(3)
                
                if recentInv.isEmpty {
                    Text("No investments recorded yet")
                        .font(.subheadline).foregroundColor(.secondary)
                        .frame(maxWidth: .infinity).padding(24)
                        .background(AppTheme.cardBackground).cornerRadius(12)
                } else {
                    ForEach(recentInv) { inv in
                        NavigationLink(destination: InvestmentDetailView(investmentID: inv.id)) {
                            InvestmentRowView(
                                name: inv.investmentName,
                                category: inv.investmentType.rawValue,
                                risk: riskLabel(for: inv),
                                amount: inv.currentValue.toCurrency(),
                                gain: (inv.currentGain >= 0 ? "+" : "") + inv.currentGain.toCurrency(),
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

    private var insuranceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Insurance").font(.title2).fontWeight(.bold)
                Spacer()
                NavigationLink(destination: InsuranceListView()) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.accentColor)
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

    private func riskLabel(for inv: AstraInvestment) -> String {
        switch inv.investmentType {
        case .stocks: return "High Risk"
        case .mutualFund: return "Moderate Risk"
        case .goldETF: return "Low Risk"
        case .physicalGold: return "Low Risk"
        case .deposits: return "Low Risk"
        case .cryptocurrency: return "Very High Risk"
        case .realEstate: return "Low Risk"
        case .bonds: return "Low Risk"
        case .ppf: return "Low Risk"
        case .nps: return "Moderate Risk"
        case .other: return "Moderate Risk"
        }
    }

    private func goalName(for inv: AstraInvestment) -> String {
        guard let gid = inv.associatedGoalID,
              let goal = appState.currentProfile?.goals.first(where: { $0.id == gid })
        else { return "General" }
        return goal.goalName
    }
}

struct InvestmentRowView: View {
    let name: String
    let category: String
    let risk: String
    let amount: String
    let gain: String
    let startDate: String
    let goal: String

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
    let title: String
    let subtitle: String
    let status: String
    let claimedAmount: String
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
                HStack {
                    Text("Claimed Amount").foregroundColor(.secondary)
                    Spacer()
                    Text(claimedAmount)
                }.font(.subheadline)
                if let reg = registrationNumber {
                    HStack {
                        Text("Registration number").foregroundColor(.secondary)
                        Spacer()
                        Text(reg)
                    }.font(.subheadline)
                }
                if let sum = sumInsured {
                    HStack {
                        Text("Sum Insured").foregroundColor(.secondary)
                        Spacer()
                        Text(sum)
                    }.font(.subheadline)
                }
                HStack {
                    Text("Renewal Date").foregroundColor(.secondary)
                    Spacer()
                    Text(renewalDate)
                }.font(.subheadline)
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
    }

}
struct ChartLegendItem: View {
    let color: Color
    let label: String
    var dashed: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            if dashed {
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(color)
                            .frame(width: 5, height: 3)
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 16, height: 4)
            }
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
}

/// A compact single-row card used inside the portfolio breakdown (gainers / losers list).
struct PortfolioBreakdownRow: View {
    let item: InvestmentSummaryItem

    var body: some View {
        HStack(spacing: 12) {
            // Colour dot
            Circle()
                .fill(item.isGainer ? Color.green.opacity(0.8) : Color.red.opacity(0.8))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline).fontWeight(.medium)
                    .lineLimit(1)
                Text(item.category + " · " + item.risk)
                    .font(.caption).foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(item.currentValue.toCurrency())
                    .font(.subheadline).fontWeight(.semibold)

                HStack(spacing: 3) {
                    Image(systemName: item.isGainer ? "arrow.up" : "arrow.down")
                        .font(.system(size: 9, weight: .bold))
                    Text(String(format: "%.1f%%", abs(item.gainLossPct)))
                        .font(.caption).fontWeight(.semibold)
                    Text("(\(item.gainLoss >= 0 ? "+" : "")\(item.gainLoss.toCurrency()))")
                        .font(.caption)
                }
                .foregroundColor(item.isGainer ? .green : .red)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            (item.isGainer ? Color.green : Color.red).opacity(0.06)
        )
        .cornerRadius(10)
    }
}

#Preview {
    NavigationStack {
        InvestmentOverviewView()
            .environment(AppStateManager())
            .environment(TrackerViewModel())
    }
}
