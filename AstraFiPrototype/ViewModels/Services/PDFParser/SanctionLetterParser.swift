import Foundation

struct SanctionLetterParser: LoanStatementParser {
    
    func parse(text: String) -> [ParsedLoan] {
        let normalizedText = text.lowercased()
        var loanData = LoanData()
        
        // --- 1. Structured Data Extraction ---
        
        // Insurance (Extract first to avoid confusion with Principal)
        if let match = extractRegex(#"insurance premium amount\.?\s?:?\s?rs\.?\s?([0-9,]+)"#, in: normalizedText) {
            loanData.insurance = cleanNumeric(match) ?? 0
        }
        
        // Loan Amount: Multiple patterns - Prioritize RE: line and structured terms
        let amountPatterns = [
               // Specific for RE: line in Baroda letters
            #"baroda\s?gyan\s?loan\s?of\s?rs\.?\s?([0-9,]+(?:\.\d{2})?)"#,
            #"loan\s?of\s?rs\.?\s?([0-9,]+(?:\.\d{2})?)"#,
            // General Amount patterns - Exclude insurance/premium lines explicitly
            #"(?<!insurance |premium )amount.{0,10}rs\.?\s?([0-9,]+)"#,
            #"sanctioned.{0,10}?rs\.?\s?([0-9,]+)"#,
            #"principal\s?sum.{0,10}?rs\.?\s?([0-9,]+)"#
        ]
        
        for pattern in amountPatterns {
            if let match = extractRegex(pattern, in: normalizedText) {
                let cleaned = cleanNumeric(match) ?? 0
                // Final check: Principal should not be exactly the insurance amount
                if cleaned > 0 && cleaned != loanData.insurance {
                   loanData.principal = cleaned
                   break 
                }
            }
        }
        
        // Total Cost: Pattern "total cost"
        if let match = extractRegex(#"total cost.{0,15}?rs\.?\s?([0-9,]+)"#, in: normalizedText) {
            loanData.totalCost = cleanNumeric(match) ?? 0
        }
        
        // Interest Rate: ONLY from "applicable rate of interest is X%" or similar
        let ratePatterns = [
            #"applicable rate of interest.{0,15}?(?:is|@)\s?(\d{1,2}(?:\.\d{1,2})?)\s?%"#,
            #"rate\sof\sinterest.{0,15}?(?:is|@)\s?(\d{1,2}(?:\.\d{1,2})?)\s?%"#,
            #"roi\s?@\s?(\d{1,2}(?:\.\d{1,2})?)\s?%"#
        ]
        for pattern in ratePatterns {
            if let match = extractRegex(pattern, in: normalizedText) {
                loanData.interestRate = Double(match) ?? 0
                if loanData.interestRate > 0 { break }
            }
        }
        
        // Tenure (months): Support ":96months" or "period 96 months"
        if let match = extractRegex(#"(?:total period|tenure).{0,15}?:?\s?(\d+)\s?months?"#, in: normalizedText) {
            loanData.tenure = Int(match) ?? 0
        }
        
        // Moratorium (months): Support ":55" or "55 months"
        if let match = extractRegex(#"(?:moratorium|holiday).{0,10}?:?\s?(\d+)"#, in: normalizedText) {
            loanData.moratorium = Int(match) ?? 0
        }
        
        // Loan Type & Scheme
        scanForMetadata(text: text, into: &loanData)
        
        // --- 2. Validation & Calculations ---
        
        // Fallback for missing Loan Amount if Total Cost is found
        if loanData.principal == 0 && loanData.totalCost > 0 {
            loanData.principal = loanData.totalCost
        }
        
        // EMI Months = Tenure - Moratorium
        loanData.emiMonths = max(0, loanData.tenure - loanData.moratorium)
        
        // Core Calculations using CalculationEngine
        if loanData.principal > 0 && loanData.interestRate > 0 && loanData.emiMonths > 0 {
            loanData.emi = LoanCalculationEngine.calculateEMI(
                principal: loanData.principal,
                annualRate: loanData.interestRate,
                months: loanData.emiMonths
            )
            
            loanData.moratoriumInterest = LoanCalculationEngine.calculateMoratoriumInterest(
                principal: loanData.principal,
                annualRate: loanData.interestRate,
                moratoriumMonths: loanData.moratorium
            )
            
            let totalInterestDuringEMI = (loanData.emi * Double(loanData.emiMonths)) - loanData.principal
            loanData.totalInterest = totalInterestDuringEMI + loanData.moratoriumInterest
            loanData.totalPayable = loanData.principal + loanData.totalInterest
        }
        
        // Confidence Score Calculation
        loanData.confidenceScore = calculateConfidence(data: loanData)
        
        // --- 3. Map to ParsedLoan for AstraFI Compatibility ---
        
        var result = ParsedLoan(
            type: detectLoanType(loanData: loanData, text: normalizedText),
            amount: loanData.principal,
            interestRate: loanData.interestRate,
            emi: loanData.emi,
            tenure: loanData.tenure,
            startDate: Date(),
            outstanding: loanData.principal,
            lender: extractLender(text: text),
            loanName: loanData.scheme,
            moratoriumMonths: loanData.moratorium,
            insurancePremium: loanData.insurance
        )
        result.confidenceScore = loanData.confidenceScore
        result.rawLoanData = loanData
        
        return [result]
    }
    
    private func extractRegex(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let nsString = text as NSString
        if let result = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: nsString.length)) {
            if result.numberOfRanges > 1 {
                return nsString.substring(with: result.range(at: 1))
            }
        }
        return nil
    }
    
    private func cleanNumeric(_ text: String) -> Double? {
        // Strip everything except digits, comma, and period
        let allowed = CharacterSet.decimalDigits.union(CharacterSet(charactersIn: ".,"))
        let filtered = text.components(separatedBy: allowed.inverted).joined()
        
        let clean = filtered.replacingOccurrences(of: ",", with: "")
                            .trimmingCharacters(in: .whitespaces)
        return Double(clean)
    }
    
    private func scanForMetadata(text: String, into data: inout LoanData) {
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            let nLine = line.lowercased()
            // Skip header fields that might be misread as scheme names
            if nLine.contains("place:") || nLine.contains("date:") || nLine.contains("ref:") { continue }
            
            if nLine.contains("scheme") || nLine.contains("product") {
                let parts = line.components(separatedBy: ":")
                if parts.count > 1 {
                    let scheme = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    // Avoid picking up dates or short garbage as scheme names
                    if scheme.count > 3 && !scheme.contains("/") && !scheme.contains("-") {
                        data.scheme = scheme
                    }
                }
            }
        }
    }
    
    private func detectLoanType(loanData: LoanData, text: String) -> AssessmentLoanEntry.LoanType {
        let nText = text.lowercased()
        if nText.contains("education") || nText.contains("gyan") { return .educationLoan }
        if nText.contains("home") || nText.contains("housing") { return .homeLoan }
        if nText.contains("car") || nText.contains("vehicle") { return .carLoan }
        return .personalLoan
    }
    
    private func extractLender(text: String) -> String? {
        let nText = text.lowercased()
        if nText.contains("bank of baroda") || nText.contains("baroda") { return "Bank of Baroda" }
        if nText.contains("sbi") || nText.contains("state bank") { return "SBI" }
        if nText.contains("hdfc") { return "HDFC Bank" }
        if nText.contains("icici") { return "ICICI Bank" }
        if nText.contains("axis") { return "Axis Bank" }
        return "Other Lender"
    }
    
    private func calculateConfidence(data: LoanData) -> Double {
        var score = 0.0
        if data.principal > 0 { score += 0.3 }
        if data.interestRate > 0 { score += 0.3 }
        if data.tenure > 0 { score += 0.2 }
        if !data.scheme.isEmpty { score += 0.1 }
        if data.insurance > 0 { score += 0.1 }
        return score
    }
}
