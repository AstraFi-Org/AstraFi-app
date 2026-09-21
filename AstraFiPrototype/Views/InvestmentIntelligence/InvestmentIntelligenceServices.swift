import Foundation

private extension CompanyFinancialSnapshot {
    var hasAnyProviderValue: Bool {
        [
            marketCap, peRatio, weekHigh52, weekLow52, dividendYield, revenue,
            netProfit, eps, cashFlow, operatingMargin, profitMargin, roe, roa,
            debtRatio, quarterlyGrowth, historicalGrowth
        ].contains { $0 != nil }
    }
}

actor CacheManager {
    static let shared = CacheManager()

    private var values: [String: (date: Date, data: Data)] = [:]
    private let ttl: TimeInterval = 10 * 60

    func cachedData(for key: String) -> Data? {
        guard let entry = values[key], Date().timeIntervalSince(entry.date) < ttl else {
            values[key] = nil
            return nil
        }
        return entry.data
    }

    func store(_ data: Data, for key: String) {
        values[key] = (Date(), data)
    }
}

final class FinnhubService {
    static let shared = FinnhubService()

    private let baseURL = "https://finnhub.io/api/v1"
    private var apiKey: String { Secrets.finnhubApiKey }
    private let cache: CacheManager

    init(cache: CacheManager = .shared) {
        self.cache = cache
    }

    func companyProfile(symbol: String) async throws -> FinnhubCompanyProfile {
        try await request(path: "stock/profile2", query: ["symbol": finnhubSymbol(symbol)])
    }

    func quote(symbol: String) async throws -> FinnhubQuoteResponse {
        let mappedSymbol = finnhubSymbol(symbol)
        print("Finnhub Symbol:", mappedSymbol)
        let response: FinnhubQuoteResponse = try await request(path: "quote", query: ["symbol": mappedSymbol])
        print("Quote Response:", response)
        return response
    }

    func metrics(symbol: String) async throws -> FinnhubMetricResponse {
        try await request(path: "stock/metric", query: ["symbol": finnhubSymbol(symbol), "metric": "all"])
    }

    func competitors(symbol: String) async throws -> [String] {
        try await request(path: "stock/peers", query: ["symbol": finnhubSymbol(symbol)])
    }

    func recommendationTrends(symbol: String) async throws -> [FinnhubRecommendationResponse] {
        try await request(path: "stock/recommendation", query: ["symbol": finnhubSymbol(symbol)])
    }

    func companyNews(symbol: String) async throws -> [FinnhubNewsResponse] {
        let calendar = Calendar.current
        let to = Date()
        let from = calendar.date(byAdding: .day, value: -14, to: to) ?? to
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return try await request(
            path: "company-news",
            query: [
                "symbol": finnhubSymbol(symbol),
                "from": formatter.string(from: from),
                "to": formatter.string(from: to)
            ]
        )
    }

    private func request<T: Decodable>(path: String, query: [String: String]) async throws -> T {
        guard !apiKey.isEmpty else { throw URLError(.userAuthenticationRequired) }

        var components = URLComponents(string: "\(baseURL)/\(path)")
        components?.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) } + [URLQueryItem(name: "token", value: apiKey)]
        guard let url = components?.url else { throw URLError(.badURL) }

        let cacheKey = url.absoluteString
        if let cached = await cache.cachedData(for: cacheKey) {
            return try JSONDecoder().decode(T.self, from: cached)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 200
        guard statusCode < 400 else {
            throw URLError(.badServerResponse)
        }
        await cache.store(data, for: cacheKey)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func finnhubSymbol(_ symbol: String) -> String {
        symbol.uppercased()
    }
}

final class AMFIService {
    static let shared = AMFIService()

    private let service: MFService

    init(service: MFService = .shared) {
        self.service = service
    }

    func schemes() async -> [MFScheme] {
        await service.fetchMFData()
        return await MainActor.run { service.allSchemes }
    }

    func searchSchemes(query: String) async -> [MFScheme] {
        await service.fetchMFData()
        return await MainActor.run { service.searchSchemes(query: query) }
    }

    func schemesByCategory(_ category: String? = nil, limit: Int = 100) async -> [MFScheme] {
        await service.fetchMFData()
        return await MainActor.run { service.schemesByCategory(category, limit: limit) }
    }

    func scheme(code: String) async -> MFScheme? {
        await service.fetchMFData()
        return await MainActor.run { service.getScheme(by: code) }
    }

    func navHistory(schemeCode: String) async -> [InvestmentChartPoint] {
        let start = Calendar.current.date(byAdding: .year, value: -1, to: Date())
        let history = await service.fetchHistoricalGraphData(schemeCode: schemeCode, startDate: start)
        return history.compactMap { point in
            guard let nav = Double(point.nav), let date = Self.navDateFormatter.date(from: point.date) else { return nil }
            return InvestmentChartPoint(date: date, value: nav)
        }
    }

    private static let navDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter
    }()
}

final class CompanyProfileService {
    private let finnhub: FinnhubService
    private let fmpService: FMPService
    private let intelligenceStore: CompanyIntelligenceStore

    init(
        finnhub: FinnhubService = .shared,
        fmpService: FMPService = .shared,
        intelligenceStore: CompanyIntelligenceStore = .shared
    ) {
        self.finnhub = finnhub
        self.fmpService = fmpService
        self.intelligenceStore = intelligenceStore
    }

    func fetch(symbol: String) async -> CompanyProfileSnapshot? {
        let marketContext = SecurityMarketContext.forSymbol(symbol)

        // 1. Check verified knowledge repository first
        if let verified = intelligenceStore.profile(for: symbol) {
            // Check if remote provider has a logo
            var logoURL: URL? = nil
            if let remote = try? await finnhub.companyProfile(symbol: symbol), let logo = remote.logo {
                logoURL = URL(string: logo)
            }

            return CompanyProfileSnapshot(
                name: verified.companyName,
                ticker: verified.symbol,
                sector: verified.sector,
                industry: verified.industry,
                country: verified.country,
                exchange: verified.exchange,
                logoURL: logoURL,
                description: verified.whatItDoes,
                whatItDoes: verified.whatItDoes,
                operatingSegments: verified.operatingSegments,
                productsAndPlatforms: verified.productsAndPlatforms,
                revenueModel: verified.revenueModel,
                targetMarkets: verified.targetMarkets,
                secularGrowthDrivers: verified.secularGrowthDrivers,
                keyBusinessRisks: verified.keyBusinessRisks,
                keyMetricsToMonitor: verified.keyMetricsToMonitor,
                isVerifiedProfile: true
            )
        }

        // 2. Try FMP remote profile
        if let profile = try? await fmpService.profile(symbol: symbol),
           hasFMPProfileData(profile) {
            return CompanyProfileSnapshot(
                name: profile.companyName ?? symbol,
                ticker: profile.symbol ?? symbol,
                sector: profile.sector ?? "Market",
                industry: profile.industry ?? profile.sector ?? "General Equities",
                country: marketContext.country,
                exchange: marketContext.exchange,
                logoURL: nil,
                description: profile.description ?? "Operational profile not provided by data provider.",
                whatItDoes: profile.description,
                isVerifiedProfile: false
            )
        }

        // 3. Try Finnhub remote profile
        do {
            let profile = try await finnhub.companyProfile(symbol: symbol)
            let hasProfileData = [
                profile.name,
                profile.ticker,
                profile.finnhubIndustry,
                profile.country,
                profile.exchange,
                profile.logo
            ].contains { value in
                guard let value else { return false }
                return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            guard hasProfileData else { return nil }

            let industry = profile.finnhubIndustry ?? "General Equities"
            let country = profile.country ?? marketContext.country
            let exchange = profile.exchange ?? marketContext.exchange
            let desc = "\(profile.name ?? symbol) operates in \(industry). Review revenue, operating margins, balance sheet debt, and competitor landscape before making investment decisions."

            return CompanyProfileSnapshot(
                name: profile.name ?? symbol,
                ticker: profile.ticker ?? symbol,
                sector: industry,
                industry: industry,
                country: country,
                exchange: exchange,
                logoURL: URL(string: profile.logo ?? ""),
                description: desc,
                whatItDoes: desc,
                isVerifiedProfile: false
            )
        } catch {
            return nil
        }
    }

    private func hasFMPProfileData(_ profile: FMPProfile) -> Bool {
        [
            profile.companyName,
            profile.symbol,
            profile.sector,
            profile.industry,
            profile.description
        ].contains { value in
            guard let value else { return false }
            return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}

final class FinancialService {
    private let finnhub: FinnhubService
    private let fmpService: FMPService

    init(finnhub: FinnhubService = .shared, fmpService: FMPService = .shared) {
        self.finnhub = finnhub
        self.fmpService = fmpService
    }

    func fetch(symbol: String) async -> CompanyFinancialSnapshot? {
        async let fmpProfile = try? fmpService.profile(symbol: symbol)
        async let fmpMetrics = try? fmpService.keyMetrics(symbol: symbol)
        async let fmpRatios = try? fmpService.ratios(symbol: symbol)
        async let fmpIncome = try? fmpService.incomeStatements(symbol: symbol)

        let profile = await fmpProfile
        let metrics = await fmpMetrics
        let ratios = await fmpRatios
        let income = (await fmpIncome) ?? []
        let revenueGrowth = growthRate(
            latest: income.first?.revenue,
            previous: income.dropFirst().first?.revenue
        )
        let profitGrowth = growthRate(
            latest: income.first?.netIncome,
            previous: income.dropFirst().first?.netIncome
        )
        let fmpSnapshot = CompanyFinancialSnapshot(
            marketCap: normalizedMarketCap(profile?.mktCap),
            peRatio: metrics?.peRatioTTM ?? ratios?.priceEarningsRatioTTM,
            weekHigh52: nil,
            weekLow52: nil,
            dividendYield: nil,
            revenue: revenueGrowth,
            netProfit: profitGrowth ?? ratios?.netProfitMarginTTM,
            eps: nil,
            cashFlow: nil,
            operatingMargin: nil,
            profitMargin: ratios?.netProfitMarginTTM,
            roe: metrics?.roeTTM ?? ratios?.returnOnEquityTTM,
            roa: nil,
            debtRatio: metrics?.debtToEquityTTM ?? ratios?.debtEquityRatioTTM,
            quarterlyGrowth: nil,
            historicalGrowth: revenueGrowth
        )
        if fmpSnapshot.hasAnyProviderValue {
            return fmpSnapshot
        }

        do {
            let metrics = try await finnhub.metrics(symbol: symbol).metric
            let liveSnapshot = CompanyFinancialSnapshot(
                marketCap: metrics.marketCapitalization,
                peRatio: metrics.peNormalizedAnnual ?? metrics.peBasicExclExtraTTM,
                weekHigh52: metrics.weekHigh52,
                weekLow52: metrics.weekLow52,
                dividendYield: metrics.dividendYieldIndicatedAnnual,
                revenue: metrics.revenueGrowthTTMYoy.map { $0 },
                netProfit: metrics.netProfitMarginTTM,
                eps: metrics.epsBasicExclExtraItemsTTM,
                cashFlow: metrics.freeCashFlowPerShareTTM,
                operatingMargin: metrics.operatingMarginTTM,
                profitMargin: metrics.netProfitMarginTTM,
                roe: metrics.roeTTM,
                roa: metrics.roaTTM,
                debtRatio: metrics.totalDebtToEquityQuarterly,
                quarterlyGrowth: metrics.revenueGrowthQuarterlyYoy,
                historicalGrowth: metrics.revenueGrowthTTMYoy
            )
            return liveSnapshot.hasAnyProviderValue ? liveSnapshot : nil
        } catch {
            return nil
        }
    }

    private func growthRate(latest: Double?, previous: Double?) -> Double? {
        guard let latest, let previous, previous != 0 else { return nil }
        return ((latest - previous) / abs(previous)) * 100
    }

    private func normalizedMarketCap(_ marketCap: Double?) -> Double? {
        guard let marketCap else { return nil }
        return marketCap
    }
}

final class NewsService {
    private let finnhub: FinnhubService

    init(finnhub: FinnhubService = .shared) {
        self.finnhub = finnhub
    }

    func fetch(symbol: String) async -> [InvestmentNewsItem] {
        do {
            return try await finnhub.companyNews(symbol: symbol)
                .prefix(8)
                .map {
                    InvestmentNewsItem(
                        headline: $0.headline ?? "Market update",
                        summary: $0.summary ?? "",
                        source: $0.source ?? "Finnhub",
                        publishedAt: Date(timeIntervalSince1970: TimeInterval($0.datetime ?? 0)),
                        url: URL(string: $0.url ?? "")
                    )
                }
        } catch {
            return []
        }
    }
}

final class CompetitorService {
    private let finnhub: FinnhubService
    private let stockService: StockService

    init(finnhub: FinnhubService = .shared, stockService: StockService = .shared) {
        self.finnhub = finnhub
        self.stockService = stockService
    }

    func fetch(symbol: String) async -> [InvestmentCompetitor] {
        let remotePeers = (try? await finnhub.competitors(symbol: symbol)) ?? []
        let peers = await normalizedPeers(remotePeers, symbol: symbol)

        return await withTaskGroup(of: InvestmentCompetitor?.self) { group in
            for peer in peers.prefix(8) {
                group.addTask {
                    let quote = await self.stockService.fetchPrice(symbol: peer)
                    let profile = try? await self.finnhub.companyProfile(symbol: peer)
                    return InvestmentCompetitor(
                        symbol: peer,
                        name: profile?.name ?? quote?.name ?? Self.symbolName(peer),
                        currentPrice: quote?.currentPrice,
                        marketCap: profile?.marketCapitalization,
                        dailyChange: quote?.priceChangePercentage
                    )
                }
            }

            var results: [InvestmentCompetitor] = []
            for await item in group {
                if let item { results.append(item) }
            }
            return results.sorted { $0.name < $1.name }
        }
    }

    private func normalizedPeers(_ remotePeers: [String], symbol: String) async -> [String] {
        let normalizedSymbol = Self.normalizeSymbol(symbol)
        var seen = Set<String>()
        var peers: [String] = []

        for peer in remotePeers.map(Self.normalizeSymbol) {
            guard !peer.isEmpty, peer != normalizedSymbol, seen.insert(peer).inserted else { continue }
            peers.append(peer)
        }

        if peers.isEmpty,
           let profile = try? await finnhub.companyProfile(symbol: normalizedSymbol),
           let industry = profile.finnhubIndustry,
           !industry.isEmpty {
            let matches = await stockService.searchStocks(query: industry)
            for match in matches.map(\.symbol).map(Self.normalizeSymbol) {
                guard !match.isEmpty, match != normalizedSymbol, seen.insert(match).inserted else { continue }
                peers.append(match)
            }
        }

        return peers
    }

    private nonisolated static func normalizeSymbol(_ symbol: String) -> String {
        let upper = symbol.uppercased()
        if upper.hasPrefix("NSE:") { return "\(upper.dropFirst(4)).NS" }
        if upper.hasPrefix("BSE:") { return "\(upper.dropFirst(4)).BO" }
        return upper
    }

    private nonisolated static func symbolName(_ symbol: String) -> String {
        symbol.replacingOccurrences(of: ".NS", with: "").replacingOccurrences(of: ".BO", with: "")
    }
}

final class RecommendationService {
    private let finnhub: FinnhubService

    init(finnhub: FinnhubService = .shared) {
        self.finnhub = finnhub
    }

    func fetch(symbol: String) async -> [RecommendationTrend] {
        do {
            guard let latest = try await finnhub.recommendationTrends(symbol: symbol).first else { return [] }
            let sb = latest.strongBuy ?? 0
            let b = latest.buy ?? 0
            let h = latest.hold ?? 0
            let s = latest.sell ?? 0
            let ss = latest.strongSell ?? 0
            let total = sb + b + h + s + ss
            let pct: (Int) -> Double? = { count in
                total > 0 ? (Double(count) / Double(total)) * 100 : nil
            }
            return [
                RecommendationTrend(label: "Strong Buy", count: sb, percentage: pct(sb)),
                RecommendationTrend(label: "Buy", count: b, percentage: pct(b)),
                RecommendationTrend(label: "Hold", count: h, percentage: pct(h)),
                RecommendationTrend(label: "Sell", count: s, percentage: pct(s)),
                RecommendationTrend(label: "Strong Sell", count: ss, percentage: pct(ss))
            ]
        } catch {
            return []
        }
    }
}

final class SearchService {
    private let stockService: StockService
    private let amfiService: AMFIService

    init(stockService: StockService = .shared, amfiService: AMFIService = .shared) {
        self.stockService = stockService
        self.amfiService = amfiService
    }

    func search(query: String) async -> [InvestmentSummaryAsset] {
        guard query.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 else { return [] }

        async let stocks = stockService.searchStocks(query: query)
        async let funds = amfiService.searchSchemes(query: query)
        async let gold = stockService.searchGoldETFs(query: query)

        let stockAssets = await enrichedStockAssets(from: Array(stocks.prefix(25)))
        let fundAssets = await funds.prefix(30).map { fundAsset(from: $0) }
        let goldAssets = await enrichedGoldAssets(from: Array(gold.prefix(15)))

        return stockAssets + fundAssets + goldAssets
    }

    func searchStocksOnly(query: String) async -> [InvestmentSummaryAsset] {
        guard query.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 else { return [] }
        let stocks = await stockService.searchStocks(query: query)
        return await enrichedStockAssets(from: Array(stocks.prefix(50)))
    }

    func searchFundsOnly(query: String) async -> [InvestmentSummaryAsset] {
        guard query.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 else { return [] }
        let funds = await amfiService.searchSchemes(query: query)
        return funds.prefix(80).map { fundAsset(from: $0) }
    }

    func searchGoldETFsOnly(query: String) async -> [InvestmentSummaryAsset] {
        guard query.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 else { return [] }
        let gold = await stockService.searchGoldETFs(query: query)
        return await enrichedGoldAssets(from: Array(gold.prefix(30)))
    }

    func enrichedStockAssets(from stocks: [AstraStock]) async -> [InvestmentSummaryAsset] {
        await withTaskGroup(of: InvestmentSummaryAsset.self) { group in
            for stock in stocks {
                group.addTask {
                    let quote = await self.stockService.fetchPrice(symbol: stock.symbol) ?? stock
                    let resolved = AstraStock(
                        symbol: stock.symbol,
                        name: quote.name == stock.symbol ? stock.name : quote.name,
                        exchange: quote.exchange,
                        currentPrice: quote.currentPrice,
                        priceChange: quote.priceChange,
                        priceChangePercentage: quote.priceChangePercentage
                    )
                    return Self.stockAsset(from: resolved, sector: "Equity")
                }
            }

            var assets: [InvestmentSummaryAsset] = []
            for await asset in group { assets.append(asset) }
            return assets.sorted { $0.name < $1.name }
        }
    }

    func enrichedGoldAssets(from stocks: [AstraStock]) async -> [InvestmentSummaryAsset] {
        await withTaskGroup(of: InvestmentSummaryAsset.self) { group in
            for stock in stocks {
                group.addTask {
                    let quote = await self.stockService.fetchPrice(symbol: stock.symbol) ?? stock
                    let resolved = AstraStock(
                        symbol: stock.symbol,
                        name: quote.name == stock.symbol ? stock.name : quote.name,
                        exchange: quote.exchange,
                        currentPrice: quote.currentPrice,
                        priceChange: quote.priceChange,
                        priceChangePercentage: quote.priceChangePercentage
                    )
                    return Self.goldAsset(from: resolved)
                }
            }

            var assets: [InvestmentSummaryAsset] = []
            for await asset in group { assets.append(asset) }
            return assets.sorted { $0.name < $1.name }
        }
    }

    nonisolated func stockAsset(from stock: AstraStock, sector: String) -> InvestmentSummaryAsset {
        Self.stockAsset(from: stock, sector: sector)
    }

    nonisolated static func stockAsset(from stock: AstraStock, sector: String) -> InvestmentSummaryAsset {
        InvestmentSummaryAsset(
            id: "stock-\(stock.symbol)",
            kind: .stock,
            symbol: stock.symbol,
            name: stock.name,
            sector: sector,
            currentValue: stock.currentPrice > 0 ? stock.currentPrice : nil,
            dailyChange: abs(stock.priceChangePercentage) > 0.0001 ? stock.priceChangePercentage : nil,
            oneYearReturn: nil,
            riskLevel: .moderate,
            sparkline: [],
            metadata: stock.exchange
        )
    }

    nonisolated func fundAsset(from scheme: MFScheme) -> InvestmentSummaryAsset {
        Self.fundAsset(from: scheme)
    }

    nonisolated static func fundAsset(from scheme: MFScheme) -> InvestmentSummaryAsset {
        let category = fundCategory(for: scheme.name)
        return InvestmentSummaryAsset(
            id: "mf-\(scheme.schemeCode)",
            kind: .mutualFund,
            symbol: scheme.schemeCode,
            name: scheme.name,
            sector: category,
            currentValue: scheme.nav,
            dailyChange: nil,
            oneYearReturn: nil,
            riskLevel: category.localizedCaseInsensitiveContains("Small") ? .high : .moderate,
            sparkline: [],
            metadata: scheme.date
        )
    }

    nonisolated func goldAsset(from stock: AstraStock) -> InvestmentSummaryAsset {
        Self.goldAsset(from: stock)
    }

    nonisolated static func goldAsset(from stock: AstraStock) -> InvestmentSummaryAsset {
        InvestmentSummaryAsset(
            id: "gold-\(stock.symbol)",
            kind: .goldETF,
            symbol: stock.symbol,
            name: stock.name,
            sector: "Gold ETF",
            currentValue: stock.currentPrice > 0 ? stock.currentPrice : nil,
            dailyChange: abs(stock.priceChangePercentage) > 0.0001 ? stock.priceChangePercentage : nil,
            oneYearReturn: nil,
            riskLevel: .moderate,
            sparkline: [],
            metadata: stock.exchange
        )
    }

    nonisolated static func fundCategory(for name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("small") { return "Small Cap" }
        if lower.contains("mid") { return "Mid Cap" }
        if lower.contains("flexi") { return "Flexi Cap" }
        if lower.contains("index") || lower.contains("nifty") || lower.contains("sensex") { return "Index Fund" }
        if lower.contains("gold") { return "Gold Fund" }
        if lower.contains("large") { return "Large Cap" }
        return "Mutual Fund"
    }
}

final class InsightEngine {
    func insights(asset: InvestmentSummaryAsset, financials: CompanyFinancialSnapshot?, recommendations: [RecommendationTrend]) -> [InvestmentInsight] {
        var insights: [InvestmentInsight] = []

        if let pe = financials?.peRatio, pe > 35 {
            insights.append(InvestmentInsight(
                title: "Valuation above average",
                explanation: "Current valuation is above many mature businesses. Investors should evaluate whether growth expectations justify the premium.",
                systemImage: "scale.3d",
                color: AppTheme.vibrantOrange
            ))
        }

        if let growth = financials?.revenue, growth > 15 {
            insights.append(InvestmentInsight(
                title: "Healthy revenue growth",
                explanation: "Revenue growth is healthy compared with many mature businesses. Check if margins and cash flow are keeping pace.",
                systemImage: "chart.line.uptrend.xyaxis",
                color: AppTheme.auraGreen
            ))
        }

        if let debt = financials?.debtRatio, debt < 0.5 {
            insights.append(InvestmentInsight(
                title: "Low debt signal",
                explanation: "The company maintains relatively low debt levels, which can improve resilience during weak cycles.",
                systemImage: "checkmark.shield.fill",
                color: AppTheme.auraGreen
            ))
        }

        let positiveRecommendations = recommendations.filter { ["Strong Buy", "Buy"].contains($0.label) }.map(\.count).reduce(0, +)
        let totalRecommendations = recommendations.map(\.count).reduce(0, +)
        if totalRecommendations > 0, Double(positiveRecommendations) / Double(totalRecommendations) > 0.55 {
            insights.append(InvestmentInsight(
                title: "Positive analyst sentiment",
                explanation: "Analyst sentiment is currently positive. Treat this as one input, not a decision by itself.",
                systemImage: "person.crop.circle.badge.checkmark",
                color: AppTheme.auraIndigo
            ))
        }

        if insights.isEmpty {
            insights.append(InvestmentInsight(
                title: "Start with fundamentals",
                explanation: "Review price trend, valuation, debt, margins, and category risk before forming a view. No signal here is a buy or sell instruction.",
                systemImage: "lightbulb.fill",
                color: asset.kind.accent
            ))
        }

        return insights
    }
}

final class FAQService {
    func faqs() -> [InvestmentFAQ] {
        [
            InvestmentFAQ(question: "When should I start investing?", answer: "Start after you understand your goal, time horizon, emergency fund, and risk capacity."),
            InvestmentFAQ(question: "What happens if my investment falls?", answer: "Market-linked assets can fall. A fall is a prompt to review fundamentals, allocation, and time horizon."),
            InvestmentFAQ(question: "Is SIP better than lump sum?", answer: "SIP spreads entry points over time. Lump sum depends more on valuation, timing, and your risk comfort."),
            InvestmentFAQ(question: "Can I lose money?", answer: "Yes. Stocks, funds, and ETFs carry market risk and can lose value."),
            InvestmentFAQ(question: "How long should I stay invested?", answer: "Equity-oriented assets generally need a multi-year horizon because earnings cycles take time."),
            InvestmentFAQ(question: "Should I diversify?", answer: "Diversification reduces dependence on one company, sector, fund manager, or asset class."),
            InvestmentFAQ(question: "Why do markets fall?", answer: "Markets fall due to earnings disappointments, rates, liquidity, policy changes, global events, and sentiment."),
            InvestmentFAQ(question: "What is risk?", answer: "Risk is the possibility that outcomes differ from expectations, including loss of capital or lower returns."),
            InvestmentFAQ(question: "What is CAGR?", answer: "CAGR is the smoothed annual growth rate over a period. It does not show year-to-year volatility."),
            InvestmentFAQ(question: "What is NAV?", answer: "NAV is a fund's per-unit value after accounting for its portfolio assets and liabilities.")
        ]
    }
}

typealias InvestmentHomeAssets = (stocks: [InvestmentSummaryAsset], funds: [InvestmentSummaryAsset], gold: [InvestmentSummaryAsset])

private actor InvestmentIntelligenceHomeAssetCache {
    static let shared = InvestmentIntelligenceHomeAssetCache()

    private var cachedAssets: InvestmentHomeAssets?
    private var loadingTask: Task<InvestmentHomeAssets, Never>?

    func assets(repository: InvestmentIntelligenceRepository) async -> InvestmentHomeAssets {
        if let cachedAssets { return cachedAssets }

        if let loadingTask {
            let assets = await loadingTask.value
            cachedAssets = assets
            self.loadingTask = nil
            return assets
        }

        let task = Task { await repository.fetchHomeAssetsFresh() }
        loadingTask = task

        let assets = await task.value
        cachedAssets = assets
        loadingTask = nil
        return assets
    }

    func warm(repository: InvestmentIntelligenceRepository) async {
        _ = await assets(repository: repository)
    }

    /// Called by the background live-price refresh to patch cached asset prices.
    func updateLivePrices(stocks: [InvestmentSummaryAsset], gold: [InvestmentSummaryAsset]) {
        guard var current = cachedAssets else { return }
        // Merge refreshed stock prices into cached list (match by symbol)
        if !stocks.isEmpty {
            let priceMap = Dictionary(uniqueKeysWithValues: stocks.map { ($0.symbol, $0) })
            current.stocks = current.stocks.map { asset in
                if let updated = priceMap[asset.symbol], updated.currentValue ?? 0 > 0 {
                    var patched = asset
                    patched.currentValue = updated.currentValue
                    patched.dailyChange = updated.dailyChange
                    return patched
                }
                return asset
            }
        }
        if !gold.isEmpty {
            let priceMap = Dictionary(uniqueKeysWithValues: gold.map { ($0.symbol, $0) })
            current.gold = current.gold.map { asset in
                if let updated = priceMap[asset.symbol], updated.currentValue ?? 0 > 0 {
                    var patched = asset
                    patched.currentValue = updated.currentValue
                    patched.dailyChange = updated.dailyChange
                    return patched
                }
                return asset
            }
        }
        cachedAssets = current
    }

    func invalidate() {
        cachedAssets = nil
        loadingTask = nil
    }
}

final class InvestmentIntelligenceRepository {
    private let stockService: StockService
    private let amfiService: AMFIService
    private let profileService: CompanyProfileService
    private let financialService: FinancialService
    private let newsService: NewsService
    private let competitorService: CompetitorService
    private let recommendationService: RecommendationService
    private let insightEngine: InsightEngine
    private let faqService: FAQService

    init(
        stockService: StockService = .shared,
        amfiService: AMFIService = .shared,
        profileService: CompanyProfileService = CompanyProfileService(),
        financialService: FinancialService = FinancialService(),
        newsService: NewsService = NewsService(),
        competitorService: CompetitorService = CompetitorService(),
        recommendationService: RecommendationService = RecommendationService(),
        insightEngine: InsightEngine = InsightEngine(),
        faqService: FAQService = FAQService()
    ) {
        self.stockService = stockService
        self.amfiService = amfiService
        self.profileService = profileService
        self.financialService = financialService
        self.newsService = newsService
        self.competitorService = competitorService
        self.recommendationService = recommendationService
        self.insightEngine = insightEngine
        self.faqService = faqService
    }

    func homeAssets() async -> InvestmentHomeAssets {
        await InvestmentIntelligenceHomeAssetCache.shared.assets(repository: self)
    }

    func warmHomeAssets() async {
        await InvestmentIntelligenceHomeAssetCache.shared.warm(repository: self)
    }

    /// Returns home assets.  First call builds static placeholder data instantly from
    /// the seed lists (< 5 ms), caches it, then fires a background task to refresh
    /// live prices so the UI can update without blocking the initial render.
    fileprivate func fetchHomeAssetsFresh() async -> InvestmentHomeAssets {
        // 1. Build static assets immediately from seeds (no network)
        let staticStocks = buildStaticStocks()
        let staticFunds  = buildStaticFunds()
        let staticGold   = buildStaticGoldETFs()

        let rotated = (
            InvestmentRecommendationEngine.shared.rotateDaily(items: staticStocks),
            InvestmentRecommendationEngine.shared.rotateDaily(items: staticFunds),
            InvestmentRecommendationEngine.shared.rotateDaily(items: staticGold)
        )

        // 2. Fire background refresh for live prices — callers update via
        //    refreshLivePrices(stocks:gold:) once network calls resolve.
        Task.detached(priority: .background) {
            await self.refreshLivePrices()
        }

        return (rotated.0, rotated.1, rotated.2)
    }

    /// Builds stock assets from seed list without any network calls.
    private func buildStaticStocks() -> [InvestmentSummaryAsset] {
        let seeds: [(symbol: String, name: String, sector: String, approxPrice: Double)] = [
            ("RELIANCE.NS", "Reliance Industries", "Energy", 2850),
            ("TCS.NS", "Tata Consultancy Services", "IT", 3950),
            ("HDFCBANK.NS", "HDFC Bank", "Banking", 1750),
            ("INFY.NS", "Infosys", "IT", 1820),
            ("ICICIBANK.NS", "ICICI Bank", "Banking", 1280),
            ("HINDUNILVR.NS", "Hindustan Unilever", "FMCG", 2680),
            ("BHARTIARTL.NS", "Bharti Airtel", "Telecom", 1850),
            ("SUNPHARMA.NS", "Sun Pharma", "Healthcare", 1920),
            ("ITC.NS", "ITC", "FMCG", 480),
            ("SBIN.NS", "State Bank of India", "Banking", 820),
            ("LT.NS", "Larsen & Toubro", "Construction", 3650),
            ("BAJFINANCE.NS", "Bajaj Finance", "Financials", 6800),
            ("ASIANPAINT.NS", "Asian Paints", "Consumer", 2850),
            ("KOTAKBANK.NS", "Kotak Mahindra Bank", "Banking", 1920),
            ("AXISBANK.NS", "Axis Bank", "Banking", 1150),
            ("MARUTI.NS", "Maruti Suzuki", "Automobile", 12800),
            ("TATAMOTORS.NS", "Tata Motors", "Automobile", 980),
            ("HCLTECH.NS", "HCL Technologies", "IT", 1850),
            ("WIPRO.NS", "Wipro", "IT", 570),
            ("TITAN.NS", "Titan Company", "Consumer", 3580),
            ("ZOMATO.NS", "Zomato", "Consumer", 245),
            ("BEL.NS", "Bharat Electronics", "Defense", 310),
            ("HAL.NS", "Hindustan Aeronautics", "Defense", 4850),
            ("ADANIENT.NS", "Adani Enterprises", "Conglomerate", 2850),
            ("BAJAJ-AUTO.NS", "Bajaj Auto", "Automobile", 9500),
            ("EICHERMOT.NS", "Eicher Motors", "Automobile", 4900),
            ("APOLLOHOSP.NS", "Apollo Hospitals", "Healthcare", 6900),
            ("TRENT.NS", "Trent", "Retail", 6500),
            ("DRREDDY.NS", "Dr Reddy's Laboratories", "Healthcare", 6200),
            ("CIPLA.NS", "Cipla", "Healthcare", 1680),
            ("AAPL", "Apple Inc", "US Tech", 193),
            ("MSFT", "Microsoft Corp", "US Tech", 415),
            ("GOOGL", "Alphabet Inc", "US Tech", 178),
            ("NVDA", "NVIDIA Corp", "US Tech", 875),
            ("TSLA", "Tesla Inc", "US Tech", 185),
            ("AMZN", "Amazon.com", "US Tech", 185)
        ]
        return seeds.map { seed in
            let stock = AstraStock(
                symbol: seed.symbol,
                name: seed.name,
                exchange: seed.symbol.hasSuffix(".NS") ? "NSE" : "NASDAQ",
                currentPrice: seed.approxPrice,
                priceChange: 0,
                priceChangePercentage: 0
            )
            return SearchService.stockAsset(from: stock, sector: seed.sector)
        }
    }

    /// Builds fund assets from the MutualFundIntelligenceStore without any network calls.
    private func buildStaticFunds() -> [InvestmentSummaryAsset] {
        let seeds: [(code: String, name: String, category: String, nav: Double)] = [
            ("122639", "Parag Parikh Flexi Cap Fund - Direct Plan - Growth", "Flexi Cap Fund", 78.5),
            ("118778", "Nippon India Small Cap Fund - Direct Plan - Growth", "Small Cap Fund", 145.2),
            ("119292", "HDFC Mid-Cap Opportunities Fund - Direct Plan - Growth", "Mid Cap Fund", 112.8),
            ("120503", "Quant Small Cap Fund - Direct Plan - Growth", "Small Cap Fund", 285.4),
            ("118989", "Mirae Asset Large Cap Fund - Direct Plan - Growth", "Large Cap Fund", 115.6),
            ("119598", "SBI Bluechip Fund - Direct Plan - Growth", "Large Cap Fund", 78.9),
            ("125354", "Axis Bluechip Fund - Direct Plan - Growth", "Large Cap Fund", 58.3),
            ("120716", "UTI Nifty 50 Index Fund - Direct Plan - Growth", "Index Fund", 148.5)
        ]
        return seeds.map { seed in
            let profile = MutualFundIntelligenceStore.shared.profile(for: seed.code)
            var asset = InvestmentSummaryAsset(
                id: seed.code,
                kind: .mutualFund,
                symbol: seed.code,
                name: profile?.shortName ?? seed.name.components(separatedBy: " ").prefix(4).joined(separator: " "),
                sector: profile?.category ?? seed.category,
                currentValue: seed.nav,
                dailyChange: nil,
                oneYearReturn: profile?.return1Y,
                riskLevel: profile?.riskLevel ?? .moderate,
                sparkline: [],
                metadata: "AMFI"
            )
            return asset
        }
    }

    /// Builds Gold ETF assets from GoldETFIntelligenceStore without any network calls.
    private func buildStaticGoldETFs() -> [InvestmentSummaryAsset] {
        let seeds: [(symbol: String, name: String, approxPrice: Double)] = [
            ("GOLDBEES.NS", "Nippon India Gold ETF", 680),
            ("HDFCGOLD.NS", "HDFC Gold ETF", 68),
            ("SETFGOLD.NS", "SBI Gold ETF", 67),
            ("ICICIGOLD.NS", "ICICI Prudential Gold ETF", 68),
            ("KOTAKGOLD.NS", "Kotak Gold ETF", 68),
            ("SILVERBEES.NS", "Nippon India Silver ETF", 102),
            ("HDFCSILVER.NS", "HDFC Silver ETF", 10),
            ("ICICISILVE.NS", "ICICI Prudential Silver ETF", 10)
        ]
        return seeds.map { seed in
            let verified = GoldETFIntelligenceStore.shared.profile(for: seed.symbol)
            let stock = AstraStock(
                symbol: seed.symbol,
                name: verified?.fundName ?? seed.name,
                exchange: "NSE",
                currentPrice: seed.approxPrice,
                priceChange: 0,
                priceChangePercentage: 0
            )
            return SearchService.goldAsset(from: stock)
        }
    }

    /// Background refresh — updates live prices after initial static render.
    /// Called as a detached Task so it never blocks the home screen.
    func refreshLivePrices() async {
        // Limit to top-20 stocks to avoid Finnhub rate limits (60 calls/min free tier)
        let stockSeeds: [(String, String, String)] = [
            ("RELIANCE.NS", "Reliance Industries", "Energy"),
            ("TCS.NS", "Tata Consultancy Services", "IT"),
            ("HDFCBANK.NS", "HDFC Bank", "Banking"),
            ("INFY.NS", "Infosys", "IT"),
            ("ICICIBANK.NS", "ICICI Bank", "Banking"),
            ("BHARTIARTL.NS", "Bharti Airtel", "Telecom"),
            ("BAJFINANCE.NS", "Bajaj Finance", "Financials"),
            ("AXISBANK.NS", "Axis Bank", "Banking"),
            ("MARUTI.NS", "Maruti Suzuki", "Automobile"),
            ("TATAMOTORS.NS", "Tata Motors", "Automobile"),
            ("HCLTECH.NS", "HCL Technologies", "IT"),
            ("AAPL", "Apple Inc", "US Tech"),
            ("MSFT", "Microsoft Corp", "US Tech"),
            ("GOOGL", "Alphabet Inc", "US Tech"),
            ("NVDA", "NVIDIA Corp", "US Tech"),
            ("TSLA", "Tesla Inc", "US Tech"),
            ("TITAN.NS", "Titan Company", "Consumer"),
            ("ZOMATO.NS", "Zomato", "Consumer"),
            ("BEL.NS", "Bharat Electronics", "Defense"),
            ("APOLLOHOSP.NS", "Apollo Hospitals", "Healthcare")
        ]
        let goldSeeds = ["GOLDBEES.NS", "HDFCGOLD.NS", "SETFGOLD.NS", "ICICIGOLD.NS", "KOTAKGOLD.NS"]

        // Fetch in small batches to stay under Finnhub rate limit
        var refreshedStocks: [InvestmentSummaryAsset] = []
        for chunk in stride(from: 0, to: stockSeeds.count, by: 5) {
            let batch = Array(stockSeeds[chunk..<min(chunk + 5, stockSeeds.count)])
            let batchAssets = await withTaskGroup(of: InvestmentSummaryAsset.self) { group in
                for seed in batch {
                    group.addTask {
                        let quote = await self.stockService.fetchPrice(symbol: seed.0)
                        let stock = AstraStock(
                            symbol: seed.0,
                            name: quote?.name == seed.0 ? seed.1 : quote?.name ?? seed.1,
                            exchange: quote?.exchange ?? (seed.0.hasSuffix(".NS") ? "NSE" : "NASDAQ"),
                            currentPrice: quote?.currentPrice ?? 0,
                            priceChange: quote?.priceChange ?? 0,
                            priceChangePercentage: quote?.priceChangePercentage ?? 0
                        )
                        return SearchService.stockAsset(from: stock, sector: seed.2)
                    }
                }
                var results: [InvestmentSummaryAsset] = []
                for await r in group { results.append(r) }
                return results
            }
            refreshedStocks.append(contentsOf: batchAssets)
            // Small delay between batches to avoid rate limiting
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        }

        let refreshedGold = await withTaskGroup(of: InvestmentSummaryAsset.self) { group in
            for sym in goldSeeds {
                group.addTask {
                    let name = GoldETFIntelligenceStore.shared.profile(for: sym)?.fundName ?? sym
                    let quote = await self.stockService.fetchPrice(symbol: sym)
                    let stock = AstraStock(
                        symbol: sym, name: quote?.name == sym ? name : quote?.name ?? name,
                        exchange: "NSE",
                        currentPrice: quote?.currentPrice ?? 0,
                        priceChange: quote?.priceChange ?? 0,
                        priceChangePercentage: quote?.priceChangePercentage ?? 0
                    )
                    return SearchService.goldAsset(from: stock)
                }
            }
            var results: [InvestmentSummaryAsset] = []
            for await r in group { results.append(r) }
            return results
        }

        // Update the cache with refreshed prices so next load() call gets live data
        if !refreshedStocks.isEmpty || !refreshedGold.isEmpty {
            await InvestmentIntelligenceHomeAssetCache.shared.updateLivePrices(
                stocks: refreshedStocks,
                gold: refreshedGold
            )
        }
    }

    func detail(for asset: InvestmentSummaryAsset) async -> InvestmentDetailSnapshot {
        switch asset.kind {
        case .stock:
            return await stockDetail(for: asset)
        case .mutualFund:
            return await mutualFundDetail(for: asset)
        case .goldETF:
            return await goldETFDetail(for: asset)
        }
    }

    func categoryAssets(kind: IntelligenceAssetKind, filter: String? = nil) async -> [InvestmentSummaryAsset] {
        switch kind {
        case .stock:
            let all = await loadStocks()
            guard let filter, filter != "All", !filter.isEmpty else { return all }
            return all.filter { $0.sector.localizedCaseInsensitiveContains(filter) }
        case .mutualFund:
            let schemes = await amfiService.schemesByCategory(filter, limit: 100)
            return schemes.map { SearchService.fundAsset(from: $0) }
        case .goldETF:
            return await loadGoldETFs()
        }
    }

    func searchCategory(kind: IntelligenceAssetKind, query: String) async -> [InvestmentSummaryAsset] {
        let searcher = SearchService(stockService: stockService, amfiService: amfiService)
        switch kind {
        case .stock:
            return await searcher.searchStocksOnly(query: query)
        case .mutualFund:
            return await searcher.searchFundsOnly(query: query)
        case .goldETF:
            return await searcher.searchGoldETFsOnly(query: query)
        }
    }

    private func loadStocks() async -> [InvestmentSummaryAsset] {
        let seeds: [(symbol: String, name: String, sector: String)] = [
            ("RADICO.NS", "Radico Khaitan", "Beverages"),
            ("RELIANCE.NS", "Reliance Industries", "Energy"),
            ("TCS.NS", "Tata Consultancy Services", "IT"),
            ("HDFCBANK.NS", "HDFC Bank", "Banking"),
            ("INFY.NS", "Infosys", "IT"),
            ("ICICIBANK.NS", "ICICI Bank", "Banking"),
            ("HINDUNILVR.NS", "Hindustan Unilever", "FMCG"),
            ("BHARTIARTL.NS", "Bharti Airtel", "Telecom"),
            ("SUNPHARMA.NS", "Sun Pharma", "Healthcare"),
            ("ITC.NS", "ITC", "FMCG"),
            ("SBIN.NS", "State Bank of India", "Banking"),
            ("LT.NS", "Larsen & Toubro", "Construction"),
            ("BAJFINANCE.NS", "Bajaj Finance", "Financials"),
            ("ASIANPAINT.NS", "Asian Paints", "Consumer"),
            ("KOTAKBANK.NS", "Kotak Mahindra Bank", "Banking"),
            ("AXISBANK.NS", "Axis Bank", "Banking"),
            ("MARUTI.NS", "Maruti Suzuki", "Automobile"),
            ("TATAMOTORS.NS", "Tata Motors", "Automobile"),
            ("M&M.NS", "Mahindra & Mahindra", "Automobile"),
            ("HCLTECH.NS", "HCL Technologies", "IT"),
            ("WIPRO.NS", "Wipro", "IT"),
            ("TATASTEEL.NS", "Tata Steel", "Metals"),
            ("JSWSTEEL.NS", "JSW Steel", "Metals"),
            ("TITAN.NS", "Titan Company", "Consumer"),
            ("ZOMATO.NS", "Zomato", "Consumer"),
            ("TRENT.NS", "Trent", "Retail"),
            ("TATAPOWER.NS", "Tata Power", "Energy"),
            ("BEL.NS", "Bharat Electronics", "Defense"),
            ("HAL.NS", "Hindustan Aeronautics", "Defense"),
            ("JIOFIN.NS", "Jio Financial Services", "Financials"),
            ("ADANIENT.NS", "Adani Enterprises", "Conglomerate"),
            ("ADANIPORTS.NS", "Adani Ports", "Infrastructure"),
            ("BAJAJ-AUTO.NS", "Bajaj Auto", "Automobile"),
            ("COALINDIA.NS", "Coal India", "Energy"),
            ("DLF.NS", "DLF", "Real Estate"),
            ("POLYCAB.NS", "Polycab India", "Industrials"),
            ("VBL.NS", "Varun Beverages", "Beverages"),
            ("MCDOWELL-N.NS", "United Spirits", "Beverages"),
            ("NESTLEIND.NS", "Nestle India", "FMCG"),
            ("BRITANNIA.NS", "Britannia Industries", "FMCG"),
            ("CIPLA.NS", "Cipla", "Healthcare"),
            ("DRREDDY.NS", "Dr Reddy's Laboratories", "Healthcare"),
            ("DIVISLAB.NS", "Divi's Laboratories", "Healthcare"),
            ("APOLLOHOSP.NS", "Apollo Hospitals", "Healthcare"),
            ("EICHERMOT.NS", "Eicher Motors", "Automobile"),
            ("GRASIM.NS", "Grasim Industries", "Materials"),
            ("TECHM.NS", "Tech Mahindra", "IT"),
            ("INDUSINDBK.NS", "IndusInd Bank", "Banking"),
            ("FEDERALBNK.NS", "Federal Bank", "Banking"),
            ("PNB.NS", "Punjab National Bank", "Banking"),
            ("BANKBARODA.NS", "Bank of Baroda", "Banking"),
            ("INDIGO.NS", "InterGlobe Aviation", "Aviation"),
            ("IOC.NS", "Indian Oil", "Energy"),
            ("BPCL.NS", "Bharat Petroleum", "Energy"),
            ("ONGC.NS", "Oil & Natural Gas Corp", "Energy"),
            ("GAIL.NS", "GAIL (India)", "Energy"),
            ("HINDALCO.NS", "Hindalco Industries", "Metals"),
            ("VEDL.NS", "Vedanta", "Metals"),
            ("HAVELLS.NS", "Havells India", "Consumer"),
            ("SIEMENS.NS", "Siemens", "Industrials"),
            ("ABB.NS", "ABB India", "Industrials"),
            ("AAPL", "Apple Inc", "US Tech"),
            ("MSFT", "Microsoft Corp", "US Tech"),
            ("GOOGL", "Alphabet Inc", "US Tech"),
            ("AMZN", "Amazon.com", "US Tech"),
            ("NVDA", "NVIDIA Corp", "US Tech"),
            ("TSLA", "Tesla Inc", "US Tech")
        ]

        return await withTaskGroup(of: InvestmentSummaryAsset.self) { group in
            for seed in seeds {
                group.addTask {
                    let quote = await self.stockService.fetchPrice(symbol: seed.symbol)
                    let stock = AstraStock(
                        symbol: seed.symbol,
                        name: quote?.name == seed.symbol ? seed.name : quote?.name ?? seed.name,
                        exchange: quote?.exchange ?? (seed.symbol.hasSuffix(".NS") ? "NSE" : "NASDAQ"),
                        currentPrice: quote?.currentPrice ?? 0,
                        priceChange: quote?.priceChange ?? 0,
                        priceChangePercentage: quote?.priceChangePercentage ?? 0
                    )
                    return SearchService.stockAsset(from: stock, sector: seed.sector)
                }
            }

            var assets: [InvestmentSummaryAsset] = []
            for await asset in group { assets.append(asset) }
            return assets.sorted { ($0.dailyChange ?? 0) > ($1.dailyChange ?? 0) }
        }
    }

    private func loadFunds() async -> [InvestmentSummaryAsset] {
        let schemes = await amfiService.schemes()
        let topSchemes = schemes
            .filter { $0.name.localizedCaseInsensitiveContains("Direct") || $0.name.localizedCaseInsensitiveContains("Growth") }
            .prefix(50)
        
        return await withTaskGroup(of: InvestmentSummaryAsset.self) { group in
            for scheme in topSchemes {
                group.addTask {
                    let chart = await self.amfiService.navHistory(schemeCode: scheme.schemeCode)
                    var asset = SearchService.fundAsset(from: scheme)
                    if let first = chart.first?.value, let last = chart.last?.value, first > 0 {
                        asset.oneYearReturn = ((last - first) / first) * 100
                    }
                    return asset
                }
            }

            var assets: [InvestmentSummaryAsset] = []
            for await asset in group { assets.append(asset) }
            return assets.sorted { ($0.oneYearReturn ?? 0) > ($1.oneYearReturn ?? 0) }
        }
    }

    private func loadGoldETFs() async -> [InvestmentSummaryAsset] {
        let seeds: [(symbol: String, name: String)] = [
            ("GOLDBEES.NS", "Nippon India Gold ETF"),
            ("HDFCGOLD.NS", "HDFC Gold ETF"),
            ("SETFGOLD.NS", "SBI Gold ETF"),
            ("ICICIGOLD.NS", "ICICI Prudential Gold ETF"),
            ("KOTAKGOLD.NS", "Kotak Gold ETF"),
            ("AXISGOLD.NS", "Axis Gold ETF"),
            ("TATAGOLD.NS", "Tata Gold ETF"),
            ("ADITYAGOLD.NS", "Aditya Birla Gold ETF"),
            ("IDBIGOLD.NS", "IDBI Gold ETF"),
            ("INVESCOGOLD.NS", "Invesco India Gold ETF"),
            ("QUANTUMGOLD.NS", "Quantum Gold Fund"),
            ("UTIGOLDETF.NS", "UTI Gold ETF"),
            ("DSPGOLDETF.NS", "DSP Gold ETF"),
            ("BSLGOLDETF.NS", "BSL Gold ETF"),
            ("CANROBGOLD.NS", "Canara Robeco Gold ETF"),
            ("RELGOLD.NS", "Religare Gold ETF"),
            ("LICNETFGOLD.NS", "LIC MF Gold ETF"),
            ("MAGMAGOLD.NS", "Magma Gold ETF"),
            ("SILVERBEES.NS", "Nippon India Silver BeES"),
            ("HDFCSILVER.NS", "HDFC Silver ETF"),
            ("ICICISILVE.NS", "ICICI Prudential Silver ETF"),
            ("TATASILV.NS", "Tata Silver ETF"),
            ("SETFSILV.NS", "SBI Silver ETF"),
            ("AXISSILVER.NS", "Axis Silver ETF")
        ]

        return await withTaskGroup(of: InvestmentSummaryAsset.self) { group in
            for seed in seeds {
                group.addTask {
                    let quote = await self.stockService.fetchPrice(symbol: seed.symbol)
                    let stock = AstraStock(
                        symbol: seed.symbol,
                        name: quote?.name == seed.symbol ? seed.name : quote?.name ?? seed.name,
                        exchange: quote?.exchange ?? "NSE",
                        currentPrice: quote?.currentPrice ?? 0,
                        priceChange: quote?.priceChange ?? 0,
                        priceChangePercentage: quote?.priceChangePercentage ?? 0
                    )
                    return SearchService.goldAsset(from: stock)
                }
            }

            var assets: [InvestmentSummaryAsset] = []
            for await asset in group { assets.append(asset) }
            return assets.sorted { ($0.dailyChange ?? 0) > ($1.dailyChange ?? 0) }
        }
    }

    private func stockDetail(for asset: InvestmentSummaryAsset) async -> InvestmentDetailSnapshot {
        async let profile = profileService.fetch(symbol: asset.symbol)
        async let financials = financialService.fetch(symbol: asset.symbol)
        async let competitors = competitorService.fetch(symbol: asset.symbol)
        async let news = newsService.fetch(symbol: asset.symbol)
        async let recommendations = recommendationService.fetch(symbol: asset.symbol)
        async let chart = stockChart(symbol: asset.symbol)

        let resolvedProfile = await profile
        let resolvedFinancials = await financials
        let resolvedCompetitors = await competitors
        let resolvedRecommendations = await recommendations

        return await InvestmentDetailSnapshot(
            asset: asset,
            profile: resolvedProfile,
            financials: resolvedFinancials,
            mutualFund: nil,
            goldETF: nil,
            chart: chart,
            competitors: resolvedCompetitors,
            news: news,
            recommendations: resolvedRecommendations,
            insights: insightEngine.insights(asset: asset, financials: resolvedFinancials, recommendations: resolvedRecommendations),
            aiInsight: nil,
            faqs: faqService.faqs()
        )
    }

    private func mutualFundDetail(for asset: InvestmentSummaryAsset) async -> InvestmentDetailSnapshot {
        let scheme = await amfiService.scheme(code: asset.symbol)
        let chart = await amfiService.navHistory(schemeCode: asset.symbol)

        // Look up verified profile — first by schemeCode, then by name
        let verified = MutualFundIntelligenceStore.shared.profile(for: asset.symbol)
            ?? MutualFundIntelligenceStore.shared.profile(matching: asset.name)

        var fund = MutualFundSnapshot(
            schemeCode: asset.symbol,
            schemeName: verified?.schemeName ?? scheme?.name ?? asset.name,
            fundHouse: verified?.fundHouse ?? scheme?.name.components(separatedBy: " ").prefix(2).joined(separator: " ") ?? "Fund House",
            category: verified?.category ?? asset.sector,
            currentNAV: scheme?.nav ?? asset.currentValue ?? 0,
            assetClass: asset.sector == "Gold Fund" ? "Commodity" : "Equity / Hybrid",
            fundType: verified?.subCategory ?? asset.sector,
            lastUpdated: scheme?.date ?? asset.metadata,
            oneYearReturn: verified?.return1Y ?? oneYearReturn(from: chart),
            riskLevel: verified?.riskLevel ?? asset.riskLevel,
            verifiedProfile: verified
        )

        // If verified profile has better 1Y data, use it; else use computed
        if fund.oneYearReturn == nil, let from = chart.first?.value, let to = chart.last?.value, from > 0 {
            fund.oneYearReturn = ((to - from) / from) * 100
        }

        // Build insights — use verified AI insights if available
        let baseInsights = insightEngine.insights(asset: asset, financials: nil, recommendations: [])
        let verifiedInsights: [InvestmentInsight] = verified?.aiInsights.enumerated().map { idx, text in
            let tagEnd = text.firstIndex(of: "]").map { text.index(after: $0) }
            let clean = tagEnd.map { String(text[text.index(after: text.startIndex)...$0].dropLast()) } ?? ""
            let body = tagEnd.map { String(text[$0...]).trimmingCharacters(in: .whitespaces) } ?? text
            return InvestmentInsight(
                title: clean.isEmpty ? "Fund Insight" : clean,
                explanation: body,
                systemImage: idx % 5 == 0 ? "chart.pie.fill" : idx % 5 == 1 ? "person.fill" : idx % 5 == 2 ? "building.2.fill" : idx % 5 == 3 ? "indianrupeesign.circle.fill" : "lightbulb.fill",
                color: [AppTheme.auraGreen, AppTheme.auraIndigo, AppTheme.auraPurple, AppTheme.vibrantOrange, AppTheme.auraMint][idx % 5]
            )
        } ?? []

        return InvestmentDetailSnapshot(
            asset: asset,
            profile: nil,
            financials: nil,
            mutualFund: fund,
            goldETF: nil,
            chart: chart.isEmpty ? asset.sparkline : chart,
            competitors: [],
            news: [],
            recommendations: [],
            insights: verifiedInsights.isEmpty ? baseInsights : verifiedInsights,
            aiInsight: nil,
            faqs: faqService.faqs()
        )
    }

    private func goldETFDetail(for asset: InvestmentSummaryAsset) async -> InvestmentDetailSnapshot {
        let chart = await stockChart(symbol: asset.symbol)

        // Look up verified profile
        let verified = GoldETFIntelligenceStore.shared.profile(for: asset.symbol)
            ?? GoldETFIntelligenceStore.shared.profile(matching: asset.name)

        let snapshot = GoldETFSnapshot(
            fundName: verified?.fundName ?? asset.name,
            symbol: asset.symbol,
            currentPrice: asset.currentValue,
            nav: asset.currentValue,
            trackingError: verified?.trackingError ?? "Review AMC factsheet",
            expenseRatio: verified?.expenseRatio ?? "Review AMC factsheet",
            fundHouse: verified?.fundHouse ?? asset.name.components(separatedBy: " ").prefix(2).joined(separator: " "),
            riskLevel: verified?.riskLevel ?? .moderate,
            category: verified != nil ? (verified!.symbol.contains("SILVER") ? "Silver ETF" : "Gold ETF") : "Gold ETF",
            verifiedProfile: verified
        )

        // Build insights from verified store
        let baseInsights = insightEngine.insights(asset: asset, financials: nil, recommendations: [])
        let verifiedInsights: [InvestmentInsight] = verified?.aiInsights.enumerated().map { idx, text in
            let tagEnd = text.firstIndex(of: "]").map { text.index(after: $0) }
            let clean = tagEnd.map { String(text[text.index(after: text.startIndex)...$0].dropLast()) } ?? ""
            let body = tagEnd.map { String(text[$0...]).trimmingCharacters(in: .whitespaces) } ?? text
            return InvestmentInsight(
                title: clean.isEmpty ? "ETF Insight" : clean,
                explanation: body,
                systemImage: idx % 4 == 0 ? "circle.hexagongrid.fill" : idx % 4 == 1 ? "building.2.fill" : idx % 4 == 2 ? "chart.line.uptrend.xyaxis" : "lightbulb.fill",
                color: [AppTheme.auraGold, AppTheme.auraMint, AppTheme.auraIndigo, AppTheme.vibrantOrange][idx % 4]
            )
        } ?? []

        return InvestmentDetailSnapshot(
            asset: asset,
            profile: nil,
            financials: nil,
            mutualFund: nil,
            goldETF: snapshot,
            chart: chart.isEmpty ? asset.sparkline : chart,
            competitors: [],
            news: [],
            recommendations: [],
            insights: verifiedInsights.isEmpty ? baseInsights : verifiedInsights,
            aiInsight: nil,
            faqs: faqService.faqs()
        )
    }

    private func stockChart(symbol: String) async -> [InvestmentChartPoint] {
        let start = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        let points = await stockService.fetchStockChartHistory(symbol: symbol, startDate: start)
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return points.compactMap { point in
            guard let date = formatter.date(from: point.date), let value = Double(point.nav) else { return nil }
            return InvestmentChartPoint(date: date, value: value)
        }
    }

    private func oneYearReturn(from chart: [InvestmentChartPoint]) -> Double? {
        guard let first = chart.first?.value, let last = chart.last?.value, first > 0 else { return nil }
        return ((last - first) / first) * 100
    }
}

struct FinnhubCompanyProfile: Decodable {
    let country: String?
    let currency: String?
    let exchange: String?
    let finnhubIndustry: String?
    let ipo: String?
    let logo: String?
    let marketCapitalization: Double?
    let name: String?
    let ticker: String?
    let weburl: String?
}

struct FinnhubQuoteResponse: Decodable {
    let c: Double?
    let d: Double?
    let dp: Double?
    let h: Double?
    let l: Double?
    let o: Double?
    let pc: Double?
}

struct FinnhubMetricResponse: Decodable {
    let metric: FinnhubMetric
}

struct FinnhubMetric: Decodable {
    let marketCapitalization: Double?
    let peNormalizedAnnual: Double?
    let peBasicExclExtraTTM: Double?
    let weekHigh52: Double?
    let weekLow52: Double?
    let dividendYieldIndicatedAnnual: Double?
    let revenueGrowthTTMYoy: Double?
    let revenueGrowthQuarterlyYoy: Double?
    let netProfitMarginTTM: Double?
    let epsBasicExclExtraItemsTTM: Double?
    let freeCashFlowPerShareTTM: Double?
    let operatingMarginTTM: Double?
    let roeTTM: Double?
    let roaTTM: Double?
    let totalDebtToEquityQuarterly: Double?

    enum CodingKeys: String, CodingKey {
        case marketCapitalization
        case peNormalizedAnnual
        case peBasicExclExtraTTM = "peBasicExclExtraTTM"
        case weekHigh52 = "52WeekHigh"
        case weekLow52 = "52WeekLow"
        case dividendYieldIndicatedAnnual
        case revenueGrowthTTMYoy
        case revenueGrowthQuarterlyYoy
        case netProfitMarginTTM
        case epsBasicExclExtraItemsTTM
        case freeCashFlowPerShareTTM
        case operatingMarginTTM
        case roeTTM
        case roaTTM
        case totalDebtToEquityQuarterly
    }
}

struct FinnhubRecommendationResponse: Decodable {
    let strongBuy: Int?
    let buy: Int?
    let hold: Int?
    let sell: Int?
    let strongSell: Int?
    let period: String?
}

struct FinnhubNewsResponse: Decodable {
    let headline: String?
    let summary: String?
    let source: String?
    let datetime: Int?
    let url: String?
}
