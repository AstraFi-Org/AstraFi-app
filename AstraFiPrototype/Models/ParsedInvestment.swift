import Foundation

struct ParsedInvestment: Identifiable {
    let id = UUID()
    var fundName: String
    var type: String // Mutual Fund, Equity, Fixed Income
    var investedAmount: Double
    var currentValue: Double?
    var units: Double?
    var mode: String // SIP, Lumpsum
    var dates: [Date]
    var schemeCode: String?
    var isin: String?
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
        return entry
    }
}
