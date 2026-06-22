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
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let assets = await repository.homeAssets()
        stocks = assets.stocks
        mutualFunds = assets.funds
        goldETFs = assets.gold
        errorMessage = (stocks.isEmpty && mutualFunds.isEmpty && goldETFs.isEmpty)
            ? "No verified market data loaded. Check FINNHUB_API_KEY, network access, and AMFI availability."
            : nil
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
