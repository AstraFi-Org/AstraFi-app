import Foundation

/// Derived insurance insights. Nothing in this file is persisted: it is recalculated
/// whenever the profile or a policy changes.

enum InsuranceDataSource: String {
    case userEntered = "Based on your policy details"
    case policyDocument = "From the policy document"
    case userConfirmed = "Confirmed by you"
    case connectedData = "From connected data"
    case officialReference = "From an official reference"
    case calculated = "Calculated by AstraFi"
    case unknown = "Unknown"
}

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

enum InsuranceProductKind: String {
    case term = "Term"
    case endowment = "Endowment"
    case moneyBack = "Money-Back"
    case ulip = "ULIP"
    case wholeLife = "Whole Life"
    case annuity = "Annuity"
    case health = "Health"
    case familyFloater = "Family Floater"
    case criticalIllness = "Critical Illness"
    case personalAccident = "Personal Accident"
    case motor = "Motor"
    case property = "Property"
    case travel = "Travel"
    case other = "Other"

    var purposeLabel: String {
        switch self {
        case .term, .personalAccident: return "Family Protection"
        case .endowment, .moneyBack, .wholeLife: return "Protection + Savings"
        case .ulip: return "Protection + Investment"
        case .annuity: return "Retirement Income"
        case .health, .familyFloater: return "Health Cover"
        case .criticalIllness: return "Illness Cover"
        case .motor: return "Vehicle Cover"
        case .property: return "Property Cover"
        case .travel: return "Travel Cover"
        case .other: return "Recorded Cover"
        }
    }

    var usesLifeProtectionGap: Bool {
        switch self {
        case .term, .endowment, .moneyBack, .ulip, .wholeLife: return true
        default: return false
        }
    }

    var usesLiquidity: Bool {
        switch self {
        case .endowment, .moneyBack, .ulip, .wholeLife, .annuity: return true
        default: return false
        }
    }

    var usesGoalAlignment: Bool {
        switch self {
        case .endowment, .moneyBack, .ulip, .annuity: return true
        default: return false
        }
    }

    var usesNominee: Bool {
        switch self {
        case .term, .endowment, .moneyBack, .ulip, .wholeLife, .annuity, .personalAccident: return true
        default: return false
        }
    }

    var usesRenewal: Bool {
        switch self {
        case .health, .familyFloater, .motor, .travel, .property, .criticalIllness, .personalAccident: return true
        default: return false
        }
    }
}

enum InsuranceProtectionStatus: String {
    case adequate = "Adequate"
    case review = "Review"
    case significantGap = "Significant Gap"
    case notApplicable = "Not applicable"
}

struct InsuranceAction: Identifiable {
    enum Priority: Int { case critical = 0, high, medium, low }
    let id = UUID()
    let priority: Priority
    let title: String
    let detail: String
    let impact: String
    let nextStep: String

    init(priority: Priority, title: String, detail: String, nextStep: String, impact: String = "") {
        self.priority = priority
        self.title = title
        self.detail = detail
        self.impact = impact
        self.nextStep = nextStep
    }
}

struct InsuranceScenario: Identifiable {
    enum Tone { case protection, maturity, caution, information }
    let id = UUID()
    let title: String
    let trigger: String
    let recipient: String
    let benefitDescription: String
    let estimatedAmount: Double?
    let tone: Tone
}

struct InsuranceBenefit: Identifiable {
    let id = UUID()
    let title: String
    let amount: Double?
    let detail: String
}

struct InsuranceScoreComponent {
    let label: String
    let weight: Double
    let score: Double
}

struct InsuranceAnalysisResult {
    let productKind: InsuranceProductKind
    let purposeLabel: String
    let summary: String
    let insuranceHealthScore: Int?
    let insuranceHealthStatus: InsuranceHealthStatus
    let scoreComponents: [InsuranceScoreComponent]
    let premiumBurdenPercentage: Double?
    let surplusBurdenPercentage: Double?
    let monthlyPremiumEquivalent: Double
    let annualizedPremium: Double
    let premiumAffordabilityStatus: InsuranceAffordabilityStatus
    let currentCoverage: Double
    let estimatedRequiredCoverage: Double?
    let protectionGap: Double?
    let protectionStatus: InsuranceProtectionStatus
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
    let benefits: [InsuranceBenefit]
    let scenarios: [InsuranceScenario]
    let trackingItems: [String]
    let actualPremium: Double
    let premiumFrequency: AstraPremiumFrequency
    let policySurrenderValue: Double?
    let healthCoverageUsed: Double?
    let healthCoverageRemaining: Double?
    let outOfPocketRisk: Double?
    let sourceCaption: String

    var hasProtectionAnalysis: Bool { estimatedRequiredCoverage != nil }
    var coverageStatus: String { protectionStatus.rawValue }
    var liquidityStatus: String {
        guard totalPremiumPaid > 0 else { return "Not enough payment history" }
        guard let surrender = policySurrenderValue else { return "Not provided" }
        return surrender < totalPremiumPaid ? "Review" : "Documented value available"
    }
}

struct HouseholdInsuranceSummary {
    let annualPremium: Double
    let monthlyEquivalent: Double
    let lifeCover: Double
    let estimatedRequiredProtection: Double
    let protectionGap: Double
    let premiumToIncome: Double?
    let premiumToSurplus: Double?
}

enum InsuranceAnalysisEngine {
    static func analyze(policy: AstraInsurance, profile: AstraUserProfile, now: Date = Date()) -> InsuranceAnalysisResult {
        let kind = productKind(for: policy)
        let warnings = validate(policy, kind: kind)
        let blocking = warnings.contains { $0.hasPrefix("Invalid:") }

        let premium = normalizedPremium(policy)
        let annualIncome = max(0, profile.basicDetails.monthlyIncomeAfterTax > 0
            ? profile.basicDetails.monthlyIncomeAfterTax * 12
            : profile.basicDetails.monthlyIncome * 12)
        let monthlyEMI = profile.loans.reduce(0.0) { $0 + max(0, $1.calculatedEMI) }
        let monthlyIncome = profile.basicDetails.monthlyIncomeAfterTax > 0
            ? profile.basicDetails.monthlyIncomeAfterTax
            : profile.basicDetails.monthlyIncome
        let surplusBeforePremium = monthlyIncome - profile.basicDetails.monthlyExpenses - monthlyEMI
        let annualSurplus = surplusBeforePremium * 12
        let burden = annualIncome > 0 ? (premium.annual / annualIncome) * 100 : nil
        let surplusBurden = annualSurplus > 0 ? (premium.annual / annualSurplus) * 100 : nil
        let goalImpact = surplusBeforePremium.isFinite ? surplusBeforePremium - premium.monthlyEquivalent : nil

        let household = householdProtection(profile: profile)
        let cover = recordedProtectionAmount(policy, kind: kind)
        let required = kind.usesLifeProtectionGap ? household.estimatedRequiredProtection : nil
        let gap = required.map { max(0, $0 - household.lifeCover) }
        let protectionStatus = protectionBand(gap: gap, required: required)

        let due = nextDueDate(policy, now: now)
        let days = due.map { max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: now), to: Calendar.current.startOfDay(for: $0)).day ?? 0) }
        let progress = policyProgress(policy, now: now)
        let paid = policy.payments.filter { $0.status == .paid }.reduce(0.0) { $0 + max(0, $1.amount) }
        let remaining = remainingPremium(policy, paid: paid, annual: premium.annual)
        let premiumProgressValue = premiumPayingProgress(policy, now: now)
        let affordability: InsuranceAffordabilityStatus = {
            guard let burden else { return .unavailable }
            if burden <= 7 { return .comfortable }
            if burden <= 15 { return .review }
            return .highBurden
        }()

        let healthUsed = kind == .health || kind == .familyFloater
            ? policy.claims.filter { $0.status == .approved }.reduce(0.0) { $0 + max(0, $1.amount) }
            : nil
        let healthRemaining = healthUsed.flatMap { used -> Double? in
            guard policy.sumAssured > 0 else { return nil }
            return max(0, policy.sumAssured - used)
        }
        let oop = outOfPocketRisk(policy, kind: kind)

        let actions = prioritizedActions(
            policy: policy,
            kind: kind,
            warnings: warnings,
            gap: gap,
            required: required,
            affordability: affordability,
            burden: burden,
            days: days,
            now: now,
            surplusBurden: surplusBurden
        )

        let components = scoreComponents(
            policy: policy,
            kind: kind,
            gap: gap,
            required: required,
            affordability: affordability,
            days: days
        )
        let (score, status) = finalizeScore(components: components, policy: policy, blocking: blocking, kind: kind, cover: cover)

        return InsuranceAnalysisResult(
            productKind: kind,
            purposeLabel: kind.purposeLabel,
            summary: summaryText(kind: kind, status: status, gap: gap, required: required, affordability: affordability, policy: policy),
            insuranceHealthScore: score,
            insuranceHealthStatus: status,
            scoreComponents: components,
            premiumBurdenPercentage: burden,
            surplusBurdenPercentage: surplusBurden,
            monthlyPremiumEquivalent: premium.monthlyEquivalent,
            annualizedPremium: premium.annual,
            premiumAffordabilityStatus: affordability,
            currentCoverage: cover,
            estimatedRequiredCoverage: required,
            protectionGap: gap,
            protectionStatus: protectionStatus,
            nextPremiumDue: due,
            daysUntilPremiumDue: days,
            policyProgress: progress,
            premiumProgress: premiumProgressValue,
            totalPremiumPaid: paid,
            totalPremiumRemaining: remaining,
            policyReviewRequired: status != .good && status != .strong,
            topIssues: actions,
            recommendations: actions.map(\.nextStep),
            goalImpact: goalImpact,
            dataValidationWarnings: warnings,
            benefits: benefits(for: policy, kind: kind),
            scenarios: scenarios(for: policy, kind: kind),
            trackingItems: trackingItems(for: policy, kind: kind),
            actualPremium: premium.installment,
            premiumFrequency: policy.premiumFrequency,
            policySurrenderValue: policy.surrenderValue,
            healthCoverageUsed: healthUsed,
            healthCoverageRemaining: healthRemaining,
            outOfPocketRisk: oop,
            sourceCaption: "Based on your policy details. Calculated values are labelled separately."
        )
    }

    static func householdProtection(profile: AstraUserProfile) -> HouseholdInsuranceSummary {
        let annualIncome = max(0, profile.basicDetails.monthlyIncomeAfterTax > 0
            ? profile.basicDetails.monthlyIncomeAfterTax * 12
            : profile.basicDetails.monthlyIncome * 12)
        let monthlyIncome = profile.basicDetails.monthlyIncomeAfterTax > 0
            ? profile.basicDetails.monthlyIncomeAfterTax
            : profile.basicDetails.monthlyIncome
        let monthlyEMI = profile.loans.reduce(0.0) { $0 + max(0, $1.calculatedEMI) }
        let surplus = monthlyIncome - profile.basicDetails.monthlyExpenses - monthlyEMI
        let annualPremium = profile.insurances.reduce(0.0) { $0 + normalizedPremium($1).annual }
        let lifeCover = profile.insurances.reduce(0.0) { sum, policy in
            let kind = productKind(for: policy)
            guard kind.usesLifeProtectionGap else { return sum }
            return sum + recordedProtectionAmount(policy, kind: kind)
        }
        let required = estimatedProtectionNeed(profile: profile, annualIncome: annualIncome)
        let incomeRatio = annualIncome > 0 ? (annualPremium / annualIncome) * 100 : nil
        let surplusRatio = surplus > 0 ? (annualPremium / (surplus * 12)) * 100 : nil
        return HouseholdInsuranceSummary(
            annualPremium: annualPremium,
            monthlyEquivalent: annualPremium / 12,
            lifeCover: lifeCover,
            estimatedRequiredProtection: required,
            protectionGap: max(0, required - lifeCover),
            premiumToIncome: incomeRatio,
            premiumToSurplus: surplusRatio
        )
    }

    static func productKind(for policy: AstraInsurance) -> InsuranceProductKind {
        switch policy.insuranceType {
        case .termLifeInsurance: return .term
        case .ulip: return .ulip
        case .health:
            let plan = (policy.healthDetails?.planType ?? "").lowercased()
            return plan.contains("float") || plan.contains("family") ? .familyFloater : .health
        case .criticalIllness: return .criticalIllness
        case .motor: return .motor
        case .travel: return .travel
        case .personalAccident: return .personalAccident
        case .property: return .property
        case .life, .other:
            return kindFromText(
                [policy.lifeDetails?.lifeInsuranceType, policy.planName, policy.insuranceType.rawValue]
                    .compactMap { $0 }
                    .joined(separator: " ")
            )
        }
    }

    static func normalizedPremium(_ policy: AstraInsurance) -> (installment: Double, annual: Double, monthlyEquivalent: Double) {
        let periods = periodsPerYear(policy.premiumFrequency)
        let installment: Double
        let annual: Double
        if let recorded = policy.installmentPremium, recorded > 0 {
            installment = recorded
            annual = periods > 0 ? recorded * periods : recorded
        } else {
            annual = max(0, policy.annualPremium)
            installment = periods > 0 ? annual / periods : annual
        }
        return (installment, annual, annual / 12)
    }

    static func validate(_ policy: AstraInsurance, kind: InsuranceProductKind? = nil) -> [String] {
        let kind = kind ?? productKind(for: policy)
        var issues: [String] = []
        if policy.annualPremium < 0 || policy.basePremium < 0 || policy.taxesGST < 0 || policy.addOnCost < 0
            || (policy.installmentPremium ?? 0) < 0 {
            issues.append("Invalid: Premium amounts cannot be negative.")
        }
        if policy.sumAssured < 0 { issues.append("Invalid: Sum assured cannot be negative.") }
        if let value = policy.surrenderValue, value < 0 { issues.append("Invalid: Surrender value cannot be negative.") }
        if let value = policy.expectedMaturityAmount, value < 0 { issues.append("Invalid: Maturity benefit cannot be negative.") }
        if let date = policy.expiryDate, date < policy.startDate { issues.append("Invalid: Expiry date is before the policy start date.") }
        if let date = policy.maturityDate, date < policy.startDate { issues.append("Invalid: Maturity date is before the policy start date.") }

        let breakdown = policy.basePremium + policy.taxesGST + policy.addOnCost
        if breakdown > 0, abs(policy.annualPremium - breakdown) > max(100, breakdown * 0.05) {
            issues.append("Premium breakdown does not match annual premium.")
        }
        let periods = periodsPerYear(policy.premiumFrequency)
        if let installment = policy.installmentPremium, installment > 0, periods > 0, policy.annualPremium > 0 {
            let expected = installment * periods
            if abs(policy.annualPremium - expected) > max(1, expected * 0.02) {
                issues.append("Premium breakdown does not match annual premium.")
            }
        }

        if kind.usesNominee, policy.lifeDetails?.nomineeName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
            issues.append("Nominee is not provided for this life policy.")
        }
        if kind == .term, positive(policy.lifeDetails?.maturityBenefit) || positive(policy.expectedMaturityAmount) {
            issues.append("A maturity benefit is recorded for a term policy; verify that this product includes it.")
        }
        if kind == .term, policy.surrenderValue != nil {
            issues.append("A surrender value is recorded where it may not apply; verify against the policy document.")
        }
        if kind == .health || kind == .familyFloater, policy.sumAssured <= 0 {
            issues.append("Health coverage amount is not provided.")
        }
        return issues
    }

    static func periodsPerYear(_ frequency: AstraPremiumFrequency) -> Double {
        switch frequency {
        case .monthly: return 12
        case .quarterly: return 4
        case .halfYearly: return 2
        case .yearly: return 1
        case .single: return 0
        }
    }

    // MARK: - Internals

    private static func kindFromText(_ text: String) -> InsuranceProductKind {
        let t = text.lowercased()
        if t.contains("ulip") { return .ulip }
        if t.contains("money") && t.contains("back") { return .moneyBack }
        if t.contains("whole") { return .wholeLife }
        if t.contains("annuity") || t.contains("pension") { return .annuity }
        if t.contains("term") { return .term }
        if t.contains("accident") { return .personalAccident }
        if t.contains("endow") || t.contains("labh") || t.contains("jeevan") { return .endowment }
        if t.contains("life") { return .endowment }
        return .other
    }

    private static func recordedProtectionAmount(_ policy: AstraInsurance, kind: InsuranceProductKind) -> Double {
        switch kind {
        case .term, .endowment, .moneyBack, .ulip, .wholeLife, .personalAccident:
            return max(0, policy.lifeDetails?.deathBenefit ?? policy.sumAssured)
        case .health, .familyFloater, .criticalIllness, .travel, .property:
            return max(0, policy.sumAssured)
        case .motor:
            return max(0, policy.motorDetails?.idv ?? policy.sumAssured)
        case .annuity, .other:
            return max(0, policy.sumAssured)
        }
    }

    private static func estimatedProtectionNeed(profile: AstraUserProfile, annualIncome: Double) -> Double {
        let dependents = profile.basicDetails.adultDependents + profile.basicDetails.childDependents
        let years = dependents > 0 ? min(15, 8 + dependents * 2) : 3
        let incomeReplacement = annualIncome * Double(years)
        let liabilities = profile.loans.reduce(0.0) { $0 + max(0, $1.remainingPrincipal) }
        let remainingGoals = profile.goals.reduce(0.0) { $0 + max(0, $1.targetAmount - $1.currentAmount) }
        let familyObligations = dependents > 0 ? remainingGoals * 0.25 : 0
        let liquidProtection = profile.basicDetails.emergencyFundAmount
            + profile.assets.savingsAccountAmount
            + profile.assets.currentAccountAmount
            + profile.assets.depositsAmount
        return max(0, incomeReplacement + liabilities + familyObligations - liquidProtection)
    }

    private static func protectionBand(gap: Double?, required: Double?) -> InsuranceProtectionStatus {
        guard let gap, let required, required > 0 else { return .notApplicable }
        let ratio = gap / required
        if ratio <= 0.10 { return .adequate }
        if ratio <= 0.35 { return .review }
        return .significantGap
    }

    private static func nextDueDate(_ policy: AstraInsurance, now: Date) -> Date? {
        guard normalizedPremium(policy).annual > 0, policy.premiumFrequency != .single else { return nil }
        let calendar = Calendar.current
        let interval: Calendar.Component
        let amount: Int
        switch policy.premiumFrequency {
        case .monthly: (interval, amount) = (.month, 1)
        case .quarterly: (interval, amount) = (.month, 3)
        case .halfYearly: (interval, amount) = (.month, 6)
        case .yearly: (interval, amount) = (.year, 1)
        case .single: return nil
        }
        var date = policy.startDate
        var guardCount = 0
        while date < now && guardCount < 600 {
            date = calendar.date(byAdding: interval, value: amount, to: date) ?? date.addingTimeInterval(31_536_000)
            guardCount += 1
        }
        return date
    }

    private static func policyProgress(_ policy: AstraInsurance, now: Date) -> Double? {
        if let years = policy.policyTermYears, years > 0 {
            let end = Calendar.current.date(byAdding: .year, value: years, to: policy.startDate) ?? policy.maturityDate
            return dateProgress(start: policy.startDate, end: end, now: now)
        }
        return dateProgress(start: policy.startDate, end: policy.maturityDate ?? policy.expiryDate, now: now)
    }

    private static func premiumPayingProgress(_ policy: AstraInsurance, now: Date) -> Double? {
        guard let ppt = policy.premiumPayingTermYears, ppt > 0 else { return nil }
        let elapsed = Calendar.current.dateComponents([.day], from: policy.startDate, to: now).day ?? 0
        let totalDays = Double(ppt) * 365.25
        guard totalDays > 0 else { return nil }
        return min(1, max(0, Double(elapsed) / totalDays))
    }

    private static func remainingPremium(_ policy: AstraInsurance, paid: Double, annual: Double) -> Double? {
        guard let ppt = policy.premiumPayingTermYears, ppt > 0 else { return nil }
        return max(0, annual * Double(ppt) - paid)
    }

    private static func dateProgress(start: Date, end: Date?, now: Date) -> Double? {
        guard let end, end > start else { return nil }
        return min(1, max(0, now.timeIntervalSince(start) / end.timeIntervalSince(start)))
    }

    private static func outOfPocketRisk(_ policy: AstraInsurance, kind: InsuranceProductKind) -> Double? {
        guard kind == .health || kind == .familyFloater else { return nil }
        let deductible = policy.healthDetails?.deductible
        let copay = policy.healthDetails?.copayPercent
        guard deductible != nil || copay != nil else { return nil }
        let cover = max(0, policy.sumAssured)
        let copayAmount = (copay != nil && cover > 0) ? cover * min(100, max(0, copay!)) / 100 : 0
        return (deductible ?? 0) + copayAmount
    }

    private static func positive(_ value: Double?) -> Bool { (value ?? 0) > 0 }

    private static func healthStatus(_ score: Int) -> InsuranceHealthStatus {
        switch score {
        case ..<40: .critical
        case 40..<60: .needsAttention
        case 60..<75: .reviewRecommended
        case 75..<90: .good
        default: .strong
        }
    }

    private static func scoreComponents(
        policy: AstraInsurance,
        kind: InsuranceProductKind,
        gap: Double?,
        required: Double?,
        affordability: InsuranceAffordabilityStatus,
        days: Int?
    ) -> [InsuranceScoreComponent] {
        var items: [InsuranceScoreComponent] = []

        if kind.usesLifeProtectionGap, let required, required > 0, let gap {
            let ratio = 1 - min(1, gap / required)
            items.append(.init(label: "Coverage Adequacy", weight: 0.30, score: ratio))
        } else if kind == .health || kind == .familyFloater || kind == .criticalIllness {
            items.append(.init(label: "Coverage Adequacy", weight: 0.30, score: policy.sumAssured > 0 ? 0.85 : 0.25))
        } else if kind == .motor || kind == .property {
            let cover = kind == .motor ? (policy.motorDetails?.idv ?? policy.sumAssured) : policy.sumAssured
            items.append(.init(label: "Coverage Adequacy", weight: 0.30, score: cover > 0 ? 0.80 : 0.30))
        }

        switch affordability {
        case .comfortable: items.append(.init(label: "Premium Affordability", weight: 0.20, score: 1.0))
        case .review: items.append(.init(label: "Premium Affordability", weight: 0.20, score: 0.62))
        case .highBurden: items.append(.init(label: "Premium Affordability", weight: 0.20, score: 0.28))
        case .unavailable: break
        }

        let statusScore: Double
        switch policy.status {
        case .active: statusScore = 1.0
        case .gracePeriod: statusScore = 0.45
        case .matured: statusScore = 0.70
        case .lapsed: statusScore = 0.05
        }
        items.append(.init(label: "Policy Status", weight: 0.15, score: statusScore))

        if kind.usesLiquidity {
            if let surrender = policy.surrenderValue, surrender > 0 {
                items.append(.init(label: "Liquidity", weight: 0.10, score: 0.80))
            } else {
                items.append(.init(label: "Liquidity", weight: 0.10, score: 0.45))
            }
        }

        if kind.usesGoalAlignment {
            let hasMaturity = positive(policy.lifeDetails?.maturityBenefit) || positive(policy.expectedMaturityAmount)
            items.append(.init(label: "Goal Alignment", weight: 0.10, score: hasMaturity ? 0.75 : 0.50))
        }

        if kind.usesNominee {
            let hasNominee = !(policy.lifeDetails?.nomineeName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            items.append(.init(label: "Nominee/Documents", weight: 0.05, score: hasNominee ? 1.0 : 0.20))
        }

        items.append(.init(label: "Riders", weight: 0.05, score: policy.riders.isEmpty ? 0.55 : 0.85))

        if kind.usesRenewal {
            if policy.payments.contains(where: { $0.status == .unknown }) {
                items.append(.init(label: "Renewal Management", weight: 0.05, score: 0.50))
            } else if let days, days <= 30 {
                items.append(.init(label: "Renewal Management", weight: 0.05, score: 0.70))
            } else {
                items.append(.init(label: "Renewal Management", weight: 0.05, score: 0.90))
            }
        }

        return items
    }

    private static func finalizeScore(
        components: [InsuranceScoreComponent],
        policy: AstraInsurance,
        blocking: Bool,
        kind: InsuranceProductKind,
        cover: Double
    ) -> (Int?, InsuranceHealthStatus) {
        if blocking { return (nil, .verificationRequired) }
        let weightSum = components.reduce(0.0) { $0 + $1.weight }
        guard weightSum > 0 else { return (nil, .verificationRequired) }
        var value = Int((components.reduce(0.0) { $0 + $1.score * $1.weight } / weightSum * 100).rounded())
        if policy.status == .lapsed {
            value = min(value, 25)
            return (value, .critical)
        }
        if kind.usesLifeProtectionGap && cover <= 0 {
            return (min(value, 30), .critical)
        }
        return (max(0, min(100, value)), healthStatus(value))
    }

    private static func summaryText(
        kind: InsuranceProductKind,
        status: InsuranceHealthStatus,
        gap: Double?,
        required: Double?,
        affordability: InsuranceAffordabilityStatus,
        policy: AstraInsurance
    ) -> String {
        if policy.status == .lapsed {
            return "The recorded policy end date has passed. Confirm the current status with the insurer before relying on this cover."
        }
        if policy.payments.contains(where: { $0.status == .unknown }) {
            return "Payment status is unknown. AstraFi does not treat this policy as lapsed from missing payment records."
        }
        if kind.usesLifeProtectionGap, let gap, let required, required > 0, gap / required > 0.20 {
            return "This policy is recorded as \(kind.purposeLabel.lowercased()), but household life protection may be below the estimated family requirement."
        }
        if affordability == .highBurden {
            return "The policy is recorded, but the premium uses a high share of income relative to your other cash needs."
        }
        if status == .good || status == .strong {
            return "Your recorded details look consistent. Review this policy when income, dependents, or goals change."
        }
        return "Review the recorded details and keep the policy document handy. Amounts not entered are shown as not provided."
    }

    private static func prioritizedActions(
        policy: AstraInsurance,
        kind: InsuranceProductKind,
        warnings: [String],
        gap: Double?,
        required: Double?,
        affordability: InsuranceAffordabilityStatus,
        burden: Double?,
        days: Int?,
        now: Date,
        surplusBurden: Double?
    ) -> [InsuranceAction] {
        var actions: [InsuranceAction] = []
        let blocking = warnings.filter { $0.hasPrefix("Invalid:") }
        for warning in blocking {
            actions.append(.init(priority: .critical, title: "Verify policy data", detail: warning, nextStep: "Check the amounts and dates against your policy document.", impact: "Analysis stays limited until the recorded figures are consistent."))
        }
        if policy.status == .lapsed {
            actions.append(.init(priority: .critical, title: "Policy may no longer be in force", detail: "The recorded end date has passed.", nextStep: "Confirm the current policy status with the insurer before taking action.", impact: "Cover should not be assumed until the insurer confirms it."))
        }
        if policy.payments.contains(where: { $0.status == .unknown }) {
            actions.append(.init(priority: .high, title: "Payment status unknown", detail: "A premium payment was marked unknown.", nextStep: "Update payment status after checking your receipt or insurer app.", impact: "AstraFi will not treat unknown payment as a lapsed policy."))
        }
        if kind.usesLifeProtectionGap, let gap, let required, required > 0, gap / required > 0.20 {
            let priority: InsuranceAction.Priority = gap / required > 0.50 ? .critical : .high
            actions.append(.init(
                priority: priority,
                title: "Increase life protection",
                detail: "Recorded household life cover may be \(gap.toCurrency()) below the estimated family requirement.",
                nextStep: "Review additional protection options with a qualified professional. This is an estimate, not an official requirement.",
                impact: "Dependents could face income replacement risk if a claim event occurs."
            ))
        }
        if affordability == .highBurden, let burden {
            actions.append(.init(
                priority: .high,
                title: "Review premium affordability",
                detail: "This policy uses \(String(format: "%.1f", burden))% of recorded annual income.",
                nextStep: "Check the policy against your current cash flow; do not cancel or replace it automatically.",
                impact: "Less money remains available for emergency savings and investment goals."
            ))
        } else if let surplusBurden, surplusBurden > 40 {
            actions.append(.init(
                priority: .high,
                title: "Insurance premium is putting pressure on surplus",
                detail: "Annualized premium is \(String(format: "%.0f", surplusBurden))% of recorded surplus.",
                nextStep: "Review whether this premium still fits after expenses and loan payments.",
                impact: "Safe investment capacity is reduced by this obligation."
            ))
        }
        if kind.usesNominee && (policy.lifeDetails?.nomineeName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) {
            actions.append(.init(priority: .high, title: "Add or update nominee", detail: "Nominee information is missing in AstraFi.", nextStep: "Update policy records from the policy document.", impact: "Claim settlement can be slower if nominee details are incomplete."))
        }
        if let days, days <= 45, policy.status == .active, policy.premiumFrequency != .single {
            actions.append(.init(priority: days <= 7 ? .high : .low, title: days == 0 ? "Premium due today" : "Premium tracking", detail: "Next scheduled premium is due \(days == 1 ? "tomorrow" : "in \(days) days").", nextStep: "Update payment status after you confirm payment.", impact: "A missed premium can affect policy status according to insurer rules."))
        }
        if let maturity = policy.maturityDate ?? policy.expiryDate {
            let remaining = Calendar.current.dateComponents([.day], from: now, to: maturity).day ?? 91
            if remaining <= 90 && remaining >= 0 {
                actions.append(.init(priority: .high, title: "Policy expiring soon", detail: "The recorded end date is \(maturity.formatted(date: .abbreviated, time: .omitted)).", nextStep: "Review renewal or maturity instructions in the policy document.", impact: "Cover or maturity handling should be confirmed before the date passes."))
            }
        }
        if policy.hasPolicyDocument != true {
            actions.append(.init(priority: .medium, title: "Keep the policy document handy", detail: "A policy document has not been marked as available in AstraFi.", nextStep: "Store or confirm the latest policy document or statement.", impact: "Bonus, surrender, and claim rules cannot be verified without the document."))
        }
        if kind.usesLiquidity && policy.surrenderValue == nil {
            actions.append(.init(priority: .medium, title: "Surrender value not provided", detail: "Early-exit value is not recorded.", nextStep: "Add the latest documented surrender value if your statement includes it.", impact: "Liquidity cannot be assessed without a documented value."))
        }
        for warning in warnings where !warning.hasPrefix("Invalid:") && !actions.contains(where: { $0.detail == warning }) {
            actions.append(.init(priority: .medium, title: "Missing or inconsistent detail", detail: warning, nextStep: "Update the policy from your document.", impact: "Insights stay limited to the information you recorded."))
        }
        if actions.isEmpty {
            actions.append(.init(priority: .low, title: "Annual policy review", detail: "No urgent issues are recorded for this policy.", nextStep: "Revisit cover when income, dependents, or goals change.", impact: "Keeps protection aligned with your current life stage."))
        }
        actions.sort { $0.priority.rawValue < $1.priority.rawValue }
        return actions
    }

    private static func amount(_ value: Double?) -> Double? {
        guard let value, value > 0 else { return nil }
        return value
    }

    private static func benefits(for policy: AstraInsurance, kind: InsuranceProductKind) -> [InsuranceBenefit] {
        let death = amount(policy.lifeDetails?.deathBenefit) ?? amount(policy.sumAssured)
        let maturity = amount(policy.lifeDetails?.maturityBenefit) ?? amount(policy.expectedMaturityAmount)
        switch kind {
        case .term:
            return [InsuranceBenefit(title: "Basic life cover", amount: death, detail: "Death benefit while the policy is active. Sum assured is the basic insured amount defined by the policy.")]
        case .endowment, .wholeLife:
            return [
                InsuranceBenefit(title: "Basic life cover", amount: death, detail: "Recorded death benefit. Amounts not entered stay as not provided."),
                InsuranceBenefit(title: "Maturity", amount: maturity, detail: maturity == nil ? "Maturity value requires bonus or policy-value information from the policy document or latest statement." : "Recorded maturity benefit. Bonuses are shown only when provided.")
            ]
        case .moneyBack:
            return [
                InsuranceBenefit(title: "Basic life cover", amount: death, detail: "Recorded death benefit."),
                InsuranceBenefit(title: "Survival / money-back", amount: nil, detail: "Milestone amounts are shown only when recorded on the policy."),
                InsuranceBenefit(title: "Maturity", amount: maturity, detail: maturity == nil ? "Final benefit is not provided." : "Recorded final benefit.")
            ]
        case .ulip:
            return [
                InsuranceBenefit(title: "Life cover", amount: death, detail: "Insurance component. Not combined with fund value."),
                InsuranceBenefit(title: "Fund / maturity value", amount: maturity, detail: "Investment component only. This is not current liquid savings.")
            ]
        case .annuity:
            return [
                InsuranceBenefit(title: "Purchase / corpus", amount: amount(policy.sumAssured), detail: "Recorded purchase or corpus amount."),
                InsuranceBenefit(title: "Annuity payout", amount: maturity, detail: "Shown only when an amount is recorded. Frequency follows the premium or payout notes you entered.")
            ]
        case .health, .familyFloater:
            return [InsuranceBenefit(title: "Health coverage", amount: amount(policy.sumAssured), detail: "Subject to recorded policy conditions. AstraFi does not assume a treatment is covered.")]
        case .criticalIllness:
            return [InsuranceBenefit(title: "Critical illness cover", amount: amount(policy.sumAssured), detail: "Lump sum only if covered conditions and waiting periods in the policy are met.")]
        case .personalAccident:
            return [InsuranceBenefit(title: "Accident cover", amount: death, detail: "Accidental death or disability benefits only where recorded.")]
        case .motor:
            return [InsuranceBenefit(title: "Vehicle cover (IDV)", amount: amount(policy.motorDetails?.idv) ?? amount(policy.sumAssured), detail: "Insured declared value or recorded sum insured.")]
        case .property:
            return [InsuranceBenefit(title: "Property cover", amount: amount(policy.sumAssured), detail: "Building or contents cover only as recorded.")]
        case .travel:
            return [InsuranceBenefit(title: "Travel medical cover", amount: amount(policy.sumAssured), detail: "Only recorded cover is shown.")]
        case .other:
            return [InsuranceBenefit(title: "Recorded cover", amount: amount(policy.sumAssured), detail: "Based on your policy details.")]
        }
    }

    private static func scenarios(for policy: AstraInsurance, kind: InsuranceProductKind) -> [InsuranceScenario] {
        let death = amount(policy.lifeDetails?.deathBenefit) ?? amount(policy.sumAssured)
        let maturity = amount(policy.lifeDetails?.maturityBenefit) ?? amount(policy.expectedMaturityAmount)
        switch kind {
        case .term:
            return [
                .init(title: "Death during policy", trigger: "Death while the policy is active", recipient: "Nominee", benefitDescription: "Applicable death benefit according to policy terms.", estimatedAmount: death, tone: .protection),
                .init(title: "Survival until expiry", trigger: "Policy reaches expiry", recipient: "Policyholder", benefitDescription: "No maturity benefit unless this product specifically provides one.", estimatedAmount: nil, tone: .information)
            ]
        case .endowment, .wholeLife:
            return [
                .init(title: "Death during policy", trigger: "Death while active", recipient: "Nominee", benefitDescription: "Applicable death benefit and any documented bonuses.", estimatedAmount: death, tone: .protection),
                .init(title: "Policy reaches maturity", trigger: "Survival until maturity", recipient: "Policyholder", benefitDescription: maturity == nil ? "Maturity value requires bonus or policy-value information from the policy document or latest statement." : "Recorded maturity benefit plus applicable documented bonuses.", estimatedAmount: maturity, tone: .maturity),
                .init(title: "Early surrender", trigger: "You exit before maturity", recipient: "Policyholder", benefitDescription: "Amount you may receive if you exit early, only if a surrender value is recorded.", estimatedAmount: policy.surrenderValue, tone: .caution)
            ]
        case .moneyBack:
            return [
                .init(title: "Death during policy", trigger: "Death while active", recipient: "Nominee", benefitDescription: "Applicable death benefit according to policy terms.", estimatedAmount: death, tone: .protection),
                .init(title: "Survival benefit milestone", trigger: "A money-back due date in the policy", recipient: "Policyholder", benefitDescription: "Survival benefit amounts appear only when recorded. AstraFi does not estimate them.", estimatedAmount: nil, tone: .maturity),
                .init(title: "Maturity", trigger: "End of the policy term", recipient: "Policyholder", benefitDescription: "Final recorded benefit, if provided.", estimatedAmount: maturity, tone: .maturity),
                .init(title: "Early surrender", trigger: "You exit early", recipient: "Policyholder", benefitDescription: "Applicable surrender value if recorded.", estimatedAmount: policy.surrenderValue, tone: .caution)
            ]
        case .ulip:
            return [
                .init(title: "Death during policy", trigger: "Death while active", recipient: "Nominee", benefitDescription: "Applicable life benefit. Fund value stays a separate investment figure.", estimatedAmount: death, tone: .protection),
                .init(title: "Maturity / vesting", trigger: "Policy reaches maturity", recipient: "Policyholder", benefitDescription: "Recorded fund or maturity value. This is not treated as current liquid savings.", estimatedAmount: maturity, tone: .maturity),
                .init(title: "Lock-in / surrender", trigger: "Exit before or after lock-in", recipient: "Policyholder", benefitDescription: policy.lockInPeriodMonths.map { "Lock-in recorded as \($0) months. Surrender value is shown only when provided." } ?? "Surrender value is shown only when provided.", estimatedAmount: policy.surrenderValue, tone: .caution)
            ]
        case .annuity:
            return [
                .init(title: "Payout phase", trigger: "Annuity start according to the policy", recipient: "Policyholder", benefitDescription: "Recorded annuity amount if provided. Frequency is not assumed.", estimatedAmount: maturity, tone: .maturity),
                .init(title: "Survivor benefit", trigger: "Death after payouts begin, if the product includes it", recipient: "Nominee", benefitDescription: "Shown only when a nominee or survivor benefit is recorded.", estimatedAmount: death, tone: .protection)
            ]
        case .health, .familyFloater:
            var items = [
                InsuranceScenario(title: "Hospitalization", trigger: "Eligible hospitalization", recipient: "Policyholder / hospital", benefitDescription: "Eligible medical expenses subject to your recorded policy conditions.", estimatedAmount: nil, tone: .protection)
            ]
            if policy.healthDetails?.daycareProcedures == true {
                items.append(.init(title: "Surgery / day-care", trigger: "Recorded day-care procedures", recipient: "Policyholder / hospital", benefitDescription: "Day-care is recorded as included. Specific procedures are not assumed.", estimatedAmount: nil, tone: .information))
            }
            if let prePost = policy.healthDetails?.prePostHospitalization, !prePost.isEmpty {
                items.append(.init(title: "Pre / post hospitalization", trigger: "Around an eligible hospital stay", recipient: "Policyholder", benefitDescription: prePost, estimatedAmount: nil, tone: .information))
            }
            return items
        case .criticalIllness:
            return [.init(title: "Covered diagnosis", trigger: "Covered illness and waiting or survival period are satisfied", recipient: "Policyholder", benefitDescription: "Applicable lump-sum benefit according to the policy.", estimatedAmount: amount(policy.sumAssured), tone: .protection)]
        case .personalAccident:
            return [
                .init(title: "Accidental death", trigger: "Accident resulting in death, if covered", recipient: "Nominee", benefitDescription: "Applicable accidental death benefit according to the policy.", estimatedAmount: death, tone: .protection),
                .init(title: "Disability", trigger: "Permanent or temporary disability, if covered", recipient: "Policyholder", benefitDescription: "Disability benefits are shown only when recorded.", estimatedAmount: nil, tone: .information)
            ]
        case .motor:
            var items: [InsuranceScenario] = []
            if policy.motorDetails?.ownDamageCoverage != false {
                items.append(.init(title: "Accident", trigger: "Own-damage event", recipient: "Policyholder", benefitDescription: "Eligible own-damage claim if own-damage cover is recorded.", estimatedAmount: nil, tone: .protection))
            }
            if policy.motorDetails?.thirdPartyCoverage != false {
                items.append(.init(title: "Third-party damage", trigger: "Third-party liability event", recipient: "Third party", benefitDescription: "Third-party liability according to the policy, if recorded.", estimatedAmount: nil, tone: .information))
            }
            items.append(.init(title: "Theft", trigger: "Theft of the vehicle, if covered", recipient: "Policyholder", benefitDescription: "Applicable theft benefit according to the policy. Not assumed unless the document confirms it.", estimatedAmount: amount(policy.motorDetails?.idv), tone: .caution))
            return items
        case .property:
            return [
                .init(title: "Fire", trigger: "Fire damage, if covered", recipient: "Policyholder", benefitDescription: "Applicable only if fire is included in the recorded policy.", estimatedAmount: nil, tone: .protection),
                .init(title: "Natural disaster", trigger: "Covered natural peril", recipient: "Policyholder", benefitDescription: "Shown as a possible claim path. Cover is not assumed.", estimatedAmount: nil, tone: .information),
                .init(title: "Theft / property damage", trigger: "Theft or accidental damage, if covered", recipient: "Policyholder", benefitDescription: "Applicable according to recorded policy terms.", estimatedAmount: amount(policy.sumAssured), tone: .caution)
            ]
        case .travel:
            return [
                .init(title: "Medical emergency", trigger: "Eligible incident during the travel dates", recipient: "Policyholder", benefitDescription: "Medical cover only where recorded.", estimatedAmount: amount(policy.sumAssured), tone: .protection),
                .init(title: "Trip disruption", trigger: "Cancellation or interruption, if covered", recipient: "Policyholder", benefitDescription: "Not assumed unless the policy details include it.", estimatedAmount: nil, tone: .information)
            ]
        case .other:
            return []
        }
    }

    private static func trackingItems(for policy: AstraInsurance, kind: InsuranceProductKind) -> [String] {
        switch kind {
        case .term, .wholeLife:
            return ["Premium status", "Next premium", "Policy expiry", "Nominee", "Basic life cover", "Possible family protection shortfall", "Policy document"]
        case .endowment, .moneyBack:
            return ["Premium status", "Next premium", "Policy expiry", "Nominee", "Basic life cover", "Amount if you exit early", "Bonuses if documented", "Policy document"]
        case .ulip:
            return ["Premium status", "Fund value", "Lock-in", "Amount if you exit early", "Nominee", "Charges if documented"]
        case .annuity:
            return ["Payout amount", "Payout start", "Nominee / survivor benefit", "Policy document"]
        case .health, .familyFloater:
            return ["Renewal", "Coverage used", "Coverage remaining", "Waiting period", "Deductible", "Co-pay", "Claims"]
        case .criticalIllness:
            return ["Policy status", "Waiting period", "Covered illnesses", "Claim status"]
        case .personalAccident:
            return ["Policy expiry", "Nominee", "Accident cover", "Premium status"]
        case .motor:
            return ["Renewal", "IDV", "Own damage", "Third-party cover", "Claims"]
        case .property:
            return ["Policy period", "Sum insured", "Deductible", "Claims"]
        case .travel:
            return ["Travel dates", "Policy expiry", "Medical cover", "Emergency assistance"]
        case .other:
            return ["Premium status", "Policy expiry", "Policy document"]
        }
    }
}
