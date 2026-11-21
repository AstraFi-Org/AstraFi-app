import Foundation

/// Goal categories used to select relevant research and planning assumptions.
enum GoalPlanningCategory: String, Codable, CaseIterable, Identifiable {
    case vehicle = "Vehicle Purchase"
    case marriage = "Marriage"
    case property = "House / Property Purchase"
    case childEducation = "Child Education"
    case higherEducation = "Higher Education"
    case retirement = "Retirement"
    case wealthCreation = "Wealth Creation"
    case emergencyFund = "Emergency Fund"
    case healthcare = "Healthcare"
    case custom = "Custom Goal"

    var id: String { rawValue }

    static func infer(from name: String) -> Self {
        let value = name.lowercased()
        if value.contains("car") || value.contains("vehicle") || value.contains("bike") { return .vehicle }
        if value.contains("wedding") || value.contains("marriage") || value.contains("marry") { return .marriage }
        if value.contains("house") || value.contains("home") || value.contains("property") { return .property }
        if value.contains("child") && value.contains("edu") { return .childEducation }
        if value.contains("edu") || value.contains("college") || value.contains("university") { return .higherEducation }
        if value.contains("retire") { return .retirement }
        if value.contains("wealth") { return .wealthCreation }
        if value.contains("emergency") { return .emergencyFund }
        if value.contains("health") || value.contains("medical") || value.contains("treatment") { return .healthcare }
        return .custom
    }

    var defaultGrowthRates: (conservative: Double, moderate: Double, high: Double) {
        // No category data feed is integrated yet, so a rate must never be implied by category.
        (0, 0, 0)
    }

    var assumptionRationale: String {
        switch self {
        case .vehicle: return "No official model, variant, or local price history is connected. Rates start at 0% until you enter an assumption."
        case .marriage: return "There is no universal official marriage cost index. Rates start at 0% until you enter an event-budget assumption."
        case .property: return "No location-specific property index is connected. This is not a property forecast; rates start at 0%."
        case .childEducation, .higherEducation: return "No institution-specific fee history is connected. Rates start at 0% until you enter an assumption."
        case .retirement: return "Household, healthcare, and lifestyle costs are not yet modelled separately. Rates start at 0%."
        case .wealthCreation: return "No cost-growth assumption is applied to a user-defined wealth target."
        case .emergencyFund: return "An emergency target should use essential expenses and selected coverage months. Rates start at 0%."
        case .healthcare: return "No treatment or provider pricing is connected. Rates start at 0% until you enter an assumption."
        case .custom: return "No default growth assumption. Enter your own documented assumption."
        }
    }
}

enum GoalSourceVerification: String, Codable, CaseIterable, Identifiable {
    case userEstimate = "User-provided estimate"
    case verified = "Verified"
    case unavailable = "Source verification unavailable"
    case outdated = "Previously verified; may be outdated"

    var id: String { rawValue }
}

struct GoalDataSource: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var url: String
    var sourceType: String
    var retrievedValue: Double
    var unit: String
    var geography: String?
    var applicableDate: Date?
    var retrievedAt: Date
    var verification: GoalSourceVerification
    var confidence: String
    var calculationMethod: String

    var validURL: URL? {
        guard let url = URL(string: url), ["https", "http"].contains(url.scheme?.lowercased() ?? ""), url.host != nil else { return nil }
        return url
    }
}

struct GoalCostAssumptions: Codable, Equatable {
    var conservativeRate: Double
    var moderateRate: Double
    var highRate: Double
    var rationale: String
    var isUserCustomized: Bool

    static func defaults(for category: GoalPlanningCategory) -> Self {
        let rates = category.defaultGrowthRates
        return .init(conservativeRate: rates.conservative, moderateRate: rates.moderate, highRate: rates.high,
                     rationale: category.assumptionRationale, isUserCustomized: false)
    }
}

struct GoalPlanningMetadata: Codable, Equatable {
    var category: GoalPlanningCategory
    var location: String?
    var requirementType: String
    var source: GoalDataSource?
    var assumptions: GoalCostAssumptions
    var savedMonthlyContribution: Double?
    var expectedInvestmentReturn: Double?

    init(category: GoalPlanningCategory, location: String? = nil, requirementType: String = "Estimated cost",
         source: GoalDataSource? = nil, assumptions: GoalCostAssumptions? = nil,
         savedMonthlyContribution: Double? = nil, expectedInvestmentReturn: Double? = nil) {
        self.category = category
        self.location = location
        self.requirementType = requirementType
        self.source = source
        self.assumptions = assumptions ?? .defaults(for: category)
        self.savedMonthlyContribution = savedMonthlyContribution
        self.expectedInvestmentReturn = expectedInvestmentReturn
    }
}

struct GoalCostScenario: Identifiable, Equatable {
    let name: String
    let rate: Double
    let futureCost: Double
    var id: String { name }
}

struct GoalInvestmentScenario: Identifiable, Equatable {
    let name: String
    let annualReturn: Double
    let monthlyContribution: Double
    let projectedValue: Double
    let totalContribution: Double
    let shortfall: Double
    let risk: String
    var id: String { name }
}

enum GoalPlanningCalculator {
    static func years(until date: Date, from now: Date = Date()) -> Double {
        max(0, date.timeIntervalSince(now) / (365.2425 * 24 * 60 * 60))
    }

    static func futureCost(current: Double, annualGrowth: Double, years: Double) -> Double {
        guard current.isFinite, annualGrowth.isFinite, years.isFinite, current >= 0, annualGrowth > -1 else { return 0 }
        return current * pow(1 + annualGrowth, max(0, years))
    }

    static func costScenarios(current: Double, years: Double, assumptions: GoalCostAssumptions) -> [GoalCostScenario] {
        [("Conservative", assumptions.conservativeRate), ("Moderate", assumptions.moderateRate), ("High cost", assumptions.highRate)]
            .map { GoalCostScenario(name: $0.0, rate: $0.1, futureCost: futureCost(current: current, annualGrowth: $0.1, years: years)) }
    }

    /// End-of-month contributions with a nominal annual return divided into monthly periods.
    static func investmentScenarios(target: Double, months: Int, existingSavings: Double) -> [GoalInvestmentScenario] {
        let months = max(0, months)
        let plans: [(String, Double, String)] = months <= 12
            ? [("Conservative", 0.03, "Lower risk"), ("Balanced", 0.04, "Lower to moderate risk"), ("Growth-oriented", 0.05, "Moderate risk; short horizon")]
            : [("Conservative", 0.04, "Lower risk"), ("Balanced", 0.07, "Moderate risk"), ("Growth-oriented", 0.10, "Higher volatility")]
        return plans.map { plan in
            let monthlyRate = plan.1 / 12
            let factor = months == 0 ? 0 : (pow(1 + monthlyRate, Double(months)) - 1) / monthlyRate
            let existingFutureValue = max(0, existingSavings) * pow(1 + monthlyRate, Double(months))
            let monthly = factor > 0 ? max(0, target - existingFutureValue) / factor : max(0, target - existingFutureValue)
            let projected = monthly * factor + existingFutureValue
            return GoalInvestmentScenario(name: plan.0, annualReturn: plan.1, monthlyContribution: monthly,
                                          projectedValue: projected, totalContribution: monthly * Double(months) + max(0, existingSavings),
                                          shortfall: max(0, target - projected), risk: plan.2)
        }
    }
}
