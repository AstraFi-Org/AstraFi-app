import Foundation

struct StockFacts: Codable, Equatable {
    let symbol: String
    let companyName: String
    let sector: String
    let industry: String
    let marketCap: Double
    let employees: Int
    let description: String
    let peRatio: Double
    let roe: Double
    let debtToEquity: Double
    let revenueGrowth: Double
    let profitGrowth: Double
    let competitors: [String]
    let analystBuy: Int
    let analystHold: Int
    let analystSell: Int
    let latestNews: [String]
    let priceHistory: [Double]
}
