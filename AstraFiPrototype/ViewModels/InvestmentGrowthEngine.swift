import Foundation

// MARK: - Timeframe

enum InvestmentGrowthTimeframe: String, CaseIterable, Identifiable, Sendable {
    case oneWeek = "1W"
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"

    var id: String { rawValue }

    var calendarComponent: Calendar.Component {
        switch self {
        case .oneWeek: return .day
        case .oneMonth, .threeMonths, .sixMonths: return .month
        case .oneYear: return .year
        }
    }

    var calendarValue: Int {
        switch self {
        case .oneWeek: return -7
        case .oneMonth: return -1
        case .threeMonths: return -3
        case .sixMonths: return -6
        case .oneYear: return -1
        }
    }

    func startDate(from now: Date = Date()) -> Date {
        let calendar = Calendar.current
        switch self {
        case .oneWeek:
            return calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .oneMonth:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .sixMonths:
            return calendar.date(byAdding: .month, value: -6, to: now) ?? now
        case .oneYear:
            return calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
    }

    /// Short forward projection window keyed to the selected range.
    var projectionTradingDays: Int {
        switch self {
        case .oneWeek: return 3
        case .oneMonth: return 5
        case .threeMonths: return 7
        case .sixMonths: return 10
        case .oneYear: return 14
        }
    }
}

// MARK: - Chart Models

struct GrowthChartPoint: Identifiable, Equatable {
    let id = UUID()
    let index: Int
    let date: Date
    let value: Double
    let isProjected: Bool

    var changeFromPrevious: Double?
    var changePctFromPrevious: Double?
}

struct GrowthHistoricalSnapshot: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let date: Date?
    let value: Double?
}

struct GrowthProjectionEstimate: Equatable {
    let low: Double
    let high: Double
    let currentValue: Double

    var isAvailable: Bool { low.isFinite && high.isFinite && low > 0 && high > 0 }
}

struct InvestmentPeriodReturn: Identifiable, Equatable {
    let id: UUID
    let name: String
    let periodReturnPct: Double?
}

struct GrowthLoadResult: Equatable {
    let actualPoints: [GrowthChartPoint]
    let projectedPoints: [GrowthChartPoint]
    let availableTimeframes: [InvestmentGrowthTimeframe]
    let snapshots: [GrowthHistoricalSnapshot]
    let periodChangePct: Double?
    let projection: GrowthProjectionEstimate?
    let individualReturns: [InvestmentPeriodReturn]
    let hasLimitedData: Bool
    let isUnavailable: Bool

    static let unavailable = GrowthLoadResult(
        actualPoints: [],
        projectedPoints: [],
        availableTimeframes: [],
        snapshots: [],
        periodChangePct: nil,
        projection: nil,
        individualReturns: [],
        hasLimitedData: false,
        isUnavailable: true
    )
}

// MARK: - Engine

@MainActor
final class InvestmentGrowthEngine {
    static let shared = InvestmentGrowthEngine()

    private var priceHistoryCache: [String: [MFHistoryPoint]] = [:]
    private static let historyDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter
    }()

    private init() {}

    func loadGrowthData(
        investments: [AstraInvestment],
        timeframe: InvestmentGrowthTimeframe
    ) async -> GrowthLoadResult {
        guard !investments.isEmpty else { return .unavailable }

        let marketInvestments = investments.filter { supportsHistoricalData($0) }
        guard !marketInvestments.isEmpty else { return .unavailable }

        var histories: [UUID: [(date: Date, price: Double)]] = [:]
        var earliestDates: [Date] = []

        for investment in marketInvestments {
            let history = await fetchPriceHistory(for: investment)
            let parsed = parseHistory(history)
            if !parsed.isEmpty {
                histories[investment.id] = parsed
                if let first = parsed.first?.date {
                    earliestDates.append(first)
                }
            }
        }

        guard !histories.isEmpty else { return .unavailable }

        let now = Date()
        let timeframeStart = timeframe.startDate(from: now)
        let availableTimeframes = InvestmentGrowthTimeframe.allCases.filter { range in
            guard let earliest = earliestDates.min() else { return false }
            return earliest <= range.startDate(from: now).addingTimeInterval(86_400)
        }

        let combinedActual = buildCombinedPortfolioSeries(
            investments: marketInvestments,
            histories: histories,
            from: timeframeStart,
            to: now,
            isProjected: false
        )

        guard combinedActual.count >= 2 else {
            return GrowthLoadResult(
                actualPoints: combinedActual,
                projectedPoints: [],
                availableTimeframes: availableTimeframes,
                snapshots: buildSnapshots(from: combinedActual, timeframe: timeframe),
                periodChangePct: periodChange(for: combinedActual),
                projection: nil,
                individualReturns: individualPeriodReturns(
                    investments: marketInvestments,
                    histories: histories,
                    timeframeStart: timeframeStart,
                    now: now
                ),
                hasLimitedData: true,
                isUnavailable: combinedActual.isEmpty
            )
        }

        let projection = buildProjection(from: combinedActual, timeframe: timeframe)

        return GrowthLoadResult(
            actualPoints: combinedActual,
            projectedPoints: projection.points,
            availableTimeframes: availableTimeframes.isEmpty ? [.oneWeek] : availableTimeframes,
            snapshots: buildSnapshots(from: combinedActual, timeframe: timeframe),
            periodChangePct: periodChange(for: combinedActual),
            projection: projection.estimate,
            individualReturns: individualPeriodReturns(
                investments: marketInvestments,
                histories: histories,
                timeframeStart: timeframeStart,
                now: now
            ),
            hasLimitedData: combinedActual.count < 5,
            isUnavailable: false
        )
    }

    func clearCache() {
        priceHistoryCache.removeAll()
    }

    // MARK: - Historical Fetch

    private func fetchPriceHistory(for investment: AstraInvestment) async -> [MFHistoryPoint] {
        if let schemeCode = investment.schemeCode {
            let cacheKey = "mf-\(schemeCode)"
            if let cached = priceHistoryCache[cacheKey] {
                return cached
            }
            let history = await MFService.shared.fetchHistoricalGraphData(schemeCode: schemeCode, startDate: nil)
            priceHistoryCache[cacheKey] = history
            return history
        }

        if isMarketPricedInvestment(investment.investmentType) {
            let symbol = (investment.symbol?.isEmpty == false ? investment.symbol : nil) ?? investment.investmentName
            guard symbol.isEmpty == false else { return [] }
            let cacheKey = "stock-\(symbol.uppercased())"
            if let cached = priceHistoryCache[cacheKey] {
                return cached
            }
            let start = investment.startDate
            let history = await StockService.shared.fetchStockChartHistory(symbol: symbol, startDate: start)
            priceHistoryCache[cacheKey] = history
            return history
        }

        return []
    }

    private func parseHistory(_ history: [MFHistoryPoint]) -> [(date: Date, price: Double)] {
        history.compactMap { point in
            guard let date = Self.historyDateFormatter.date(from: point.date),
                  let price = Double(point.nav),
                  price.isFinite, price > 0 else { return nil }
            return (date, price)
        }
        .sorted { $0.date < $1.date }
    }

    // MARK: - Portfolio Value Series

    private func buildCombinedPortfolioSeries(
        investments: [AstraInvestment],
        histories: [UUID: [(date: Date, price: Double)]],
        from startDate: Date,
        to endDate: Date,
        isProjected: Bool
    ) -> [GrowthChartPoint] {
        var allDates = Set<Date>()
        for history in histories.values {
            for entry in history where entry.date >= startDate && entry.date <= endDate {
                allDates.insert(entry.date)
            }
        }

        // Always include the latest available trading day on or before endDate.
        if let latest = histories.values.flatMap({ $0 }).map(\.date).filter({ $0 <= endDate }).max() {
            allDates.insert(latest)
        }

        let sortedDates = allDates.sorted()
        guard !sortedDates.isEmpty else { return [] }

        var points: [GrowthChartPoint] = []
        var previousValue: Double?

        for (index, date) in sortedDates.enumerated() {
            var combinedValue = 0.0
            var hasAnyValue = false

            for investment in investments {
                guard let history = histories[investment.id] else { continue }
                if let price = nearestPrice(onOrBefore: date, in: history) {
                    let units = unitsOwned(on: date, investment: investment)
                    if units > 0 {
                        combinedValue += units * price
                        hasAnyValue = true
                    }
                }
            }

            guard hasAnyValue, combinedValue.isFinite, combinedValue > 0 else { continue }

            let change = previousValue.map { combinedValue - $0 }
            let changePct = previousValue.flatMap { prev in
                prev > 0 ? ((combinedValue - prev) / prev) * 100 : nil
            }

            points.append(GrowthChartPoint(
                index: index,
                date: date,
                value: combinedValue,
                isProjected: isProjected,
                changeFromPrevious: change,
                changePctFromPrevious: changePct
            ))
            previousValue = combinedValue
        }

        return reindex(points)
    }

    private func reindex(_ points: [GrowthChartPoint]) -> [GrowthChartPoint] {
        points.enumerated().map { offset, point in
            GrowthChartPoint(
                index: offset,
                date: point.date,
                value: point.value,
                isProjected: point.isProjected,
                changeFromPrevious: point.changeFromPrevious,
                changePctFromPrevious: point.changePctFromPrevious
            )
        }
    }

    private func nearestPrice(onOrBefore date: Date, in history: [(date: Date, price: Double)]) -> Double? {
        history.last(where: { $0.date <= date })?.price
    }

    func unitsOwned(on date: Date, investment: AstraInvestment) -> Double {
        if !investment.installments.isEmpty {
            let units = investment.installments
                .filter { $0.date <= date }
                .reduce(0.0) { result, tx in
                    tx.type == .buy ? result + tx.units : result - tx.units
                }
            if units > 0 { return units }
        }

        if date >= investment.startDate {
            if let units = investment.units ?? investment.quantity, units > 0 {
                return units
            }
            let entryPrice = investment.purchaseNAV ?? investment.lastNAV ?? investment.livePrice
            if let entryPrice, entryPrice > 0 {
                return investment.investmentAmount / entryPrice
            }
        }
        return 0
    }

    // MARK: - Projection

    private func buildProjection(
        from actual: [GrowthChartPoint],
        timeframe: InvestmentGrowthTimeframe
    ) -> (points: [GrowthChartPoint], estimate: GrowthProjectionEstimate?) {
        guard actual.count >= 3,
              let lastActual = actual.last,
              let firstActual = actual.first else {
            return ([], nil)
        }

        let daySpan = max(lastActual.date.timeIntervalSince(firstActual.date) / 86_400, 1)
        let totalChange = lastActual.value - firstActual.value
        let dailyTrend = totalChange / daySpan

        let values = actual.map(\.value)
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(values.count)
        let dailyVolatility = sqrt(variance) / max(daySpan, 1)

        var projected: [GrowthChartPoint] = []
        var previous = lastActual.value
        let calendar = Calendar.current

        for step in 1...timeframe.projectionTradingDays {
            guard let futureDate = calendar.date(byAdding: .day, value: step, to: lastActual.date) else { break }
            let projectedValue = lastActual.value + dailyTrend * Double(step)
            let change = projectedValue - previous
            let changePct = previous > 0 ? (change / previous) * 100 : nil

            projected.append(GrowthChartPoint(
                index: actual.count + step - 1,
                date: futureDate,
                value: max(0, projectedValue),
                isProjected: true,
                changeFromPrevious: change,
                changePctFromPrevious: changePct
            ))
            previous = projectedValue
        }

        let band = dailyVolatility * Double(timeframe.projectionTradingDays)
        let estimate = GrowthProjectionEstimate(
            low: max(0, lastActual.value + dailyTrend * Double(timeframe.projectionTradingDays) - band),
            high: lastActual.value + dailyTrend * Double(timeframe.projectionTradingDays) + band,
            currentValue: lastActual.value
        )

        let indexedProjected = projected.enumerated().map { offset, point in
            GrowthChartPoint(
                index: (actual.last?.index ?? 0) + offset + 1,
                date: point.date,
                value: point.value,
                isProjected: true,
                changeFromPrevious: point.changeFromPrevious,
                changePctFromPrevious: point.changePctFromPrevious
            )
        }

        return (indexedProjected, estimate.isAvailable ? estimate : nil)
    }

    // MARK: - Insights

    private func periodChange(for points: [GrowthChartPoint]) -> Double? {
        guard let first = points.first, let last = points.last, first.value > 0 else { return nil }
        return ((last.value - first.value) / first.value) * 100
    }

    private func buildSnapshots(
        from points: [GrowthChartPoint],
        timeframe: InvestmentGrowthTimeframe
    ) -> [GrowthHistoricalSnapshot] {
        guard let last = points.last else { return [] }

        let calendar = Calendar.current
        let now = last.date

        var targets: [(String, Date)] = [
            ("Today", now)
        ]

        if let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: now) {
            targets.append(("2 Days Ago", twoDaysAgo))
        }
        if timeframe == .oneWeek, let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) {
            targets.append(("1 Week Ago", weekAgo))
        }

        let periodLabel = "\(timeframe.rawValue) Change"
        if let first = points.first {
            targets.append((periodLabel, first.date))
        }

        return targets.map { label, date in
            if label == periodLabel {
                let pct = periodChange(for: points)
                return GrowthHistoricalSnapshot(label: label, date: date, value: pct)
            }
            let value = nearestPointValue(onOrBefore: date, in: points)?.value
            return GrowthHistoricalSnapshot(label: label, date: date, value: value)
        }
    }

    private func nearestPointValue(onOrBefore date: Date, in points: [GrowthChartPoint]) -> GrowthChartPoint? {
        points.last(where: { $0.date <= date })
    }

    private func individualPeriodReturns(
        investments: [AstraInvestment],
        histories: [UUID: [(date: Date, price: Double)]],
        timeframeStart: Date,
        now: Date
    ) -> [InvestmentPeriodReturn] {
        investments.map { investment in
            guard let history = histories[investment.id] else {
                return InvestmentPeriodReturn(id: investment.id, name: investment.investmentName, periodReturnPct: nil)
            }

            let series = buildCombinedPortfolioSeries(
                investments: [investment],
                histories: [investment.id: history],
                from: timeframeStart,
                to: now,
                isProjected: false
            )
            return InvestmentPeriodReturn(
                id: investment.id,
                name: investment.investmentName,
                periodReturnPct: periodChange(for: series)
            )
        }
    }

    // MARK: - Helpers

    func supportsHistoricalData(_ investment: AstraInvestment) -> Bool {
        if investment.schemeCode != nil { return true }
        if isMarketPricedInvestment(investment.investmentType) {
            return (investment.symbol ?? investment.investmentName).isEmpty == false
        }
        return false
    }

    private func isMarketPricedInvestment(_ type: AstraInvestmentType) -> Bool {
        switch type {
        case .stocks, .goldETF, .cryptocurrency:
            return true
        default:
            return false
        }
    }
}
