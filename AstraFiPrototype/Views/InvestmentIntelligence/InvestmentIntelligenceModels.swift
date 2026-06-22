import Foundation
import SwiftUI

enum IntelligenceAssetKind: String, CaseIterable, Identifiable {
    case stock = "Stocks"
    case mutualFund = "Mutual Funds"
    case goldETF = "Gold ETFs"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .stock: return "building.columns.fill"
        case .mutualFund: return "chart.pie.fill"
        case .goldETF: return "circle.hexagongrid.fill"
        }
    }

    var accent: Color {
        switch self {
        case .stock: return AppTheme.auraIndigo
        case .mutualFund: return AppTheme.auraGreen
        case .goldETF: return AppTheme.auraGold
        }
    }
}

enum IntelligenceRiskLevel: String {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"

    var color: Color {
        switch self {
        case .low: return AppTheme.auraGreen
        case .moderate: return AppTheme.vibrantOrange
        case .high: return AppTheme.vibrantRed
        }
    }
}

struct InvestmentSummaryAsset: Identifiable, Equatable {
    let id: String
    let kind: IntelligenceAssetKind
    let symbol: String
    let name: String
    let sector: String
    var currentValue: Double?
    var dailyChange: Double?
    var oneYearReturn: Double?
    var riskLevel: IntelligenceRiskLevel
    var sparkline: [InvestmentChartPoint]
    var metadata: String
}

struct InvestmentChartPoint: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct InvestmentMetric: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let value: String
    let systemImage: String
    let color: Color
}

struct CompanyProfileSnapshot: Equatable {
    var name: String
    var ticker: String
    var sector: String
    var industry: String
    var country: String
    var exchange: String
    var logoURL: URL?
    var description: String
}

struct CompanyFinancialSnapshot: Equatable {
    var marketCap: Double?
    var peRatio: Double?
    var weekHigh52: Double?
    var weekLow52: Double?
    var dividendYield: Double?
    var revenue: Double?
    var netProfit: Double?
    var eps: Double?
    var cashFlow: Double?
    var operatingMargin: Double?
    var profitMargin: Double?
    var roe: Double?
    var roa: Double?
    var debtRatio: Double?
    var quarterlyGrowth: Double?
    var historicalGrowth: Double?
}

struct RecommendationTrend: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let count: Int
}

struct InvestmentNewsItem: Identifiable, Equatable {
    let id = UUID()
    let headline: String
    let summary: String
    let source: String
    let publishedAt: Date
    let url: URL?
}

struct InvestmentCompetitor: Identifiable, Equatable {
    let id = UUID()
    let symbol: String
    let name: String
    var currentPrice: Double?
    var marketCap: Double?
    var dailyChange: Double?
}

struct MutualFundSnapshot: Equatable {
    var schemeCode: String
    var schemeName: String
    var fundHouse: String
    var category: String
    var currentNAV: Double
    var assetClass: String
    var fundType: String
    var lastUpdated: String
    var oneYearReturn: Double?
    var riskLevel: IntelligenceRiskLevel
}

struct GoldETFSnapshot: Equatable {
    var fundName: String
    var symbol: String
    var currentPrice: Double?
    var nav: Double?
    var trackingError: String
    var expenseRatio: String
    var fundHouse: String
    var riskLevel: IntelligenceRiskLevel
    var category: String
}

struct InvestmentFAQ: Identifiable, Equatable {
    let id = UUID()
    let question: String
    let answer: String
}

struct InvestmentInsight: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let explanation: String
    let systemImage: String
    let color: Color
}

struct InvestmentDetailSnapshot: Equatable {
    var asset: InvestmentSummaryAsset
    var profile: CompanyProfileSnapshot?
    var financials: CompanyFinancialSnapshot?
    var mutualFund: MutualFundSnapshot?
    var goldETF: GoldETFSnapshot?
    var chart: [InvestmentChartPoint]
    var competitors: [InvestmentCompetitor]
    var news: [InvestmentNewsItem]
    var recommendations: [RecommendationTrend]
    var insights: [InvestmentInsight]
    var aiInsight: String?
    var faqs: [InvestmentFAQ]
}

extension Double {
    var intelligenceCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.maximumFractionDigits = self >= 1000 ? 0 : 2
        return formatter.string(from: NSNumber(value: self)) ?? String(format: "%.2f", self)
    }

    var compactCurrency: String {
        let absValue = abs(self)
        let sign = self < 0 ? "-" : ""
        if absValue >= 10_000_000 {
            return "\(sign)₹\(String(format: "%.1f", absValue / 10_000_000))Cr"
        }
        if absValue >= 100_000 {
            return "\(sign)₹\(String(format: "%.1f", absValue / 100_000))L"
        }
        if absValue >= 1000 {
            return "\(sign)₹\(String(format: "%.1f", absValue / 1000))K"
        }
        return intelligenceCurrency
    }

    var percentText: String {
        String(format: "%.2f%%", self)
    }
}
