import SwiftUI
import Charts

struct NetWorthCard: View {
    let netWorth: Double
    let growthAmount: Double
    let accounts: [Account]
    let annualGrowthRate: Double
    let monthlySurplus: Double
    let monthlyEMI: Double

    @State private var projectionYears = 5
    @State private var extraMonthlyInvestment: Double = 0
    @State private var extraLoanRepayment: Double = 0
    @State private var inflationRate: Double = 0.06
    @State private var showAddNetWorth = false
    @State private var areScenarioControlsExpanded = false
    
    @Environment(\.colorScheme) private var colorScheme

    private let defaultLoanRate = 0.10
    private let defaultInflationRate: Double = 0.06

    private var normalizedGrowthRate: Double {
        let rate = annualGrowthRate.safeFinite
        if rate > 1 { return rate / 100 }
        if rate > 0 { return rate }
        return 0.08
    }

    private var maxInvestmentStepUp: Double {
        max(1000, min(100000, max(monthlySurplus, 5000)))
    }

    /// True if the user has customized any scenario slider from its default
    private var hasSliderChanges: Bool {
        extraMonthlyInvestment != 0 ||
        extraLoanRepayment != 0 ||
        inflationRate != defaultInflationRate
    }

    private var projectionItems: [NetWorthProjectionItem] {
        accounts.map { account in
            NetWorthProjectionItem(
                account: account,
                fallbackGrowthRate: normalizedGrowthRate,
                defaultLoanRate: defaultLoanRate
            )
        }
    }

    // MARK: - Historical data (fixed, never changes with sliders)

    /// Back-project ~1 year of historical net worth so the chart stays focused on projection.
    private var historicalChartPoints: [NetWorthChartPoint] {
        let historyYears = 1
        let rate = max(normalizedGrowthRate, 0.01)
        return stride(from: -Double(historyYears), through: 0, by: 0.5).map { year in
            let value = (netWorth / pow(1 + rate, abs(year))).safeFinite
            return NetWorthChartPoint(year: year, value: value, series: .baseline)
        }
    }

    // MARK: - Baseline projection (continue as-is, no slider changes)

    private var baselineChartPoints: [NetWorthChartPoint] {
        projectionYearSteps.map { year in
            let summary = baselineProjectionSummary(for: year)
            return NetWorthChartPoint(year: year, value: summary.nominalNetWorth, series: .baseline)
        }
    }

    // MARK: - Adjusted projection (reactive to sliders)

    private var adjustedChartPoints: [NetWorthChartPoint] {
        projectionYearSteps.map { year in
            let summary = adjustedProjectionSummary(for: year)
            return NetWorthChartPoint(year: year, value: summary.nominalNetWorth, series: .adjusted)
        }
    }

    private var inflationChartPoints: [NetWorthChartPoint] {
        projectionYearSteps.map { year in
            let summary = hasSliderChanges ? adjustedProjectionSummary(for: year) : baselineProjectionSummary(for: year)
            return NetWorthChartPoint(year: year, value: summary.realPurchasingPower, series: .inflation)
        }
    }

    private var baselineInflationChartPoints: [NetWorthChartPoint] {
        projectionYearSteps.map { year in
            let summary = baselineProjectionSummary(for: year, inflationRate: inflationRate)
            return NetWorthChartPoint(year: year, value: summary.realPurchasingPower, series: .baselineInflation)
        }
    }

    private var projectionYearSteps: [Double] {
        Array(stride(from: 0.0, through: Double(projectionYears), by: 0.5))
    }

    /// Combined blue points (history -1 to 0 + baseline 0 to N, avoiding duplicate Year 0)
    private var bluePoints: [NetWorthChartPoint] {
        let history = historicalChartPoints.filter { $0.year < 0 }
        return history + baselineChartPoints
    }

    /// All points fed to the chart.
    private var allChartPoints: [NetWorthChartPoint] {
        var points = bluePoints
        if hasSliderChanges {
            points += adjustedChartPoints
            points += inflationChartPoints
            points += baselineInflationChartPoints
        }
        return points
    }

    private var finalSummary: NetWorthProjectionSummary {
        hasSliderChanges
            ? adjustedProjectionSummary(for: projectionYears)
            : baselineProjectionSummary(for: projectionYears)
    }

    private var baselineFinalSummary: NetWorthProjectionSummary {
        baselineProjectionSummary(for: projectionYears)
    }

    private var selectedYearLabel: String {
        "\(projectionYears)Y"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Total Net Worth").font(.auraCaption()).foregroundColor(.secondary)
                    Text(netWorth.toCurrency())
                        .font(.auraDigital(size: 32))

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .bold))
                        Text(growthAmount.toCurrency())
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(AppTheme.auraGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.auraGreen.opacity(0.1))
                    .cornerRadius(8)
                }
                Spacer()
                Button(action: { showAddNetWorth = true }) {
                    Image(systemName: "pencil.circle")
                        .font(.title2)
                        .foregroundColor(AppTheme.auraIndigo)
                }
            }

            ProjectionSelector(selectedYears: $projectionYears)

            NetWorthProjectionChart(
                points: allChartPoints,
                projectionYears: projectionYears,
                showAdjusted: hasSliderChanges
            )
            .frame(height: 304)
            .padding(.horizontal, -18)
            .animation(.easeOut(duration: 0.18), value: extraMonthlyInvestment)
            .animation(.easeOut(duration: 0.18), value: extraLoanRepayment)
            .animation(.easeOut(duration: 0.18), value: inflationRate)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 14) {
                    chartLegendItems
                }

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), alignment: .leading),
                        GridItem(.flexible(), alignment: .leading)
                    ],
                    alignment: .leading,
                    spacing: 8
                ) {
                    chartLegendItems
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .animation(.easeInOut(duration: 0.3), value: hasSliderChanges)

            HStack(spacing: 10) {
                if hasSliderChanges {
                    ProjectionMetricTile(
                        title: "\(selectedYearLabel) baseline",
                        value: baselineFinalSummary.nominalNetWorth.toCurrency(compact: true),
                        color: Color(hex: "#8E8E93")
                    )
                    ProjectionMetricTile(
                        title: "\(selectedYearLabel) adjusted",
                        value: finalSummary.nominalNetWorth.toCurrency(compact: true),
                        color: NetWorthProjectionChart.adjustedColor
                    )
                } else {
                    ProjectionMetricTile(
                        title: "\(selectedYearLabel) nominal",
                        value: finalSummary.nominalNetWorth.toCurrency(compact: true),
                        color: AppTheme.auraIndigo
                    )
                    ProjectionMetricTile(
                        title: "Real purchasing power",
                        value: finalSummary.realPurchasingPower.toCurrency(compact: true),
                        color: AppTheme.vibrantOrange
                    )
                }
            }
            .animation(.easeInOut(duration: 0.3), value: hasSliderChanges)

            VStack(alignment: .leading, spacing: 14) {
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        areScenarioControlsExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text("Scenario Controls")
                            .font(.auraBody(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(AppTheme.auraIndigo)
                            .rotationEffect(.degrees(areScenarioControlsExpanded ? 180 : 0))
                            .accessibilityHidden(true)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(areScenarioControlsExpanded ? "Collapse scenario controls" : "Expand scenario controls")

                if areScenarioControlsExpanded {
                    VStack(spacing: 14) {
                        ProjectionSliderRow(
                            title: "Increase monthly investment",
                            icon: "plus.circle.fill",
                            value: $extraMonthlyInvestment,
                            range: 0...maxInvestmentStepUp,
                            step: 1000,
                            tint: AppTheme.auraGreen,
                            suffix: "/mo"
                        )

                        ProjectionSliderRow(
                            title: "Add extra loan repayment",
                            icon: "minus.circle.fill",
                            value: $extraLoanRepayment,
                            range: 0...30000,
                            step: 1000,
                            tint: AppTheme.vibrantRed,
                            suffix: "/mo"
                        )

                        ScenarioPercentSliderRow(
                            title: "Inflation",
                            icon: "chart.line.downtrend.xyaxis",
                            value: $inflationRate,
                            range: 0.03...0.08,
                            step: 0.005,
                            tint: AppTheme.vibrantOrange
                        )

                        Divider()

                        InflationImpactSection(
                            projectedValue: finalSummary.nominalNetWorth,
                            realValue: finalSummary.realPurchasingPower,
                            years: projectionYears,
                            inflationRate: hasSliderChanges ? inflationRate : defaultInflationRate
                        )

                        ProjectionBreakdownSection(
                            items: projectionItems,
                            years: projectionYears,
                            monthlyInvestment: extraMonthlyInvestment,
                            monthlyLoanPayment: monthlyEMI + extraLoanRepayment
                        )
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(14)
            .background(AppTheme.elevatedCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

        }
        .auraCardStyle(radius: 34)
        .sheet(isPresented: $showAddNetWorth) {
            AddNetWorthView()
        }
    }

    @ViewBuilder
    private var chartLegendItems: some View {
        ChartLegendDot(color: NetWorthProjectionChart.baselineColor, label: "Current Plan")
        if hasSliderChanges {
            ChartLegendDot(color: NetWorthProjectionChart.adjustedColor, label: "Projected Future Growth")
            ChartLegendDot(color: NetWorthProjectionChart.inflationColor, label: "Projected Future Inflation")
            ChartLegendDot(color: NetWorthProjectionChart.baselineInflationColor, label: "Current Inflation")
        }
    }

    // MARK: - Baseline projection (no slider changes, default assumptions)

    private func baselineProjectionSummary(for years: Int) -> NetWorthProjectionSummary {
        baselineProjectionSummary(for: Double(years))
    }

    private func baselineProjectionSummary(for years: Double) -> NetWorthProjectionSummary {
        baselineProjectionSummary(for: years, inflationRate: defaultInflationRate)
    }

    private func baselineProjectionSummary(for years: Double, inflationRate: Double) -> NetWorthProjectionSummary {
        let appreciatingItems = projectionItems.filter { $0.group == .appreciating }
        let depreciatingItems = projectionItems.filter { $0.group == .depreciating }
        let liabilityItems = projectionItems.filter { $0.group == .liability }

        let appreciatingBase = appreciatingItems.reduce(0.0) { $0 + $1.projectedValue(after: years, monthlyPayment: 0) }.safeFinite
        let depreciatingValue = depreciatingItems.reduce(0.0) { $0 + $1.projectedValue(after: years, monthlyPayment: 0) }.safeFinite
        let outstandingLiabilities = baselineLiabilityValue(for: liabilityItems, years: years)
        let nominal = (appreciatingBase + depreciatingValue - outstandingLiabilities).safeFinite
        let real = years > 0 ? (nominal / pow(1 + inflationRate, years)).safeFinite : nominal

        return NetWorthProjectionSummary(
            year: Int(years.rounded()),
            appreciatingAssets: appreciatingBase,
            depreciatingAssets: depreciatingValue,
            liabilities: outstandingLiabilities,
            nominalNetWorth: nominal,
            realPurchasingPower: real
        )
    }

    private func baselineLiabilityValue(for items: [NetWorthProjectionItem], years: Double) -> Double {
        let totalLiability = items.reduce(0.0) { $0 + abs($1.currentValue) }.safeFinite
        guard totalLiability > 0 else { return 0 }

        return items.reduce(0.0) { partial, item in
            let share = abs(item.currentValue) / totalLiability
            let allocatedPayment = max(0, monthlyEMI) * share
            return partial + item.projectedValue(after: years, monthlyPayment: allocatedPayment)
        }.safeFinite
    }

    // MARK: - Adjusted projection (with slider changes)

    private func adjustedProjectionSummary(for years: Int) -> NetWorthProjectionSummary {
        adjustedProjectionSummary(for: Double(years))
    }

    private func adjustedProjectionSummary(for years: Double) -> NetWorthProjectionSummary {
        let appreciatingItems = projectionItems.filter { $0.group == .appreciating }
        let depreciatingItems = projectionItems.filter { $0.group == .depreciating }
        let liabilityItems = projectionItems.filter { $0.group == .liability }

        let appreciatingBase = appreciatingItems.reduce(0.0) { $0 + $1.projectedValue(after: years, monthlyPayment: 0) }.safeFinite
        let futureMonthlyInvestment = projectedMonthlyInvestmentValue(for: appreciatingItems, years: years)
        let appreciatingValue = (appreciatingBase + futureMonthlyInvestment).safeFinite
        let depreciatingValue = depreciatingItems.reduce(0.0) { $0 + $1.projectedValue(after: years, monthlyPayment: 0) }.safeFinite
        let outstandingLiabilities = adjustedLiabilityValue(for: liabilityItems, years: years)
        let nominal = (appreciatingValue + depreciatingValue - outstandingLiabilities).safeFinite
        let real = years > 0 ? (nominal / pow(1 + inflationRate, years)).safeFinite : nominal

        return NetWorthProjectionSummary(
            year: Int(years.rounded()),
            appreciatingAssets: appreciatingValue,
            depreciatingAssets: depreciatingValue,
            liabilities: outstandingLiabilities,
            nominalNetWorth: nominal,
            realPurchasingPower: real
        )
    }

    private func projectedMonthlyInvestmentValue(for items: [NetWorthProjectionItem], years: Double) -> Double {
        guard years > 0, extraMonthlyInvestment > 0 else { return 0 }
        let weightedRate = weightedAnnualRate(for: items)
        let monthlyRate = weightedRate / 12
        let months = years * 12

        guard monthlyRate != 0 else {
            return extraMonthlyInvestment * months
        }

        return (extraMonthlyInvestment * ((pow(1 + monthlyRate, months) - 1) / monthlyRate)).safeFinite
    }

    private func weightedAnnualRate(for items: [NetWorthProjectionItem]) -> Double {
        let total = items.reduce(0.0) { $0 + max(0, $1.currentValue) }.safeFinite
        guard total > 0 else { return normalizedGrowthRate }
        return items.reduce(0.0) { partial, item in
            partial + (item.rate * (max(0, item.currentValue) / total))
        }.safeFinite
    }

    private func adjustedLiabilityValue(for items: [NetWorthProjectionItem], years: Double) -> Double {
        let totalLiability = items.reduce(0.0) { $0 + abs($1.currentValue) }.safeFinite
        guard totalLiability > 0 else { return 0 }

        return items.reduce(0.0) { partial, item in
            let share = abs(item.currentValue) / totalLiability
            let allocatedPayment = max(0, monthlyEMI + extraLoanRepayment) * share
            return partial + item.projectedValue(after: years, monthlyPayment: allocatedPayment)
        }.safeFinite
    }
}

struct AccountRow: View {
    let account: Account

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                    .font(.auraHeader(size: 15))
                    
                Text(account.institution)
                    .font(.auraCaption())
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(account.balance.toCurrency())
                .font(.auraDigital(size: 16))
                .foregroundColor(account.balance >= 0 ? AppTheme.auraGreen : .red)
        }
    }
}

// MARK: - Chart Data Models

private enum NetWorthSeries {
    case baseline
    case adjusted
    case inflation
    case baselineInflation
}

private struct NetWorthChartPoint: Identifiable {
    let id = UUID()
    let year: Double
    let value: Double
    let series: NetWorthSeries
}

private struct NetWorthProjectionPoint: Identifiable {
    let id = UUID()
    let year: Int
    let value: Double
}

private struct NetWorthProjectionSummary {
    let year: Int
    let appreciatingAssets: Double
    let depreciatingAssets: Double
    let liabilities: Double
    let nominalNetWorth: Double
    let realPurchasingPower: Double

    var point: NetWorthProjectionPoint {
        NetWorthProjectionPoint(year: year, value: nominalNetWorth)
    }
}

// MARK: - Projection Engine Models

private enum NetWorthProjectionGroup: String, CaseIterable, Identifiable {
    case appreciating = "Appreciating Assets"
    case depreciating = "Depreciating Assets"
    case liability = "Liabilities"

    var id: String { rawValue }

    var tint: Color {
        switch self {
        case .appreciating: return AppTheme.auraGreen
        case .depreciating: return AppTheme.vibrantOrange
        case .liability: return AppTheme.vibrantRed
        }
    }
}

private struct NetWorthProjectionItem: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let currentValue: Double
    let group: NetWorthProjectionGroup
    let rate: Double

    init(
        account: Account,
        fallbackGrowthRate: Double,
        defaultLoanRate: Double
    ) {
        name = account.name
        category = account.institution
        currentValue = account.balance.safeFinite

        let combined = "\(account.name) \(account.institution)".lowercased()
        if account.balance < 0 || combined.contains("loan") || combined.contains("debt") || combined.contains("liability") || combined.contains("credit card") {
            group = .liability
            rate = Self.loanRate(for: combined, defaultRate: defaultLoanRate)
        } else if Self.isDepreciatingAsset(combined) {
            group = .depreciating
            rate = Self.depreciationRate(for: combined)
        } else {
            group = .appreciating
            rate = Self.growthRate(for: combined, fallback: fallbackGrowthRate)
        }
    }

    var rateLabel: String {
        switch group {
        case .appreciating: return "\(percentString(rate)) growth"
        case .depreciating: return "\(percentString(rate)) depreciation"
        case .liability: return "\(percentString(rate)) loan rate"
        }
    }

    func projectedValue(after years: Double, monthlyPayment: Double) -> Double {
        guard years > 0 else { return abs(currentValue).safeFinite }

        switch group {
        case .appreciating:
            return (max(0, currentValue) * pow(1 + rate, years)).safeFinite
        case .depreciating:
            return (max(0, currentValue) * pow(max(0, 1 - rate), years)).safeFinite
        case .liability:
            return projectedOutstandingLoan(after: years, monthlyPayment: monthlyPayment)
        }
    }

    private func projectedOutstandingLoan(after years: Double, monthlyPayment: Double) -> Double {
        var outstanding = abs(currentValue).safeFinite
        let monthlyRate = rate / 12
        let months = Int((years * 12).rounded())

        for _ in 0..<months {
            outstanding = (outstanding * (1 + monthlyRate) - max(0, monthlyPayment)).safeFinite
            if outstanding <= 0 { return 0 }
        }

        return outstanding
    }

    private func percentString(_ value: Double) -> String {
        String(format: "%.1f%%", value * 100)
    }

    private static func isDepreciatingAsset(_ text: String) -> Bool {
        ["vehicle", "car", "bike", "electronics", "furniture", "appliance", "luxury"].contains { text.contains($0) }
    }

    private static func growthRate(
        for text: String,
        fallback: Double
    ) -> Double {
        if text.contains("mutual") { return max(fallback, 0.12) }
        if text.contains("stock") || text.contains("equity") { return max(fallback, 0.11) }
        if text.contains("property") || text.contains("real estate") { return 0.07 }
        if text.contains("gold") || text.contains("jewellery") { return 0.06 }
        if text.contains("deposit") { return 0.065 }
        if text.contains("ppf") { return 0.071 }
        if text.contains("epf") { return 0.081 }
        if text.contains("nps") { return 0.10 }
        if text.contains("savings") || text.contains("current account") { return 0.03 }
        return max(fallback, 0.06)
    }

    private static func depreciationRate(for text: String) -> Double {
        if text.contains("electronics") { return 0.25 }
        if text.contains("vehicle") || text.contains("car") || text.contains("bike") { return 0.15 }
        if text.contains("furniture") || text.contains("appliance") { return 0.10 }
        if text.contains("luxury") { return 0.12 }
        return 0.10
    }

    private static func loanRate(for text: String, defaultRate: Double) -> Double {
        if text.contains("credit card") { return 0.30 }
        if text.contains("home") { return 0.085 }
        if text.contains("education") { return 0.095 }
        if text.contains("vehicle") || text.contains("car") { return 0.105 }
        return defaultRate
    }
}

// MARK: - Projection Selector

private struct ProjectionSelector: View {
    @Binding var selectedYears: Int

    var body: some View {
        HStack(spacing: 8) {
            ProjectionOptionButton(title: "5Y", years: 5, selectedYears: $selectedYears)
            ProjectionOptionButton(title: "10Y", years: 10, selectedYears: $selectedYears)
        }
    }
}

private struct ProjectionOptionButton: View {
    let title: String
    let years: Int
    @Binding var selectedYears: Int

    var body: some View {
        Button {
            selectedYears = years
        } label: {
            Text(title)
                .font(.auraBody(size: 13, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(selectedYears == years ? Color.white : AppTheme.auraIndigo)
                .background(selectedYears == years ? AppTheme.auraIndigo : AppTheme.auraIndigo.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Chart Legend Helper

private struct ChartLegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.auraCaption(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Re-designed Net Worth Chart

private struct NetWorthProjectionChart: View {
    let points: [NetWorthChartPoint]
    let projectionYears: Int
    let showAdjusted: Bool
    @State private var zoomScale: Double = 2.0
    @State private var gestureStartZoom: Double = 2.0

    private let minZoomScale = 0.65
    private let maxZoomScale = 2.2

    private var baselinePoints: [NetWorthChartPoint] {
        points.filter { $0.series == .baseline }
    }

    private var adjustedPoints: [NetWorthChartPoint] {
        points.filter { $0.series == .adjusted }
    }

    private var inflationPoints: [NetWorthChartPoint] {
        points.filter { $0.series == .inflation }
    }

    private var baselineInflationPoints: [NetWorthChartPoint] {
        points.filter { $0.series == .baselineInflation }
    }

    // Exposed theme colors
    static let baselineColor = AppTheme.auraIndigo  // Blue line
    static let adjustedColor = AppTheme.auraGreen    // Green line
    static let inflationColor = AppTheme.vibrantOrange
    static let baselineInflationColor = Color.yellow

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .trailing) {
            Chart {
            // ── 1. Baseline Area (Subtle Blue shading)
            ForEach(baselinePoints) { point in
                AreaMark(
                    x: .value("Year", point.year),
                    yStart: .value("Baseline", chartDomain.lowerBound),
                    yEnd: .value("Net Worth", point.value)
                )
                .foregroundStyle(by: .value("Series", "baselineArea"))
                .interpolationMethod(.monotone)
            }

            // ── 2. Baseline Line (Solid Blue)
            ForEach(baselinePoints) { point in
                LineMark(
                    x: .value("Year", point.year),
                    y: .value("Net Worth", point.value)
                )
                .foregroundStyle(by: .value("Series", "baseline"))
                .interpolationMethod(.monotone)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            }

            // ── 3. Adjusted Area (Subtle Green shading) - only if changes exist
            if showAdjusted {
                ForEach(adjustedPoints) { point in
                    AreaMark(
                        x: .value("Year", point.year),
                        yStart: .value("Baseline", chartDomain.lowerBound),
                        yEnd: .value("Net Worth", displayValue(for: point))
                    )
                    .foregroundStyle(by: .value("Series", "adjustedArea"))
                    .interpolationMethod(.monotone)
                }

                // ── 4. Adjusted Line (Solid Green)
                ForEach(adjustedPoints) { point in
                    LineMark(
                        x: .value("Year", point.year),
                        y: .value("Net Worth", displayValue(for: point))
                    )
                    .foregroundStyle(by: .value("Series", "adjusted"))
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                }
            }

            if showAdjusted {
                ForEach(baselineInflationPoints) { point in
                    LineMark(
                        x: .value("Year", point.year),
                        y: .value("Net Worth", displayValue(for: point))
                    )
                    .foregroundStyle(by: .value("Series", "baselineInflation"))
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 2.3, lineCap: .round, lineJoin: .round, dash: [3, 5]))
                }

                ForEach(inflationPoints) { point in
                    LineMark(
                        x: .value("Year", point.year),
                        y: .value("Net Worth", displayValue(for: point))
                    )
                    .foregroundStyle(by: .value("Series", "inflation"))
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round, dash: [6, 5]))
                }
            }

            // ── 5. Point Marks for Baseline
            ForEach(baselinePoints) { point in
                if point.year == -3 || point.year == 0 || (!showAdjusted && point.year == Double(projectionYears)) {
                    PointMark(
                        x: .value("Year", point.year),
                        y: .value("Net Worth", point.value)
                    )
                    .foregroundStyle(by: .value("Series", "baseline"))
                    .symbolSize(point.year == 0 ? 70 : 38)
                }
            }

            // ── 6. Point Marks for Adjusted (only if changes exist)
            if showAdjusted {
                ForEach(adjustedPoints) { point in
                    if point.year == 0 || point.year == Double(projectionYears) {
                        PointMark(
                            x: .value("Year", point.year),
                            y: .value("Net Worth", displayValue(for: point))
                        )
                        .foregroundStyle(by: .value("Series", "adjusted"))
                        .symbolSize(point.year == 0 ? 70 : 38)
                    }
                }
            }

            // ── 7. Baseline endpoint annotation
            if let lastBaseline = baselinePoints.last {
                PointMark(
                    x: .value("Year", lastBaseline.year),
                    y: .value("Net Worth", lastBaseline.value)
                )
                .foregroundStyle(.white)
                .symbolSize(24)
            }

            // ── 8. Adjusted endpoint annotation (only if adjusted IS shown)
            if showAdjusted, let lastAdjusted = adjustedPoints.last {
                PointMark(
                    x: .value("Year", lastAdjusted.year),
                    y: .value("Net Worth", displayValue(for: lastAdjusted))
                )
                .foregroundStyle(.white)
                .symbolSize(28)
            }

            if showAdjusted, let lastInflation = inflationPoints.last {
                PointMark(
                    x: .value("Year", lastInflation.year),
                    y: .value("Net Worth", displayValue(for: lastInflation))
                )
                .foregroundStyle(by: .value("Series", "inflation"))
                .symbolSize(24)
            }

            if showAdjusted, let lastBaselineInflation = baselineInflationPoints.last {
                PointMark(
                    x: .value("Year", lastBaselineInflation.year),
                    y: .value("Net Worth", displayValue(for: lastBaselineInflation))
                )
                .foregroundStyle(by: .value("Series", "baselineInflation"))
                .symbolSize(22)
            }
            }
            .chartXScale(domain: -1.0...Double(projectionYears))
            .chartYScale(domain: chartDomain)
            .chartXAxis {
                AxisMarks(values: xAxisValues) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 4]))
                        .foregroundStyle(AppTheme.auraIndigo.opacity(0.16))
                    AxisValueLabel {
                        if let year = value.as(Double.self) {
                            Text(xAxisLabel(for: year))
                                .font(.auraCaption(size: 9))
                                .foregroundStyle(.secondary.opacity(0.9))
                                .frame(width: 28)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: yAxisValues) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(AppTheme.auraIndigo.opacity(0.12))
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(amount.toCurrency(compact: true))
                                .font(.auraCaption(size: 8))
                                .foregroundStyle(.secondary.opacity(0.95))
                                .frame(width: 24, alignment: .trailing)
                                .lineLimit(1)
                                .minimumScaleFactor(0.55)
                        }
                    }
                }
            }
            .chartPlotStyle { plotArea in
                plotArea
                    .padding(.top, 12)
                    .padding(.trailing, showAdjusted ? 72 : 48)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.auraIndigo.opacity(0.025))
                    )
            }
            .chartForegroundStyleScale([
                "baseline": AnyShapeStyle(Self.baselineColor),
                "adjusted": AnyShapeStyle(Self.adjustedColor),
                "inflation": AnyShapeStyle(Self.inflationColor),
                "baselineInflation": AnyShapeStyle(Self.baselineInflationColor),
                "baselineArea": AnyShapeStyle(
                    LinearGradient(
                        colors: [
                            Self.baselineColor.opacity(0.18),
                            Self.baselineColor.opacity(0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                ),
                "adjustedArea": AnyShapeStyle(
                    LinearGradient(
                        colors: [
                            Self.adjustedColor.opacity(0.16),
                            Self.adjustedColor.opacity(0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            ])
            .chartLegend(.hidden)
            .clipped()
            .contentShape(Rectangle())
            .gesture(zoomGesture)
            .simultaneousGesture(
                TapGesture(count: 2).onEnded {
                    withAnimation(.easeOut(duration: 0.18)) {
                        zoomScale = 1.0
                        gestureStartZoom = 1.0
                    }
                }
            )

                endpointValueRail
                    .padding(.trailing, 2)
                    .padding(.top, 30)
                    .padding(.bottom, 38)
            }

            HStack {
                Spacer()
                chartZoomControls
            }
        }
        .accessibilityLabel("Net worth baseline, adjusted, and inflation projection chart")
    }

    private var xAxisValues: [Double] {
        if projectionYears <= 5 {
            return [-1.0, 0.0, 1.0, 3.0, Double(projectionYears)]
                .reduce(into: [Double]()) { values, year in
                    if !values.contains(year) { values.append(year) }
                }
                .sorted()
        }

        var values = [-1.0, 0.0]
        let step = projectionYears > 7 ? 2.0 : 1.0
        values += stride(from: step, through: Double(projectionYears), by: step)
        if values.last != Double(projectionYears) {
            values.append(Double(projectionYears))
        }
        return values
    }

    @ViewBuilder
    private var endpointValueRail: some View {
        let labels = endpointLabels
        if !labels.isEmpty {
            GeometryReader { proxy in
                let positionedLabels = positionedEndpointLabels(in: proxy.size.height)

                ZStack(alignment: .trailing) {
                    ForEach(positionedLabels) { positioned in
                        Text(positioned.label.value.toCurrency(compact: true))
                            .font(.auraCaption(size: 9, weight: .bold))
                            .foregroundStyle(positioned.label.color)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 5)
                            .background(positioned.label.color.opacity(0.14))
                            .clipShape(Capsule())
                            .position(x: proxy.size.width / 2, y: positioned.y)
                    }
                }
            }
            .frame(width: 62)
            .frame(maxHeight: .infinity, alignment: .center)
        }
    }

    private var endpointLabels: [EndpointValueLabel] {
        var labels: [EndpointValueLabel] = []

        if let adjusted = adjustedPoints.last, showAdjusted {
            labels.append(EndpointValueLabel(value: adjusted.value, displayValue: displayValue(for: adjusted), color: Self.adjustedColor))
        }
        if let inflation = inflationPoints.last, showAdjusted {
            labels.append(EndpointValueLabel(value: inflation.value, displayValue: displayValue(for: inflation), color: Self.inflationColor))
        }
        if let baseline = baselinePoints.last {
            labels.append(EndpointValueLabel(value: baseline.value, displayValue: baseline.value, color: Self.baselineColor))
        }
        if let baselineInflation = baselineInflationPoints.last, showAdjusted {
            labels.append(EndpointValueLabel(value: baselineInflation.value, displayValue: displayValue(for: baselineInflation), color: Self.baselineInflationColor))
        }

        return labels.sorted { $0.displayValue > $1.displayValue }
    }

    private func positionedEndpointLabels(in height: CGFloat) -> [PositionedEndpointValueLabel] {
        let minSpacing: CGFloat = 34
        let topPadding: CGFloat = 12
        let bottomPadding: CGFloat = 12
        let availableHeight = max(height, 1)
        let domain = chartDomain
        let span = max(domain.upperBound - domain.lowerBound, 1)

        var positioned = endpointLabels.map { label in
            let normalized = (domain.upperBound - label.displayValue) / span
            let y = CGFloat(normalized) * availableHeight
            return PositionedEndpointValueLabel(
                label: label,
                y: min(max(y, topPadding), availableHeight - bottomPadding)
            )
        }
        .sorted { $0.y < $1.y }

        for index in positioned.indices {
            if index == positioned.startIndex {
                positioned[index].y = max(positioned[index].y, topPadding)
            } else {
                positioned[index].y = max(positioned[index].y, positioned[index - 1].y + minSpacing)
            }
        }

        if let lastY = positioned.last?.y, lastY > availableHeight - bottomPadding {
            let overflow = lastY - (availableHeight - bottomPadding)
            for index in positioned.indices {
                positioned[index].y -= overflow
            }
        }

        for index in positioned.indices {
            positioned[index].y = min(max(positioned[index].y, topPadding), availableHeight - bottomPadding)
        }

        return positioned
    }

    private func xAxisLabel(for year: Double) -> String {
        let currentYear = Calendar.current.component(.year, from: Date())
        return "\(currentYear + Int(year.rounded()))"
    }

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let nextScale = gestureStartZoom / max(value, 0.01)
                zoomScale = limitedZoomScale(nextScale)
            }
            .onEnded { value in
                let nextScale = gestureStartZoom / max(value, 0.01)
                zoomScale = limitedZoomScale(nextScale)
                gestureStartZoom = zoomScale
            }
    }

    private var chartZoomControls: some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.easeOut(duration: 0.18)) {
                    zoomScale = 1.0
                    gestureStartZoom = 1.0
                }
            } label: {
                Image(systemName: "arrow.counterclockwise")
            }
            .disabled(abs(zoomScale - 1.0) < 0.01)

            Button {
                withAnimation(.easeOut(duration: 0.18)) {
                    zoomScale = minZoomScale
                    gestureStartZoom = minZoomScale
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "minus.magnifyingglass")
                    Text("Fit")
                }
            }

            Text(String(format: "%.1fx", effectiveZoomScale))
                .font(.auraCaption(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(width: 42)
        }
        .font(.auraCaption(size: 10, weight: .bold))
        .foregroundStyle(AppTheme.auraIndigo)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    private var chartDomain: ClosedRange<Double> {
        let visibleValues = domainReferenceValues
        guard let rawMax = visibleValues.max(), let rawMin = visibleValues.min() else {
            return 0...100_000
        }

        let valueSpan = max(rawMax - rawMin, abs(rawMax) * 0.08, 100_000)
        let lowerCandidate = rawMin - valueSpan * 0.18
        let negativeCushion = niceCeiling(max(valueSpan * 0.14, 50_000))
        let lower = rawMin >= 0 ? -negativeCushion : niceFloor(lowerCandidate)
        let span = max(rawMax - lower, valueSpan, 100_000)
        let baseUpper = niceCeiling(rawMax + span * 0.16)
        let upper = lower + ((max(baseUpper, lower + 100_000) - lower) / effectiveZoomScale)
        return lower...max(upper, lower + 20_000)
    }

    private var effectiveZoomScale: Double {
        limitedZoomScale(zoomScale)
    }

    private func limitedZoomScale(_ scale: Double) -> Double {
        min(max(scale, minZoomScale), dynamicMaxZoomScale)
    }

    private var dynamicMaxZoomScale: Double {
        let visibleValues = domainReferenceValues
        guard let rawMax = visibleValues.max(), let rawMin = visibleValues.min() else {
            return maxZoomScale
        }

        let valueSpan = max(rawMax - rawMin, abs(rawMax) * 0.08, 100_000)
        let lowerCandidate = rawMin - valueSpan * 0.18
        let negativeCushion = niceCeiling(max(valueSpan * 0.14, 50_000))
        let lower = rawMin >= 0 ? -negativeCushion : niceFloor(lowerCandidate)
        let span = max(rawMax - lower, valueSpan, 100_000)
        let baseUpper = max(niceCeiling(rawMax + span * 0.16), lower + 100_000)
        let minimumVisibleUpper = lower + ((rawMax - lower) * 1.12)
        let allowed = (baseUpper - lower) / max(minimumVisibleUpper - lower, 1)
        return min(maxZoomScale, max(1.0, allowed))
    }

    private var domainReferenceValues: [Double] {
        let baselineValues = baselinePoints.map(\.value).filter(\.isFinite)
        guard showAdjusted else { return baselineValues }

        let scenarioValues = (adjustedPoints + inflationPoints + baselineInflationPoints).map(\.value).filter(\.isFinite)
        return baselineValues + scenarioValues
    }

    private func displayValue(for point: NetWorthChartPoint) -> Double {
        guard point.series == .adjusted || point.series == .inflation || point.series == .baselineInflation else { return point.value }
        let domain = chartDomain
        let topLimit = domain.lowerBound + ((domain.upperBound - domain.lowerBound) * 0.92)
        return min(max(point.value, domain.lowerBound), topLimit)
    }

    private var yAxisValues: [Double] {
        let domain = chartDomain
        let step = (domain.upperBound - domain.lowerBound) / 4
        var values = (0...4).map { domain.lowerBound + (Double($0) * step) }
        if domain.lowerBound < 0, domain.upperBound > 0 {
            values.append(0)
        }
        return values.sorted()
    }

    private func niceCeiling(_ value: Double) -> Double {
        guard value > 0, value.isFinite else { return 100_000 }
        let exponent = floor(log10(value))
        let magnitude = pow(10, exponent)
        let normalized = value / magnitude
        let niceNormalized: Double

        if normalized <= 1 { niceNormalized = 1 }
        else if normalized <= 2 { niceNormalized = 2 }
        else if normalized <= 3 { niceNormalized = 3 }
        else if normalized <= 5 { niceNormalized = 5 }
        else { niceNormalized = 10 }

        return niceNormalized * magnitude
    }

    private func nicePositiveFloor(_ value: Double) -> Double {
        guard value > 0, value.isFinite else { return 0 }
        let magnitude = pow(10, floor(log10(value)))
        return floor(value / magnitude) * magnitude
    }

    private func niceFloor(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        if value >= 0 { return 0 }
        let magnitude = pow(10, floor(log10(abs(value))))
        return floor(value / magnitude) * magnitude
    }

    private struct EndpointValueLabel: Identifiable {
        let id = UUID()
        let value: Double
        let displayValue: Double
        let color: Color
    }

    private struct PositionedEndpointValueLabel: Identifiable {
        var id: UUID { label.id }
        let label: EndpointValueLabel
        var y: CGFloat
    }
}

// MARK: - Projection Metric Tile View

private struct ProjectionMetricTile: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.auraCaption(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(value)
                .font(.auraDigital(size: 18))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Slider Row Views

private struct ProjectionSliderRow: View {
    let title: String
    let icon: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let tint: Color
    let suffix: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.auraBody(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 8)
                Text("\(value.toCurrency(compact: true))\(suffix)")
                    .font(.auraCaption(size: 12, weight: .bold))
                    .foregroundStyle(tint)
            }

            Slider(value: $value, in: range, step: step)
                .tint(tint)

            HStack {
                Text(range.lowerBound.toCurrency(compact: true))
                Spacer()
                Text(range.upperBound.toCurrency(compact: true))
            }
            .font(.auraCaption(size: 10, weight: .medium))
            .foregroundStyle(.secondary)
        }
    }
}

private struct ScenarioPercentSliderRow: View {
    let title: String
    let icon: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.auraBody(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 8)
                Text(percentText(value))
                    .font(.auraCaption(size: 12, weight: .bold))
                    .foregroundStyle(tint)
            }

            Slider(value: $value, in: range, step: step)
                .tint(tint)

            HStack {
                Text(percentText(range.lowerBound))
                Spacer()
                Text(percentText(range.upperBound))
            }
            .font(.auraCaption(size: 10, weight: .medium))
            .foregroundStyle(.secondary)
        }
    }

    private func percentText(_ rawValue: Double) -> String {
        let percentage = rawValue * 100
        if percentage.rounded() == percentage {
            return String(format: "%.0f%%", percentage)
        }
        return String(format: "%.1f%%", percentage)
    }
}

// MARK: - Inflation Impact View

private struct InflationImpactSection: View {
    let projectedValue: Double
    let realValue: Double
    let years: Int
    let inflationRate: Double

    private var inflationDrag: Double {
        max(0, projectedValue - realValue).safeFinite
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "chart.line.downtrend.xyaxis")
                    .foregroundStyle(AppTheme.vibrantOrange)
                Text("Inflation affected net worth")
                    .font(.auraBody(size: 15, weight: .semibold))
                Spacer()
                Text("\((inflationRate * 100).safeInt)%")
                    .font(.auraCaption(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.vibrantOrange)
            }

            HStack {
                InflationValueColumn(label: "Nominal projected", value: projectedValue.toCurrency(compact: true), color: AppTheme.auraIndigo)
                Spacer(minLength: 10)
                InflationValueColumn(label: "Real purchasing power", value: realValue.toCurrency(compact: true), color: AppTheme.vibrantOrange)
            }

            Text("Inflation may reduce purchasing power by \(inflationDrag.toCurrency(compact: true)) over \(years) years.")
                .font(.auraCaption(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(AppTheme.vibrantOrange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct InflationValueColumn: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.auraCaption(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(value)
                .font(.auraBody(size: 16, weight: .bold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Projection Breakdown Views

private struct ProjectionBreakdownSection: View {
    let items: [NetWorthProjectionItem]
    let years: Int
    let monthlyInvestment: Double
    let monthlyLoanPayment: Double

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Divider().background(Color.gray.opacity(0.12))

                Text("Projection breakdown")
                    .font(.auraBody(size: 16, weight: .semibold))

                ForEach(NetWorthProjectionGroup.allCases) { group in
                    let groupItems = items.filter { $0.group == group }
                    if !groupItems.isEmpty {
                        ProjectionGroupView(
                            title: group.rawValue,
                            tint: group.tint,
                            items: groupItems,
                            years: years,
                            monthlyInvestment: group == .appreciating ? monthlyInvestment : 0,
                            monthlyLoanPayment: group == .liability ? monthlyLoanPayment : 0
                        )
                    }
                }
            }
        }
    }
}

private struct ProjectionGroupView: View {
    let title: String
    let tint: Color
    let items: [NetWorthProjectionItem]
    let years: Int
    let monthlyInvestment: Double
    let monthlyLoanPayment: Double

    private var totalCurrent: Double {
        items.reduce(0.0) { $0 + abs($1.currentValue) }.safeFinite
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.auraCaption(size: 12, weight: .bold))
                    .foregroundStyle(tint)
                Spacer()
                Text(totalCurrent.toCurrency(compact: true))
                    .font(.auraCaption(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    ProjectionBreakdownRow(
                        item: item,
                        years: years,
                        monthlyInvestment: allocatedMonthlyInvestment(for: item),
                        monthlyLoanPayment: allocatedPayment(for: item)
                    )
                    .padding(.vertical, 7)

                    if index < items.count - 1 {
                        Divider()
                            .padding(.leading, 18)
                            .background(tint.opacity(0.08))
                    }
                }
            }
        }
        .padding(14)
        .background(tint.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func allocatedPayment(for item: NetWorthProjectionItem) -> Double {
        guard item.group == .liability, totalCurrent > 0 else { return 0 }
        return monthlyLoanPayment * (abs(item.currentValue) / totalCurrent)
    }

    private func allocatedMonthlyInvestment(for item: NetWorthProjectionItem) -> Double {
        guard item.group == .appreciating, totalCurrent > 0 else { return 0 }
        return monthlyInvestment * (max(0, item.currentValue) / totalCurrent)
    }
}

private struct ProjectionBreakdownRow: View {
    let item: NetWorthProjectionItem
    let years: Int
    let monthlyInvestment: Double
    let monthlyLoanPayment: Double

    private var projectedValue: Double {
        let baseValue = item.projectedValue(after: Double(years), monthlyPayment: monthlyLoanPayment)
        guard item.group == .appreciating, monthlyInvestment > 0, years > 0 else {
            return baseValue
        }

        let monthlyRate = item.rate / 12
        let months = years * 12
        if monthlyRate == 0 {
            return (baseValue + monthlyInvestment * Double(months)).safeFinite
        }

        let contributionValue = monthlyInvestment * ((pow(1 + monthlyRate, Double(months)) - 1) / monthlyRate)
        return (baseValue + contributionValue).safeFinite
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(item.group.tint)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(.auraBody(size: 14, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("\(item.category) · \(item.rateLabel)")
                        .font(.auraCaption(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(displayValue(abs(item.currentValue)))
                        .font(.auraBody(size: 14, weight: .semibold))
                        .foregroundStyle(item.group == .liability ? AppTheme.vibrantRed : item.group.tint)
                    Text("\(years)Y \(displayValue(projectedValue))")
                        .font(.auraCaption(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func displayValue(_ value: Double) -> String {
        let sign = item.group == .liability ? "-" : ""
        return "\(sign)\(value.toCurrency(compact: true))"
    }
}

#Preview {
    NetWorthCard(
        netWorth: 1250000,
        growthAmount: 45000,
        accounts: [
            Account(name: "Savings Account", institution: "HDFC Bank", balance: 150000),
            Account(name: "Mutual Funds", institution: "Goal Based", balance: 850000),
            Account(name: "Vehicles", institution: "Vehicle Asset", balance: 550000),
            Account(name: "Credit Card", institution: "SBI", balance: -25000)
        ],
        annualGrowthRate: 11,
        monthlySurplus: 25000,
        monthlyEMI: 18000
    )
    .environment(AppStateManager())
    .padding()
}
