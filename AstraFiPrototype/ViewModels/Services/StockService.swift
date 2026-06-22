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
    
    // Local search seeds keep common NSE symbols discoverable even when a remote
    // provider's search API does not return Indian equities reliably.
    private var mockStocks: [AstraStock] = [
        AstraStock(symbol: "RADICO.NS", name: "Radico Khaitan Ltd", exchange: "NSE", currentPrice: 0, priceChange: 0, priceChangePercentage: 0),
        AstraStock(symbol: "RELIANCE.NS", name: "Reliance Industries Ltd", exchange: "NSE", currentPrice: 2450.50, priceChange: 15.20, priceChangePercentage: 0.62),
        AstraStock(symbol: "TCS.NS", name: "Tata Consultancy Services", exchange: "NSE", currentPrice: 3520.00, priceChange: -25.50, priceChangePercentage: -0.72),
        AstraStock(symbol: "HDFCBANK.NS", name: "HDFC Bank Ltd", exchange: "NSE", currentPrice: 1680.75, priceChange: 4.30, priceChangePercentage: 0.26),
        AstraStock(symbol: "INFY.NS", name: "Infosys Ltd", exchange: "NSE", currentPrice: 0, priceChange: 0, priceChangePercentage: 0),
        AstraStock(symbol: "ICICIBANK.NS", name: "ICICI Bank Ltd", exchange: "NSE", currentPrice: 0, priceChange: 0, priceChangePercentage: 0),
        AstraStock(symbol: "BAJFINANCE.NS", name: "Bajaj Finance Ltd", exchange: "NSE", currentPrice: 0, priceChange: 0, priceChangePercentage: 0),
        AstraStock(symbol: "BHARTIARTL.NS", name: "Bharti Airtel Ltd", exchange: "NSE", currentPrice: 0, priceChange: 0, priceChangePercentage: 0),
        AstraStock(symbol: "HINDUNILVR.NS", name: "Hindustan Unilever Ltd", exchange: "NSE", currentPrice: 0, priceChange: 0, priceChangePercentage: 0),
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
        return normalizeSearchSymbol(symbol)
    }
    
    func searchStocks(query: String) async -> [AstraStock] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.count >= 2 else { return [] }

        let localResults = searchLocalStocks(query: trimmedQuery)
        let yahooResults = await searchYahooStocks(query: trimmedQuery)
        let finnhubResults = apiKey.isEmpty ? [] : await searchFinnhubStocks(query: trimmedQuery)

        return mergeSearchResults([localResults, yahooResults, finnhubResults])
    }

    func searchGoldETFs(query: String) async -> [AstraStock] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.count >= 2 else { return [] }

        let remoteResults = await searchStocks(query: trimmedQuery)
        let q = trimmedQuery.lowercased()
        let filteredResults = remoteResults.filter { stock in
            let searchable = "\(stock.symbol) \(stock.name)".lowercased()
            return searchable.contains("gold") ||
                   searchable.contains("goldbees") ||
                   searchable.contains("setfgold") ||
                   q.contains("gold")
        }

        return filteredResults
    }

    func searchCryptoSymbols(query: String) async -> [AstraStock] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }

        let q = trimmedQuery.uppercased()
        guard let url = URL(string: "https://api.binance.com/api/v3/exchangeInfo") else {
            return []
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(BinanceExchangeInfoResponse.self, from: data)
            let results = response.symbols
                .filter { symbol in
                    symbol.status == "TRADING" &&
                    symbol.quoteAsset == "USDT" &&
                    (
                        symbol.symbol.contains(q) ||
                        symbol.baseAsset.contains(q) ||
                        cryptoDisplayName(for: symbol.baseAsset).uppercased().contains(q)
                    )
                }
                .prefix(30)
                .map { symbol in
                    AstraStock(
                        symbol: "BINANCE:\(symbol.symbol)",
                        name: cryptoDisplayName(for: symbol.baseAsset),
                        exchange: "Binance",
                        currentPrice: 0,
                        priceChange: 0,
                        priceChangePercentage: 0
                    )
                }

            return mergeSearchResults([Array(results)])
        } catch {
            print("Binance crypto search error: \(error)")
            return []
        }
    }

    private func searchFinnhubStocks(query: String) async -> [AstraStock] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(baseURL)/search?q=\(encodedQuery)&token=\(apiKey)"
        guard let url = URL(string: urlString) else { return [] }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(FinnhubSearchResponse.self, from: data)
            
            return response.result.compactMap { item in
                let symbol = normalizeSearchSymbol(item.symbol, exchangeHint: item.type)
                guard !symbol.isEmpty else { return nil }
                return AstraStock(
                    symbol: symbol,
                    name: item.description.isEmpty ? symbol : item.description,
                    exchange: exchangeName(for: symbol, fallback: item.type),
                    currentPrice: 0,
                    priceChange: 0,
                    priceChangePercentage: 0
                )
            }
        } catch {
            print("Finnhub Search Error: \(error)")
            return []
        }
    }

    private func searchYahooStocks(query: String) async -> [AstraStock] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://query1.finance.yahoo.com/v1/finance/search?q=\(encodedQuery)&quotesCount=20&newsCount=0&enableFuzzyQuery=true&quotesQueryId=tss_match_phrase_query") else {
            return []
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(YahooSearchResponse.self, from: data)

            return response.quotes.compactMap { quote in
                guard let rawSymbol = quote.symbol, !rawSymbol.isEmpty else { return nil }
                let symbol = normalizeSearchSymbol(rawSymbol, exchangeHint: quote.exchDisp ?? quote.exchange ?? "")
                let name = quote.longname ?? quote.shortname ?? symbol
                guard isSupportedSearchResult(symbol: symbol, name: name, query: query) else { return nil }

                return AstraStock(
                    symbol: symbol,
                    name: name,
                    exchange: exchangeName(for: symbol, fallback: quote.exchDisp ?? quote.exchange ?? "Market"),
                    currentPrice: 0,
                    priceChange: 0,
                    priceChangePercentage: 0
                )
            }
        } catch {
            print("Yahoo Search Error: \(error)")
            return []
        }
    }

    private func searchLocalStocks(query: String) -> [AstraStock] {
        let q = query.lowercased()
        return mockStocks
            .map { stock in
                let normalizedSymbol = stock.symbol.replacingOccurrences(of: ".NS", with: "").replacingOccurrences(of: ".BO", with: "")
                let score =
                    SearchUtility.fuzzyMatchScore(query: q, target: stock.name) +
                    SearchUtility.fuzzyMatchScore(query: q, target: stock.symbol) +
                    SearchUtility.fuzzyMatchScore(query: q, target: normalizedSymbol)
                return (stock: stock, score: score)
            }
            .filter { $0.score > 0.5 }
            .sorted { $0.score > $1.score }
            .map { $0.stock }
    }

    private func mergeSearchResults(_ resultGroups: [[AstraStock]]) -> [AstraStock] {
        var seenSymbols = Set<String>()
        var merged: [AstraStock] = []

        for stock in resultGroups.flatMap({ $0 }) {
            let symbol = normalizeSearchSymbol(stock.symbol)
            guard !symbol.isEmpty, !seenSymbols.contains(symbol) else { continue }
            seenSymbols.insert(symbol)
            merged.append(AstraStock(
                symbol: symbol,
                name: stock.name,
                exchange: exchangeName(for: symbol, fallback: stock.exchange),
                currentPrice: stock.currentPrice.safeFinite,
                priceChange: stock.priceChange.safeFinite,
                priceChangePercentage: stock.priceChangePercentage.safeFinite
            ))
        }

        return merged
    }

    private func normalizeSearchSymbol(_ symbol: String, exchangeHint: String = "") -> String {
        let trimmed = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmed.isEmpty else { return "" }

        if trimmed.hasPrefix("NSE:") {
            return "\(trimmed.dropFirst(4)).NS"
        }
        if trimmed.hasPrefix("BSE:") {
            return "\(trimmed.dropFirst(4)).BO"
        }
        if trimmed.hasSuffix(".NS") || trimmed.hasSuffix(".BO") || trimmed.contains(".") {
            return trimmed
        }

        let hint = exchangeHint.lowercased()
        if hint.contains("nse") || hint.contains("national stock exchange") {
            return "\(trimmed).NS"
        }
        if hint.contains("bse") || hint.contains("bombay stock exchange") {
            return "\(trimmed).BO"
        }

        return trimmed
    }

    private func exchangeName(for symbol: String, fallback: String) -> String {
        if symbol.hasSuffix(".NS") { return "NSE" }
        if symbol.hasSuffix(".BO") { return "BSE" }
        return fallback.isEmpty ? "Market" : fallback
    }

    private func isSupportedSearchResult(symbol: String, name: String, query: String) -> Bool {
        guard !symbol.isEmpty else { return false }
        let quoteTypeIsEquity = !symbol.contains("=") && !symbol.contains("^")
        let q = query.lowercased()
        let searchable = "\(symbol) \(name)".lowercased()
        return quoteTypeIsEquity && (searchable.contains(q) || SearchUtility.fuzzyMatchScore(query: q, target: searchable) > 0.4)
    }
    
    func fetchPrice(symbol: String) async -> AstraStock? {
        if isCryptoSymbol(symbol),
           let cryptoPrice = await fetchCryptoINRPrice(symbol: symbol, date: nil) {
            return AstraStock(
                symbol: symbol,
                name: symbol,
                exchange: "Binance",
                currentPrice: cryptoPrice,
                priceChange: 0,
                priceChangePercentage: 0
            )
        }

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

    func fetchCryptoINRPrice(symbol: String, date: Date? = nil) async -> Double? {
        guard let usdtPair = cryptoUSDTTradingPair(from: symbol) else { return nil }

        let usdPrice: Double?
        if let date {
            usdPrice = await fetchHistoricalCryptoUSDPrice(pair: usdtPair, date: date)
        } else {
            usdPrice = await fetchCurrentCryptoUSDPrice(pair: usdtPair)
        }

        guard let usdPrice, usdPrice > 0 else { return nil }
        let usdInr = await fetchUSDINRRate() ?? 83.0
        return usdPrice * usdInr
    }

    private func isCryptoSymbol(_ symbol: String) -> Bool {
        cryptoUSDTTradingPair(from: symbol) != nil
    }

    private func cryptoUSDTTradingPair(from symbol: String) -> String? {
        let upper = symbol.uppercased()
        if upper.hasPrefix("BINANCE:") {
            return String(upper.dropFirst("BINANCE:".count))
        }
        if upper.hasSuffix("USDT"), !upper.contains(".") {
            return upper
        }
        return nil
    }

    private func cryptoDisplayName(for asset: String) -> String {
        let names = [
            "BTC": "Bitcoin",
            "ETH": "Ethereum",
            "SOL": "Solana",
            "XRP": "XRP",
            "BNB": "BNB",
            "ADA": "Cardano",
            "DOGE": "Dogecoin",
            "DOT": "Polkadot",
            "MATIC": "Polygon",
            "AVAX": "Avalanche",
            "LINK": "Chainlink",
            "LTC": "Litecoin",
            "TRX": "TRON",
            "UNI": "Uniswap",
            "ATOM": "Cosmos",
            "NEAR": "NEAR Protocol"
        ]
        return names[asset.uppercased()] ?? asset.uppercased()
    }

    private func fetchCurrentCryptoUSDPrice(pair: String) async -> Double? {
        guard let url = URL(string: "https://api.binance.com/api/v3/ticker/price?symbol=\(pair)") else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(BinanceTickerPriceResponse.self, from: data)
            return Double(response.price)
        } catch {
            print("Binance crypto quote error: \(error)")
            return nil
        }
    }

    private func fetchHistoricalCryptoUSDPrice(pair: String, date: Date) async -> Double? {
        let calendar = Calendar(identifier: .gregorian)
        let startOfDay = calendar.startOfDay(for: date)
        let startMs = Int(startOfDay.timeIntervalSince1970 * 1000)
        let endMs = startMs + (24 * 60 * 60 * 1000)
        let urlString = "https://api.binance.com/api/v3/klines?symbol=\(pair)&interval=1d&startTime=\(startMs)&endTime=\(endMs)&limit=1"
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let rows = try JSONDecoder().decode([[BinanceKlineValue]].self, from: data)
            guard let row = rows.first, row.count > 4 else {
                return await fetchCurrentCryptoUSDPrice(pair: pair)
            }
            if case let .string(closeString) = row[4] {
                return Double(closeString)
            }
            return nil
        } catch {
            print("Binance crypto historical quote error: \(error)")
            return await fetchCurrentCryptoUSDPrice(pair: pair)
        }
    }

    private func fetchUSDINRRate() async -> Double? {
        guard let url = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/USDINR=X?interval=1d&range=1d") else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(YahooChartResponse.self, from: data)
            return response.chart.result?.first?.meta.regularMarketPrice
        } catch {
            print("USD/INR quote error: \(error)")
            return nil
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
        if isCryptoSymbol(symbol) {
            return await fetchCryptoINRPrice(symbol: symbol, date: date)
        }

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
        if isCryptoSymbol(symbol) {
            return await fetchCryptoChartHistory(symbol: symbol, startDate: startDate)
        }

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

    func fetchCryptoChartHistory(symbol: String, startDate: Date) async -> [MFHistoryPoint] {
        guard let pair = cryptoUSDTTradingPair(from: symbol) else { return [] }

        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: Date())
        let startMs = Int(start.timeIntervalSince1970 * 1000)
        let endMs = Int(end.addingTimeInterval(86_400).timeIntervalSince1970 * 1000)
        let urlString = "https://api.binance.com/api/v3/klines?symbol=\(pair)&interval=1d&startTime=\(startMs)&endTime=\(endMs)&limit=1000"
        guard let url = URL(string: urlString) else { return [] }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let rows = try JSONDecoder().decode([[BinanceKlineValue]].self, from: data)
            let usdInr = await fetchUSDINRRate() ?? 83.0
            let formatter = DateFormatter()
            formatter.dateFormat = "dd-MM-yyyy"
            formatter.timeZone = TimeZone(identifier: "UTC")

            return rows.compactMap { row in
                guard row.count > 4,
                      let openTime = row[0].doubleValue,
                      let close = row[4].doubleValue,
                      close > 0 else { return nil }

                let date = Date(timeIntervalSince1970: openTime / 1000)
                return MFHistoryPoint(date: formatter.string(from: date), nav: String(format: "%.2f", close * usdInr))
            }
        } catch {
            print("Crypto chart history error for \(symbol): \(error)")
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

struct BinanceTickerPriceResponse: Codable {
    let symbol: String
    let price: String
}

struct BinanceExchangeInfoResponse: Codable {
    let symbols: [BinanceExchangeSymbol]
}

struct BinanceExchangeSymbol: Codable {
    let symbol: String
    let status: String
    let baseAsset: String
    let quoteAsset: String
}

enum BinanceKlineValue: Decodable {
    case string(String)
    case double(Double)
    case int(Int)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else {
            self = .null
        }
    }

    var doubleValue: Double? {
        switch self {
        case .string(let value): return Double(value)
        case .double(let value): return value
        case .int(let value): return Double(value)
        case .null: return nil
        }
    }
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

struct YahooSearchResponse: Codable {
    let quotes: [YahooSearchQuote]
}

struct YahooSearchQuote: Codable {
    let symbol: String?
    let shortname: String?
    let longname: String?
    let exchange: String?
    let exchDisp: String?
    let quoteType: String?
}
