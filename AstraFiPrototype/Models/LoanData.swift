import Foundation

struct LoanData: Codable {
    var loanType: String = ""
    var scheme: String = ""
    var principal: Double = 0.0
    var totalCost: Double = 0.0
    var interestRate: Double = 0.0
    var tenure: Int = 0 // total period
    var moratorium: Int = 0
    var emiMonths: Int = 0
    var insurance: Double = 0.0
    
    // Calculated fields
    var emi: Double = 0.0
    var totalInterest: Double = 0.0
    var moratoriumInterest: Double = 0.0
    var totalPayable: Double = 0.0
    
    // Metadata
    var confidenceScore: Double = 0.0
    
    // Helper for JSON output as requested
    func ToJSONString() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(self) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
