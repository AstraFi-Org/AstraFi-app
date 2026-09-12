import Foundation

/// Derived insurance insights. Nothing in this file is persisted: it is recalculated
/// whenever the profile or a policy changes.
enum InsuranceHealthStatus: String {
    case critical = "Critical"
    case needsAttention = "Needs Attention"
    case reviewRecommended = "Review Recommended"
    case good = "Good"
    case strong = "Strong"
    case verificationRequired = "Data verification required"
}

enum InsuranceAffordabilityStatus: String {
    case comfortable = "Comfortable"
    case review = "Review premium"
    case highBurden = "High premium burden"
    case unavailable = "Income needed"
}

struct InsuranceAction: Identifiable {
    enum Priority: Int { case critical = 0, high, medium, low }
    let id = UUID()
    let priority: Priority
    let title: String
    let detail: String
    let nextStep: String
}

struct InsuranceAnalysisResult {
    let insuranceHealthScore: Int?
    let insuranceHealthStatus: InsuranceHealthStatus
    let premiumBurdenPercentage: Double?
    let monthlyPremiumEquivalent: Double
    let premiumAffordabilityStatus: InsuranceAffordabilityStatus
    let currentCoverage: Double
    let estimatedRequiredCoverage: Double?
    let protectionGap: Double?
    let nextPremiumDue: Date?
    let daysUntilPremiumDue: Int?
    let policyProgress: Double?
    let premiumProgress: Double?
    let totalPremiumPaid: Double
    let totalPremiumRemaining: Double?
    let policyReviewRequired: Bool
    let topIssues: [InsuranceAction]
    let recommendations: [String]
    let goalImpact: Double?
    let dataValidationWarnings: [String]

    var hasProtectionAnalysis: Bool { estimatedRequiredCoverage != nil }
    var coverageStatus: String {
        guard let gap = protectionGap else { return "Not applicable" }
        return gap > 0 ? "Review required" : "Coverage aligned"
    }
    var liquidityStatus: String {
        guard totalPremiumPaid > 0 else { return "Not enough payment history" }
        guard let surrender = policySurrenderValue else { return "Not applicable" }
        return surrender < totalPremiumPaid ? "Review" : "Documented value available"
    }
    // Stored separately to preserve the distinction between unavailable and ₹0.
    let policySurrenderValue: Double?
}

enum InsuranceAnalysisEngine {
    static func analyze(policy: AstraInsurance, profile: AstraUserProfile, now: Date = Date()) -> InsuranceAnalysisResult {
        let warnings = validate(policy)
        let annualIncome = max(0, profile.basicDetails.monthlyIncomeAfterTax > 0
            ? profile.basicDetails.monthlyIncomeAfterTax * 12
            : profile.basicDetails.monthlyIncome * 12)
        let monthlyPremium = max(0, policy.annualPremium) / 12
        let burden = annualIncome > 0 ? (policy.annualPremium / annualIncome) * 100 : nil
        let monthlyEMI = profile.loans.reduce(0.0) { $0 + max(0, $1.calculatedEMI) }
        let surplusBeforePremium = max(0, profile.basicDetails.monthlyIncomeAfterTax - profile.basicDetails.monthlyExpenses - monthlyEMI)
        let goalImpact = max(0, surplusBeforePremium - monthlyPremium)
        let isLife = isLifeProtection(policy)
        let cover = isLife ? policy.sumAssured : 0
        let required = isLife ? estimatedProtectionNeed(profile: profile, annualIncome: annualIncome) : nil
        let gap = required.map { max(0, $0 - cover) }
        let due = nextDueDate(policy, now: now)
        let days = due.map { max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: now), to: Calendar.current.startOfDay(for: $0)).day ?? 0) }
        let progress = dateProgress(start: policy.startDate, end: policy.maturityDate ?? policy.expiryDate, now: now)
        let paid = policy.payments.filter { $0.status == .paid }.reduce(0.0) { $0 + max(0, $1.amount) }
        let scheduled = totalScheduledPremium(policy)
        let remaining = scheduled.map { max(0, $0 - paid) }
        let premiumProgress = scheduled.flatMap { $0 > 0 ? min(1, paid / $0) : nil }
        let affordability: InsuranceAffordabilityStatus = {
            guard let burden else { return .unavailable }
            if burden <= 7 { return .comfortable }
            if burden <= 15 { return .review }
            return .highBurden
        }()

        var actions: [InsuranceAction] = []
        if !warnings.isEmpty {
            actions.append(.init(priority: .critical, title: "Verify policy data", detail: warnings[0], nextStep: "Verify the amounts and dates against your policy document."))
        }
        if policy.status == .lapsed {
            actions.append(.init(priority: .critical, title: "Policy status needs attention", detail: "The recorded expiry date has passed.", nextStep: "Confirm the current policy status with the insurer before taking action."))
        }
        if let gap, let required, required > 0, gap / required > 0.20 {
            actions.append(.init(priority: .high, title: "Review protection gap", detail: "Your recorded life cover may be \(gap.toCurrency()) below the estimated protection need.", nextStep: "Review your protection requirement with a qualified insurance professional."))
        }
        if affordability == .highBurden, let burden {
            actions.append(.init(priority: .high, title: "Review premium burden", detail: "This policy uses \(String(format: "%.1f", burden))% of annual income.", nextStep: "Check the policy against your current cash flow; do not cancel or replace it automatically."))
        }
        if isLife && (policy.lifeDetails?.nomineeName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) {
            actions.append(.init(priority: .medium, title: "Nominee information incomplete", detail: "No nominee is recorded in AstraFi.", nextStep: "Verify nominee details from the policy document and update them if needed."))
        }
        if let days, days <= 30, policy.status == .active {
            actions.append(.init(priority: .low, title: days == 0 ? "Premium due today" : "Premium upcoming", detail: "The next scheduled premium is due \(days == 1 ? "tomorrow" : "in \(days) days").", nextStep: "Update payment status after you confirm payment."))
        }
        if let maturity = policy.maturityDate, Calendar.current.dateComponents([.day], from: now, to: maturity).day ?? 91 <= 90 {
            actions.append(.init(priority: .medium, title: "Maturity approaching", detail: "The recorded maturity date is \(maturity.formatted(date: .abbreviated, time: .omitted)).", nextStep: "Review maturity instructions and policy documents."))
        }
        actions.sort { $0.priority.rawValue < $1.priority.rawValue }

        let score: Int?
        let status: InsuranceHealthStatus
        if !warnings.isEmpty { score = nil; status = .verificationRequired }
        else {
            var value = 82
            if policy.status == .lapsed { value = min(value, 25) }
            if let gap, let required, required > 0 {
                let ratio = gap / required
                value -= ratio > 0.60 ? 35 : ratio > 0.20 ? 20 : 5
            }
            if affordability == .highBurden { value -= 20 } else if affordability == .review { value -= 8 }
            if isLife && (policy.lifeDetails?.nomineeName?.isEmpty ?? true) { value -= 7 }
            if let surrender = policy.surrenderValue, paid > 0, surrender < paid { value -= 5 }
            score = max(0, min(100, value))
            status = healthStatus(score!)
        }
        return .init(insuranceHealthScore: score, insuranceHealthStatus: status, premiumBurdenPercentage: burden,
                     monthlyPremiumEquivalent: monthlyPremium, premiumAffordabilityStatus: affordability,
                     currentCoverage: cover, estimatedRequiredCoverage: required, protectionGap: gap,
                     nextPremiumDue: due, daysUntilPremiumDue: days, policyProgress: progress,
                     premiumProgress: premiumProgress, totalPremiumPaid: paid, totalPremiumRemaining: remaining,
                     policyReviewRequired: status != .good && status != .strong, topIssues: actions,
                     recommendations: actions.map(\.nextStep), goalImpact: goalImpact,
                     dataValidationWarnings: warnings, policySurrenderValue: policy.surrenderValue)
    }

    static func validate(_ policy: AstraInsurance) -> [String] {
        var issues: [String] = []
        if policy.annualPremium < 0 || policy.basePremium < 0 || policy.taxesGST < 0 || policy.addOnCost < 0 { issues.append("Premium amounts cannot be negative.") }
        if policy.sumAssured < 0 { issues.append("Sum assured cannot be negative.") }
        if let value = policy.surrenderValue, value < 0 { issues.append("Surrender value cannot be negative.") }
        if let value = policy.expectedMaturityAmount, value < 0 { issues.append("Maturity benefit cannot be negative.") }
        if let date = policy.expiryDate, date < policy.startDate { issues.append("Expiry date is before the policy start date.") }
        if let date = policy.maturityDate, date < policy.startDate { issues.append("Maturity date is before the policy start date.") }
        let breakdown = policy.basePremium + policy.taxesGST + policy.addOnCost
        if breakdown > 0, abs(policy.annualPremium - breakdown) > max(100, breakdown * 0.05) {
            issues.append("Policy data mismatch: annual premium \(policy.annualPremium.toCurrency()) differs from the recorded premium breakdown \(breakdown.toCurrency()).")
        }
        return issues
    }

    private static func isLifeProtection(_ policy: AstraInsurance) -> Bool { [.life, .termLifeInsurance, .ulip].contains(policy.insuranceType) }
    private static func estimatedProtectionNeed(profile: AstraUserProfile, annualIncome: Double) -> Double {
        let dependents = profile.basicDetails.adultDependents + profile.basicDetails.childDependents
        let years = dependents > 0 ? min(15, 8 + dependents * 2) : 3
        let incomeReplacement = annualIncome * Double(years)
        let liabilities = profile.loans.reduce(0.0) { $0 + max(0, $1.remainingPrincipal) }
        let remainingGoals = profile.goals.reduce(0.0) { $0 + max(0, $1.targetAmount - $1.currentAmount) }
        let familyObligations = dependents > 0 ? remainingGoals * 0.25 : 0
        let liquidProtection = profile.basicDetails.emergencyFundAmount + profile.assets.savingsAccountAmount + profile.assets.currentAccountAmount + profile.assets.depositsAmount
        return max(0, incomeReplacement + liabilities + familyObligations - liquidProtection)
    }
    private static func nextDueDate(_ policy: AstraInsurance, now: Date) -> Date? {
        guard policy.annualPremium > 0, policy.premiumFrequency != .single else { return nil }
        let calendar = Calendar.current
        var date = policy.startDate
        while date < now { date = calendar.date(byAdding: .year, value: 1, to: date) ?? date.addingTimeInterval(31_536_000) }
        return date
    }
    private static func dateProgress(start: Date, end: Date?, now: Date) -> Double? {
        guard let end, end > start else { return nil }
        return min(1, max(0, now.timeIntervalSince(start) / end.timeIntervalSince(start)))
    }
    private static func totalScheduledPremium(_ policy: AstraInsurance) -> Double? {
        guard let end = policy.maturityDate ?? policy.expiryDate, end > policy.startDate else { return nil }
        let years = max(1, Calendar.current.dateComponents([.year], from: policy.startDate, to: end).year ?? 0)
        return policy.annualPremium * Double(years)
    }
    private static func healthStatus(_ score: Int) -> InsuranceHealthStatus {
        switch score { case ..<40: .critical; case 40..<60: .needsAttention; case 60..<75: .reviewRecommended; case 75..<90: .good; default: .strong }
    }
}
