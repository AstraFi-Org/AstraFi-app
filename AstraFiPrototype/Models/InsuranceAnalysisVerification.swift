import Foundation

/// Deterministic insurance analysis checks. These run independently of SwiftUI.
enum InsuranceAnalysisVerification {
    struct CaseResult {
        let name: String
        let passed: Bool
        let detail: String
    }

    static func run() -> [CaseResult] {
        [
            termInsurance(),
            endowmentJeevanLabh(),
            moneyBack(),
            ulipSeparatesCoverAndFund(),
            healthInsurance(),
            familyFloater(),
            criticalIllness(),
            personalAccident(),
            motor(),
            property(),
            travel(),
            missingData(),
            invalidPremiumBreakdown(),
            lapsedPolicy(),
            unknownPaymentStatus(),
            protectionGap(),
            highPremiumBurden(),
            limitedPremiumPayingTerm(),
            policyMaturityReached(),
            policyExpiringSoon()
        ]
    }

    static func allPassed() -> Bool { run().allSatisfy(\.passed) }

    // MARK: - Cases

    private static func termInsurance() -> CaseResult {
        var policy = basePolicy(type: .termLifeInsurance, cover: 10_000_000, annual: 12_000)
        policy.lifeDetails = AstraLifeInsuranceDetails(nomineeName: "Asha", deathBenefit: 10_000_000, lifeInsuranceType: "Term")
        let result = InsuranceAnalysisEngine.analyze(policy: policy, profile: profile(), now: now)
        let noMaturityScenario = result.scenarios.contains { $0.title.contains("Survival") && $0.estimatedAmount == nil }
        let passed = result.productKind == .term
            && result.purposeLabel == "Family Protection"
            && result.benefits.contains(where: { $0.title == "Basic life cover" })
            && noMaturityScenario
            && result.hasProtectionAnalysis
        return CaseResult(name: "Term insurance", passed: passed, detail: result.purposeLabel)
    }

    private static func endowmentJeevanLabh() -> CaseResult {
        var policy = basePolicy(type: .life, cover: 200_000, annual: 19_664)
        policy.provider = "LIC"
        policy.planName = "Jeevan Labh"
        policy.planNumber = "836"
        policy.premiumFrequency = .halfYearly
        policy.installmentPremium = 9_832
        policy.startDate = date(2018, 8, 28)
        policy.policyTermYears = 16
        policy.lifeDetails = AstraLifeInsuranceDetails(nomineeName: "Asha", deathBenefit: 200_000, lifeInsuranceType: "Endowment")
        let result = InsuranceAnalysisEngine.analyze(policy: policy, profile: profile(), now: now)
        let premium = InsuranceAnalysisEngine.normalizedPremium(policy)
        let maturityNotInvented = result.benefits.contains { $0.title == "Maturity" && $0.amount == nil }
        let passed = result.productKind == .endowment
            && abs(premium.annual - 19_664) < 0.5
            && abs(premium.installment - 9_832) < 0.5
            && abs(premium.monthlyEquivalent - (19_664 / 12)) < 0.05
            && maturityNotInvented
            && (result.policyProgress ?? 0) > 0.4
            && (result.policyProgress ?? 1) < 0.7
        return CaseResult(name: "Endowment", passed: passed, detail: "annual \(Int(premium.annual)) monthlyEq \(Int(premium.monthlyEquivalent))")
    }

    private static func moneyBack() -> CaseResult {
        var policy = basePolicy(type: .life, cover: 500_000, annual: 40_000)
        policy.lifeDetails = AstraLifeInsuranceDetails(deathBenefit: 500_000, lifeInsuranceType: "Money-Back")
        let result = InsuranceAnalysisEngine.analyze(policy: policy, profile: profile(), now: now)
        let passed = result.productKind == .moneyBack
            && result.scenarios.contains { $0.title.contains("Survival") }
            && result.scenarios.contains { $0.title.contains("Survival") && $0.estimatedAmount == nil }
        return CaseResult(name: "Money-back", passed: passed, detail: "\(result.scenarios.count) scenarios")
    }

    private static func ulipSeparatesCoverAndFund() -> CaseResult {
        var policy = basePolicy(type: .ulip, cover: 1_000_000, annual: 60_000)
        policy.expectedMaturityAmount = 850_000
        policy.lifeDetails = AstraLifeInsuranceDetails(nomineeName: "Asha", deathBenefit: 1_000_000, lifeInsuranceType: "ULIP")
        let result = InsuranceAnalysisEngine.analyze(policy: policy, profile: profile(), now: now)
        let cover = result.benefits.first { $0.title == "Life cover" }?.amount
        let fund = result.benefits.first { $0.title.contains("Fund") }?.amount
        let passed = result.productKind == .ulip
            && cover == 1_000_000
            && fund == 850_000
            && cover != fund
        return CaseResult(name: "ULIP", passed: passed, detail: "cover \(cover ?? -1) fund \(fund ?? -1)")
    }

    private static func healthInsurance() -> CaseResult {
        var policy = basePolicy(type: .health, cover: 500_000, annual: 18_000)
        policy.healthDetails = AstraHealthInsuranceDetails(planType: "Individual", deductible: 10_000, copayPercent: 10)
        policy.claims = [AstraClaim(date: now, amount: 50_000, status: .approved)]
        let result = InsuranceAnalysisEngine.analyze(policy: policy, profile: profile(), now: now)
        let passed = result.productKind == .health
            && result.healthCoverageUsed == 50_000
            && result.healthCoverageRemaining == 450_000
            && result.outOfPocketRisk != nil
            && result.estimatedRequiredCoverage == nil
        return CaseResult(name: "Health insurance", passed: passed, detail: "remaining \(result.healthCoverageRemaining ?? -1)")
    }

    private static func familyFloater() -> CaseResult {
        var policy = basePolicy(type: .health, cover: 700_000, annual: 22_000)
        policy.healthDetails = AstraHealthInsuranceDetails(
            planType: "Family Floater",
            coveredMembers: [AstraCoveredMember(name: "Self", age: 34, relationship: "Self")]
        )
        let result = InsuranceAnalysisEngine.analyze(policy: policy, profile: profile(), now: now)
        return CaseResult(name: "Family floater", passed: result.productKind == .familyFloater, detail: result.productKind.rawValue)
    }

    private static func criticalIllness() -> CaseResult {
        var policy = basePolicy(type: .criticalIllness, cover: 1_000_000, annual: 9_000)
        let result = InsuranceAnalysisEngine.analyze(policy: policy, profile: profile(), now: now)
        let passed = result.productKind == .criticalIllness
            && result.scenarios.contains { $0.title.contains("diagnosis") }
        return CaseResult(name: "Critical illness", passed: passed, detail: result.purposeLabel)
    }

    private static func personalAccident() -> CaseResult {
        var policy = basePolicy(type: .personalAccident, cover: 2_000_000, annual: 3_000)
        policy.lifeDetails = AstraLifeInsuranceDetails(nomineeName: "Asha", deathBenefit: 2_000_000)
        let result = InsuranceAnalysisEngine.analyze(policy: policy, profile: profile(), now: now)
        let passed = result.productKind == .personalAccident
            && result.scenarios.contains { $0.title.contains("Accidental death") }
        return CaseResult(name: "Personal accident", passed: passed, detail: result.productKind.rawValue)
    }

    private static func motor() -> CaseResult {
        var policy = basePolicy(type: .motor, cover: 400_000, annual: 14_000)
        policy.motorDetails = AstraMotorInsuranceDetails(vehicleModel: "Nexon", idv: 450_000, thirdPartyCoverage: true, ownDamageCoverage: true)
        let result = InsuranceAnalysisEngine.analyze(policy: policy, profile: profile(), now: now)
        let passed = result.productKind == .motor
            && result.scenarios.contains { $0.title == "Accident" }
            && result.currentCoverage == 450_000
            && result.estimatedRequiredCoverage == nil
        return CaseResult(name: "Motor", passed: passed, detail: "cover \(Int(result.currentCoverage))")
    }

    private static func property() -> CaseResult {
        let policy = basePolicy(type: .property, cover: 5_000_000, annual: 8_000)
        let result = InsuranceAnalysisEngine.analyze(policy: policy, profile: profile(), now: now)
        let passed = result.productKind == .property && result.scenarios.contains { $0.title == "Fire" }
        return CaseResult(name: "Property", passed: passed, detail: "\(result.scenarios.count) scenarios")
    }

    private static func travel() -> CaseResult {
        var policy = basePolicy(type: .travel, cover: 300_000, annual: 4_000)
        policy.expiryDate = Calendar.current.date(byAdding: .day, value: 20, to: now)
        let result = InsuranceAnalysisEngine.analyze(policy: policy, profile: profile(), now: now)
        return CaseResult(name: "Travel", passed: result.productKind == .travel && !result.scenarios.isEmpty, detail: result.purposeLabel)
    }

    private static func missingData() -> CaseResult {
        var policy = basePolicy(type: .life, cover: 0, annual: 10_000)
        policy.lifeDetails = AstraLifeInsuranceDetails(lifeInsuranceType: "Endowment")
        let result = InsuranceAnalysisEngine.analyze(policy: policy, profile: profile(), now: now)
        let passed = result.benefits.contains { $0.title == "Maturity" && $0.amount == nil }
            && result.premiumProgress == nil
            && result.dataValidationWarnings.contains { $0.lowercased().contains("nominee") }
        return CaseResult(name: "Missing data", passed: passed, detail: result.dataValidationWarnings.joined(separator: "; "))
    }

    private static func invalidPremiumBreakdown() -> CaseResult {
        var policy = basePolicy(type: .health, cover: 500_000, annual: 640_000)
        policy.basePremium = 56_000
        policy.taxesGST = 3_400
        policy.addOnCost = 1_000
        let warnings = InsuranceAnalysisEngine.validate(policy)
        let passed = warnings.contains { $0.contains("does not match annual premium") }
        return CaseResult(name: "Invalid premium breakdown", passed: passed, detail: warnings.joined(separator: "; "))
    }

    private static func lapsedPolicy() -> CaseResult {
        var policy = basePolicy(type: .health, cover: 300_000, annual: 12_000)
        policy.startDate = date(2020, 1, 1)
        policy.expiryDate = date(2022, 1, 1)
        let result = InsuranceAnalysisEngine.analyze(policy: policy, profile: profile(), now: now)
        let passed = policy.status == .lapsed
            && result.insuranceHealthStatus == .critical
            && result.topIssues.contains { $0.priority == .critical }
        return CaseResult(name: "Lapsed policy", passed: passed, detail: result.insuranceHealthStatus.rawValue)
    }

    private static func unknownPaymentStatus() -> CaseResult {
        var policy = basePolicy(type: .health, cover: 300_000, annual: 12_000)
        policy.payments = [AstraInsurancePayment(date: now, amount: 12_000, status: .unknown)]
        let result = InsuranceAnalysisEngine.analyze(policy: policy, profile: profile(), now: now)
        let passed = policy.status == .active
            && result.insuranceHealthStatus != .critical
            && result.topIssues.contains { $0.title.lowercased().contains("unknown") }
            && result.summary.lowercased().contains("unknown")
        return CaseResult(name: "Unknown payment status", passed: passed, detail: result.summary)
    }

    private static func protectionGap() -> CaseResult {
        var policy = basePolicy(type: .termLifeInsurance, cover: 200_000, annual: 8_000)
        policy.lifeDetails = AstraLifeInsuranceDetails(nomineeName: "Asha", deathBenefit: 200_000, lifeInsuranceType: "Term")
        let rich = profile(income: 100_000, dependents: 2)
        let result = InsuranceAnalysisEngine.analyze(policy: policy, profile: rich, now: now)
        let passed = (result.protectionGap ?? 0) > 0
            && result.protectionStatus == .significantGap
            && result.hasProtectionAnalysis
        return CaseResult(name: "Protection gap", passed: passed, detail: "gap \(Int(result.protectionGap ?? -1)) status \(result.protectionStatus.rawValue)")
    }

    private static func highPremiumBurden() -> CaseResult {
        var policy = basePolicy(type: .health, cover: 500_000, annual: 240_000)
        policy.healthDetails = AstraHealthInsuranceDetails(planType: "Individual")
        let tight = profile(income: 50_000, expenses: 40_000, dependents: 0)
        let result = InsuranceAnalysisEngine.analyze(policy: policy, profile: tight, now: now)
        let passed = (result.premiumBurdenPercentage ?? 0) > 15
            && result.premiumAffordabilityStatus == .highBurden
        return CaseResult(name: "High premium burden", passed: passed, detail: String(format: "%.1f%%", result.premiumBurdenPercentage ?? -1))
    }

    private static func limitedPremiumPayingTerm() -> CaseResult {
        var policy = basePolicy(type: .life, cover: 200_000, annual: 19_664)
        policy.startDate = date(2018, 8, 28)
        policy.policyTermYears = 16
        policy.premiumPayingTermYears = 10
        policy.lifeDetails = AstraLifeInsuranceDetails(nomineeName: "Asha", deathBenefit: 200_000, lifeInsuranceType: "Endowment")
        let result = InsuranceAnalysisEngine.analyze(policy: policy, profile: profile(), now: now)
        let passed = result.premiumProgress != nil
            && (result.premiumProgress ?? 0) > 0.7
            && (result.policyProgress ?? 1) < (result.premiumProgress ?? 0)
        return CaseResult(name: "Limited premium-paying term", passed: passed, detail: "ppt \(Int((result.premiumProgress ?? 0) * 100)) policy \(Int((result.policyProgress ?? 0) * 100))")
    }

    private static func policyMaturityReached() -> CaseResult {
        var policy = basePolicy(type: .life, cover: 200_000, annual: 10_000)
        policy.startDate = date(2008, 1, 1)
        policy.maturityDate = date(2024, 1, 1)
        policy.lifeDetails = AstraLifeInsuranceDetails(nomineeName: "Asha", deathBenefit: 200_000, lifeInsuranceType: "Endowment")
        let result = InsuranceAnalysisEngine.analyze(policy: policy, profile: profile(), now: now)
        let passed = policy.status == .matured && (result.policyProgress ?? 0) >= 1
        return CaseResult(name: "Policy maturity reached", passed: passed, detail: policy.status.rawValue)
    }

    private static func policyExpiringSoon() -> CaseResult {
        var policy = basePolicy(type: .motor, cover: 400_000, annual: 12_000)
        policy.expiryDate = Calendar.current.date(byAdding: .day, value: 20, to: now)
        policy.motorDetails = AstraMotorInsuranceDetails(thirdPartyCoverage: true, ownDamageCoverage: true)
        let result = InsuranceAnalysisEngine.analyze(policy: policy, profile: profile(), now: now)
        let passed = result.topIssues.contains { $0.title.lowercased().contains("expir") }
        return CaseResult(name: "Policy expiring soon", passed: passed, detail: result.topIssues.first?.title ?? "")
    }

    // MARK: - Fixtures

    private static let now = date(2026, 9, 12)

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar(identifier: .gregorian).date(from: components) ?? Date(timeIntervalSince1970: 0)
    }

    private static func basePolicy(type: AstraInsuranceType, cover: Double, annual: Double) -> AstraInsurance {
        AstraInsurance(
            insuranceType: type,
            provider: "Test Insurer",
            policyNumber: "P-1",
            sumAssured: cover,
            annualPremium: annual,
            startDate: date(2024, 1, 1),
            expiryDate: date(2029, 1, 1)
        )
    }

    private static func profile(income: Double = 100_000, expenses: Double = 40_000, dependents: Int = 1) -> AstraUserProfile {
        AstraUserProfile(
            signUp: AstraSignUp(signUpName: "Test", email: "test@example.com", password: ""),
            basicDetails: AstraBasicDetails(
                name: "Test",
                age: 34,
                gender: .male,
                adultDependents: dependents,
                childDependents: 0,
                incomeType: .fixed,
                monthlyIncome: income,
                monthlyIncomeAfterTax: income,
                monthlyExpenses: expenses,
                emergencyFundAmount: 100_000,
                activeInvestment: false
            ),
            assets: AstraAssets(),
            liabilities: AstraLiabilities(),
            investments: [],
            loans: [],
            insurances: [],
            goals: []
        )
    }
}
