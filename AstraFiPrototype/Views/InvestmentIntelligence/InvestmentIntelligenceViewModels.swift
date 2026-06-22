import Foundation
import Observation

@Observable
final class InvestmentIntelligenceHomeViewModel {
    var stocks: [InvestmentSummaryAsset] = []
    var mutualFunds: [InvestmentSummaryAsset] = []
    var goldETFs: [InvestmentSummaryAsset] = []
    var isLoading = false
    var errorMessage: String?

    private let repository: InvestmentIntelligenceRepository

    init(repository: InvestmentIntelligenceRepository = InvestmentIntelligenceRepository()) {
        self.repository = repository
        loadSeedData()
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let assets = await repository.homeAssets()
        stocks = assets.stocks.isEmpty ? stocks : assets.stocks
        mutualFunds = assets.funds.isEmpty ? mutualFunds : assets.funds
        goldETFs = assets.gold.isEmpty ? goldETFs : assets.gold
    }

    private func loadSeedData() {
        stocks = [
            seedStock("HDFCBANK.NS", "HDFC Bank", "Banking", 1680, 0.42),
            seedStock("TCS.NS", "TCS", "IT", 3520, -0.34),
            seedStock("HINDUNILVR.NS", "Hindustan Unilever", "FMCG", 2460, 0.18),
            seedStock("SUNPHARMA.NS", "Sun Pharma", "Healthcare", 1520, 0.64),
            seedStock("RELIANCE.NS", "Reliance", "Energy", 2450, 0.52),
            seedStock("NTPC.NS", "NTPC", "Power", 365, 1.1),
            seedStock("MARUTI.NS", "Maruti Suzuki", "Automobile", 12200, -0.22)
        ]

        mutualFunds = [
            seedFund("mf-large", "Large Cap Fund", "Large Cap", 82.4, 11.2, .moderate),
            seedFund("mf-flexi", "Flexi Cap Fund", "Flexi Cap", 64.8, 14.5, .moderate),
            seedFund("mf-mid", "Mid Cap Fund", "Mid Cap", 118.2, 18.1, .high),
            seedFund("mf-small", "Small Cap Fund", "Small Cap", 151.7, 22.6, .high),
            seedFund("mf-index", "Nifty Index Fund", "Index Fund", 42.3, 12.8, .moderate),
            seedFund("mf-gold", "Gold Fund", "Gold Fund", 29.6, 13.4, .moderate)
        ]

        goldETFs = [
            seedGold("GOLDBEES.NS", "Nippon India Gold ETF"),
            seedGold("HDFCGOLD.NS", "HDFC Gold ETF"),
            seedGold("SETFGOLD.NS", "SBI Gold ETF"),
            seedGold("ICICIGOLD.NS", "ICICI Gold ETF")
        ]
    }

    private func seedStock(_ symbol: String, _ name: String, _ sector: String, _ price: Double, _ change: Double) -> InvestmentSummaryAsset {
        InvestmentSummaryAsset(
            id: "stock-\(symbol)",
            kind: .stock,
            symbol: symbol,
            name: name,
            sector: sector,
            currentValue: price,
            dailyChange: change,
            oneYearReturn: nil,
            riskLevel: .moderate,
            sparkline: SearchService.seedSparkline(base: price),
            metadata: "NSE"
        )
    }

    private func seedFund(_ id: String, _ name: String, _ category: String, _ nav: Double, _ oneYearReturn: Double, _ risk: IntelligenceRiskLevel) -> InvestmentSummaryAsset {
        InvestmentSummaryAsset(
            id: id,
            kind: .mutualFund,
            symbol: id.replacingOccurrences(of: "mf-", with: ""),
            name: name,
            sector: category,
            currentValue: nav,
            dailyChange: nil,
            oneYearReturn: oneYearReturn,
            riskLevel: risk,
            sparkline: SearchService.seedSparkline(base: nav),
            metadata: "AMFI"
        )
    }

    private func seedGold(_ symbol: String, _ name: String) -> InvestmentSummaryAsset {
        InvestmentSummaryAsset(
            id: "gold-\(symbol)",
            kind: .goldETF,
            symbol: symbol,
            name: name,
            sector: "Gold ETF",
            currentValue: nil,
            dailyChange: nil,
            oneYearReturn: nil,
            riskLevel: .moderate,
            sparkline: SearchService.seedSparkline(base: 62),
            metadata: "NSE"
        )
    }
}

@Observable
final class InvestmentSearchViewModel {
    var query = ""
    var results: [InvestmentSummaryAsset] = []
    var recentSearches: [InvestmentSummaryAsset] = []
    var trendingStocks: [InvestmentSummaryAsset] = []
    var popularFunds: [InvestmentSummaryAsset] = []
    var topGoldETFs: [InvestmentSummaryAsset] = []
    var isSearching = false

    private let searchService: SearchService
    private let homeRepository: InvestmentIntelligenceRepository

    init(searchService: SearchService = SearchService(), homeRepository: InvestmentIntelligenceRepository = InvestmentIntelligenceRepository()) {
        self.searchService = searchService
        self.homeRepository = homeRepository
    }

    func loadDiscovery() async {
        let assets = await homeRepository.homeAssets()
        trendingStocks = assets.stocks
        popularFunds = assets.funds
        topGoldETFs = assets.gold
    }

    func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            results = []
            return
        }

        isSearching = true
        defer { isSearching = false }
        results = await searchService.search(query: trimmed)
    }

    func recordRecent(_ asset: InvestmentSummaryAsset) {
        recentSearches.removeAll { $0.id == asset.id }
        recentSearches.insert(asset, at: 0)
        recentSearches = Array(recentSearches.prefix(6))
    }
}

@Observable
final class InvestmentDetailViewModel {
    var snapshot: InvestmentDetailSnapshot?
    var isLoading = false
    var selectedTab: InvestmentDetailTab = .overview

    let asset: InvestmentSummaryAsset
    private let repository: InvestmentIntelligenceRepository

    init(asset: InvestmentSummaryAsset, repository: InvestmentIntelligenceRepository = InvestmentIntelligenceRepository()) {
        self.asset = asset
   	    self.repository = repository
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        snapshot = await repository.detail(for: asset)
    }
}

enum InvestmentDetailTab: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case financials = "Financials"
    case competition = "Competition"
    case news = "News"
    case insights = "Insights"
    case faq = "FAQ"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .overview: return "rectangle.grid.2x2.fill"
        case .financials: return "chart.bar.xaxis"
        case .competition: return "person.3.fill"
        case .news: return "newspaper.fill"
        case .insights: return "lightbulb.fill"
        case .faq: return "questionmark.circle.fill"
        }
    }
}
