import Foundation

/// Internal model for raw extracted data before enrichment.
struct NormalizedTransaction: Codable {
    var assetName: String
    var isin: String?
    var date: Date
    var quantity: Double
    var amount: Double?
    var price: Double?
    var type: String // "Buy" or "Sell"
}

/// Internal model for grouping transactions by asset.
struct NormalizedAsset: Codable {
    var name: String
    var isin: String?
    var transactions: [NormalizedTransaction]
    
    var assetType: String {
        guard let isin = isin else { return "Unknown" }
        if isin.hasPrefix("INF") { return "Mutual Fund" }
        if isin.hasPrefix("INE") { return "Stocks" }
        return "Unknown"
    }
}
