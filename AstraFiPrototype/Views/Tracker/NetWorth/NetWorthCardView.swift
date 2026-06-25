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
    
    // Viewport zoom state
    @State private var isZoomedOut = false

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

    /// Back-project ~3 years of historical net worth using CAGR so the chart
    /// has a meaningful "past" section even without persisted snapshots.
    private var historicalChartPoints: [NetWorthChartPoint] {
        let historyYears = 3
        let rate = max(normalizedGrowthRate, 0.01)
        return (0...historyYears).map { yearsAgo in
            let offset = -(historyYears - yearsAgo) // -3, -2, -1, 0
            let value = (netWorth / pow(1 + rate, Double(historyYears - yearsAgo))).safeFinite
            return NetWorthChartPoint(year: offset, value: value, series: .baseline)
        }
    }

    // MARK: - Baseline projection (continue as-is, no slider changes)

    private var baselineChartPoints: [NetWorthChartPoint] {
        (0...projectionYears).map { year in
            let summary = baselineProjectionSummary(for: year)
            return NetWorthChartPoint(year: year, value: summary.nominalNetWorth, series: .baseline)
        }
    }

    // MARK: - Adjusted projection (reactive to sliders)

    private var adjustedChartPoints: [NetWorthChartPoint] {
        (0...projectionYears).map { year in
            let summary = adjustedProjectionSummary(for: year)
            return NetWorthChartPoint(year: year, value: summary.nominalNetWorth, series: .adjusted)
        }
    }

    /// Combined blue points (history -3 to 0 + baseline 0 to N, avoiding duplicate Year 0)
    private var bluePoints: [NetWorthChartPoint] {
        let history = historicalChartPoints.filter { $0.year < 0 }
        return history + baselineChartPoints
    }

    /// All points fed to the chart.
    private var allChartPoints: [NetWorthChartPoint] {
        var points = bluePoints
        if hasSliderChanges {
            points += adjustedChartPoints
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

    // MARK: - Viewport Bounds calculations

    private var baselineMax: Double {
        let values = bluePoints.map(\.value)
        guard let maxValue = values.max(), let minValue = values.min() else { return 100_000 }
        let padding = Swift.max((maxValue - minValue) * 0.16, abs(maxValue) * 0.04)
        return maxValue + padding
    }

    private var adjustedMax: Double {
        let values = adjustedChartPoints.map(\.value)
        guard let maxValue = values.max(), let minValue = values.min() else { return 100_000 }
        let padding = Swift.max((maxValue - minValue) * 0.16, abs(maxValue) * 0.04)
        return maxValue + padding
    }

    private var isProjectionTooBig: Bool {
        hasSliderChanges && adjustedMax > baselineMax
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

            // Chart area with context-aware Zoom Out button
            ZStack(alignment: .topTrailing) {
                NetWorthProjectionChart(
                    points: allChartPoints,
                    projectionYears: projectionYears,
                    showAdjusted: hasSliderChanges,
                    isZoomedOut: isZoomedOut,
                    baselineMax: baselineMax,
                    adjustedMax: adjustedMax
                )
                .frame(height: 250)

                if isProjectionTooBig {
                    Button(action: { isZoomedOut.toggle() }) {
                        HStack(spacing: 4) {
                            Image(systemName: isZoomedOut ? "minus.magnifyingglass" : "plus.magnifyingglass")
                            Text(isZoomedOut ? "Reset Zoom" : "Zoom Out to Fit")
                        }
                        .font(.auraCaption(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.auraIndigo)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(colorScheme == .dark ? Color.black.opacity(0.6) : Color.white.opacity(0.8))
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 3)
                    }
                    .padding(8)
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: isProjectionTooBig)

            // Chart legend
            HStack(spacing: 20) {
                ChartLegendDot(color: NetWorthProjectionChart.baselineColor, label: "Current Plan")
                if hasSliderChanges {
                    ChartLegendDot(color: NetWorthProjectionChart.adjustedColor, label: "After Changes")
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
                Text("Scenario Controls")
                    .font(.auraBody(size: 16, weight: .semibold))

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
            }
            .padding(14)
            .background(AppTheme.elevatedCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

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
        .auraCardStyle(radius: 34)
        .sheet(isPresented: $showAddNetWorth) {
            AddNetWorthView()
        }
    }

    // MARK: - Baseline projection (no slider changes, default assumptions)

    private func baselineProjectionSummary(for years: Int) -> NetWorthProjectionSummary {
        let appreciatingItems = projectionItems.filter { $0.group == .appreciating }
        let depreciatingItems = projectionItems.filter { $0.group == .depreciating }
        let liabilityItems = projectionItems.filter { $0.group == .liability }

        let appreciatingBase = appreciatingItems.reduce(0.0) { $0 + $1.projectedValue(after: years, monthlyPayment: 0) }.safeFinite
        let depreciatingValue = depreciatingItems.reduce(0.0) { $0 + $1.projectedValue(after: years, monthlyPayment: 0) }.safeFinite
        let outstandingLiabilities = baselineLiabilityValue(for: liabilityItems, years: years)
        let nominal = (appreciatingBase + depreciatingValue - outstandingLiabilities).safeFinite
        let real = years > 0 ? (nominal / pow(1 + defaultInflationRate, Double(years))).safeFinite : nominal

        return NetWorthProjectionSummary(
            year: years,
            appreciatingAssets: appreciatingBase,
            depreciatingAssets: depreciatingValue,
            liabilities: outstandingLiabilities,
            nominalNetWorth: nominal,
            realPurchasingPower: real
        )
    }

    private func baselineLiabilityValue(for items: [NetWorthProjectionItem], years: Int) -> Double {
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
        let appreciatingItems = projectionItems.filter { $0.group == .appreciating }
        let depreciatingItems = projectionItems.filter { $0.group == .depreciating }
        let liabilityItems = projectionItems.filter { $0.group == .liability }

        let appreciatingBase = appreciatingItems.reduce(0.0) { $0 + $1.projectedValue(after: years, monthlyPayment: 0) }.safeFinite
        let futureMonthlyInvestment = projectedMonthlyInvestmentValue(for: appreciatingItems, years: years)
        let appreciatingValue = (appreciatingBase + futureMonthlyInvestment).safeFinite
        let depreciatingValue = depreciatingItems.reduce(0.0) { $0 + $1.projectedValue(after: years, monthlyPayment: 0) }.safeFinite
        let outstandingLiabilities = adjustedLiabilityValue(for: liabilityItems, years: years)
        let nominal = (appreciatingValue + depreciatingValue - outstandingLiabilities).safeFinite
        let real = years > 0 ? (nominal / pow(1 + inflationRate, Double(years))).safeFinite : nominal

        return NetWorthProjectionSummary(
            year: years,
            appreciatingAssets: appreciatingValue,
            depreciatingAssets: depreciatingValue,
            liabilities: outstandingLiabilities,
            nominalNetWorth: nominal,
            realPurchasingPower: real
        )
    }

    private func projectedMonthlyInvestmentValue(for items: [NetWorthProjectionItem], years: Int) -> Double {
        guard years > 0, extraMonthlyInvestment > 0 else { return 0 }
        let weightedRate = weightedAnnualRate(for: items)
        let monthlyRate = weightedRate / 12
        let months = years * 12

        guard monthlyRate != 0 else {
            return extraMonthlyInvestment * Double(months)
        }

        return (extraMonthlyInvestment * ((pow(1 + monthlyRate, Double(months)) - 1) / monthlyRate)).safeFinite
    }

    private func weightedAnnualRate(for items: [NetWorthProjectionItem]) -> Double {
        let total = items.reduce(0.0) { $0 + max(0, $1.currentValue) }.safeFinite
        guard total > 0 else { return normalizedGrowthRate }
        return items.reduce(0.0) { partial, item in
            partial + (item.rate * (max(0, item.currentValue) / total))
        }.safeFinite
    }

    private func adjustedLiabilityValue(for items: [NetWorthProjectionItem], years: Int) -> Double {
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
}

private struct NetWorthChartPoint: Identifiable {
    let id = UUID()
    let year: Int
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

    func projectedValue(after years: Int, monthlyPayment: Double) -> Double {
        guard years > 0 else { return abs(currentValue).safeFinite }

        switch group {
        case .appreciating:
            return (max(0, currentValue) * pow(1 + rate, Double(years))).safeFinite
        case .depreciating:
            return (max(0, currentValue) * pow(max(0, 1 - rate), Double(years))).safeFinite
        case .liability:
            return projectedOutstandingLoan(after: years, monthlyPayment: monthlyPayment)
        }
    }

    private func projectedOutstandingLoan(after years: Int, monthlyPayment: Double) -> Double {
        var outstanding = abs(currentValue).safeFinite
        let monthlyRate = rate / 12
        let months = years * 12

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
    let isZoomedOut: Bool
    let baselineMax: Double
    let adjustedMax: Double

    private var baselinePoints: [NetWorthChartPoint] {
        points.filter { $0.series == .baseline }
    }

    private var adjustedPoints: [NetWorthChartPoint] {
        points.filter { $0.series == .adjusted }
    }

    // Exposed theme colors
    static let baselineColor = AppTheme.auraIndigo  // Blue line
    static let adjustedColor = AppTheme.auraGreen    // Green line

    var body: some View {
        Chart {
            // ── 1. Baseline Area (Subtle Blue shading)
            ForEach(baselinePoints) { point in
                AreaMark(
                    x: .value("Year", point.year),
                    yStart: .value("Baseline", chartDomain.lowerBound),
                    yEnd: .value("Net Worth", point.value)
                )
                .foregroundStyle(by: .value("Series", "baselineArea"))
                .interpolationMethod(.catmullRom)
            }

            // ── 2. Baseline Line (Solid Blue)
            ForEach(baselinePoints) { point in
                LineMark(
                    x: .value("Year", point.year),
                    y: .value("Net Worth", point.value)
                )
                .foregroundStyle(by: .value("Series", "baseline"))
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            }

            // ── 3. Adjusted Area (Subtle Green shading) - only if changes exist
            if showAdjusted {
                ForEach(adjustedPoints) { point in
                    AreaMark(
                        x: .value("Year", point.year),
                        yStart: .value("Baseline", chartDomain.lowerBound),
                        yEnd: .value("Net Worth", point.value)
                    )
                    .foregroundStyle(by: .value("Series", "adjustedArea"))
                    .interpolationMethod(.catmullRom)
                }

                // ── 4. Adjusted Line (Solid Green)
                ForEach(adjustedPoints) { point in
                    LineMark(
                        x: .value("Year", point.year),
                        y: .value("Net Worth", point.value)
                    )
                    .foregroundStyle(by: .value("Series", "adjusted"))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                }
            }

            // ── 5. Point Marks for Baseline
            ForEach(baselinePoints) { point in
                if point.year == -3 || point.year == 0 || (!showAdjusted && point.year == projectionYears) {
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
                    if point.year == 0 || point.year == projectionYears {
                        PointMark(
                            x: .value("Year", point.year),
                            y: .value("Net Worth", point.value)
                        )
                        .foregroundStyle(by: .value("Series", "adjusted"))
                        .symbolSize(point.year == 0 ? 70 : 38)
                    }
                }
            }

            // ── 7. Baseline endpoint annotation (only if adjusted is NOT shown)
            if !showAdjusted, let lastBaseline = baselinePoints.last {
                PointMark(
                    x: .value("Year", lastBaseline.year),
                    y: .value("Net Worth", lastBaseline.value)
                )
                .foregroundStyle(.white)
                .symbolSize(24)
                .annotation(position: .top, alignment: .trailing, spacing: 6) {
                    Text(lastBaseline.value.toCurrency(compact: true))
                        .font(.auraCaption(size: 9, weight: .bold))
                        .foregroundStyle(Self.baselineColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Self.baselineColor.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            // ── 8. Adjusted endpoint annotation (only if adjusted IS shown)
            if showAdjusted, let lastAdjusted = adjustedPoints.last {
                PointMark(
                    x: .value("Year", lastAdjusted.year),
                    y: .value("Net Worth", lastAdjusted.value)
                )
                .foregroundStyle(.white)
                .symbolSize(28)
                .annotation(position: .top, alignment: .trailing, spacing: 6) {
                    Text(lastAdjusted.value.toCurrency(compact: true))
                        .font(.auraCaption(size: 9, weight: .bold))
                        .foregroundStyle(Self.adjustedColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Self.adjustedColor.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
        .chartXScale(domain: -3...projectionYears)
        .chartYScale(domain: chartDomain)
        .chartXAxis {
            AxisMarks(values: xAxisValues) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 4]))
                    .foregroundStyle(AppTheme.auraIndigo.opacity(0.16))
                AxisValueLabel {
                    if let year = value.as(Int.self) {
                        Text(xAxisLabel(for: year))
                            .font(.auraCaption(size: 10))
                            .foregroundStyle(.secondary.opacity(0.8))
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(AppTheme.auraIndigo.opacity(0.08))
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(amount.toCurrency(compact: true))
                            .font(.auraCaption(size: 10))
                            .foregroundStyle(.secondary.opacity(0.8))
                    }
                }
            }
        }
        .chartPlotStyle { plotArea in
            plotArea
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppTheme.auraIndigo.opacity(0.025))
                )
        }
        .chartForegroundStyleScale([
            "baseline": AnyShapeStyle(Self.baselineColor),
            "adjusted": AnyShapeStyle(Self.adjustedColor),
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
        .accessibilityLabel("Net worth baseline and projection chart")
    }

    private var xAxisValues: [Int] {
        let allYears = Set(points.map(\.year)).sorted()
        return allYears
    }

    private func xAxisLabel(for year: Int) -> String {
        if year == 0 { return "Now" }
        if year < 0 { return "\(abs(year))Y ago" }
        return "\(year)Y"
    }

    private var chartDomain: ClosedRange<Double> {
        let stableMin = points.filter { $0.series == .baseline }.map(\.value).min() ?? 0.0
        let stableMaxVal = baselineMax
        let adjustedMaxVal = adjustedMax

        let targetMax = (showAdjusted && isZoomedOut && adjustedMaxVal > stableMaxVal) ? max(stableMaxVal, adjustedMaxVal) : stableMaxVal
        let targetMin = stableMin >= 0 ? 0.0 : stableMin
        return targetMin...targetMax
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
        let baseValue = item.projectedValue(after: years, monthlyPayment: monthlyLoanPayment)
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
