import Foundation

struct ParsedTransaction: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date
    var type: String // "Buy" or "Sell"
    var units: Double
    var amount: Double = 0
    var nav: Double = 0
}

struct ParsedInvestment: Identifiable {
    let id = UUID()
    var fundName: String
    var type: String // Mutual Fund, Equity, Fixed Income
    var investedAmount: Double
    var currentValue: Double?
    var units: Double?
    var mode: String // SIP, Lumpsum
    var dates: [Date]
    var transactions: [ParsedTransaction] = []
    var schemeCode: String?
    var isin: String?
    var symbol: String?
    var quantity: Double?
    var isSelected: Bool = true // User can select/deselect for import

    // Converters to existing models if needed
    func toAssessmentEntry() -> AssessmentInvestmentEntry {
        var entry = AssessmentInvestmentEntry()
        entry.fundName = fundName
        entry.amount = String(format: "%.0f", investedAmount)
        entry.type = (type.lowercased().contains("equity") || type.lowercased().contains("stock")) ? .stocks : .mutualFund
        entry.mode = mode.lowercased() == "sip" ? .sip : .lumpsum
        entry.isin = isin
        entry.schemeCode = schemeCode
        
        if let u = units {
            entry.units = String(format: "%.4f", u)
        }
        
        // We use the first date
        if let firstDate = dates.min() {
            entry.startDate = firstDate
        }
        
        entry.symbol = symbol
        if let q = quantity {
            entry.quantity = String(format: "%.0f", q)
        }
        
        entry.totalInvested = investedAmount
        entry.currentValue = currentValue
        if investedAmount > 0, let cv = currentValue {
            entry.growthRate = ((cv - investedAmount) / investedAmount) * 100
        }
        
        // Map transactions
        entry.transactions = transactions.map { tx in
            AssessmentInvestmentEntry.AssessmentInvestmentTransaction(
                id: tx.id,
                date: tx.date,
                type: tx.type,
                amount: tx.amount,
                nav: tx.nav,
                units: tx.units
            )
        }
        
        return entry
    }
}

