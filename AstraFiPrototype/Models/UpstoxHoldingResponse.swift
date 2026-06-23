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

struct UpstoxMutualFundOrderResponse: Decodable {
    let status: String?
    let data: [UpstoxMutualFundOrder]?
    let metaData: UpstoxPaginationMetadata?

    enum CodingKeys: String, CodingKey {
        case status
        case data
        case metaData = "meta_data"
    }
}

struct UpstoxMutualFundSIPResponse: Decodable {
    let status: String?
    let data: [UpstoxMutualFundSIP]?
    let metaData: UpstoxPaginationMetadata?

    enum CodingKeys: String, CodingKey {
        case status
        case data
        case metaData = "meta_data"
    }
}

struct UpstoxPaginationMetadata: Decodable {
    let page: UpstoxPageMetadata?
}

struct UpstoxPageMetadata: Decodable {
    let pageNumber: Int
    let totalPages: Int
    let records: Int
    let totalRecords: Int

    enum CodingKeys: String, CodingKey {
        case pageNumber = "page_number"
        case totalPages = "total_pages"
        case records
        case totalRecords = "total_records"
    }
}

struct UpstoxMutualFundOrder: Decodable, Identifiable, Equatable {
    var id: String { orderID }

    let instrumentKey: String?
    let status: String?
    let folio: String?
    let fund: String?
    let amount: Double
    let quantity: Double
    let price: Double
    let orderID: String
    let orderTimestamp: String?
    let exchangeTimestamp: String?
    let transactionType: String?
    let lastPrice: Double
    let averagePrice: Double
    let variety: String?

    enum CodingKeys: String, CodingKey {
        case instrumentKey = "instrument_key"
        case status
        case folio
        case fund
        case amount
        case quantity
        case price
        case orderID = "order_id"
        case orderTimestamp = "order_timestamp"
        case exchangeTimestamp = "exchange_timestamp"
        case transactionType = "transaction_type"
        case lastPrice = "last_price"
        case averagePrice = "average_price"
        case variety
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        instrumentKey = try container.decodeIfPresent(String.self, forKey: .instrumentKey)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        folio = try container.decodeIfPresent(String.self, forKey: .folio)
        fund = try container.decodeIfPresent(String.self, forKey: .fund)
        amount = container.flexibleDouble(forKey: .amount)
        quantity = container.flexibleDouble(forKey: .quantity)
        price = container.flexibleDouble(forKey: .price)
        orderID = (try container.decodeIfPresent(String.self, forKey: .orderID)) ?? UUID().uuidString
        orderTimestamp = try container.decodeIfPresent(String.self, forKey: .orderTimestamp)
        exchangeTimestamp = try container.decodeIfPresent(String.self, forKey: .exchangeTimestamp)
        transactionType = try container.decodeIfPresent(String.self, forKey: .transactionType)
        lastPrice = container.flexibleDouble(forKey: .lastPrice)
        averagePrice = container.flexibleDouble(forKey: .averagePrice)
        variety = try container.decodeIfPresent(String.self, forKey: .variety)
    }

    var isCompleted: Bool {
        status?.uppercased() == "COMPLETED" && quantity > 0
    }

    var isSIP: Bool {
        variety?.uppercased() == "SIP"
    }

    var transactionDate: Date? {
        Self.parseDate(exchangeTimestamp) ?? Self.parseDate(orderTimestamp)
    }

    var executedNAV: Double {
        if averagePrice > 0 { return averagePrice }
        if price > 0 { return price }
        if quantity > 0 && amount > 0 { return amount / quantity }
        return 0
    }

    private static func parseDate(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }
        for format in ["yyyy-MM-dd HH:mm:ss.S", "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd"] {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: "Asia/Kolkata")
            formatter.dateFormat = format
            if let date = formatter.date(from: value) { return date }
        }
        return nil
    }
}

struct UpstoxMutualFundSIP: Decodable, Identifiable, Equatable {
    var id: String { sipID }

    let instrumentKey: String?
    let fund: String?
    let status: String?
    let created: String?
    let frequency: String?
    let sipID: String
    let nextInstalment: String?
    let instalmentAmount: Double
    let lastInstalment: String?
    let instalmentDay: Int?
    let completedInstalments: Int?

    enum CodingKeys: String, CodingKey {
        case instrumentKey = "instrument_key"
        case fund
        case status
        case created
        case frequency
        case sipID = "sip_id"
        case nextInstalment = "next_instalment"
        case instalmentAmount = "instalment_amount"
        case lastInstalment = "last_instalment"
        case instalmentDay = "instalment_day"
        case completedInstalments = "completed_instalments"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        instrumentKey = try container.decodeIfPresent(String.self, forKey: .instrumentKey)
        fund = try container.decodeIfPresent(String.self, forKey: .fund)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        created = try container.decodeIfPresent(String.self, forKey: .created)
        frequency = try container.decodeIfPresent(String.self, forKey: .frequency)
        sipID = (try container.decodeIfPresent(String.self, forKey: .sipID)) ?? UUID().uuidString
        nextInstalment = try container.decodeIfPresent(String.self, forKey: .nextInstalment)
        instalmentAmount = container.flexibleDouble(forKey: .instalmentAmount)
        lastInstalment = try container.decodeIfPresent(String.self, forKey: .lastInstalment)
        instalmentDay = try container.decodeIfPresent(Int.self, forKey: .instalmentDay)
        completedInstalments = try container.decodeIfPresent(Int.self, forKey: .completedInstalments)
    }

    var createdDate: Date? {
        guard let created else { return nil }
        for format in ["yyyy-MM-dd HH:mm:ss.S", "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd"] {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: "Asia/Kolkata")
            formatter.dateFormat = format
            if let date = formatter.date(from: created) { return date }
        }
        return nil
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
