import Foundation

struct UpstoxHoldingResponse: Decodable {
    let status: String?
    let data: [UpstoxHolding]?
    let errors: [UpstoxAPIMessage]?
}

struct UpstoxHolding: Decodable, Identifiable, Equatable {
    var id: String { instrumentToken ?? "\(exchange ?? "")-\(tradingSymbol ?? "")-\(isin ?? "")" }

    let isin: String?
    let companyName: String?
    let tradingSymbol: String?
    let exchange: String?
    let product: String?
    let quantity: Double
    let averagePrice: Double
    let lastPrice: Double
    let closePrice: Double
    let pnl: Double
    let dayChange: Double
    let dayChangePercentage: Double
    let instrumentToken: String?

    enum CodingKeys: String, CodingKey {
        case isin
        case companyName = "company_name"
        case tradingSymbol = "trading_symbol"
        case exchange
        case product
        case quantity
        case averagePrice = "average_price"
        case lastPrice = "last_price"
        case closePrice = "close_price"
        case pnl
        case dayChange = "day_change"
        case dayChangePercentage = "day_change_percentage"
        case instrumentToken = "instrument_token"
    }

    init(
        isin: String?,
        companyName: String?,
        tradingSymbol: String?,
        exchange: String?,
        product: String?,
        quantity: Double,
        averagePrice: Double,
        lastPrice: Double,
        closePrice: Double,
        pnl: Double,
        dayChange: Double,
        dayChangePercentage: Double,
        instrumentToken: String?
    ) {
        self.isin = isin
        self.companyName = companyName
        self.tradingSymbol = tradingSymbol
        self.exchange = exchange
        self.product = product
        self.quantity = quantity
        self.averagePrice = averagePrice
        self.lastPrice = lastPrice
        self.closePrice = closePrice
        self.pnl = pnl
        self.dayChange = dayChange
        self.dayChangePercentage = dayChangePercentage
        self.instrumentToken = instrumentToken
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isin = try container.decodeIfPresent(String.self, forKey: .isin)
        companyName = try container.decodeIfPresent(String.self, forKey: .companyName)
        tradingSymbol = try container.decodeIfPresent(String.self, forKey: .tradingSymbol)
        exchange = try container.decodeIfPresent(String.self, forKey: .exchange)
        product = try container.decodeIfPresent(String.self, forKey: .product)
        quantity = container.flexibleDouble(forKey: .quantity)
        averagePrice = container.flexibleDouble(forKey: .averagePrice)
        lastPrice = container.flexibleDouble(forKey: .lastPrice)
        closePrice = container.flexibleDouble(forKey: .closePrice)
        pnl = container.flexibleDouble(forKey: .pnl)
        dayChange = container.flexibleDouble(forKey: .dayChange)
        dayChangePercentage = container.flexibleDouble(forKey: .dayChangePercentage)
        instrumentToken = try container.decodeIfPresent(String.self, forKey: .instrumentToken)
    }

    var displayName: String {
        if let companyName, !companyName.isEmpty { return companyName }
        if let tradingSymbol, !tradingSymbol.isEmpty { return tradingSymbol }
        return "Upstox Holding"
    }

    var currentPrice: Double {
        if lastPrice > 0 { return lastPrice }
        return closePrice
    }

    var investedAmount: Double {
        averagePrice * quantity
    }
}

struct UpstoxPositionResponse: Decodable {
    let status: String?
    let data: [UpstoxPosition]?
    let errors: [UpstoxAPIMessage]?
}

struct UpstoxPosition: Decodable, Identifiable, Equatable {
    var id: String { instrumentToken ?? "\(exchange ?? "")-\(tradingSymbol ?? "")-position" }

    let tradingSymbol: String?
    let exchange: String?
    let product: String?
    let quantity: Double
    let overnightQuantity: Double
    let averagePrice: Double
    let buyPrice: Double
    let lastPrice: Double
    let closePrice: Double
    let pnl: Double
    let dayChange: Double
    let dayChangePercentage: Double
    let instrumentToken: String?

    enum CodingKeys: String, CodingKey {
        case tradingSymbol = "trading_symbol"
        case exchange
        case product
        case quantity
        case overnightQuantity = "overnight_quantity"
        case averagePrice = "average_price"
        case buyPrice = "buy_price"
        case lastPrice = "last_price"
        case closePrice = "close_price"
        case pnl
        case dayChange = "day_change"
        case dayChangePercentage = "day_change_percentage"
        case instrumentToken = "instrument_token"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tradingSymbol = try container.decodeIfPresent(String.self, forKey: .tradingSymbol)
        exchange = try container.decodeIfPresent(String.self, forKey: .exchange)
        product = try container.decodeIfPresent(String.self, forKey: .product)
        quantity = container.flexibleDouble(forKey: .quantity)
        overnightQuantity = container.flexibleDouble(forKey: .overnightQuantity)
        averagePrice = container.flexibleDouble(forKey: .averagePrice)
        buyPrice = container.flexibleDouble(forKey: .buyPrice)
        lastPrice = container.flexibleDouble(forKey: .lastPrice)
        closePrice = container.flexibleDouble(forKey: .closePrice)
        pnl = container.flexibleDouble(forKey: .pnl)
        dayChange = container.flexibleDouble(forKey: .dayChange)
        dayChangePercentage = container.flexibleDouble(forKey: .dayChangePercentage)
        instrumentToken = try container.decodeIfPresent(String.self, forKey: .instrumentToken)
    }

    var asHolding: UpstoxHolding {
        let effectiveQuantity = quantity != 0 ? quantity : overnightQuantity
        let effectiveAveragePrice = averagePrice > 0 ? averagePrice : buyPrice

        return UpstoxHolding(
            isin: nil,
            companyName: tradingSymbol,
            tradingSymbol: tradingSymbol,
            exchange: exchange,
            product: product,
            quantity: effectiveQuantity,
            averagePrice: effectiveAveragePrice,
            lastPrice: lastPrice,
            closePrice: closePrice,
            pnl: pnl,
            dayChange: dayChange,
            dayChangePercentage: dayChangePercentage,
            instrumentToken: instrumentToken
        )
    }
}

struct UpstoxMutualFundHoldingResponse: Decodable {
    let status: String?
    let data: [UpstoxMutualFundHolding]?
    let errors: [UpstoxAPIMessage]?
}

struct UpstoxMutualFundHolding: Decodable, Identifiable, Equatable {
    var id: String { "\(instrumentKey ?? "")-\(folio ?? "")" }

    let instrumentKey: String?
    let folio: String?
    let fund: String?
    let pnl: Double
    let quantity: Double
    let averagePrice: Double
    let lastPrice: Double
    let lastPriceDate: String?
    let pledgedQuantity: Double

    enum CodingKeys: String, CodingKey {
        case instrumentKey = "instrument_key"
        case folio
        case fund
        case pnl
        case quantity
        case averagePrice = "average_price"
        case lastPrice = "last_price"
        case lastPriceDate = "last_price_date"
        case pledgedQuantity = "pledged_quantity"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        instrumentKey = try container.decodeIfPresent(String.self, forKey: .instrumentKey)
        folio = try container.decodeIfPresent(String.self, forKey: .folio)
        fund = try container.decodeIfPresent(String.self, forKey: .fund)
        pnl = container.flexibleDouble(forKey: .pnl)
        quantity = container.flexibleDouble(forKey: .quantity)
        averagePrice = container.flexibleDouble(forKey: .averagePrice)
        lastPrice = container.flexibleDouble(forKey: .lastPrice)
        lastPriceDate = try container.decodeIfPresent(String.self, forKey: .lastPriceDate)
        pledgedQuantity = container.flexibleDouble(forKey: .pledgedQuantity)
    }

    var displayName: String {
        if let fund, !fund.isEmpty { return fund }
        return "Upstox Mutual Fund"
    }

    var investedAmount: Double {
        averagePrice * quantity
    }

    var currentValue: Double {
        lastPrice * quantity
    }
}

private extension KeyedDecodingContainer {
    func flexibleDouble(forKey key: Key) -> Double {
        if let value = try? decode(Double.self, forKey: key) {
            return value.safeFinite
        }
        if let value = try? decode(Int.self, forKey: key) {
            return Double(value)
        }
        if let value = try? decode(String.self, forKey: key),
           let doubleValue = Double(value.replacingOccurrences(of: ",", with: "")) {
            return doubleValue.safeFinite
        }
        return 0
    }
}
