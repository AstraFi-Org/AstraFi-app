import Foundation

enum StockFactsBuilderError: LocalizedError {
    case unsupportedAsset

    var errorDescription: String? {
        switch self {
        case .unsupportedAsset:
            return "AI stock intelligence is available for stocks only."
        }
    }
}

final class StockFactsBuilder {
    private let profileService: CompanyProfileService
    private let financialService: FinancialService
    private let stockService: StockService
    private let competitorService: CompetitorService
    private let recommendationService: RecommendationService
    private let newsService: NewsService

    init(
        profileService: CompanyProfileService = CompanyProfileService(),
        financialService: FinancialService = FinancialService(),
        stockService: StockService = .shared,
        competitorService: CompetitorService = CompetitorService(),
        recommendationService: RecommendationService = RecommendationService(),
        newsService: NewsService = NewsService()
    ) {
        self.profileService = profileService
        self.financialService = financialService
        self.stockService = stockService
        self.competitorService = competitorService
        self.recommendationService = recommendationService
        self.newsService = newsService
    }

    func buildFacts(for asset: InvestmentSummaryAsset) async throws -> StockFacts {
        guard asset.kind == .stock else { throw StockFactsBuilderError.unsupportedAsset }

        async let profile = profileService.fetch(symbol: asset.symbol)
        async let financials = financialService.fetch(symbol: asset.symbol)
        async let competitors = competitorService.fetch(symbol: asset.symbol)
        async let recommendations = recommendationService.fetch(symbol: asset.symbol)
        async let news = newsService.fetch(symbol: asset.symbol)
        let chartStart = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        async let chartHistory = stockService.fetchStockChartHistory(symbol: asset.symbol, startDate: chartStart)

        let resolvedProfile = await profile
        let resolvedFinancials = await financials
        let resolvedCompetitors = await competitors
        let resolvedRecommendations = await recommendations
        let resolvedNews = await news
        let resolvedChartHistory = await chartHistory

        let buyCount = recommendationCount(in: resolvedRecommendations, labels: ["Strong Buy", "Buy"])
        let holdCount = recommendationCount(in: resolvedRecommendations, labels: ["Hold"])
        let sellCount = recommendationCount(in: resolvedRecommendations, labels: ["Sell", "Strong Sell"])
        let revenueGrowth = resolvedFinancials?.historicalGrowth ?? resolvedFinancials?.quarterlyGrowth
        let profitGrowth: Double? = nil
        var resolvedPeers = resolvedCompetitors.map(\.symbol)
        if resolvedPeers.isEmpty, let verified = CompanyIntelligenceStore.shared.profile(for: asset.symbol) {
            resolvedPeers = verified.operatingSegments.map(\.name)
        }

        let resolvedDesc = resolvedProfile?.whatItDoes
            ?? resolvedProfile?.description
            ?? fallbackDescription(for: asset)

        return StockFacts(
            symbol: asset.symbol,
            companyName: resolvedProfile?.name ?? asset.name,
            sector: resolvedProfile?.sector ?? asset.sector,
            industry: resolvedProfile?.industry ?? asset.sector,
            marketCap: resolvedFinancials?.marketCap,
            employees: nil,
            description: resolvedDesc,
            peRatio: resolvedFinancials?.peRatio,
            roe: resolvedFinancials?.roe,
            debtToEquity: resolvedFinancials?.debtRatio,
            revenueGrowth: revenueGrowth,
            profitGrowth: profitGrowth,
            competitors: resolvedPeers,
            analystBuy: resolvedRecommendations.isEmpty ? nil : buyCount,
            analystHold: resolvedRecommendations.isEmpty ? nil : holdCount,
            analystSell: resolvedRecommendations.isEmpty ? nil : sellCount,
            latestNews: resolvedNews.prefix(5).map { $0.headline },
            priceHistory: resolvedChartHistory.compactMap { Double($0.nav) }.suffix(30).map { $0 }
        )
    }

    private func recommendationCount(in trends: [RecommendationTrend], labels: Set<String>) -> Int {
        trends
            .filter { labels.contains($0.label) }
            .reduce(0) { $0 + $1.count }
    }

    private func fallbackDescription(for asset: InvestmentSummaryAsset) -> String {
        var details = "\(asset.name) (\(asset.symbol))"
        if !asset.sector.isEmpty {
            details += " operates in the \(asset.sector) sector"
        }
        if !asset.metadata.isEmpty {
            details += " listed on \(asset.metadata)"
        }
        details += ". Detailed business filings should be reviewed through official regulatory exchange disclosures."
        return details
    }
}
