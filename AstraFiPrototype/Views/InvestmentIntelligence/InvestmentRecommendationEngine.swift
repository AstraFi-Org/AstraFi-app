import Foundation

final class InvestmentRecommendationEngine {
    static let shared = InvestmentRecommendationEngine()

    private let stockService: StockService

    init(stockService: StockService = .shared) {
        self.stockService = stockService
    }

    // MARK: - Daily Recommendations
    /// Produces a curated, diverse set of investment recommendations that changes every day.
    /// Incorporates an optional offset for user-initiated shuffle.
    func dailyRecommendations(date: Date = Date(), offset: Int = 0) -> [InvestmentSummaryAsset] {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let year = calendar.component(.year, from: date)
        let seed = abs(year * 365 + dayOfYear + offset * 7)

        var selected: [InvestmentSummaryAsset] = []

        // 1. Pick 3 diverse stocks from different sectors
        let stocksPool = Self.stockCandidates
        if !stocksPool.isEmpty {
            var usedSectors = Set<String>()
            var stockIndices: [Int] = []
            
            // Try pseudo-random deterministic steps
            for i in 0..<stocksPool.count {
                let index = (seed * 11 + i * 13) % stocksPool.count
                let candidate = stocksPool[index]
                if !usedSectors.contains(candidate.sector) && !stockIndices.contains(index) {
                    usedSectors.insert(candidate.sector)
                    stockIndices.append(index)
                    if stockIndices.count == 3 { break }
                }
            }
            // Fallback if sectors were duplicated
            for i in 0..<stocksPool.count where stockIndices.count < 3 {
                let index = (seed + i) % stocksPool.count
                if !stockIndices.contains(index) {
                    stockIndices.append(index)
                }
            }
            for idx in stockIndices {
                selected.append(stocksPool[idx])
            }
        }

        // 2. Pick 2 diverse mutual funds from different categories
        let mfPool = Self.mutualFundCandidates
        if !mfPool.isEmpty {
            var mfIndices: [Int] = []
            var usedCategories = Set<String>()
            for i in 0..<mfPool.count {
                let index = (seed * 7 + i * 17) % mfPool.count
                let candidate = mfPool[index]
                if !usedCategories.contains(candidate.sector) && !mfIndices.contains(index) {
                    usedCategories.insert(candidate.sector)
                    mfIndices.append(index)
                    if mfIndices.count == 2 { break }
                }
            }
            for i in 0..<mfPool.count where mfIndices.count < 2 {
                let index = (seed + i * 3) % mfPool.count
                if !mfIndices.contains(index) {
                    mfIndices.append(index)
                }
            }
            for idx in mfIndices {
                selected.append(mfPool[idx])
            }
        }

        // 3. Pick 1 Gold or Silver ETF
        let etfPool = Self.etfCandidates
        if !etfPool.isEmpty {
            let etfIndex = (seed * 5 + 2) % etfPool.count
            selected.append(etfPool[etfIndex])
        }

        // Interleave nicely: Stock, Fund, Stock, ETF, Stock, Fund
        if selected.count >= 6 {
            return [
                selected[0], // Stock 1 (e.g. Radico Khaitan)
                selected[3], // Mutual Fund 1 (e.g. Parag Parikh Flexi Cap)
                selected[1], // Stock 2 (e.g. Trent)
                selected[5], // ETF (e.g. Silver BeES)
                selected[2], // Stock 3 (e.g. Tata Power)
                selected[4]  // Mutual Fund 2 (e.g. Quant Small Cap)
            ]
        }

        return selected
    }

    /// Asynchronously updates recommendations with real-time live quotes from StockService
    func enrichWithLiveQuotes(assets: [InvestmentSummaryAsset]) async -> [InvestmentSummaryAsset] {
        await withTaskGroup(of: (Int, InvestmentSummaryAsset).self) { group in
            for (index, asset) in assets.enumerated() {
                group.addTask {
                    guard asset.kind == .stock || asset.kind == .goldETF else {
                        return (index, asset)
                    }
                    if let quote = await self.stockService.fetchPrice(symbol: asset.symbol), quote.currentPrice > 0 {
                        var updated = asset
                        updated.currentValue = quote.currentPrice
                        if abs(quote.priceChangePercentage) > 0.0001 {
                            updated.dailyChange = quote.priceChangePercentage
                        }
                        return (index, updated)
                    }
                    return (index, asset)
                }
            }

            var enriched = assets
            for await (index, updatedAsset) in group {
                if index < enriched.count {
                    enriched[index] = updatedAsset
                }
            }
            return enriched
        }
    }

    /// Deterministically rotates an array based on date and offset
    func rotateDaily<T>(items: [T], date: Date = Date(), offset: Int = 0) -> [T] {
        guard items.count > 1 else { return items }
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let year = calendar.component(.year, from: date)
        let seed = abs(year * 365 + dayOfYear + offset * 7)
        let shift = seed % items.count
        return Array(items[shift...] + items[..<shift])
    }

    // MARK: - Curated Candidates Catalog
    private static var stockCandidates: [InvestmentSummaryAsset] = [
        InvestmentSummaryAsset(
            id: "rec-stock-radico",
            kind: .stock,
            symbol: "RADICO.NS",
            name: "Radico Khaitan Ltd",
            sector: "Beverages & Spirits",
            currentValue: 2240,
            dailyChange: 1.45,
            oneYearReturn: nil,
            riskLevel: .moderate,
            sparkline: previewSparkline(base: 2240, moves: [0.8, -0.4, 1.2, 0.5, 1.8, 1.4]),
            metadata: "NSE"
        ),
        InvestmentSummaryAsset(
            id: "rec-stock-zomato",
            kind: .stock,
            symbol: "ZOMATO.NS",
            name: "Zomato Ltd",
            sector: "Consumer Internet",
            currentValue: 268,
            dailyChange: 2.15,
            oneYearReturn: nil,
            riskLevel: .high,
            sparkline: previewSparkline(base: 268, moves: [1.2, 0.8, -1.0, 2.5, 1.4, 2.1]),
            metadata: "NSE"
        ),
        InvestmentSummaryAsset(
            id: "rec-stock-trent",
            kind: .stock,
            symbol: "TRENT.NS",
            name: "Trent Ltd (Westside/Zudio)",
            sector: "Retail & Apparel",
            currentValue: 7120,
            dailyChange: 0.88,
            oneYearReturn: nil,
            riskLevel: .moderate,
            sparkline: previewSparkline(base: 7120, moves: [-0.5, 1.2, 2.0, 0.4, 1.1, 0.9]),
            metadata: "NSE"
        ),
        InvestmentSummaryAsset(
            id: "rec-stock-tatapower",
            kind: .stock,
            symbol: "TATAPOWER.NS",
            name: "Tata Power Co Ltd",
            sector: "Clean Energy & Power",
            currentValue: 432,
            dailyChange: 1.20,
            oneYearReturn: nil,
            riskLevel: .moderate,
            sparkline: previewSparkline(base: 432, moves: [0.4, -0.8, 1.5, 0.9, 1.0, 1.2]),
            metadata: "NSE"
        ),
        InvestmentSummaryAsset(
            id: "rec-stock-polycab",
            kind: .stock,
            symbol: "POLYCAB.NS",
            name: "Polycab India Ltd",
            sector: "Cables & Infrastructure",
            currentValue: 6540,
            dailyChange: -0.42,
            oneYearReturn: nil,
            riskLevel: .moderate,
            sparkline: previewSparkline(base: 6540, moves: [1.1, -0.6, 0.8, -1.2, 0.5, -0.4]),
            metadata: "NSE"
        ),
        InvestmentSummaryAsset(
            id: "rec-stock-bel",
            kind: .stock,
            symbol: "BEL.NS",
            name: "Bharat Electronics Ltd",
            sector: "Defense Electronics",
            currentValue: 295,
            dailyChange: 1.65,
            oneYearReturn: nil,
            riskLevel: .moderate,
            sparkline: previewSparkline(base: 295, moves: [0.5, 1.0, -0.2, 1.8, 0.9, 1.6]),
            metadata: "NSE"
        ),
        InvestmentSummaryAsset(
            id: "rec-stock-hal",
            kind: .stock,
            symbol: "HAL.NS",
            name: "Hindustan Aeronautics",
            sector: "Aerospace & Defense",
            currentValue: 4680,
            dailyChange: 2.40,
            oneYearReturn: nil,
            riskLevel: .moderate,
            sparkline: previewSparkline(base: 4680, moves: [-1.0, 1.5, 2.1, 0.8, 1.9, 2.4]),
            metadata: "NSE"
        ),
        InvestmentSummaryAsset(
            id: "rec-stock-titan",
            kind: .stock,
            symbol: "TITAN.NS",
            name: "Titan Company Ltd",
            sector: "Luxury & Jewellery",
            currentValue: 3480,
            dailyChange: 0.54,
            oneYearReturn: nil,
            riskLevel: .moderate,
            sparkline: previewSparkline(base: 3480, moves: [0.2, 0.7, -0.3, 0.9, 0.1, 0.5]),
            metadata: "NSE"
        ),
        InvestmentSummaryAsset(
            id: "rec-stock-sunpharma",
            kind: .stock,
            symbol: "SUNPHARMA.NS",
            name: "Sun Pharma Industries",
            sector: "Pharmaceuticals",
            currentValue: 1820,
            dailyChange: 0.95,
            oneYearReturn: nil,
            riskLevel: .moderate,
            sparkline: previewSparkline(base: 1820, moves: [0.6, 0.4, 1.1, -0.5, 1.3, 0.9]),
            metadata: "NSE"
        ),
        InvestmentSummaryAsset(
            id: "rec-stock-vbl",
            kind: .stock,
            symbol: "VBL.NS",
            name: "Varun Beverages Ltd",
            sector: "Consumer Beverages",
            currentValue: 620,
            dailyChange: 1.10,
            oneYearReturn: nil,
            riskLevel: .moderate,
            sparkline: previewSparkline(base: 620, moves: [0.4, 0.9, -0.2, 1.5, 0.8, 1.1]),
            metadata: "NSE"
        ),
        InvestmentSummaryAsset(
            id: "rec-stock-tatamotors",
            kind: .stock,
            symbol: "TATAMOTORS.NS",
            name: "Tata Motors Ltd",
            sector: "Automobile & EV",
            currentValue: 980,
            dailyChange: -0.85,
            oneYearReturn: nil,
            riskLevel: .moderate,
            sparkline: previewSparkline(base: 980, moves: [1.4, -0.5, 0.8, -1.1, 0.2, -0.8]),
            metadata: "NSE"
        ),
        InvestmentSummaryAsset(
            id: "rec-stock-hdfcbank",
            kind: .stock,
            symbol: "HDFCBANK.NS",
            name: "HDFC Bank Ltd",
            sector: "Banking & Finance",
            currentValue: 1680,
            dailyChange: 0.45,
            oneYearReturn: nil,
            riskLevel: .low,
            sparkline: previewSparkline(base: 1680, moves: [0.3, 0.8, -0.2, 0.6, 0.1, 0.4]),
            metadata: "NSE"
        ),
        InvestmentSummaryAsset(
            id: "rec-stock-tcs",
            kind: .stock,
            symbol: "TCS.NS",
            name: "Tata Consultancy Services",
            sector: "IT Services",
            currentValue: 3520,
            dailyChange: -0.34,
            oneYearReturn: nil,
            riskLevel: .low,
            sparkline: previewSparkline(base: 3520, moves: [-1.4, 0.8, 1.2, -0.5, 1.7, -0.3]),
            metadata: "NSE"
        ),
        InvestmentSummaryAsset(
            id: "rec-stock-reliance",
            kind: .stock,
            symbol: "RELIANCE.NS",
            name: "Reliance Industries",
            sector: "Energy & Retail",
            currentValue: 2896,
            dailyChange: 0.62,
            oneYearReturn: nil,
            riskLevel: .moderate,
            sparkline: previewSparkline(base: 2896, moves: [0.5, 1.1, -0.4, 0.9, 1.3, 0.6]),
            metadata: "NSE"
        ),
        InvestmentSummaryAsset(
            id: "rec-stock-nvda",
            kind: .stock,
            symbol: "NVDA",
            name: "NVIDIA Corporation",
            sector: "AI & Semiconductors",
            currentValue: 118,
            dailyChange: 3.20,
            oneYearReturn: nil,
            riskLevel: .high,
            sparkline: previewSparkline(base: 118, moves: [2.0, -1.1, 4.5, 1.2, 2.8, 3.2]),
            metadata: "NASDAQ"
        )
    ]

    private static var mutualFundCandidates: [InvestmentSummaryAsset] = [
        InvestmentSummaryAsset(
            id: "rec-mf-parag-parikh",
            kind: .mutualFund,
            symbol: "122639",
            name: "Parag Parikh Flexi Cap Fund",
            sector: "Flexi Cap",
            currentValue: 82.45,
            dailyChange: nil,
            oneYearReturn: 24.8,
            riskLevel: .moderate,
            sparkline: previewSparkline(base: 82.45, moves: [0.5, 0.8, 1.2, 0.9, 1.4, 1.1]),
            metadata: "AMFI"
        ),
        InvestmentSummaryAsset(
            id: "rec-mf-quant-small",
            kind: .mutualFund,
            symbol: "120828",
            name: "Quant Small Cap Fund",
            sector: "Small Cap",
            currentValue: 268.30,
            dailyChange: nil,
            oneYearReturn: 38.2,
            riskLevel: .high,
            sparkline: previewSparkline(base: 268.30, moves: [1.2, -0.6, 2.4, 1.8, -0.5, 2.1]),
            metadata: "AMFI"
        ),
        InvestmentSummaryAsset(
            id: "rec-mf-nippon-small",
            kind: .mutualFund,
            symbol: "118778",
            name: "Nippon India Small Cap Fund",
            sector: "Small Cap",
            currentValue: 174.50,
            dailyChange: nil,
            oneYearReturn: 32.6,
            riskLevel: .high,
            sparkline: previewSparkline(base: 174.50, moves: [0.8, 1.4, 1.0, -0.4, 1.8, 1.5]),
            metadata: "AMFI"
        ),
        InvestmentSummaryAsset(
            id: "rec-mf-mirae-large-mid",
            kind: .mutualFund,
            symbol: "118834",
            name: "Mirae Asset Large & Midcap",
            sector: "Large & Mid Cap",
            currentValue: 142.10,
            dailyChange: nil,
            oneYearReturn: 21.4,
            riskLevel: .moderate,
            sparkline: previewSparkline(base: 142.10, moves: [0.6, 0.9, 0.4, 1.1, 0.8, 1.2]),
            metadata: "AMFI"
        ),
        InvestmentSummaryAsset(
            id: "rec-mf-hdfc-flexi",
            kind: .mutualFund,
            symbol: "100033",
            name: "HDFC Flexi Cap Fund",
            sector: "Flexi Cap",
            currentValue: 1940.20,
            dailyChange: nil,
            oneYearReturn: 26.1,
            riskLevel: .moderate,
            sparkline: previewSparkline(base: 1940.20, moves: [0.7, 1.1, 0.3, 1.4, 0.9, 1.0]),
            metadata: "AMFI"
        ),
        InvestmentSummaryAsset(
            id: "rec-mf-sbi-contra",
            kind: .mutualFund,
            symbol: "100377",
            name: "SBI Contra Fund",
            sector: "Contra / Value",
            currentValue: 412.80,
            dailyChange: nil,
            oneYearReturn: 29.5,
            riskLevel: .moderate,
            sparkline: previewSparkline(base: 412.80, moves: [1.0, 0.5, 1.3, -0.2, 1.5, 1.2]),
            metadata: "AMFI"
        ),
        InvestmentSummaryAsset(
            id: "rec-mf-uti-nifty50",
            kind: .mutualFund,
            symbol: "100412",
            name: "UTI Nifty 50 Index Fund",
            sector: "Index Fund",
            currentValue: 184.60,
            dailyChange: nil,
            oneYearReturn: 16.8,
            riskLevel: .moderate,
            sparkline: previewSparkline(base: 184.60, moves: [0.4, 0.7, 0.2, 0.9, -0.1, 0.8]),
            metadata: "AMFI"
        ),
        InvestmentSummaryAsset(
            id: "rec-mf-aditya-birla",
            kind: .mutualFund,
            symbol: "119436",
            name: "Aditya Birla Large & Mid Cap",
            sector: "Large & Mid Cap",
            currentValue: 1043,
            dailyChange: nil,
            oneYearReturn: 18.4,
            riskLevel: .moderate,
            sparkline: previewSparkline(base: 1043, moves: [0.6, 0.8, 1.0, -0.2, 1.1, 1.4]),
            metadata: "AMFI"
        )
    ]

    private static var etfCandidates: [InvestmentSummaryAsset] = [
        InvestmentSummaryAsset(
            id: "rec-etf-silverbees",
            kind: .goldETF,
            symbol: "SILVERBEES.NS",
            name: "Nippon India Silver BeES",
            sector: "Silver ETF",
            currentValue: 88.5,
            dailyChange: 1.85,
            oneYearReturn: nil,
            riskLevel: .moderate,
            sparkline: previewSparkline(base: 88.5, moves: [0.8, 1.5, -0.4, 2.1, 1.2, 1.8]),
            metadata: "NSE"
        ),
        InvestmentSummaryAsset(
            id: "rec-etf-goldbees",
            kind: .goldETF,
            symbol: "GOLDBEES.NS",
            name: "Nippon India Gold BeES",
            sector: "Gold ETF",
            currentValue: 68.4,
            dailyChange: 0.38,
            oneYearReturn: nil,
            riskLevel: .low,
            sparkline: previewSparkline(base: 68.4, moves: [0.2, 0.5, -0.1, 0.7, 0.4, 0.9]),
            metadata: "NSE"
        ),
        InvestmentSummaryAsset(
            id: "rec-etf-hdfcsilver",
            kind: .goldETF,
            symbol: "HDFCSILVER.NS",
            name: "HDFC Silver ETF",
            sector: "Silver ETF",
            currentValue: 89.1,
            dailyChange: 1.72,
            oneYearReturn: nil,
            riskLevel: .moderate,
            sparkline: previewSparkline(base: 89.1, moves: [0.6, 1.4, -0.3, 1.9, 1.0, 1.7]),
            metadata: "NSE"
        ),
        InvestmentSummaryAsset(
            id: "rec-etf-hdfcgold",
            kind: .goldETF,
            symbol: "HDFCGOLD.NS",
            name: "HDFC Gold ETF",
            sector: "Gold ETF",
            currentValue: 69.1,
            dailyChange: 0.24,
            oneYearReturn: nil,
            riskLevel: .low,
            sparkline: previewSparkline(base: 69.1, moves: [-0.1, 0.3, 0.6, 0.2, 0.5, 0.2]),
            metadata: "NSE"
        ),
        InvestmentSummaryAsset(
            id: "rec-etf-tatagold",
            kind: .goldETF,
            symbol: "TATAGOLD.NS",
            name: "Tata Gold ETF",
            sector: "Gold ETF",
            currentValue: 12.8,
            dailyChange: 0.45,
            oneYearReturn: nil,
            riskLevel: .low,
            sparkline: previewSparkline(base: 12.8, moves: [0.1, 0.4, 0.3, 0.5, 0.2, 0.4]),
            metadata: "NSE"
        ),
        InvestmentSummaryAsset(
            id: "rec-etf-setfgold",
            kind: .goldETF,
            symbol: "SETFGOLD.NS",
            name: "SBI Gold ETF",
            sector: "Gold ETF",
            currentValue: 67.9,
            dailyChange: 0.30,
            oneYearReturn: nil,
            riskLevel: .low,
            sparkline: previewSparkline(base: 67.9, moves: [0.2, 0.3, 0.1, 0.6, 0.3, 0.3]),
            metadata: "NSE"
        )
    ]

    private static func previewSparkline(base: Double, moves: [Double]) -> [InvestmentChartPoint] {
        let calendar = Calendar.current
        return moves.enumerated().map { index, move in
            let date = calendar.date(byAdding: .day, value: index - moves.count + 1, to: Date()) ?? Date()
            return InvestmentChartPoint(date: date, value: base * (1 + move / 100))
        }
    }
}
