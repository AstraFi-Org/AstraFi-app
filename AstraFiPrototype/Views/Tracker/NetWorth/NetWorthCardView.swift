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
    @State private var extraMonthlyInvestment: Double = 1000
    @State private var extraLoanRepayment: Double = 0
    @State private var propertyGrowthRate: Double = 0.07
    @State private var goldGrowthRate: Double = 0.06
    @State private var carDepreciationRate: Double = 0.15
    @State private var inflationRate: Double = 0.06
    @State private var showAddNetWorth = false
    @Environment(\.colorScheme) private var colorScheme

    private let defaultLoanRate = 0.10

    private var normalizedGrowthRate: Double {
        let rate = annualGrowthRate.safeFinite
        if rate > 1 { return rate / 100 }
        if rate > 0 { return rate }
        return 0.08
    }

    private var maxInvestmentStepUp: Double {
        max(1000, min(100000, max(monthlySurplus, 5000)))
    }

    private var scenarioAssumptions: ProjectionScenarioAssumptions {
        ProjectionScenarioAssumptions(
            propertyGrowthRate: propertyGrowthRate,
            goldGrowthRate: goldGrowthRate,
            carDepreciationRate: carDepreciationRate
        )
    }

    private var projectionItems: [NetWorthProjectionItem] {
        accounts.map { account in
            NetWorthProjectionItem(
                account: account,
                fallbackGrowthRate: normalizedGrowthRate,
                defaultLoanRate: defaultLoanRate,
                assumptions: scenarioAssumptions
            )
        }
    }

    private var projectedPoints: [NetWorthProjectionPoint] {
        (0...projectionYears).map { year in
            projectionSummary(for: year).point
        }
    }

    private var finalSummary: NetWorthProjectionSummary {
        projectionSummary(for: projectionYears)
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
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppTheme.auraIndigo)
                }
            }

            ProjectionSelector(selectedYears: $projectionYears)

            NetWorthProjectionChart(points: projectedPoints)
                .frame(height: 210)

            HStack(spacing: 10) {
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
                    title: "Property growth",
                    icon: "house.fill",
                    value: $propertyGrowthRate,
                    range: 0.02...0.12,
                    step: 0.005,
                    tint: AppTheme.auraIndigo
                )

                ScenarioPercentSliderRow(
                    title: "Gold growth",
                    icon: "sparkles",
                    value: $goldGrowthRate,
                    range: 0.02...0.10,
                    step: 0.005,
                    tint: AppTheme.vibrantOrange
                )

                ScenarioPercentSliderRow(
                    title: "Car depreciation",
                    icon: "car.fill",
                    value: $carDepreciationRate,
                    range: 0.05...0.25,
                    step: 0.005,
                    tint: AppTheme.vibrantRed
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
                inflationRate: inflationRate
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

    private func projectionSummary(for years: Int) -> NetWorthProjectionSummary {
        let appreciatingItems = projectionItems.filter { $0.group == .appreciating }
        let depreciatingItems = projectionItems.filter { $0.group == .depreciating }
        let liabilityItems = projectionItems.filter { $0.group == .liability }

        let appreciatingBase = appreciatingItems.reduce(0.0) { $0 + $1.projectedValue(after: years, monthlyPayment: 0) }.safeFinite
        let futureMonthlyInvestment = projectedMonthlyInvestmentValue(for: appreciatingItems, years: years)
        let appreciatingValue = (appreciatingBase + futureMonthlyInvestment).safeFinite
        let depreciatingValue = depreciatingItems.reduce(0.0) { $0 + $1.projectedValue(after: years, monthlyPayment: 0) }.safeFinite
        let outstandingLiabilities = projectedLiabilityValue(for: liabilityItems, years: years)
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

    private func projectedLiabilityValue(for items: [NetWorthProjectionItem], years: Int) -> Double {
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

private struct ProjectionScenarioAssumptions {
    let propertyGrowthRate: Double
    let goldGrowthRate: Double
    let carDepreciationRate: Double
}

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
        defaultLoanRate: Double,
        assumptions: ProjectionScenarioAssumptions
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
            rate = Self.depreciationRate(for: combined, assumptions: assumptions)
        } else {
            group = .appreciating
            rate = Self.growthRate(for: combined, fallback: fallbackGrowthRate, assumptions: assumptions)
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
        fallback: Double,
        assumptions: ProjectionScenarioAssumptions
    ) -> Double {
        if text.contains("mutual") { return max(fallback, 0.12) }
        if text.contains("stock") || text.contains("equity") { return max(fallback, 0.11) }
        if text.contains("property") || text.contains("real estate") { return assumptions.propertyGrowthRate }
        if text.contains("gold") || text.contains("jewellery") { return assumptions.goldGrowthRate }
        if text.contains("deposit") { return 0.065 }
        if text.contains("ppf") { return 0.071 }
        if text.contains("epf") { return 0.081 }
        if text.contains("nps") { return 0.10 }
        if text.contains("savings") || text.contains("current account") { return 0.03 }
        return max(fallback, 0.06)
    }

    private static func depreciationRate(for text: String, assumptions: ProjectionScenarioAssumptions) -> Double {
        if text.contains("electronics") { return 0.25 }
        if text.contains("vehicle") || text.contains("car") || text.contains("bike") { return assumptions.carDepreciationRate }
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

private struct NetWorthProjectionChart: View {
    let points: [NetWorthProjectionPoint]

    var body: some View {
        Chart {
            ForEach(points) { point in
                AreaMark(
                    x: .value("Year", point.year),
                    yStart: .value("Baseline", chartDomain.lowerBound),
                    yEnd: .value("Net Worth", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            AppTheme.auraIndigo.opacity(0.22),
                            AppTheme.auraIndigo.opacity(0.04)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Year", point.year),
                    y: .value("Net Worth", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.auraIndigo, AppTheme.vibrantIndigo],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                PointMark(
                    x: .value("Year", point.year),
                    y: .value("Net Worth", point.value)
                )
                .foregroundStyle(AppTheme.auraIndigo)
                .symbolSize(point.id == points.last?.id ? 80 : 38)
            }

            if let lastPoint = points.last {
                PointMark(
                    x: .value("Year", lastPoint.year),
                    y: .value("Net Worth", lastPoint.value)
                )
                .foregroundStyle(.white)
                .symbolSize(28)
                .annotation(position: .top, alignment: .trailing, spacing: 8) {
                    Text(lastPoint.value.toCurrency(compact: true))
                        .font(.auraCaption(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.auraIndigo)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(AppTheme.auraIndigo.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .chartXScale(domain: 0...max(points.last?.year ?? 1, 1))
        .chartYScale(domain: chartDomain)
        .chartXAxis {
            AxisMarks(values: points.map(\.year)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 4]))
                    .foregroundStyle(AppTheme.auraIndigo.opacity(0.16))
                AxisValueLabel {
                    if let year = value.as(Int.self) {
                        Text(year == 0 ? "Now" : "\(year)Y")
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
        .accessibilityLabel("Projected net worth chart")
    }

    private var chartDomain: ClosedRange<Double> {
        let values = points.map(\.value)
        guard let minValue = values.min(), let maxValue = values.max() else {
            return 0...1
        }

        if minValue == maxValue {
            let padding = Swift.max(abs(maxValue) * 0.18, 1)
            return Swift.min(0, minValue - padding)...(maxValue + padding)
        }

        let padding = Swift.max((maxValue - minValue) * 0.16, abs(maxValue) * 0.04)
        let lowerBound = minValue >= 0 ? 0 : minValue - padding
        return lowerBound...(maxValue + padding)
    }
}

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
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.auraCaption(size: 12, weight: .bold))
                    .foregroundStyle(tint)
                Spacer()
                Text(totalCurrent.toCurrency(compact: true))
                    .font(.auraCaption(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                ForEach(items) { item in
                    ProjectionBreakdownRow(
                        item: item,
                        years: years,
                        monthlyInvestment: allocatedMonthlyInvestment(for: item),
                        monthlyLoanPayment: allocatedPayment(for: item)
                    )
                }
            }
        }
        .padding(12)
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
