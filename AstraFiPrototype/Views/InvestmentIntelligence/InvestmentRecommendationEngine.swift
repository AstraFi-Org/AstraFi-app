import Foundation

final class InvestmentRecommendationEngine {
    static let shared = InvestmentRecommendationEngine()
    private let stockService: StockService

    init(stockService: StockService = .shared) {
        self.stockService = stockService
    }

    func dailyRecommendations(
        from candidates: [InvestmentSummaryAsset],
        date: Date = Date(),
        offset: Int = 0
    ) async -> [InvestmentSummaryAsset] {
        let eligible = candidates
            .filter { $0.kind == .stock && ($0.currentValue ?? 0) > 0 }
            .sorted { $0.symbol < $1.symbol }
        guard !eligible.isEmpty else { return [] }

        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let start = (day - 1 + max(0, offset)) % eligible.count
        let count = min(6, eligible.count)
        let selected = (0..<count).map { eligible[(start + $0) % eligible.count] }
        return await enrichWithLiveQuotes(assets: selected)
    }

    func enrichWithLiveQuotes(assets: [InvestmentSummaryAsset]) async -> [InvestmentSummaryAsset] {
        await withTaskGroup(of: InvestmentSummaryAsset?.self) { group in
            for asset in assets {
                group.addTask {
                    guard let quote = await self.stockService.fetchPrice(symbol: asset.symbol), quote.currentPrice > 0 else { return nil }
                    return SearchService.stockAsset(from: quote, sector: asset.sector)
                }
            }

            var refreshed: [InvestmentSummaryAsset] = []
            for await asset in group {
                if let asset { refreshed.append(asset) }
            }
            return refreshed.sorted { $0.symbol < $1.symbol }
        }
    }
}
