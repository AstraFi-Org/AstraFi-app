import Foundation
import Observation

struct AstraStock: Identifiable, Codable, Hashable {
    var id = UUID()
    var symbol: String
    var name: String
    var exchange: String
    var currentPrice: Double
    var priceChange: Double
    var priceChangePercentage: Double
}

class StockService {
    static let shared = StockService()
    
    private let baseURL = "https://finnhub.io/api/v1"
    private var apiKey: String { Secrets.finnhubApiKey }
    
    // Fallback data
    private var mockStocks: [AstraStock] = [
        AstraStock(symbol: "RELIANCE.NS", name: "Reliance Industries Ltd", exchange: "NSE", currentPrice: 2450.50, priceChange: 15.20, priceChangePercentage: 0.62),
        AstraStock(symbol: "TCS.NS", name: "Tata Consultancy Services", exchange: "NSE", currentPrice: 3520.00, priceChange: -25.50, priceChangePercentage: -0.72),
        AstraStock(symbol: "HDFCBANK.NS", name: "HDFC Bank Ltd", exchange: "NSE", currentPrice: 1680.75, priceChange: 4.30, priceChangePercentage: 0.26),
        AstraStock(symbol: "AAPL", name: "Apple Inc", exchange: "NASDAQ", currentPrice: 185.20, priceChange: 1.25, priceChangePercentage: 0.68)
    ]

    // Bug 4b Fix: Map user-friendly symbols to Finnhub format
    // Finnhub uses "NSE:RELIANCE" not "RELIANCE.NS"
    private func toFinnhubSymbol(_ symbol: String) -> String {
        if symbol.hasSuffix(".NS") {
            return "NSE:" + symbol.dropLast(3)
        }
        if symbol.hasSuffix(".BO") {
            return "BSE:" + symbol.dropLast(3)
        }
        return symbol
    }

    // Yahoo Finance symbol: RELIANCE.NS stays as-is, AAPL stays as-is
    private func toYahooSymbol(_ symbol: String) -> String {
        return symbol // Yahoo already uses .NS / .BO suffixes
    }
    
    func searchStocks(query: String) async -> [AstraStock] {
        if query.isEmpty { return [] }
        if apiKey.isEmpty {
            let q = query.lowercased()
            return mockStocks.map { (stock: $0, score: SearchUtility.fuzzyMatchScore(query: q, target: $0.name) + SearchUtility.fuzzyMatchScore(query: q, target: $0.symbol)) }
                .filter { $0.score > 0.5 }
                .sorted { $0.score > $1.score }
                .map { $0.stock }
        }
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(baseURL)/search?q=\(encodedQuery)&token=\(apiKey)"
        guard let url = URL(string: urlString) else { return [] }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(FinnhubSearchResponse.self, from: data)
            
            return response.result.map { item in
                AstraStock(
                    symbol: item.symbol,
                    name: item.description,
                    exchange: item.type,
                    currentPrice: 0,
                    priceChange: 0,
                    priceChangePercentage: 0
                )
            }
        } catch {
            print("Finnhub Search Error: \(error)")
            let q = query.lowercased()
            return mockStocks.map { (stock: $0, score: SearchUtility.fuzzyMatchScore(query: q, target: $0.name) + SearchUtility.fuzzyMatchScore(query: q, target: $0.symbol)) }
                .filter { $0.score > 0.5 }
                .sorted { $0.score > $1.score }
                .map { $0.stock }
        }
    }
    
    func fetchPrice(symbol: String) async -> AstraStock? {
        if apiKey.isEmpty {
            return await fetchPriceFromYahoo(symbol: symbol)
        }

        let finnhubSymbol = toFinnhubSymbol(symbol)
        let urlString = "\(baseURL)/quote?symbol=\(finnhubSymbol)&token=\(apiKey)"
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Finnhub Quote Response for \(finnhubSymbol): \(jsonString)")
            }
            
            let quote = try JSONDecoder().decode(FinnhubQuote.self, from: data)
            let price = quote.c ?? 0

            // If Finnhub returns 0 (symbol not found / free plan limit), try Yahoo Finance
            if price == 0 {
                return await fetchPriceFromYahoo(symbol: symbol)
            }

            return AstraStock(
                symbol: symbol,
                name: symbol,
                exchange: "Market",
                currentPrice: price,
                priceChange: quote.d ?? 0,
                priceChangePercentage: quote.dp ?? 0
            )
        } catch {
            print("Finnhub Quote Error: \(error) — falling back to Yahoo Finance")
            return await fetchPriceFromYahoo(symbol: symbol)
        }
    }

    // Bug 4a Fix: Yahoo Finance fallback for live price
    private func fetchPriceFromYahoo(symbol: String) async -> AstraStock? {
        let yahooSymbol = toYahooSymbol(symbol)
        guard let encoded = yahooSymbol.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(encoded)?interval=1d&range=1d") else {
            return mockStocks.first { $0.symbol == symbol }
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(YahooChartResponse.self, from: data)
            if let result = response.chart.result?.first,
               let price = result.meta.regularMarketPrice,
               price > 0 {
                let change = result.meta.regularMarketChange ?? 0
                let changePct = result.meta.regularMarketChangePercent ?? 0
                return AstraStock(
                    symbol: symbol,
                    name: result.meta.shortName ?? symbol,
                    exchange: result.meta.exchangeName ?? "Market",
                    currentPrice: price,
                    priceChange: change,
                    priceChangePercentage: changePct
                )
            }
        } catch {
            print("Yahoo Finance Quote Error: \(error)")
        }
        return mockStocks.first { $0.symbol == symbol }
    }

    // Bug 4a Fix: Use Yahoo Finance for historical prices (free, no paid plan needed)
    func fetchHistoricalPrice(symbol: String, date: Date) async -> Double? {
        let yahooSymbol = toYahooSymbol(symbol)
        // Use a 5-day window to handle weekends and market holidays
        let from = Int(date.timeIntervalSince1970) - (4 * 86400)
        let to   = Int(date.timeIntervalSince1970) + (2 * 86400)

        guard let encoded = yahooSymbol.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(encoded)?interval=1d&period1=\(from)&period2=\(to)") else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(YahooChartResponse.self, from: data)
            if let result = response.chart.result?.first,
               let closes = result.indicators?.quote?.first?.close {
                // Return the last available close price in the window (closest to the requested date)
                let validCloses = closes.compactMap { $0 }
                return validCloses.last
            }
        } catch {
            print("Yahoo Finance Historical Price Error for \(symbol): \(error)")
        }

        // Final fallback: use current live price as approximation
        return await fetchPriceFromYahoo(symbol: symbol).map { $0.currentPrice }
    }
    
    func calculateLumpsumUnits(symbol: String, amount: Double, startDate: Date) async -> (totalUnits: Double, totalInvested: Double, installments: [AstraInvestmentTransaction]) {
        if let price = await fetchHistoricalPrice(symbol: symbol, date: startDate), price > 0 {
            let units = amount / price
            let tx = AstraInvestmentTransaction(
                date: startDate,
                type: .buy,
                amount: amount,
                nav: price,
                units: units
            )
            return (units, amount, [tx])
        }
        return (0, amount, [])
    }

    /// Fetches daily close prices for a stock from startDate to today.
    /// Returns an array of MFHistoryPoint (date string "dd-MM-yyyy" + nav string) so it's
    /// compatible with the existing chart rendering code in InvestmentDetailView.
    func fetchStockChartHistory(symbol: String, startDate: Date) async -> [MFHistoryPoint] {
        let yahooSymbol = toYahooSymbol(symbol)
        let from = Int(startDate.timeIntervalSince1970)
        let to   = Int(Date().timeIntervalSince1970) + 86400
        guard let encoded = yahooSymbol.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(encoded)?interval=1d&period1=\(from)&period2=\(to)") else {
            return []
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response  = try JSONDecoder().decode(YahooChartResponse.self, from: data)
            guard let result = response.chart.result?.first,
                  let timestamps = result.timestamps,
                  let closes = result.indicators?.quote?.first?.close else { return [] }

            let df = DateFormatter()
            df.dateFormat = "dd-MM-yyyy"
            df.timeZone   = TimeZone(identifier: "UTC")

            var points: [MFHistoryPoint] = []
            for (i, ts) in timestamps.enumerated() {
                guard i < closes.count, let close = closes[i] else { continue }
                let date = Date(timeIntervalSince1970: Double(ts))
                points.append(MFHistoryPoint(date: df.string(from: date), nav: String(format: "%.2f", close)))
            }
            return points
        } catch {
            print("Stock chart history error for \(symbol): \(error)")
            return []
        }
    }

    func calculateHistoricalSIPUnits(symbol: String, monthlyAmount: Double, startDate: Date, frequency: AssessmentInvestmentEntry.AssessmentSIPFrequency = .monthly) async -> (totalUnits: Double, totalInvested: Double, installments: [AstraInvestmentTransaction]) {
        var totalUnits: Double = 0
        var totalInvested: Double = 0
        var installments: [AstraInvestmentTransaction] = []
        
        let calendar = Calendar.current
        let today = Date()
        
        var currentDate = startDate
        var dates: [Date] = []
        
        let component: Calendar.Component
        let value: Int
        
        switch frequency {
        case .weekly:
            component = .weekOfYear
            value = 1
        case .monthly:
            component = .month
            value = 1
        case .quarterly:
            component = .month
            value = 3
        case .yearly:
            component = .year
            value = 1
        }
        
        while currentDate <= today {
            dates.append(currentDate)
            guard let next = calendar.date(byAdding: component, value: value, to: currentDate) else { break }
            currentDate = next
        }
        
        for date in dates {
            if let price = await fetchHistoricalPrice(symbol: symbol, date: date), price > 0 {
                let units = monthlyAmount / price
                totalUnits += units
                totalInvested += monthlyAmount
                
                installments.append(AstraInvestmentTransaction(
                    date: date,
                    type: .buy,
                    amount: monthlyAmount,
                    nav: price,
                    units: units
                ))
            }
        }
        
        return (totalUnits, totalInvested, installments)
    }
    
    func fetchLivePrices(symbols: [String]) async -> [String: Double] {
        var results: [String: Double] = [:]
        for symbol in symbols {
            if let stock = await fetchPrice(symbol: symbol) {
                results[symbol] = stock.currentPrice
            }
        }
        return results
    }

    func fetchBatchQuotes(symbols: [String]) async -> [String: AstraStock] {
        var results: [String: AstraStock] = [:]
        let limitedSymbols = Array(symbols.prefix(15))
        
        await withTaskGroup(of: (String, AstraStock?).self) { group in
            for symbol in limitedSymbols {
                group.addTask {
                    let quote = await self.fetchPrice(symbol: symbol)
                    return (symbol, quote)
                }
            }
            
            for await (symbol, quote) in group {
                if let quote = quote {
                    results[symbol] = quote
                }
            }
        }
        return results
    }
}

// MARK: - Finnhub Models

struct FinnhubQuote: Codable {
    let c: Double?  // Current price
    let d: Double?  // Change
    let dp: Double? // Percent change
    let o: Double?  // Open price of the day
}

struct FinnhubSearchResponse: Codable {
    let count: Int
    let result: [FinnhubSearchItem]
}

struct FinnhubSearchItem: Codable {
    let description: String
    let symbol: String
    let type: String
}

struct FinnhubCandleResponse: Codable {
    let c: [Double]? // Close prices
    let s: String?   // Status
}

// MARK: - Yahoo Finance Models

struct YahooChartResponse: Codable {
    let chart: YahooChart
}

struct YahooChart: Codable {
    let result: [YahooChartResult]?
    let error: YahooError?
}

struct YahooError: Codable {
    let code: String?
    let description: String?
}

struct YahooChartResult: Codable {
    let meta: YahooMeta
    let timestamps: [Int]?
    let indicators: YahooIndicators?

    enum CodingKeys: String, CodingKey {
        case meta
        case timestamps = "timestamp"
        case indicators
    }
}

struct YahooMeta: Codable {
    let regularMarketPrice: Double?
    let regularMarketChange: Double?
    let regularMarketChangePercent: Double?
    let shortName: String?
    let exchangeName: String?
}

struct YahooIndicators: Codable {
    let quote: [YahooQuote]?
}

struct YahooQuote: Codable {
    let close: [Double?]?
}
