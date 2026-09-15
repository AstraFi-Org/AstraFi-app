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
    @ObservationIgnored private var searchGeneration = 0

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
        searchGeneration += 1
        let generation = searchGeneration
        guard trimmed.count >= 2 else {
            results = []
            isSearching = false
            return
        }

        isSearching = true
        let matchingResults = await searchService.search(query: trimmed)

        // A network-backed search is launched for each keystroke. Ignore an older
        // request that completes after a newer query, rather than replacing the
        // current results with stale matches.
        guard generation == searchGeneration,
              query.trimmingCharacters(in: .whitespacesAndNewlines) == trimmed else { return }
        results = matchingResults
        isSearching = false
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

@Observable
final class InvestmentCategoryListViewModel {
    let kind: IntelligenceAssetKind
    var initialAssets: [InvestmentSummaryAsset]
    var categoryAssets: [InvestmentSummaryAsset] = []
    var searchResults: [InvestmentSummaryAsset] = []
    var selectedFilter: String = "All"
    var searchText: String = ""
    var isLoading = false
    var isSearching = false

    private let repository: InvestmentIntelligenceRepository
    @ObservationIgnored private var searchGeneration = 0

    var availableFilters: [String] {
        switch kind {
        case .stock:
            return ["All", "Banking", "IT", "Automobile", "FMCG", "Healthcare", "Energy", "Metals", "Consumer", "Beverages", "US Tech"]
        case .mutualFund:
            return ["All", "Large Cap", "Mid Cap", "Small Cap", "Flexi Cap", "Index Fund", "ELSS", "Debt"]
        case .goldETF:
            return ["All", "Gold", "Silver"]
        }
    }

    var displayAssets: [InvestmentSummaryAsset] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.count >= 2 {
            return searchResults
        }

        let baseList = categoryAssets.isEmpty ? initialAssets : categoryAssets
        if selectedFilter == "All" {
            return baseList
        }

        switch kind {
        case .stock:
            return baseList.filter { $0.sector.localizedCaseInsensitiveContains(selectedFilter) }
        case .mutualFund:
            return baseList.filter { $0.sector.localizedCaseInsensitiveContains(selectedFilter) }
        case .goldETF:
            return baseList.filter { $0.name.localizedCaseInsensitiveContains(selectedFilter) || $0.symbol.localizedCaseInsensitiveContains(selectedFilter) }
        }
    }

    init(kind: IntelligenceAssetKind, initialAssets: [InvestmentSummaryAsset] = [], repository: InvestmentIntelligenceRepository = InvestmentIntelligenceRepository()) {
        self.kind = kind
        self.initialAssets = initialAssets
        self.categoryAssets = initialAssets
        self.repository = repository
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let assets = await repository.categoryAssets(kind: kind, filter: selectedFilter == "All" ? nil : selectedFilter)
        categoryAssets = assets
    }

    func selectFilter(_ filter: String) async {
        selectedFilter = filter
        if kind == .mutualFund && searchText.isEmpty {
            isLoading = true
            defer { isLoading = false }
            categoryAssets = await repository.categoryAssets(kind: kind, filter: filter == "All" ? nil : filter)
        }
    }

    func performSearch() async {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        searchGeneration += 1
        let generation = searchGeneration

        guard trimmed.count >= 2 else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true
        let results = await repository.searchCategory(kind: kind, query: trimmed)

        guard generation == searchGeneration,
              searchText.trimmingCharacters(in: .whitespacesAndNewlines) == trimmed else { return }
        searchResults = results
        isSearching = false
    }
}

