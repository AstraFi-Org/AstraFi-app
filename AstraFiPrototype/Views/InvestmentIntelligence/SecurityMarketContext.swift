import Foundation

public struct SecurityMarketContext: Equatable {
    public let symbol: String
    public let exchange: String
    public let country: String
    public let isIndian: Bool
    public let isUS: Bool
    public let currencySymbol: String
    public let currencyCode: String

    private static let knownIndianSymbols: Set<String> = [
        "RADICO", "RELIANCE", "TCS", "HDFCBANK", "INFY", "ICICIBANK", "BAJFINANCE", "BHARTIARTL",
        "HINDUNILVR", "ITC", "SBIN", "LT", "KOTAKBANK", "AXISBANK", "ASIANPAINT", "MARUTI",
        "TATAMOTORS", "M&M", "HCLTECH", "WIPRO", "TATASTEEL", "JSWSTEEL", "SUNPHARMA", "TITAN",
        "ULTRACEMCO", "NTPC", "POWERGRID", "TATAPOWER", "ZOMATO", "TRENT", "BEL", "HAL",
        "JIOFIN", "ADANIENT", "ADANIPORTS", "BAJAJ-AUTO", "COALINDIA", "DLF", "POLYCAB", "VBL",
        "MCDOWELL-N", "NESTLEIND", "BRITANNIA", "CIPLA", "DRREDDY", "DIVISLAB", "APOLLOHOSP",
        "EICHERMOT", "GRASIM", "TECHM", "INDUSINDBK", "FEDERALBNK", "PNB", "BANKBARODA",
        "INDIGO", "IOC", "BPCL", "ONGC", "GAIL", "HINDALCO", "VEDL", "HAVELLS", "SIEMENS",
        "ABB", "RECLTD", "PFC", "MUTHOOTFIN", "CHOLAFIN", "NAUKRI", "NYKAA", "PAYTM",
        "POLICYBZR", "BSE", "CDSL",
        // Gold / Silver ETFs on NSE
        "GOLDBEES", "HDFCGOLD", "SETFGOLD", "ICICIGOLD", "KOTAKGOLD", "AXISGOLD", "TATAGOLD",
        "ADITYAGOLD", "QUANTUMGOLD", "UTIGOLDETF", "DSPGOLDETF", "INVESCGOLD", "LICNETFGOLD",
        "CANROBGOLD", "SILVERBEES", "HDFCSILVER", "ICICISILVE", "TATASILV", "SETFSILV", "IPGETF"
    ]

    public init(symbol: String, exchange: String? = nil, country: String? = nil, isMutualFund: Bool = false) {
        let cleanSymbol = symbol.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedExchange = exchange?.uppercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let resolvedCountry = country?.uppercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        self.symbol = cleanSymbol

        let isNumericCode = !cleanSymbol.isEmpty && cleanSymbol.allSatisfy({ $0.isNumber })
        let isIndianISIN = cleanSymbol.hasPrefix("INF") || cleanSymbol.hasPrefix("INE")
        let isMFPrefix = cleanSymbol.hasPrefix("MF-")
        let isKnownIndian = Self.knownIndianSymbols.contains(cleanSymbol)
            || Self.knownIndianSymbols.contains(cleanSymbol.replacingOccurrences(of: ".NS", with: "").replacingOccurrences(of: ".BO", with: ""))

        // Indian security detection: mutual funds, numeric scheme codes, .NS, .BO, NSE, BSE, India
        let isIndiaDetected = isMutualFund
            || isNumericCode
            || isIndianISIN
            || isMFPrefix
            || cleanSymbol.hasSuffix(".NS")
            || cleanSymbol.hasSuffix(".BO")
            || resolvedExchange == "NSE"
            || resolvedExchange == "BSE"
            || resolvedExchange.contains("NSE")
            || resolvedExchange.contains("BSE")
            || resolvedExchange.contains("AMFI")
            || resolvedExchange.contains("MUTUAL FUND")
            || resolvedCountry == "INDIA"
            || resolvedCountry == "IN"
            || resolvedCountry.contains("INDIA")
            || isKnownIndian

        self.isIndian = isIndiaDetected

        // US security detection: NASDAQ, NYSE, AMEX, US, or known US tickers without dot suffix
        let isUSDetected = !isIndiaDetected && (
            resolvedExchange.contains("NASDAQ")
            || resolvedExchange.contains("NYSE")
            || resolvedExchange.contains("AMEX")
            || resolvedCountry == "US"
            || resolvedCountry == "USA"
            || resolvedCountry == "UNITED STATES"
            || ["AAPL", "MSFT", "GOOGL", "GOOG", "AMZN", "NVDA", "TSLA", "META", "NFLX", "AMD", "INTC", "BRK.B", "JPM", "V"].contains(cleanSymbol)
        )

        self.isUS = isUSDetected

        if isIndiaDetected {
            self.currencySymbol = "₹"
            self.currencyCode = "INR"
            self.exchange = resolvedExchange.isEmpty ? "NSE" : resolvedExchange
            self.country = "India"
        } else if isUSDetected {
            self.currencySymbol = "$"
            self.currencyCode = "USD"
            self.exchange = resolvedExchange.isEmpty ? "NASDAQ" : resolvedExchange
            self.country = "United States"
        } else {
            self.currencySymbol = "$"
            self.currencyCode = "USD"
            self.exchange = resolvedExchange.isEmpty ? "Global" : resolvedExchange
            self.country = resolvedCountry.isEmpty ? "International" : resolvedCountry
        }
    }

    public var currencySystemImage: String {
        isIndian ? "indianrupeesign.circle.fill" : "dollarsign.circle.fill"
    }

    public func formatPrice(_ value: Double?) -> String {
        guard let value, value.isFinite, value > 0 else { return "Unavailable" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = currencySymbol
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.locale = Locale(identifier: isIndian ? "en_IN" : "en_US")
        return formatter.string(from: NSNumber(value: value)) ?? "\(currencySymbol)\(String(format: "%.2f", value))"
    }

    public func formatCompactPrice(_ value: Double?) -> String {
        guard let value, value.isFinite, value > 0 else { return "-" }
        let absValue = abs(value)
        let sign = value < 0 ? "-" : ""

        if isIndian {
            if absValue >= 10_000_000 {
                return "\(sign)₹\(String(format: "%.1f", absValue / 10_000_000))Cr"
            }
            if absValue >= 100_000 {
                return "\(sign)₹\(String(format: "%.1f", absValue / 100_000))L"
            }
            if absValue >= 10_000 {
                return "\(sign)₹\(String(format: "%.1f", absValue / 1000))K"
            }
            return formatPrice(value)
        } else {
            if absValue >= 1_000_000_000 {
                return "\(sign)$\(String(format: "%.1f", absValue / 1_000_000_000))B"
            }
            if absValue >= 1_000_000 {
                return "\(sign)$\(String(format: "%.1f", absValue / 1_000_000))M"
            }
            if absValue >= 10_000 {
                return "\(sign)$\(String(format: "%.1f", absValue / 1000))K"
            }
            return formatPrice(value)
        }
    }

    public func formatMarketCap(_ value: Double?) -> String {
        guard let value, value > 0 else { return "Unavailable" }
        let absValue = abs(value)
        let sign = value < 0 ? "-" : ""

        if isIndian {
            // Indian standard: Crores (1 Cr = 10,000,000) & Lakhs (1 L = 100,000)
            if absValue >= 100_000_000_000 {
                let lakhCr = absValue / 100_000_000_000
                return "\(sign)₹\(String(format: "%.2f", lakhCr)) Lakh Cr"
            }
            if absValue >= 10_000_000 {
                let cr = absValue / 10_000_000
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.maximumFractionDigits = cr >= 100 ? 0 : 1
                let formatted = formatter.string(from: NSNumber(value: cr)) ?? String(format: "%.1f", cr)
                return "\(sign)₹\(formatted) Cr"
            }
            if absValue >= 100_000 {
                let lakh = absValue / 100_000
                return "\(sign)₹\(String(format: "%.1f", lakh)) L"
            }
            return "\(sign)₹\(String(format: "%.0f", absValue))"
        } else {
            // US standard: Trillions ($T), Billions ($B), Millions ($M)
            if absValue >= 1_000_000_000_000 {
                let t = absValue / 1_000_000_000_000
                return "\(sign)$\(String(format: "%.2f", t))T"
            }
            if absValue >= 1_000_000_000 {
                let b = absValue / 1_000_000_000
                return "\(sign)$\(String(format: "%.2f", b))B"
            }
            if absValue >= 1_000_000 {
                let m = absValue / 1_000_000
                return "\(sign)$\(String(format: "%.1f", m))M"
            }
            return "\(sign)$\(String(format: "%.0f", absValue))"
        }
    }

    public func formatChange(percent: Double?) -> String {
        guard let percent else { return "0.00%" }
        let sign = percent > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", percent))%"
    }

    public static func forSymbol(_ symbol: String, exchange: String? = nil, country: String? = nil, isMutualFund: Bool = false) -> SecurityMarketContext {
        SecurityMarketContext(symbol: symbol, exchange: exchange, country: country, isMutualFund: isMutualFund)
    }

    static func forAsset(_ asset: InvestmentSummaryAsset) -> SecurityMarketContext {
        SecurityMarketContext(
            symbol: asset.symbol,
            exchange: asset.metadata,
            country: nil,
            isMutualFund: asset.kind == .mutualFund
        )
    }

    static func forStock(_ stock: AstraStock) -> SecurityMarketContext {
        SecurityMarketContext(symbol: stock.symbol, exchange: stock.exchange)
    }
}
