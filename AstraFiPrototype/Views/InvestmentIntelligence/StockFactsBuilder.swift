import Foundation

enum StockFactsBuilderError: LocalizedError {
    case unsupportedAsset
    case noProviderFacts

    var errorDescription: String? {
        switch self {
        case .unsupportedAsset:
            return "AI stock intelligence is available for stocks only."
        case .noProviderFacts:
            return "Provider facts are unavailable for this stock right now."
        }
    }
}

final class StockFactsBuilder {
    private let fmpService: FMPService
    private let profileService: CompanyProfileService
    private let financialService: FinancialService
    private let competitorService: CompetitorService
    private let recommendationService: RecommendationService
    private let newsService: NewsService

    init(
        fmpService: FMPService = .shared,
        profileService: CompanyProfileService = CompanyProfileService(),
        financialService: FinancialService = FinancialService(),
        competitorService: CompetitorService = CompetitorService(),
        recommendationService: RecommendationService = RecommendationService(),
        newsService: NewsService = NewsService()
    ) {
        self.fmpService = fmpService
        self.profileService = profileService
        self.financialService = financialService
        self.competitorService = competitorService
        self.recommendationService = recommendationService
        self.newsService = newsService
    }

    func buildFacts(for asset: InvestmentSummaryAsset) async throws -> StockFacts {
        guard asset.kind == .stock else { throw StockFactsBuilderError.unsupportedAsset }

        async let fmpProfile = optionalFMPProfile(symbol: asset.symbol)
        async let fmpMetrics = optionalFMPMetrics(symbol: asset.symbol)
        async let fmpRatios = optionalFMPRatios(symbol: asset.symbol)
        async let fmpIncome = optionalFMPIncomeStatements(symbol: asset.symbol)
        async let fmpPeers = optionalFMPPeers(symbol: asset.symbol)
        async let profile = profileService.fetch(symbol: asset.symbol)
        async let financials = financialService.fetch(symbol: asset.symbol)
        async let competitors = competitorService.fetch(symbol: asset.symbol)
        async let recommendations = recommendationService.fetch(symbol: asset.symbol)
        async let news = newsService.fetch(symbol: asset.symbol)

        let resolvedFMPProfile = await fmpProfile
        let resolvedFMPMetrics = await fmpMetrics
        let resolvedFMPRatios = await fmpRatios
        let resolvedFMPIncome = await fmpIncome
        let resolvedFMPPeers = await fmpPeers
        let resolvedProfile = await profile
        let resolvedFinancials = await financials
        let resolvedCompetitors = await competitors
        let resolvedRecommendations = await recommendations
        let resolvedNews = await news

        guard resolvedFMPProfile != nil || resolvedFMPMetrics != nil || resolvedFMPRatios != nil || resolvedProfile != nil || resolvedFinancials != nil || !resolvedNews.isEmpty else {
            throw StockFactsBuilderError.noProviderFacts
        }

        let buyCount = recommendationCount(in: resolvedRecommendations, labels: ["Strong Buy", "Buy"])
        let holdCount = recommendationCount(in: resolvedRecommendations, labels: ["Hold"])
        let sellCount = recommendationCount(in: resolvedRecommendations, labels: ["Sell", "Strong Sell"])
        let revenueGrowth = growthRate(
            latest: resolvedFMPIncome.first?.revenue,
            previous: resolvedFMPIncome.dropFirst().first?.revenue
        ) ?? resolvedFinancials?.historicalGrowth ?? resolvedFinancials?.quarterlyGrowth ?? 0
        let profitGrowth = growthRate(
            latest: resolvedFMPIncome.first?.netIncome,
            previous: resolvedFMPIncome.dropFirst().first?.netIncome
        ) ?? resolvedFinancials?.netProfit ?? resolvedFinancials?.profitMargin ?? 0
        let peerSymbols = resolvedFMPPeers.isEmpty ? resolvedCompetitors.map(\.symbol) : resolvedFMPPeers

        return StockFacts(
            symbol: asset.symbol,
            companyName: resolvedFMPProfile?.companyName ?? resolvedProfile?.name ?? asset.name,
            sector: resolvedFMPProfile?.sector ?? resolvedProfile?.sector ?? asset.sector,
            industry: resolvedFMPProfile?.industry ?? resolvedProfile?.industry ?? asset.sector,
            marketCap: normalizedMarketCap(resolvedFMPProfile?.mktCap) ?? resolvedFinancials?.marketCap ?? 0,
            employees: employeeCount(from: resolvedFMPProfile?.fullTimeEmployees),
            description: resolvedFMPProfile?.description ?? resolvedProfile?.description ?? "Provider profile text is unavailable for this company.",
            peRatio: resolvedFMPMetrics?.peRatioTTM ?? resolvedFMPRatios?.priceEarningsRatioTTM ?? resolvedFinancials?.peRatio ?? 0,
            roe: resolvedFMPMetrics?.roeTTM ?? resolvedFMPRatios?.returnOnEquityTTM ?? resolvedFinancials?.roe ?? 0,
            debtToEquity: resolvedFMPMetrics?.debtToEquityTTM ?? resolvedFMPRatios?.debtEquityRatioTTM ?? resolvedFinancials?.debtRatio ?? 0,
            revenueGrowth: revenueGrowth,
            profitGrowth: profitGrowth,
            competitors: peerSymbols,
            analystBuy: buyCount,
            analystHold: holdCount,
            analystSell: sellCount,
            latestNews: resolvedNews.prefix(5).map { $0.headline },
            priceHistory: asset.sparkline.suffix(30).map(\.value)
        )
    }

    private func recommendationCount(in trends: [RecommendationTrend], labels: Set<String>) -> Int {
        trends
            .filter { labels.contains($0.label) }
            .reduce(0) { $0 + $1.count }
    }

    private func optionalFMPProfile(symbol: String) async -> FMPProfile? {
        try? await fmpService.profile(symbol: symbol)
    }

    private func optionalFMPMetrics(symbol: String) async -> FMPKeyMetrics? {
        try? await fmpService.keyMetrics(symbol: symbol)
    }

    private func optionalFMPRatios(symbol: String) async -> FMPRatios? {
        try? await fmpService.ratios(symbol: symbol)
    }

    private func optionalFMPIncomeStatements(symbol: String) async -> [FMPIncomeStatement] {
        (try? await fmpService.incomeStatements(symbol: symbol)) ?? []
    }

    private func optionalFMPPeers(symbol: String) async -> [String] {
        (try? await fmpService.peers(symbol: symbol)) ?? []
    }

    private func growthRate(latest: Double?, previous: Double?) -> Double? {
        guard let latest, let previous, previous != 0 else { return nil }
        return ((latest - previous) / abs(previous)) * 100
    }

    private func employeeCount(from value: String?) -> Int {
        guard let value else { return 0 }
        let digits = value.filter(\.isNumber)
        return Int(digits) ?? 0
    }

    private func normalizedMarketCap(_ marketCap: Double?) -> Double? {
        guard let marketCap else { return nil }
        return marketCap > 1_000_000 ? marketCap / 1_000_000 : marketCap
    }
}
