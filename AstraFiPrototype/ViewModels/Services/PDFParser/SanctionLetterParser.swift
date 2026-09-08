import Foundation

struct SanctionLetterParser: LoanStatementParser {
    
    func parse(text: String) -> [ParsedLoan] {
        let normalizedText = normalizeForParsing(text)
        var loanData = LoanData()
        
        // --- 1. Structured Data Extraction ---
        
        // Insurance Premium
        if let match = extractRegex(#"insurance\s+premium\s*(?:amount)?\s*[:\-]?\s*(?:rs[\.,:]?|inr|₹)?\s*([0-9][0-9,]*(?:\.\d{1,2})?)"#, in: normalizedText) {
            loanData.insurance = cleanNumeric(match) ?? 0
        }
        
        // Sanctioned Loan Amount
        loanData.principal = extractPrincipalAmount(from: normalizedText, insuranceAmount: loanData.insurance)
        
        // Total Cost (Course / Project Total Cost)
        if let match = extractRegex(#"total\s+cost\s*[:\-]?\s*(?:rs[\.,:]?|inr|₹)?\s*([0-9][0-9,]*(?:\.\d{1,2})?)"#, in: normalizedText) {
            loanData.totalCost = cleanNumeric(match) ?? 0
        }
        
        // Loan Requested Amount
        if let match = extractRegex(#"(?:loan\s+requested|requested\s+amount)\s*[:\-]?\s*(?:rs[\.,:]?|inr|₹)?\s*([0-9][0-9,]*(?:\.\d{1,2})?)"#, in: normalizedText) {
            loanData.requestedAmount = cleanNumeric(match) ?? 0
        }
        
        // Permissible Limit
        if let match = extractRegex(#"permissible\s+limit\s*[:\-]?\s*(?:rs[\.,:]?|inr|₹)?\s*([0-9][0-9,]*(?:\.\d{1,2})?)"#, in: normalizedText) {
            loanData.permissibleLimit = cleanNumeric(match) ?? 0
        }
        
        // Actual Margin %
        if let match = extractRegex(#"(?:actual\s+)?margin\s*[:\-]?\s*(\d{1,2}(?:\.\d{1,2})?)\s*%"#, in: normalizedText) {
            loanData.actualMargin = Double(match) ?? 0
        }
        
        if loanData.principal == 0 {
            loanData.principal = extractRepeatedLoanAmountFallback(
                from: normalizedText,
                insuranceAmount: loanData.insurance,
                totalCost: loanData.totalCost
            )
        }
        
        // Interest Rate
        let ratePatterns = [
            #"applicable\s+interest\s+rate.{0,80}?(?:is|@|:)\s*(\d{1,2}(?:\.\d{1,2})?)\s*%"#,
            #"applicable\s+rate\s+of\s+interest.{0,80}?(?:is|@|:)\s*(\d{1,2}(?:\.\d{1,2})?)\s*%"#,
            #"rate\s+of\s+interest.{0,80}?(?:is|@|:)\s*(\d{1,2}(?:\.\d{1,2})?)\s*%"#,
            #"interest\s+rate.{0,60}?(?:is|@|:)\s*(\d{1,2}(?:\.\d{1,2})?)\s*%"#,
            #"\broi\b.{0,30}?(\d{1,2}(?:\.\d{1,2})?)\s*%"#,
            #"roi\s*@\s*(\d{1,2}(?:\.\d{1,2})?)\s*%"#
        ]
        for pattern in ratePatterns {
            if let match = extractRegex(pattern, in: normalizedText) {
                loanData.interestRate = Double(match) ?? 0
                if loanData.interestRate > 0 { break }
            }
        }
        
        // Benchmark Rate components (Repo rate, markup, credit spread)
        if let match = extractRegex(#"(?:rbi\s+repo\s+rate|repo\s+rate)\s*[:\-]?\s*(\d{1,2}(?:\.\d{1,2})?)\s*%"#, in: normalizedText) {
            loanData.repoRate = Double(match) ?? 0
        }
        if let match = extractRegex(#"mark-?up\s*[:\-]?\s*(\d{1,2}(?:\.\d{1,2})?)\s*%"#, in: normalizedText) {
            loanData.markup = Double(match) ?? 0
        }
        if let match = extractRegex(#"credit\s+spread\s*[:\-]?\s*(\d{1,2}(?:\.\d{1,2})?)\s*%"#, in: normalizedText) {
            loanData.creditSpread = Double(match) ?? 0
        }
        
        // Floating / Variable vs Fixed Rate Type Detection
        if normalizedText.contains("reset") || normalizedText.contains("floating") || normalizedText.contains("variable") || loanData.repoRate > 0 || loanData.markup > 0 {
            loanData.interestRateType = "Floating / Variable"
        } else if normalizedText.contains("fixed") {
            loanData.interestRateType = "Fixed"
        } else {
            loanData.interestRateType = "Floating / Variable"
        }
        
        // Interest Rest Frequency Detection
        if normalizedText.contains("monthly rests") || normalizedText.contains("monthly rest") {
            loanData.interestRestFrequency = "Monthly"
        } else if normalizedText.contains("quarterly rests") {
            loanData.interestRestFrequency = "Quarterly"
        } else {
            loanData.interestRestFrequency = "Monthly"
        }
        
        // Total Loan Period (months)
        let tenurePatterns = [
            #"(?:total\s+period|total\s+loan\s+period|loan\s+tenure|tenure)\s*[:\-]?\s*(\d{1,3})\s*months?"#,
            #"(?:total\s+period|total\s+loan\s+period|loan\s+tenure|tenure).{0,30}?(\d{1,3})\s*months?"#,
            #"(?:total\s+period|total\s+loan\s+period|loan\s+tenure|tenure)\s*[:\-]?\s*(\d{1,3})(?=\D)"#,
            #"period\s*[:\-]?\s*(\d{1,3})\s*months?"#
        ]
        for pattern in tenurePatterns {
            if let match = extractRegex(pattern, in: normalizedText) {
                let val = Int(match) ?? 0
                if val > 0 { loanData.totalLoanPeriodMonths = val; break }
            }
        }
        
        // Repayment Period (months)
        if let emiMonths = extractRepayableMonths(from: normalizedText) {
            loanData.emiMonths = emiMonths
        }
        
        // Moratorium Period (months)
        let moratoriumPatterns = [
            #"(?:moratorium|holiday\s+period)\s*[:\-]?\s*(\d{1,3})\s*months?"#,
            #"(?:moratorium|holiday\s+period)\s*[:\-]?\s*(\d{1,3})(?=\D)"#,
            #"morator\w*\s*[:\-]?\s*(\d{1,3})(?=\D)"#,
            #"(?:moratorium|holiday\s+period).{0,20}?(\d{1,3})\s*months?"#,
            #"(\d{1,3})\s*months?.{0,20}(?:moratorium|holiday\s+period)"#
        ]
        for pattern in moratoriumPatterns {
            if let match = extractRegex(pattern, in: normalizedText) {
                let val = Int(match) ?? 0
                if val > 0 {
                    loanData.moratorium = val
                    break
                }
            }
        }
        
        // Explicit EMI Amount (only if explicitly stated in document)
        let emiExplicitPatterns = [
            #"(?:emi\s+amount|installment\s+amount|monthly\s+installment|equated\s+monthly\s+installment)\s*[:\-]?\s*(?:rs[\.,:]?|inr|₹)?\s*([0-9][0-9,]*(?:\.\d{1,2})?)"#,
            #"emi\s*@\s*(?:rs[\.,:]?|inr|₹)?\s*([0-9][0-9,]*(?:\.\d{1,2})?)"#
        ]
        for pattern in emiExplicitPatterns {
            if let match = extractRegex(pattern, in: normalizedText), let val = cleanNumeric(match), val > 0 {
                loanData.emi = val
                break
            }
        }
        
        // Metadata & Lender
        scanForMetadata(text: text, into: &loanData)
        
        // --- 2. Period Adjustments & Calculations ---
        
        if loanData.totalLoanPeriodMonths == 0 && loanData.moratorium > 0 && loanData.emiMonths > 0 {
            loanData.totalLoanPeriodMonths = loanData.moratorium + loanData.emiMonths
        }
        if loanData.totalLoanPeriodMonths == 0 {
            loanData.totalLoanPeriodMonths = extractLikelyTotalPeriod(from: normalizedText, moratorium: loanData.moratorium, emiMonths: loanData.emiMonths)
        }
        if loanData.emiMonths == 0 && loanData.totalLoanPeriodMonths > 0 {
            loanData.emiMonths = max(0, loanData.totalLoanPeriodMonths - loanData.moratorium)
        }
        loanData.tenure = loanData.totalLoanPeriodMonths > 0 ? loanData.totalLoanPeriodMonths : loanData.emiMonths
        
        // Internal EMI & Accretion Calculation
        if loanData.principal > 0 && loanData.interestRate > 0 && loanData.emiMonths > 0 {
            loanData.calculatedEMI = LoanCalculationEngine.calculateEMI(
                principal: loanData.principal,
                annualRate: loanData.interestRate,
                months: loanData.emiMonths
            )
            
            loanData.moratoriumInterest = LoanCalculationEngine.calculateMoratoriumInterest(
                principal: loanData.principal,
                annualRate: loanData.interestRate,
                moratoriumMonths: loanData.moratorium
            )
            
            let totalInterestDuringEMI = (loanData.calculatedEMI * Double(loanData.emiMonths)) - loanData.principal
            loanData.totalInterest = totalInterestDuringEMI + loanData.moratoriumInterest
            loanData.totalPayable = loanData.principal + loanData.totalInterest
        }
        
        // Confidence Score Calculation
        loanData.confidenceScore = calculateConfidence(data: loanData)
        
        // --- 3. Map to ParsedLoan ---
        
        var result = ParsedLoan(
            type: detectLoanType(loanData: loanData, text: normalizedText),
            amount: loanData.principal > 0 ? loanData.principal : (loanData.requestedAmount > 0 ? loanData.requestedAmount : loanData.permissibleLimit),
            interestRate: loanData.interestRate,
            emi: loanData.emi, // Explicit EMI if present, else nil
            tenure: loanData.totalLoanPeriodMonths > 0 ? loanData.totalLoanPeriodMonths : loanData.emiMonths,
            startDate: extractSanctionDate(from: normalizedText) ?? Date(),
            outstanding: loanData.principal > 0 ? loanData.principal : nil,
            lender: extractLender(text: text),
            loanName: !loanData.scheme.isEmpty ? loanData.scheme : loanData.productName,
            moratoriumMonths: loanData.moratorium,
            repaymentMonths: loanData.emiMonths,
            insurancePremium: loanData.insurance > 0 ? loanData.insurance : nil
        )
        
        result.totalCost = loanData.totalCost > 0 ? loanData.totalCost : nil
        result.requestedAmount = loanData.requestedAmount > 0 ? loanData.requestedAmount : nil
        result.permissibleLimit = loanData.permissibleLimit > 0 ? loanData.permissibleLimit : nil
        result.actualMargin = loanData.actualMargin > 0 ? loanData.actualMargin : nil
        result.interestRateType = loanData.interestRateType.contains("Fixed") ? .fixed : .floatingVariable
        result.interestRestFrequency = .monthly
        result.repoRate = loanData.repoRate > 0 ? loanData.repoRate : nil
        result.markup = loanData.markup > 0 ? loanData.markup : nil
        result.creditSpread = loanData.creditSpread > 0 ? loanData.creditSpread : nil
        result.confidenceScore = loanData.confidenceScore
        result.rawLoanData = loanData
        
        return [result]
    }
    
    private func normalizeForParsing(_ text: String) -> String {
        var normalized = text.lowercased()
        normalized = normalized.replacingOccurrences(of: "₹", with: "rs.")
        normalized = normalized.replacingOccurrences(of: "rs ,", with: "rs,")
        normalized = normalized.replacingOccurrences(of: "rs .", with: "rs.")
        normalized = normalized.replacingOccurrences(of: "r s .", with: "rs.")
        normalized = normalized.replacingOccurrences(of: "r s", with: "rs")
        normalized = normalized.replacingOccurrences(of: "\u{00a0}", with: " ")
        normalized = normalized.replacingOccurrences(of: "\n", with: " ")
        normalized = normalized.replacingOccurrences(of: "\t", with: " ")
        normalized = normalized.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return normalized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractPrincipalAmount(from text: String, insuranceAmount: Double) -> Double {
        let prioritizedPatterns = [
            #"baroda\s+gyan\s+loan\s+of\s+(?:rs[\.,:]?|inr)\s*([0-9][0-9,]*(?:\.\d{1,2})?)"#,
            #"(?:permissible\s+limit|sanctioned\s+(?:loan\s+)?(?:amount|limit)|loan\s+amount|credit\s+facility|principal\s+sum)\s*[:\-]?\s*(?:rs[\.,:]?|inr)?\s*([0-9][0-9,]*(?:\.\d{1,2})?)"#,
            #"(?:education|home|housing|vehicle|car|personal)\s+loan.{0,80}?\b(?:of|for)\s+(?:rs[\.,:]?|inr)\s*([0-9][0-9,]*(?:\.\d{1,2})?)"#,
            #"(?:we\s+have\s+sanctioned|sanctioned\s+you|sanctioned\s+credit\s+facility).{0,80}?(?:rs[\.,:]?|inr)\s*([0-9][0-9,]*(?:\.\d{1,2})?)"#,
            #"\bloan\s+of\s+(?:rs[\.,:]?|inr)\s*([0-9][0-9,]*(?:\.\d{1,2})?)"#
        ]
        
        for pattern in prioritizedPatterns {
            let matches = extractRegexMatches(pattern, in: text)
            for match in matches {
                let value = cleanNumeric(match) ?? 0
                if isLikelyLoanAmount(value, insuranceAmount: insuranceAmount) {
                    return value
                }
            }
        }
        
        return 0
    }
    
    private func extractRepeatedLoanAmountFallback(from text: String, insuranceAmount: Double, totalCost: Double) -> Double {
        let amounts = extractRegexMatches(#"(?:rs[\.,:]?|inr|₹)\s*([0-9][0-9,]*(?:\.\d{1,2})?)"#, in: text)
            .compactMap { cleanNumeric($0) }
            .filter { isLikelyLoanAmount($0, insuranceAmount: insuranceAmount) }
            .filter { totalCost == 0 || $0 != totalCost }
        
        guard !amounts.isEmpty else { return 0 }
        
        let counts = Dictionary(grouping: amounts.map { round($0) }, by: { $0 })
        if let repeated = counts.max(by: { lhs, rhs in
            if lhs.value.count == rhs.value.count {
                return lhs.key < rhs.key
            }
            return lhs.value.count < rhs.value.count
        }) {
            return repeated.key
        }
        
        return amounts.max() ?? 0
    }
    
    private func extractRepayableMonths(from text: String) -> Int? {
        let patterns = [
            #"repayment\s*[:\-]?\s*(\d{1,3})\s*months?"#,
            #"repayment\s+period\s*[:\-]?\s*(\d{1,3})\s*months?"#,
            #"repayable\s+in\s*[:\-]?\s*(\d{1,3})\s*months?"#,
            #"repayable\s+in.{0,30}?(\d{1,3})\s*months?"#,
            #"(\d{1,3})\s*months?\s+by\s+equated\s+monthly\s+instal?l?ments?"#,
            #"(\d{1,3})\s*months?.{0,40}?equated\s+monthly\s+instal?l?ments?"#,
            #"emi\s+(?:period|tenure)\s*[:\-]?\s*(\d{1,3})\s*months?"#
        ]
        
        for pattern in patterns {
            if let match = extractRegex(pattern, in: text), let value = Int(match), value > 0 {
                return value
            }
        }
        return nil
    }
    
    private func extractLikelyTotalPeriod(from text: String, moratorium: Int, emiMonths: Int) -> Int {
        if moratorium > 0 && emiMonths > 0 {
            return moratorium + emiMonths
        }
        
        let monthValues = extractRegexMatches(#"(\d{1,3})\s*months?"#, in: text)
            .compactMap { Int($0) }
            .filter { $0 > 0 && $0 <= 360 }
        
        if let largest = monthValues.max(), largest >= max(moratorium, emiMonths) {
            return largest
        }
        
        return 0
    }
    
    private func isLikelyLoanAmount(_ value: Double, insuranceAmount: Double) -> Bool {
        value >= 1_000 && value != insuranceAmount
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
    
    private func extractRegexMatches(_ pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return [] }
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        return matches.compactMap { result in
            guard result.numberOfRanges > 1 else { return nil }
            return nsString.substring(with: result.range(at: 1))
        }
    }
    
    private func cleanNumeric(_ text: String) -> Double? {
        let allowed = CharacterSet.decimalDigits.union(CharacterSet(charactersIn: ".,"))
        let filtered = text.components(separatedBy: allowed.inverted).joined()
        let clean = filtered.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces)
        return Double(clean)
    }
    
    private func scanForMetadata(text: String, into data: inout LoanData) {
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            let nLine = line.lowercased()
            if nLine.contains("place:") || nLine.contains("date:") || nLine.contains("ref:") { continue }
            
            if nLine.contains("scheme") || nLine.contains("product") {
                let parts = line.components(separatedBy: ":")
                if parts.count > 1 {
                    let scheme = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    if scheme.count > 3 && !scheme.contains("/") && !scheme.contains("-") {
                        data.scheme = scheme
                    }
                }
            }
        }
    }
    
    private func extractSanctionDate(from text: String) -> Date? {
        let patterns = [
            #"\bdate\s*[:\-]?\s*(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})"#,
            #"\bdated\s+(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})"#,
            #"\b(\d{1,2}\s+[a-zA-Z]{3,9}\s+\d{4})\b"#,
            #"\b(\d{1,2}[-/]\d{1,2}[-/]\d{4})\b"#
        ]
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for pattern in patterns {
            guard let match = extractRegex(pattern, in: text) else { continue }
            for format in ["dd-MM-yyyy", "dd/MM/yyyy", "d MMM yyyy", "dd MMM yyyy", "dd-MM-yy"] {
                formatter.dateFormat = format
                if let date = formatter.date(from: match) {
                    return date
                }
            }
        }
        return nil
    }
    
    private func detectLoanType(loanData: LoanData, text: String) -> AssessmentLoanEntry.LoanType {
        let nText = text.lowercased()
        if nText.contains("education") || nText.contains("gyan") || nText.contains("student") { return .educationLoan }
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
        return "Bank of Baroda"
    }
    
    private func calculateConfidence(data: LoanData) -> Double {
        var score = 0.0
        if data.principal > 0 { score += 0.3 }
        if data.interestRate > 0 { score += 0.25 }
        if data.totalLoanPeriodMonths > 0 || data.moratorium > 0 { score += 0.25 }
        if !data.scheme.isEmpty { score += 0.1 }
        if data.insurance > 0 { score += 0.1 }
        return score
    }
}
