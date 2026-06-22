import Foundation

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
            return CompanyFinancialSnapshot(
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
        do {
            let peers = try await finnhub.competitors(symbol: symbol).filter { !$0.isEmpty && $0 != symbol }.prefix(8)
            return await withTaskGroup(of: InvestmentCompetitor?.self) { group in
                for peer in peers {
                    group.addTask {
                        let quote = await self.stockService.fetchPrice(symbol: peer)
                        let profile = try? await self.finnhub.companyProfile(symbol: peer)
                        return InvestmentCompetitor(
                            symbol: peer,
                            name: profile?.name ?? quote?.name ?? peer,
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
                return results
            }
        } catch {
            return []
        }
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

        let stockAssets = await stocks.prefix(8).map { stockAsset(from: $0, sector: "Equity") }
        let fundAssets = await funds.prefix(8).map { fundAsset(from: $0) }
        let goldAssets = await gold.prefix(4).map { goldAsset(from: $0) }

        return stockAssets + fundAssets + goldAssets
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
            dailyChange: stock.priceChangePercentage,
            oneYearReturn: nil,
            riskLevel: .moderate,
            sparkline: seedSparkline(base: max(stock.currentPrice, 100)),
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
            sparkline: seedSparkline(base: scheme.nav),
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
            dailyChange: stock.priceChangePercentage,
            oneYearReturn: nil,
            riskLevel: .moderate,
            sparkline: seedSparkline(base: max(stock.currentPrice, 50)),
            metadata: stock.exchange
        )
    }

    nonisolated static func seedSparkline(base: Double) -> [InvestmentChartPoint] {
        let calendar = Calendar.current
        return (0..<8).compactMap { index in
            guard let date = calendar.date(byAdding: .day, value: index - 7, to: Date()) else { return nil }
            let wave = sin(Double(index)) * 0.018
            return InvestmentChartPoint(date: date, value: base * (1 + wave + Double(index) * 0.006))
        }
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

final class AIInsightService {
    private let apiKey: String
    private let endpoint: URL
    private let model: String

    init(
        apiKey: String = ProcessInfo.processInfo.environment["GROQ_API_KEY"] ?? "",
        endpoint: URL = URL(string: "https://api.groq.com/openai/v1/chat/completions")!,
        model: String = ProcessInfo.processInfo.environment["GROQ_MODEL"] ?? "qwen/qwen3-32b"
    ) {
        self.apiKey = apiKey
        self.endpoint = endpoint
        self.model = model
    }

    func analyze(
        asset: InvestmentSummaryAsset,
        profile: CompanyProfileSnapshot?,
        financials: CompanyFinancialSnapshot?,
        mutualFund: MutualFundSnapshot?,
        goldETF: GoldETFSnapshot?,
        competitors: [InvestmentCompetitor]
    ) async -> String? {
        guard !apiKey.isEmpty else {
            return "AI explanation is ready, but `GROQ_API_KEY` is not configured. Add it to the Xcode scheme environment or proxy requests through your backend."
        }

        let request = GroqChatCompletionRequest(
            model: model,
            messages: [
                GroqChatMessage(
                    role: "system",
                    content: "You are AstraFi's educational investment explainer. Use plain language. Do not recommend buying, selling, or guaranteeing returns. Mention uncertainty and risk."
                ),
                GroqChatMessage(
                    role: "user",
                    content: prompt(
                        asset: asset,
                        profile: profile,
                        financials: financials,
                        mutualFund: mutualFund,
                        goldETF: goldETF,
                        competitors: competitors
                    )
                )
            ],
            temperature: 0.25,
            maxTokens: 650
        )

        do {
            var urlRequest = URLRequest(url: endpoint)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.timeoutInterval = 30
            urlRequest.httpBody = try JSONEncoder().encode(request)

            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
                return "AI explanation could not be loaded right now. AstraFi is still showing transparent rule-based insights below."
            }

            let decoded = try JSONDecoder().decode(GroqChatCompletionResponse.self, from: data)
            return decoded.choices.first?.message.content
        } catch {
            return "AI explanation could not be generated right now. AstraFi is still showing transparent rule-based insights below."
        }
    }

    private func prompt(
        asset: InvestmentSummaryAsset,
        profile: CompanyProfileSnapshot?,
        financials: CompanyFinancialSnapshot?,
        mutualFund: MutualFundSnapshot?,
        goldETF: GoldETFSnapshot?,
        competitors: [InvestmentCompetitor]
    ) -> String {
        """
        Analyze the following investment for education only.

        Asset:
        Name: \(asset.name)
        Type: \(asset.kind.rawValue)
        Symbol: \(asset.symbol)
        Sector/Category: \(asset.sector)
        Current value: \(asset.currentValue?.description ?? "Unavailable")
        Daily change: \(asset.dailyChange?.description ?? "Unavailable")
        Risk level: \(asset.riskLevel.rawValue)

        Company profile:
        Sector: \(profile?.sector ?? "Unavailable")
        Industry: \(profile?.industry ?? "Unavailable")
        Country: \(profile?.country ?? "Unavailable")
        Exchange: \(profile?.exchange ?? "Unavailable")

        Financials:
        PE Ratio: \(financials?.peRatio?.description ?? "Unavailable")
        Revenue Growth: \(financials?.revenue?.description ?? "Unavailable")
        Profit Margin: \(financials?.profitMargin?.description ?? "Unavailable")
        ROE: \(financials?.roe?.description ?? "Unavailable")
        ROA: \(financials?.roa?.description ?? "Unavailable")
        Debt Ratio: \(financials?.debtRatio?.description ?? "Unavailable")
        Market Cap: \(financials?.marketCap?.description ?? "Unavailable")

        Mutual fund:
        Scheme: \(mutualFund?.schemeName ?? "Not applicable")
        Fund House: \(mutualFund?.fundHouse ?? "Not applicable")
        Category: \(mutualFund?.category ?? "Not applicable")
        Current NAV: \(mutualFund?.currentNAV.description ?? "Not applicable")

        Gold ETF:
        Fund House: \(goldETF?.fundHouse ?? "Not applicable")
        Tracking Error: \(goldETF?.trackingError ?? "Not applicable")
        Expense Ratio: \(goldETF?.expenseRatio ?? "Not applicable")

        Competitors:
        \(competitors.prefix(5).map { "\($0.name) (\($0.symbol))" }.joined(separator: ", "))

        Explain in short paragraphs:
        1. Business or fund overview.
        2. Strengths.
        3. Risks.
        4. Growth drivers or demand drivers.
        5. Explain like I am 20 years old.

        Use factual and cautious language. Never say guaranteed. Never say buy, sell, or hold.
        """
    }
}

private struct GroqChatCompletionRequest: Encodable {
    let model: String
    let messages: [GroqChatMessage]
    let temperature: Double
    let maxTokens: Int

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case maxTokens = "max_tokens"
    }
}

private struct GroqChatMessage: Codable {
    let role: String
    let content: String
}

private struct GroqChatCompletionResponse: Decodable {
    let choices: [GroqChatChoice]
}

private struct GroqChatChoice: Decodable {
    let message: GroqChatMessage
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
    private let aiInsightService: AIInsightService

    init(
        stockService: StockService = .shared,
        amfiService: AMFIService = .shared,
        profileService: CompanyProfileService = CompanyProfileService(),
        financialService: FinancialService = FinancialService(),
        newsService: NewsService = NewsService(),
        competitorService: CompetitorService = CompetitorService(),
        recommendationService: RecommendationService = RecommendationService(),
        insightEngine: InsightEngine = InsightEngine(),
        faqService: FAQService = FAQService(),
        aiInsightService: AIInsightService = AIInsightService()
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
        self.aiInsightService = aiInsightService
    }

    func homeAssets() async -> (stocks: [InvestmentSummaryAsset], funds: [InvestmentSummaryAsset], gold: [InvestmentSummaryAsset]) {
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
        let seeds: [(String, String, String)] = [
            ("HDFCBANK.NS", "HDFC Bank Ltd", "Banking"),
            ("TCS.NS", "Tata Consultancy Services", "IT"),
            ("HINDUNILVR.NS", "Hindustan Unilever Ltd", "FMCG"),
            ("SUNPHARMA.NS", "Sun Pharma", "Healthcare"),
            ("RELIANCE.NS", "Reliance Industries", "Energy"),
            ("NTPC.NS", "NTPC Ltd", "Power"),
            ("MARUTI.NS", "Maruti Suzuki", "Automobile")
        ]

        return await withTaskGroup(of: InvestmentSummaryAsset.self) { group in
            for seed in seeds {
                group.addTask {
                    let quote = await self.stockService.fetchPrice(symbol: seed.0)
                    return InvestmentSummaryAsset(
                        id: "stock-\(seed.0)",
                        kind: .stock,
                        symbol: seed.0,
                        name: quote?.name == seed.0 ? seed.1 : quote?.name ?? seed.1,
                        sector: seed.2,
                        currentValue: quote?.currentPrice,
                        dailyChange: quote?.priceChangePercentage,
                        oneYearReturn: nil,
                        riskLevel: .moderate,
                        sparkline: SearchService.seedSparkline(base: max(quote?.currentPrice ?? 100, 100)),
                        metadata: quote?.exchange ?? "NSE"
                    )
                }
            }

            var assets: [InvestmentSummaryAsset] = []
            for await item in group { assets.append(item) }
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
        let seeds = [
            AstraStock(symbol: "GOLDBEES.NS", name: "Nippon India Gold ETF", exchange: "NSE", currentPrice: 0, priceChange: 0, priceChangePercentage: 0),
            AstraStock(symbol: "HDFCGOLD.NS", name: "HDFC Gold ETF", exchange: "NSE", currentPrice: 0, priceChange: 0, priceChangePercentage: 0),
            AstraStock(symbol: "SETFGOLD.NS", name: "SBI Gold ETF", exchange: "NSE", currentPrice: 0, priceChange: 0, priceChangePercentage: 0),
            AstraStock(symbol: "ICICIGOLD.NS", name: "ICICI Gold ETF", exchange: "NSE", currentPrice: 0, priceChange: 0, priceChangePercentage: 0)
        ]

        return await withTaskGroup(of: InvestmentSummaryAsset.self) { group in
            for seed in seeds {
                group.addTask {
                    let quote = await self.stockService.fetchPrice(symbol: seed.symbol)
                    return SearchService.goldAsset(from: quote ?? seed)
                }
            }
            var assets: [InvestmentSummaryAsset] = []
            for await item in group { assets.append(item) }
            return assets
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
        let aiInsight = await aiInsightService.analyze(
            asset: asset,
            profile: resolvedProfile,
            financials: resolvedFinancials,
            mutualFund: nil,
            goldETF: nil,
            competitors: resolvedCompetitors
        )

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
            aiInsight: aiInsight,
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
            aiInsight: await aiInsightService.analyze(
                asset: asset,
                profile: nil,
                financials: nil,
                mutualFund: fund,
                goldETF: nil,
                competitors: []
            ),
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
            aiInsight: await aiInsightService.analyze(
                asset: asset,
                profile: nil,
                financials: nil,
                mutualFund: nil,
                goldETF: snapshot,
                competitors: []
            ),
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
