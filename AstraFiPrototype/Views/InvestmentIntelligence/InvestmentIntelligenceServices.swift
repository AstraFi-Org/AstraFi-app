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
        try await request(path: "quote", query: ["symbol": finnhubSymbol(symbol)])
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
        guard (response as? HTTPURLResponse)?.statusCode ?? 200 < 400 else {
            throw URLError(.badServerResponse)
        }
        await cache.store(data, for: cacheKey)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func finnhubSymbol(_ symbol: String) -> String {
        let upper = symbol.uppercased()
        if upper.hasSuffix(".NS") { return "NSE:\(upper.dropLast(3))" }
        if upper.hasSuffix(".BO") { return "BSE:\(upper.dropLast(3))" }
        return upper
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

    init(finnhub: FinnhubService = .shared) {
        self.finnhub = finnhub
    }

    func fetch(symbol: String) async -> CompanyProfileSnapshot? {
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

            return CompanyProfileSnapshot(
                name: profile.name ?? symbol,
                ticker: profile.ticker ?? symbol,
                sector: profile.finnhubIndustry ?? "Market",
                industry: profile.finnhubIndustry ?? "Unknown",
                country: profile.country ?? "Unknown",
                exchange: profile.exchange ?? "Market",
                logoURL: URL(string: profile.logo ?? ""),
                description: "This company operates in \(profile.finnhubIndustry ?? "its industry"). Review revenue, margins, debt and competition before making investment decisions."
            )
        } catch {
            return nil
        }
    }
}

final class FinancialService {
    private let finnhub: FinnhubService

    init(finnhub: FinnhubService = .shared) {
        self.finnhub = finnhub
    }

    func fetch(symbol: String) async -> CompanyFinancialSnapshot? {
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
            return [
                RecommendationTrend(label: "Strong Buy", count: latest.strongBuy ?? 0),
                RecommendationTrend(label: "Buy", count: latest.buy ?? 0),
                RecommendationTrend(label: "Hold", count: latest.hold ?? 0),
                RecommendationTrend(label: "Sell", count: latest.sell ?? 0),
                RecommendationTrend(label: "Strong Sell", count: latest.strongSell ?? 0)
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

        let stockAssets = await enrichedStockAssets(from: Array(stocks.prefix(8)))
        let fundAssets = await funds.prefix(8).map { fundAsset(from: $0) }
        let goldAssets = await enrichedGoldAssets(from: Array(gold.prefix(4)))

        return stockAssets + fundAssets + goldAssets
    }

    private func enrichedStockAssets(from stocks: [AstraStock]) async -> [InvestmentSummaryAsset] {
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

    private func enrichedGoldAssets(from stocks: [AstraStock]) async -> [InvestmentSummaryAsset] {
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

    fileprivate func fetchHomeAssetsFresh() async -> InvestmentHomeAssets {
        async let stocks = loadStocks()
        async let funds = loadFunds()
        async let gold = loadGoldETFs()
        return await (stocks, funds, gold)
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

    private func loadStocks() async -> [InvestmentSummaryAsset] {
        let seeds: [(symbol: String, name: String, sector: String)] = [
            ("RELIANCE.NS", "Reliance Industries", "Energy"),
            ("TCS.NS", "Tata Consultancy Services", "IT"),
            ("HDFCBANK.NS", "HDFC Bank", "Banking"),
            ("INFY.NS", "Infosys", "IT"),
            ("ICICIBANK.NS", "ICICI Bank", "Banking"),
            ("HINDUNILVR.NS", "Hindustan Unilever", "FMCG"),
            ("BHARTIARTL.NS", "Bharti Airtel", "Telecom"),
            ("SUNPHARMA.NS", "Sun Pharma", "Healthcare")
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
                    return SearchService.stockAsset(from: stock, sector: seed.sector)
                }
            }

            var assets: [InvestmentSummaryAsset] = []
            for await asset in group { assets.append(asset) }
            return assets.sorted { $0.sector < $1.sector }
        }
    }

    private func loadFunds() async -> [InvestmentSummaryAsset] {
        let schemes = await amfiService.schemes()
        let categories = ["Large Cap", "Flexi Cap", "Mid Cap", "Small Cap", "Index Fund", "Gold Fund"]
        return categories.compactMap { category in
            schemes.first { SearchService.fundCategory(for: $0.name) == category }
        }
        .map { SearchService.fundAsset(from: $0) }
    }

    private func loadGoldETFs() async -> [InvestmentSummaryAsset] {
        let seeds: [(symbol: String, name: String)] = [
            ("GOLDBEES.NS", "Nippon India Gold ETF"),
            ("HDFCGOLD.NS", "HDFC Gold ETF"),
            ("SETFGOLD.NS", "SBI Gold ETF"),
            ("ICICIGOLD.NS", "ICICI Prudential Gold ETF")
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
            return assets.sorted { $0.name < $1.name }
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
        let fund = MutualFundSnapshot(
            schemeCode: asset.symbol,
            schemeName: scheme?.name ?? asset.name,
            fundHouse: scheme?.name.components(separatedBy: " ").prefix(2).joined(separator: " ") ?? "Fund House",
            category: asset.sector,
            currentNAV: scheme?.nav ?? asset.currentValue ?? 0,
            assetClass: asset.sector == "Gold Fund" ? "Commodity" : "Equity / Hybrid",
            fundType: asset.sector,
            lastUpdated: scheme?.date ?? asset.metadata,
            oneYearReturn: oneYearReturn(from: chart),
            riskLevel: asset.riskLevel
        )

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
            insights: insightEngine.insights(asset: asset, financials: nil, recommendations: []),
            aiInsight: nil,
            faqs: faqService.faqs()
        )
    }

    private func goldETFDetail(for asset: InvestmentSummaryAsset) async -> InvestmentDetailSnapshot {
        let chart = await stockChart(symbol: asset.symbol)
        let snapshot = GoldETFSnapshot(
            fundName: asset.name,
            symbol: asset.symbol,
            currentPrice: asset.currentValue,
            nav: asset.currentValue,
            trackingError: "Review factsheet",
            expenseRatio: "AMC disclosed",
            fundHouse: asset.name.components(separatedBy: " ").prefix(2).joined(separator: " "),
            riskLevel: .moderate,
            category: "Gold ETF"
        )

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
            insights: insightEngine.insights(asset: asset, financials: nil, recommendations: []),
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
