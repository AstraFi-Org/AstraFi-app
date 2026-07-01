import Foundation

enum Plan2Strategy {
    case loanPlusSIPParallel
    case sipSprintThenBuy
    case hybridDownpayPlusSIP
}

class InvestmentPlannerEngine {

    static func generateFullPlan(
        input: InvestmentPlanInputModel,
        profile: AstraUserProfile? = nil
    ) -> FullPlanResult {

        let healthCtx = buildFinancialHealthContext(input: input, profile: profile)

        let goalCategory = InvestmentGoalCategory.from(purpose: input.purposeOfInvestment)

        let risk = resolveRiskLevel(input: input, profile: profile, goalCategory: goalCategory)
        let liquid = mapLiquidityLevel(input.liquidity)

        let feasibility = validateFeasibility(input: input, healthCtx: healthCtx)

        let requestedAmt = parseAmount(input.amount)
        let safeAmt = healthAdjustedSIPAmount(requested: requestedAmt, healthCtx: healthCtx)

        var plan1 = generatePlan1(input: input, risk: risk, liquidity: liquid,
                                  safeAmt: safeAmt, goalCategory: goalCategory,
                                  healthCtx: healthCtx)
        plan1 = applyGoalBranding(to: plan1, goal: goalCategory,
                                  purpose: input.purposeOfInvestment)

        var plan2: Plan2Result? = nil
        if shouldGeneratePlan2(input: input, goal: goalCategory, health: healthCtx) {
            let strategy = choosePlan2Strategy(input: input, goal: goalCategory, healthCtx: healthCtx)
            plan2 = generatePlan2(input: input, risk: risk, liquidity: liquid,
                                  strategy: strategy, healthCtx: healthCtx)
            plan2 = plan2.map { applyPlan2Branding(to: $0, goal: goalCategory, strategy: strategy) }
        }

        var plan3: Plan3Result? = nil
        if input.openToLoan && healthCtx.debtToIncomeRatio < 0.35 {
             plan3 = generatePlan3(input: input, healthCtx: healthCtx)
        }

        let tenure = Swift.max(1, Int(input.timePeriod) ?? 1)
        let saved = parseAmount(input.savedAmount)
        let mentalityRate = input.investmentMentality.avgGrowthRate
        let mentalityGrowth = sipFutureValue(monthly: requestedAmt, rateCAGR: mentalityRate, years: tenure) +
                             lumpsumFutureValue(amount: saved, rateCAGR: mentalityRate, years: tenure)
        let mentalityLabel = "\(input.investmentMentality.rawValue) (\(Int(mentalityRate))%)"

        let recommendations = generateRecommendations(input: input, plan1: plan1, plan2: plan2,
                                                       feasibility: feasibility, healthCtx: healthCtx)
        let comparison = scorePlans(plan1: plan1, plan2: plan2, plan3: plan3, input: input,
                                     healthCtx: healthCtx, goal: goalCategory)

        return FullPlanResult(
            plan1: plan1,
            plan2: plan2,
            plan3: plan3,
            feasibility: feasibility,
            recommendations: recommendations,
            comparisonScore: comparison,
            goalCategory: goalCategory,
            financialHealthSummary: healthCtx,
            mentalityGrowthValue: mentalityGrowth,
            mentalityGrowthLabel: mentalityLabel
        )
    }

    static func recalculatePlan1(input: InvestmentPlanInputModel,
                                 overridenRisk: AstraRiskLevel? = nil,
                                 overridenSIP: Double? = nil,
                                 overridenTenure: Int? = nil) -> Plan1Result {
        let risk = overridenRisk ?? mapRiskLevel(input.riskType)
        let goalCategory = InvestmentGoalCategory.from(purpose: input.purposeOfInvestment)
        let liquid = mapLiquidityLevel(input.liquidity)

        let sipAmt = overridenSIP ?? parseAmount(input.amount)

        var customInput = input
        if let s = overridenSIP { customInput.amount = String(format: "%.0f", s) }
        if let t = overridenTenure { customInput.timePeriod = String(t) }

        return generatePlan1(input: customInput, risk: risk, liquidity: liquid,
                           safeAmt: sipAmt, goalCategory: goalCategory,
                           healthCtx: buildFinancialHealthContext(input: customInput, profile: nil))
    }

    static func recalculatePlan3(
        input: InvestmentPlanInputModel,
        overridenLoan: Double,
        overridenTenure: Int,
        overridenBank: String? = nil,
        overridenRate: Double? = nil,
        overridenReturn: Double? = nil,
        emiFrequency: EMIFrequency = .monthly,
        interestType: InterestType = .compounded,
        investmentMode: String = "Lumpsum",
        lumpsumPhases: Int = 1,
        emiFromPocket: Bool = true,
        historicalPeriodYears: Int = 10
    ) -> Plan3Result {
        var customInput = input
        customInput.targetAmount = String(Int(overridenLoan))
        customInput.timePeriod = String(overridenTenure)
        if let b = overridenBank { customInput.bankName = b }
        if let r = overridenRate { customInput.interestRate = r }

        let healthCtx = buildFinancialHealthContext(input: customInput, profile: nil)

        return generatePlan3(
            input: customInput,
            healthCtx: healthCtx,
            loanAmountOverride: overridenLoan,
            loanRateOverride: overridenRate,
            tenureOverride: overridenTenure,
            emiFrequency: emiFrequency,
            interestType: interestType,
            investmentMode: investmentMode,
            lumpsumPhases: lumpsumPhases,
            emiFromPocket: emiFromPocket,
            overridenReturn: overridenReturn,
            historicalPeriodYears: historicalPeriodYears
        )
    }

    static func recalculatePlan2(input: InvestmentPlanInputModel,
                                 overridenLoan: Double? = nil,
                                 overridenSIP: Double? = nil,
                                 overridenTenure: Int? = nil,
                                 emiFrequency: EMIFrequency = .quarterly,
                                 interestType: InterestType = .compounded) -> Plan2Result {
        let risk = mapRiskLevel(input.riskType)
        let goalCategory = InvestmentGoalCategory.from(purpose: input.purposeOfInvestment)
        let healthCtx = buildFinancialHealthContext(input: input, profile: nil)

        var strategy = choosePlan2Strategy(input: input, goal: goalCategory, healthCtx: healthCtx)

        if let l = overridenLoan, l > 0 {
            strategy = .loanPlusSIPParallel
        }

        let liquid = mapLiquidityLevel(input.liquidity)

        var customInput = input
        if let l = overridenLoan { customInput.loanAmount = l }
        if let s = overridenSIP { customInput.amount = String(format: "%.0f", s) }
        if let t = overridenTenure { customInput.timePeriod = String(t) }

        return generatePlan2(input: customInput, risk: risk, liquidity: liquid,
                           strategy: strategy, healthCtx: healthCtx,
                           emiFrequency: emiFrequency, interestType: interestType) ?? Plan2Result.empty()
    }

    private static func buildFinancialHealthContext(
        input: InvestmentPlanInputModel,
        profile: AstraUserProfile?
    ) -> FinancialHealthContext {
        let income: Double = profile?.basicDetails.monthlyIncomeAfterTax ?? Swift.max(input.monthlyIncome, 1.0)
        let expenses: Double = profile?.basicDetails.monthlyExpenses ?? (income * 0.45)
        let emiLoad: Double = profile?.loans.reduce(0.0) { $0 + $1.calculatedEMI } ?? input.existingEMIs
        let emergFund: Double = profile?.basicDetails.emergencyFundAmount ?? 0.0
        let netWorth: Double = profile?.financialHealthReport?.netWorth ?? 0.0
        let investScore: Int = profile?.financialHealthReport?.investmentScore ?? 50

        let dti = income > 0 ? emiLoad / income : 0
        let surplus = income - expenses - emiLoad
        let investable = Swift.max(0.0, surplus * 0.9)
        let emergMonths = expenses > 0 ? emergFund / expenses : 0

        let grade: String
        let advice: String

        let minSafetyMonths: Double = 6.0
        let hasGoodSafety = emergMonths >= minSafetyMonths
        let hasLowSafety = emergMonths < 3.0

        if dti > 0.5 {
            grade = "D"
            advice = "High debt burden detected. Prioritize clearing loans before aggressive investing."
        } else if hasLowSafety {
            grade = "C"
            advice = "Safety net is low. Allocate your ₹\(Int(surplus/1000))K surplus to build a 6-month emergency fund."
        } else if !hasGoodSafety {
            grade = "B"
            advice = "Good start! Aim to reach 6 months of safety net while continuing small investments."
        } else if surplus > (income * 0.3) {
            grade = "A"
            advice = "Excellent surplus! You can afford to invest more and reach your goal \(input.timePeriod) years earlier."
        } else {
            grade = "A"
            advice = "Solid foundation. Your safety net is secure; focus on steady long-term growth."
        }

        return FinancialHealthContext(
            netWorth: netWorth,
            monthlyIncome: income,
            monthlyExpenses: expenses,
            existingEMIBurden: emiLoad,
            emergencyFundCoverage: emergMonths,
            investmentScore: investScore,
            debtToIncomeRatio: dti,
            investableMonthly: investable,
            healthGrade: grade,
            healthSummary: advice
        )
    }

    private static func validateFeasibility(
        input: InvestmentPlanInputModel,
        healthCtx: FinancialHealthContext
    ) -> FeasibilityResult {
        var points: [ValidationPoint] = []
        let reqSIP = parseAmount(input.amount)

        if reqSIP > healthCtx.investableMonthly * 1.5 {
            points.append(ValidationPoint(
                icon: "exclamationmark.triangle.fill",
                title: "Budget Over-stretch",
                detail: "This SIP takes up >150% of your current investable surplus. Risk of discontinuation.",
                severity: .critical
            ))
        } else if reqSIP > healthCtx.investableMonthly {
            points.append(ValidationPoint(
                icon: "exclamationmark.circle.fill",
                title: "Aggressive Allocation",
                detail: "SIP exceeds the projected safe surplus. Ensure expenses are tightly managed.",
                severity: .warning
            ))
        } else {
            points.append(ValidationPoint(
                icon: "checkmark.circle.fill",
                title: "Comfortable Budget",
                detail: "Monthly commitment is well within your safe investable surplus.",
                severity: .positive
            ))
        }

        if healthCtx.emergencyFundCoverage < 1 {
            points.append(ValidationPoint(
                icon: "shield.slash.fill",
                title: "Safety Net Missing",
                detail: "You have <1 month of expenses saved. Prioritise Emergency Fund over this goal.",
                severity: .critical
            ))
        } else if healthCtx.emergencyFundCoverage < 3 {
            points.append(ValidationPoint(
                icon: "shield.fill",
                title: "Lean Safety Net",
                detail: "Safety net is <3 months. Consider a lower SIP until you reach 6 months.",
                severity: .warning
            ))
        }

        if healthCtx.debtToIncomeRatio > 0.5 {
            points.append(ValidationPoint(
                icon: "creditcard.fill",
                title: "High Debt Load",
                detail: "Your DTI is >50%. Consider lowering debt before new investments.",
                severity: .warning
            ))
        }

        let warning = points.first(where: { $0.severity == .critical })?.detail
                   ?? points.first(where: { $0.severity == .warning })?.detail

        return FeasibilityResult(
            isAffordable: !points.contains(where: { $0.severity == .critical }),
            disposableIncome: healthCtx.investableMonthly,
            sipToIncomeRatio: reqSIP / Swift.max(1, healthCtx.investableMonthly),
            warning: warning
        )
    }

    private static func resolveRiskLevel(input: InvestmentPlanInputModel,
                                         profile: AstraUserProfile?,
                                         goalCategory: InvestmentGoalCategory) -> AstraRiskLevel {
        var base = mapRiskLevel(input.riskType)
        if let tol = profile?.basicDetails.riskTolerance {
            switch tol {
            case .low: base = .low
            case .medium: base = .mid
            case .high: base = .high
            }
        }

        let tenure = Swift.max(1, Int(input.timePeriod) ?? 1)
        if tenure <= 3 && [.emergency, .travel].contains(goalCategory) { return .low }
        return base
    }

    private static func buildPortfolio(risk: AstraRiskLevel,
                                       liquidity: AstraLiquidityLevel,
                                       goalCategory: InvestmentGoalCategory,
                                       tenure: Int,
                                       amount: Double = 0.0) -> PortfolioBlueprint {
        var allocations: [AssetAllocation]
        
        switch risk {
        case .low:
            allocations = [
                AssetAllocation(name: "Corporate Bond / Debt Fund", percentage: 35, expectedCAGR: 7.5, riskLevel: .low, 
                                role: "Stability",
                                description: "Invests in high-quality debt instruments issued by companies and the government.", 
                                fundExamples: ["Example: Corporate bond mutual funds"],
                                howItWorks: "Fixed-income instruments that pay regular interest. Less volatile than stocks.",
                                whyIncluded: "Provides capital protection and steady returns to offset market risks."),
                AssetAllocation(name: "Liquid / Short-Term Fund", percentage: 25, expectedCAGR: 6.5, riskLevel: .low, 
                                role: "Liquidity",
                                description: "Ultra-safe funds that invest in very short-term debt securities.", 
                                fundExamples: ["Example: Liquid or Overnight Funds"],
                                howItWorks: "Invests in assets maturing in 91 days or less. Very low price fluctuations.",
                                whyIncluded: "Ensures you can access your cash quickly without losing capital value."),
                AssetAllocation(name: "Large Cap Index Fund", percentage: 20, expectedCAGR: 13.0, riskLevel: .mid, 
                                role: "Stable Growth",
                                description: "A passive fund that tracks the top 50 or 100 largest companies in India.", 
                                fundExamples: ["Example: Nifty 50 Index Fund (tracks top 50 companies)"],
                                howItWorks: "Market-linked. Value changes based on the performance of India's biggest companies.",
                                whyIncluded: "Captures the growth of the broader economy with lower volatility than mid/small caps."),
                AssetAllocation(name: "Bluechip Equity", percentage: 15, expectedCAGR: 14.0, riskLevel: .mid, 
                                role: "Consistent Returns",
                                description: "Investments in established, market-leading companies with strong track records.", 
                                fundExamples: ["Example: Bluechip Focused Equity Funds"],
                                howItWorks: "Directly linked to corporate earnings and stock market growth of stable giants.",
                                whyIncluded: "Aims for reliable dividends and long-term capital appreciation."),
                AssetAllocation(name: "Small Cap (Minimal Exposure)", percentage: 5, expectedCAGR: 18.0, riskLevel: .high, 
                                role: "Growth Boost",
                                description: "Small portion allocated to fast-growing emerging companies.", 
                                fundExamples: ["Example: Nifty Smallcap 250 Index"],
                                howItWorks: "High-risk, market-linked. Can grow significantly but is highly volatile.",
                                whyIncluded: "Provides a small 'kicker' to help beat inflation over a 3-5 year period.")
            ]
        case .mid:
            allocations = [
                AssetAllocation(name: "Flexi Cap Fund", percentage: 30, expectedCAGR: 14.5, riskLevel: .mid, 
                                role: "Adaptive Growth",
                                description: "A diversified fund that can invest in companies of any size (Large, Mid, or Small).", 
                                fundExamples: ["Example: Multi-Cap or Flexi Cap Mutual Funds"],
                                howItWorks: "Fund manager dynamically shifts money based on where the best opportunities are.",
                                whyIncluded: "Offers optimal risk-adjusted returns by adapting to different market cycles."),
                AssetAllocation(name: "Large & Mid Cap Fund", percentage: 25, expectedCAGR: 15.0, riskLevel: .mid, 
                                role: "Balanced Growth",
                                description: "Invests equally in stable Large Cap giants and high-growth Mid Cap firms.", 
                                fundExamples: ["Example: Large & Mid Cap Hybrid Equity Funds"],
                                howItWorks: "Market-linked. Combines the safety of top firms with the agility of mid-sized ones.",
                                whyIncluded: "Balances high growth potential with a layer of established company stability."),
                AssetAllocation(name: "Index Fund", percentage: 20, expectedCAGR: 13.5, riskLevel: .mid, 
                                role: "Market Stability",
                                description: "Invests in a predefined bucket of stocks like the Nifty 50 or Sensex.", 
                                fundExamples: ["Example: Broad Market Index Funds"],
                                howItWorks: "Mirrors the performance of the entire stock market. No manager risk.",
                                whyIncluded: "Ensures your portfolio doesn't underperform the overall stock market average."),
                AssetAllocation(name: "Small Cap Fund", percentage: 15, expectedCAGR: 18.5, riskLevel: .high, 
                                role: "High Growth",
                                description: "Focuses on young companies that have the potential to become future giants.", 
                                fundExamples: ["Example: Active Small Cap Mutual Funds"],
                                howItWorks: "Aggressive market-linked growth. High price swings but high long-term gains.",
                                whyIncluded: "Significantly accelerates wealth creation over 5+ year periods."),
                AssetAllocation(name: "Corporate Bond Fund", percentage: 10, expectedCAGR: 7.5, riskLevel: .low, 
                                role: "Stability",
                                description: "Invests in debt of high-rated companies for predictable income.", 
                                fundExamples: ["Example: AAA-rated Corporate Bond Funds"],
                                howItWorks: "Debt-based returns. Acts as a safety net when the stock market is volatile.",
                                whyIncluded: "Provides a reliable anchor to protect your portfolio during market corrections.")
            ]
        case .high:
            allocations = [
                AssetAllocation(name: "Small Cap Fund", percentage: 35, expectedCAGR: 19.5, riskLevel: .high, 
                                role: "Aggressive Growth",
                                description: "Maximum exposure to emerging small-sized companies with multi-bagger potential.", 
                                fundExamples: ["Example: Small Cap Focused Growth Funds"],
                                howItWorks: "Highly volatile market-linked investment. Can have sharp drops and huge gains.",
                                whyIncluded: "Designed for long-horizon scenarios seeking higher growth potential."),
                AssetAllocation(name: "Mid Cap Fund", percentage: 25, expectedCAGR: 17.5, riskLevel: .high, 
                                role: "Growth Acceleration",
                                description: "Invests in medium-sized companies that are rapidly expanding their business.", 
                                fundExamples: ["Example: Midcap Opportunities Funds"],
                                howItWorks: "Focused on the 'middle' segment of the market. High growth with high risk.",
                                whyIncluded: "Provides the primary engine for capital appreciation in an aggressive plan."),
                AssetAllocation(name: "Direct Equity / Thematic", percentage: 20, expectedCAGR: 22.0, riskLevel: .high, 
                                role: "High Conviction",
                                description: "Focused bets on specific high-performing sectors or individual stock picks.", 
                                fundExamples: ["Example: Technology, Banking, or ESG Thematic Funds"],
                                howItWorks: "Concentrated portfolio. Value changes rapidly based on sector performance.",
                                whyIncluded: "Aims to significantly outperform the market by betting on trending sectors."),
                AssetAllocation(name: "Flexi Cap Fund", percentage: 15, expectedCAGR: 14.0, riskLevel: .mid, 
                                role: "Risk Balance",
                                description: "A flexible equity fund used to maintain some diversification across sizes.", 
                                fundExamples: ["Example: Parag Parikh or Quant Style Flexi Caps"],
                                howItWorks: "Hybrid market-linked strategy. Provides a secondary layer of diversification.",
                                whyIncluded: "Ensures the portfolio isn't too concentrated in just one segment of the market."),
                AssetAllocation(name: "Large Cap Index Fund", percentage: 5, expectedCAGR: 13.0, riskLevel: .mid, 
                                role: "Stability Anchor",
                                description: "A small portion in safe large-cap stocks to prevent a total portfolio crash.", 
                                fundExamples: ["Example: Nifty 50 Passive Index Fund"],
                                howItWorks: "Passive market tracker. Provides basic stability to the aggressive mix.",
                                whyIncluded: "Acts as a safety valve to preserve some capital during severe market crashes.")
            ]
        }

        if liquidity == .high {
            allocations = allocations.map { a in
                var x = a
                if a.riskLevel == .high { x.percentage = Swift.max(2, a.percentage - 10) }
                if a.name == "Liquid Fund" || a.name == "Debt MF" { x.percentage += 5 }
                return x
            }
        }

        let total = allocations.reduce(0.0) { $0 + $1.percentage }
        if total > 0 { allocations = allocations.map { var x = $0; x.percentage = (x.percentage / total) * 100; return x } }

        let blended = allocations.reduce(0.0) { $0 + ($1.expectedCAGR * $1.percentage / 100) }
        return PortfolioBlueprint(allocations: allocations, blendedCAGR: blended, riskLabel: risk.rawValue.capitalized)
    }

    private static func generatePlan1(input: InvestmentPlanInputModel,
                                      risk: AstraRiskLevel,
                                      liquidity: AstraLiquidityLevel,
                                      safeAmt: Double,
                                      goalCategory: InvestmentGoalCategory,
                                      healthCtx: FinancialHealthContext) -> Plan1Result {
        let tenure = Swift.max(1, Int(input.timePeriod) ?? 1)
        let target = parseAmount(input.targetAmount)
        let saved  = parseAmount(input.savedAmount)
        let sipAmt = safeAmt > 0 ? safeAmt : parseAmount(input.amount)

        let portfolio = buildPortfolio(risk: risk, liquidity: liquidity, goalCategory: goalCategory, tenure: tenure, amount: sipAmt)

        let fvSIP = sipFutureValue(monthly: sipAmt, rateCAGR: portfolio.blendedCAGR, years: tenure)
        let fvLump = lumpsumFutureValue(amount: saved, rateCAGR: portfolio.blendedCAGR, years: tenure)
        let projected = fvSIP + fvLump
        let totalInvested = (sipAmt * 12 * Double(tenure)) + saved

        let reachesGoal = projected >= target
        let shortfall = Swift.max(0, target - projected)

        var sipPerAsset: [String: Double] = [:]
        for asset in portfolio.allocations { sipPerAsset[asset.name] = sipAmt * asset.percentage / 100 }

        let scenarios = generateScenarios(totalInvested: totalInvested, sip: sipAmt, lumpsum: saved, years: tenure)

        var hl: [String] = []
        hl.append("Blended CAGR: \(String(format: "%.1f", portfolio.blendedCAGR))%")
        hl.append("Lumpsum boost: ₹\(formatL_Internal(fvLump))")
        if reachesGoal {
            hl.append("May reach goal under assumptions")
        } else {
            hl.append("Illustrative shortfall: ₹\(formatL_Internal(shortfall))")
        }

        return Plan1Result(
            totalInvested: totalInvested,
            projectedValue: projected,
            lumpsumContribution: fvLump,
            sipContribution: fvSIP,
            portfolio: portfolio,
            scenarios: scenarios,
            reachesGoal: reachesGoal,
            shortfall: shortfall,
            sipPerAsset: sipPerAsset,
            tenure: tenure,
            highlights: hl
        )
    }

    private static func generatePlan2(input: InvestmentPlanInputModel,
                                      risk: AstraRiskLevel,
                                      liquidity: AstraLiquidityLevel,
                                      strategy: Plan2Strategy,
                                      healthCtx: FinancialHealthContext,
                                      emiFrequency: EMIFrequency = .quarterly,
                                      interestType: InterestType = .compounded) -> Plan2Result? {
        let saved  = parseAmount(input.savedAmount)
        let target = parseAmount(input.targetAmount)
        let amt    = parseAmount(input.amount)
        let tenure = Swift.max(1, Int(input.timePeriod) ?? 1)
        let months = tenure * 12

        let portfolio = buildPortfolio(risk: risk, liquidity: liquidity, goalCategory: .other, tenure: tenure, amount: target)
        let loanRate = input.interestRate ?? 9.5
        let monthlyRate = loanRate / 100 / 12
        _ = monthlyRate
        let bankSuffix = input.bankName.map { " via \($0)" } ?? ""

        switch strategy {
        case .loanPlusSIPParallel:
            let loanAmount = input.loanAmount ?? target
            let emi = calculateEMIPublic(principal: loanAmount, rate: loanRate, years: tenure, frequency: emiFrequency, interestType: interestType)
            let totalPayments = Double(tenure) * emiFrequency.paymentsPerYear
            let totalPaid = emi * totalPayments
            let interest = totalPaid - loanAmount
            let sipRet = sipFutureValue(monthly: amt, rateCAGR: portfolio.blendedCAGR, years: tenure)
            let totalOutflow = totalPaid + (amt * Double(months))
            let finalStateValue = sipRet + target
            let gain = finalStateValue - totalOutflow

            let reaches = gain >= target
            let gap = Swift.max(0, target - gain)

            let profit = sipRet - (amt * Double(months))
            let invested = amt * Double(months)

            var yearDetails: [Plan2YearlyDetail] = []
            for y in 1...tenure {
                let p_y = Double(y) * emiFrequency.paymentsPerYear
                let r = (loanRate / 100.0) / emiFrequency.paymentsPerYear
                let remP: Double
                if interestType == .compounded {
                    let pqr_total = pow(1 + r, totalPayments)
                    let pqr_q = pow(1 + r, p_y)
                    remP = r > 0 ? (loanAmount * (pqr_total - pqr_q)) / (pqr_total - 1) : (loanAmount * (1.0 - p_y/totalPayments))
                } else {
                    let yearlyPrincipalPaid = loanAmount / Double(tenure)
                    remP = loanAmount - (yearlyPrincipalPaid * Double(y))
                }

                let fvSIP_y = sipFutureValue(monthly: amt, rateCAGR: portfolio.blendedCAGR, years: y)

                yearDetails.append(Plan2YearlyDetail(
                    year: y,
                    date: Calendar.current.date(byAdding: .year, value: y, to: Date()) ?? Date(),
                    emiPaidYearly: emi * emiFrequency.paymentsPerYear,
                    sipInvestedYearly: amt * 12,
                    remainingPrincipal: Swift.max(0, remP),
                    totalPortfolioValue: fvSIP_y
                ))
            }

            return Plan2Result(
                loanAmount: loanAmount, loanRate: loanRate, monthlyEMI: emi,
                totalAmountPaid: totalPaid, totalInterestPaid: interest,
                monthlySIPKept: amt, sipReturns: sipRet, investmentProfit: profit,
                netWealthGain: gain, totalMonthlyCommitment: (emi * emiFrequency.paymentsPerYear / 12) + amt,
                roi: invested > 0 ? (gain / invested) * 100 : 0,
                reachesGoal: reaches, shortfall: gap,
                breakdown: buildLoanBreakdown(planType: "Loan + SIP", target: target, loan: loanAmount, emi: emi, sip: amt, sipRet: sipRet, gain: gain),
                highlights: ["Buy asset now" + bankSuffix, "EMI + SIP parallel", "Net Gain: ₹\(formatL_Internal(gain))"],
                yearlyBreakdown: yearDetails
            )

        case .sipSprintThenBuy:
            let shortfall = Swift.max(0, target - saved)
            let reqSIP = computeRequiredSIP(target: shortfall, lumpsum: 0, cagr: portfolio.blendedCAGR, years: tenure)
            let totalInv = reqSIP * Double(months)
            let ret = sipRetVal(monthly: reqSIP, cagr: portfolio.blendedCAGR, years: tenure)
            let profit = ret - totalInv

            let reaches = ret >= target
            let gap = Swift.max(0, target - ret)

            var yearDetails: [Plan2YearlyDetail] = []
            for y in 1...tenure {
                let fvSIP_y = sipFutureValue(monthly: reqSIP, rateCAGR: portfolio.blendedCAGR, years: y)
                yearDetails.append(Plan2YearlyDetail(
                    year: y,
                    date: Calendar.current.date(byAdding: .year, value: y, to: Date()) ?? Date(),
                    emiPaidYearly: 0,
                    sipInvestedYearly: reqSIP * 12,
                    remainingPrincipal: 0,
                    totalPortfolioValue: fvSIP_y
                ))
            }

            return Plan2Result(
                loanAmount: 0, loanRate: 0, monthlyEMI: 0,
                totalAmountPaid: totalInv, totalInterestPaid: 0,
                monthlySIPKept: reqSIP, sipReturns: ret,
                investmentProfit: profit, netWealthGain: profit,
                totalMonthlyCommitment: reqSIP, roi: totalInv > 0 ? (profit/totalInv)*100 : 0,
                reachesGoal: reaches, shortfall: gap,
                breakdown: [], highlights: ["Aggressive Saving", "Zero Debt", "SIP: ₹\(formatL_Internal(reqSIP))/mo"],
                yearlyBreakdown: yearDetails
            )

        case .hybridDownpayPlusSIP:
            let dp = saved * 0.7
            let loan = input.loanAmount ?? Swift.max(0, target - dp)
            let emi = calculateEMIPublic(principal: loan, rate: loanRate, years: tenure, frequency: emiFrequency, interestType: interestType)
            let totalPayments = Double(tenure) * emiFrequency.paymentsPerYear

            let totalSIPInvested = amt * Double(months)
            let totalOutflow = (emi * totalPayments) + totalSIPInvested
            let sipRet = sipFutureValue(monthly: amt, rateCAGR: portfolio.blendedCAGR, years: tenure)
            let finalValue = sipRet + target
            let gain = finalValue - totalOutflow

            let reaches = gain >= target
            let gap = Swift.max(0, target - gain)

            var yearDetails: [Plan2YearlyDetail] = []
            for y in 1...tenure {
                let p_y = Double(y) * emiFrequency.paymentsPerYear
                let r = (loanRate / 100.0) / emiFrequency.paymentsPerYear
                let remP: Double
                if interestType == .compounded {
                    let pqr_total = pow(1 + r, totalPayments)
                    let pqr_q = pow(1 + r, p_y)
                    remP = r > 0 ? (loan * (pqr_total - pqr_q)) / (pqr_total - 1) : (loan * (1.0 - p_y/totalPayments))
                } else {
                    let yearlyPrincipalPaid = loan / Double(tenure)
                    remP = loan - (yearlyPrincipalPaid * Double(y))
                }

                let fvSIP_y = sipFutureValue(monthly: amt, rateCAGR: portfolio.blendedCAGR, years: y)

                yearDetails.append(Plan2YearlyDetail(
                    year: y,
                    date: Calendar.current.date(byAdding: .year, value: y, to: Date()) ?? Date(),
                    emiPaidYearly: emi * emiFrequency.paymentsPerYear,
                    sipInvestedYearly: amt * 12,
                    remainingPrincipal: Swift.max(0, remP),
                    totalPortfolioValue: fvSIP_y
                ))
            }
            return Plan2Result(
                loanAmount: loan, loanRate: loanRate, monthlyEMI: emi,
                totalAmountPaid: emi * totalPayments, totalInterestPaid: (emi * totalPayments) - loan,
                monthlySIPKept: amt, sipReturns: sipRet, investmentProfit: sipRet - totalSIPInvested,
                netWealthGain: gain, totalMonthlyCommitment: (emi * emiFrequency.paymentsPerYear / 12) + amt,
                roi: totalOutflow > 0 ? (gain / totalOutflow) * 100 : 0,
                reachesGoal: reaches, shortfall: gap,
                breakdown: [], highlights: ["Optimised Down-payment" + bankSuffix, "Lower EMI"],
                yearlyBreakdown: yearDetails
            )
        }
    }

    private static func scorePlans(plan1: Plan1Result, plan2: Plan2Result?, plan3: Plan3Result?,
                                   input: InvestmentPlanInputModel,
                                   healthCtx: FinancialHealthContext,
                                   goal: InvestmentGoalCategory) -> PlanComparisonScore {

        var dims: [ScoreDimension] = []
        let p1Gain = plan1.projectedValue - plan1.totalInvested
        let p2Gain = plan2?.netWealthGain ?? 0
        let p3Gain = plan3?.moderate.netProfit ?? 0

        dims.append(ScoreDimension(
            axis: "Wealth Gain",
            plan1Value: "₹\(formatL_Internal(p1Gain))",
            plan2Value: "₹\(formatL_Internal(p2Gain))",
            plan3Value: "₹\(formatL_Internal(p3Gain))",
            plan1Points: 6.0,
            plan2Points: plan2 != nil ? (p2Gain > p1Gain ? 8.5 : 7.0) : 0,
            plan3Points: plan3 != nil ? (p3Gain > p1Gain ? 9.5 : 8.0) : 0,
            weight: 0.4,
            winner: p3Gain > p1Gain && p3Gain > p2Gain ? "P3" : (p2Gain > p1Gain ? "P2" : "P1")
        ))

        let p1Load = parseAmount(input.amount)
        let p2Load = plan2?.totalMonthlyCommitment ?? 0
        let p3Load = plan3?.monthlyEMI ?? 0

        dims.append(ScoreDimension(
            axis: "Monthly Load",
            plan1Value: "₹\(formatL_Internal(p1Load))",
            plan2Value: "₹\(formatL_Internal(p2Load))",
            plan3Value: "₹\(formatL_Internal(p3Load))",
            plan1Points: 9.0,
            plan2Points: plan2 != nil ? (p2Load < healthCtx.investableMonthly ? 8.0 : 5.0) : 0,
            plan3Points: plan3 != nil ? (p3Load < (healthCtx.monthlyIncome * 0.4) ? 7.0 : 4.0) : 0,
            weight: 0.3,
            winner: "P1"
        ))

        let s1 = dims.reduce(0.0) { $0 + $1.plan1Points * $1.weight } * 10
        let s2 = dims.reduce(0.0) { $0 + ($1.plan2Points) * $1.weight } * 10
        let s3 = dims.reduce(0.0) { $0 + ($1.plan3Points ?? 0) * $1.weight } * 10

        let winnerStr: String
        if s3 > s1 && s3 > s2 { winnerStr = "Plan 3" }
        else if s2 > s1 { winnerStr = "Plan 2" }
        else { winnerStr = "Plan 1" }

        return PlanComparisonScore(
            plan1Score: s1, plan2Score: s2, plan3Score: s3,
            winner: winnerStr,
            confidence: "High", dimensions: dims,
            detailedReasoning: "Plan 1 is safer for your current grade.",
            keyValidations: []
        )
    }

    private static func buildFinancialHealthReport(profile: AstraUserProfile) -> AstraFinancialHealthReport? { return profile.financialHealthReport }

    private static func healthAdjustedSIPAmount(requested: Double, healthCtx: FinancialHealthContext) -> Double {
        if healthCtx.healthGrade == "D" { return Swift.min(requested, healthCtx.investableMonthly * 0.4) }
        return requested
    }

    private static func shouldGeneratePlan2(input: InvestmentPlanInputModel, goal: InvestmentGoalCategory, health: FinancialHealthContext) -> Bool {
        return input.openToLoan && ![.travel, .emergency].contains(goal) && health.debtToIncomeRatio < 0.5
    }

    private static func choosePlan2Strategy(input: InvestmentPlanInputModel, goal: InvestmentGoalCategory, healthCtx: FinancialHealthContext) -> Plan2Strategy {
        if goal == .homePurchase { return .hybridDownpayPlusSIP }
        return .loanPlusSIPParallel
    }

    private static func generatePlan3(
        input: InvestmentPlanInputModel,
        healthCtx: FinancialHealthContext,
        loanAmountOverride: Double? = nil,
        loanRateOverride: Double? = nil,
        tenureOverride: Int? = nil,
        emiFrequency: EMIFrequency = .monthly,
        interestType: InterestType = .compounded,
        investmentMode: String = "Lumpsum",
        lumpsumPhases: Int = 1,
        emiFromPocket: Bool = true,
        overridenReturn: Double? = nil,
        historicalPeriodYears: Int = 10
    ) -> Plan3Result {
        let loanAmt = loanAmountOverride ?? parseAmount(input.targetAmount)
        let rate = loanRateOverride ?? input.interestRate ?? 10.5
        let years = tenureOverride ?? Int(input.timePeriod) ?? 5

        let conservativePortfolio = buildPlan3Portfolio(risk: .low, amount: loanAmt)
        let moderatePortfolio = buildPlan3Portfolio(risk: .mid, amount: loanAmt)
        let aggressivePortfolio = buildPlan3Portfolio(risk: .high, amount: loanAmt)

        let emi = calculateEMIPublic(principal: loanAmt, rate: rate, years: years, frequency: emiFrequency, interestType: interestType)

        let cons = runLeveragedSimulation(
            name: "Conservative",
            loanAmount: loanAmt,
            loanRate: rate,
            tenure: years,
            portfolio: conservativePortfolio,
            emiFrequency: emiFrequency,
            phases: lumpsumPhases,
            emiFromPocket: emiFromPocket,
            isSIPMode: investmentMode == "SIP",
            historicalPeriodYears: historicalPeriodYears
        )

        let mod = runLeveragedSimulation(
            name: "Moderate",
            loanAmount: loanAmt,
            loanRate: rate,
            tenure: years,
            portfolio: moderatePortfolio,
            emiFrequency: emiFrequency,
            phases: lumpsumPhases,
            emiFromPocket: emiFromPocket,
            isSIPMode: investmentMode == "SIP",
            historicalPeriodYears: historicalPeriodYears
        )

        let agg = runLeveragedSimulation(
            name: "Aggressive",
            loanAmount: loanAmt,
            loanRate: rate,
            tenure: years,
            portfolio: aggressivePortfolio,
            emiFrequency: emiFrequency,
            phases: lumpsumPhases,
            emiFromPocket: emiFromPocket,
            isSIPMode: investmentMode == "SIP",
            historicalPeriodYears: historicalPeriodYears
        )

        var recStrategy = "Moderate"
        var recReason = "This balanced scenario is shown for education. Review the downside cases before acting."

        if healthCtx.healthGrade == "C" || healthCtx.healthGrade == "D" {
            recStrategy = "Conservative"
            recReason = "Lower stability detected. This conservative scenario reduces exposure, but it is not a recommendation."
        } else if healthCtx.investmentScore > 80 {
            recStrategy = "Aggressive"
            recReason = "Your profile can be stress-tested against an aggressive scenario, including higher loss potential."
        }

        let scenarioStats = buildHistoricalPortfolioStats(portfolio: moderatePortfolio, years: historicalPeriodYears)

        let worstSim = runLeveragedSimulation(name: "Worst", loanAmount: loanAmt, loanRate: rate, tenure: years, portfolio: conservativePortfolio, emiFrequency: emiFrequency, phases: lumpsumPhases, emiFromPocket: emiFromPocket, isSIPMode: investmentMode == "SIP", overridenReturn: scenarioStats.p5CAGR, historicalPeriodYears: historicalPeriodYears)
        
        let bullSim = runLeveragedSimulation(name: "Bull", loanAmount: loanAmt, loanRate: rate, tenure: years, portfolio: aggressivePortfolio, emiFrequency: emiFrequency, phases: lumpsumPhases, emiFromPocket: emiFromPocket, isSIPMode: investmentMode == "SIP", overridenReturn: scenarioStats.p75CAGR, historicalPeriodYears: historicalPeriodYears)

        let scenarios = [
            PlanScenario(name: "Worst Case", cagr: scenarioStats.p5CAGR, gainLoss: worstSim.netProfit, finalValue: worstSim.finalValue),
            PlanScenario(name: "Conservative", cagr: scenarioStats.p25CAGR, gainLoss: cons.netProfit, finalValue: cons.finalValue),
            PlanScenario(name: "Expected", cagr: scenarioStats.meanCAGR, gainLoss: mod.netProfit, finalValue: mod.finalValue),
            PlanScenario(name: "Bull Market", cagr: scenarioStats.p75CAGR, gainLoss: bullSim.netProfit, finalValue: bullSim.finalValue)
        ]

        return Plan3Result(
            loanAmount: loanAmt, loanRate: rate, tenure: years, monthlyEMI: emi,
            conservative: cons, moderate: mod, aggressive: agg,
            recommendedStrategy: recStrategy, recommendationReason: recReason, scenarios: scenarios,
            portfolio: moderatePortfolio
        )
    }

    private static func buildPlan3Portfolio(risk: AstraRiskLevel, amount: Double) -> PortfolioBlueprint {
        let allocations: [AssetAllocation]
        
        switch risk {
        case .high: // Aggressive: Balanced with a safe anchor
            allocations = [
                AssetAllocation(name: "Small & Mid Cap Alpha Stocks", percentage: 40, expectedCAGR: 18.5, riskLevel: .high, 
                                description: "Focused stock picks for maximum capital appreciation.", 
                                fundExamples: ["Direct Stock Portfolio", "Small Cap Focus"]),
                AssetAllocation(name: "Momentum Growth Mutual Funds", percentage: 30, expectedCAGR: 16.5, riskLevel: .high, 
                                description: "Invests in stocks showing strong upward price trends.", 
                                fundExamples: ["UTI Momentum 30 Index", "Motilal Oswal Momentum"]),
                AssetAllocation(name: "Small-Cap Alpha Mutual Funds", percentage: 15, expectedCAGR: 18.0, riskLevel: .high, 
                                description: "High-conviction small-cap picks through institutional funds.", 
                                fundExamples: ["Quant Small Cap", "Nippon India Small Cap"]),
                AssetAllocation(name: "Large Cap Index (Safety Anchor)", percentage: 10, expectedCAGR: 13.0, riskLevel: .mid, 
                                description: "Provides stability during market downturns.", 
                                fundExamples: ["HDFC Nifty 50 Index"]),
                AssetAllocation(name: "Liquid Fund (Emergency Reserve)", percentage: 5, expectedCAGR: 7.0, riskLevel: .low, 
                                description: "Keeps 5% in cash for tactical arbitrage or safety.", 
                                fundExamples: ["ICICI Pru Liquid Fund"])
            ]
        case .mid: // Moderate: Diversified exposure
            allocations = [
                AssetAllocation(name: "Multi-Cap Growth Mutual Funds", percentage: 35, expectedCAGR: 14.5, riskLevel: .mid, 
                                description: "Flexible allocation across all market capitalizations.", 
                                fundExamples: ["Parag Parikh Flexi Cap", "Canara Robeco Multi Cap"]),
                AssetAllocation(name: "Bluechip & Mid-Cap Stocks", percentage: 25, expectedCAGR: 16.0, riskLevel: .high, 
                                description: "A mix of stable industry leaders and emerging winners.", 
                                fundExamples: ["HDFC Bank", "Reliance", "Trent", "Varun Beverages"]),
                AssetAllocation(name: "Large & Mid Cap Mutual Funds", percentage: 20, expectedCAGR: 13.5, riskLevel: .mid, 
                                description: "Institutional exposure to top 250 companies.", 
                                fundExamples: ["Mirae Asset Emerging Bluechip"]),
                AssetAllocation(name: "Corporate Bond Fund (Stable)", percentage: 15, expectedCAGR: 7.5, riskLevel: .low, 
                                description: "Safe fixed-income component for regular returns.", 
                                fundExamples: ["SBI Corporate Bond Fund"]),
                AssetAllocation(name: "Small Cap Alpha (Kicker)", percentage: 5, expectedCAGR: 18.0, riskLevel: .high, 
                                description: "Small tactical exposure to small-caps for higher gains.", 
                                fundExamples: ["Tata Small Cap Fund"])
            ]
        case .low: // Conservative: Safety with a growth kicker
            allocations = [
                AssetAllocation(name: "Large Cap (Bluechip) Index MFs", percentage: 40, expectedCAGR: 12.5, riskLevel: .low, 
                                description: "Core portfolio in top 100 stable companies.", 
                                fundExamples: ["UTI Nifty 50 Index"]),
                AssetAllocation(name: "Short Term Debt (Safety)", percentage: 30, expectedCAGR: 7.2, riskLevel: .low, 
                                description: "Safe bonds with low interest rate risk.", 
                                fundExamples: ["Axis Short Term Fund"]),
                AssetAllocation(name: "Mid-Cap Quality Focus Funds", percentage: 15, expectedCAGR: 13.5, riskLevel: .mid, 
                                description: "Quality mid-sized companies with strong balance sheets.", 
                                fundExamples: ["Kotak Emerging Equity"]),
                AssetAllocation(name: "Small Cap Alpha (Growth Kicker)", percentage: 10, expectedCAGR: 18.0, riskLevel: .high, 
                                description: "A small portion allocated to small-caps to beat inflation significantly.", 
                                fundExamples: ["Quant Small Cap"]),
                AssetAllocation(name: "Gold & Silver SGBs", percentage: 5, expectedCAGR: 9.5, riskLevel: .low, 
                                description: "Protects against currency devaluation.", 
                                fundExamples: ["Sovereign Gold Bonds"])
            ]
        }
        
        let blended = allocations.reduce(0.0) { $0 + ($1.percentage * $1.expectedCAGR / 100) }
        return PortfolioBlueprint(allocations: allocations, blendedCAGR: blended, riskLabel: risk.rawValue.capitalized)
    }

    private static func runLeveragedSimulation(
        name: String,
        loanAmount: Double,
        loanRate: Double,
        tenure: Int,
        portfolio: PortfolioBlueprint,
        emiFrequency: EMIFrequency,
        phases: Int,
        emiFromPocket: Bool,
        isSIPMode: Bool = false,
        overridenReturn: Double? = nil,
        historicalPeriodYears: Int = 10
    ) -> LeveragedStrategyResult {
        let months = tenure * 12
        let monthsPerPayment = Int(12 / emiFrequency.paymentsPerYear)
        let historicalStats = buildHistoricalPortfolioStats(portfolio: portfolio, years: historicalPeriodYears)

        let emi = calculateEMIPublic(principal: loanAmount, rate: loanRate, years: tenure, frequency: emiFrequency)

        var investedPool = 0.0
        var cashPool = isSIPMode ? 0.0 : loanAmount
        let phaseAmount = isSIPMode ? 0.0 : (loanAmount / Double(max(1, phases)))
        let interval = max(1, 12 / max(1, phases))
        var phasesInvested = 0
        var totalInvestedOrPaid = 0.0
        var survivalDuration: Int? = nil
        var monthlySteps: [Plan3MonthlyStep] = []

        let monthSymbols = Calendar.current.shortMonthSymbols
        for m in 1...months {
            _ = investedPool + cashPool
            var monthlyInvestment = 0.0
            let periodStartValue = investedPool

            if isSIPMode {
                if m > 12 {
                    monthlyInvestment = emi
                    totalInvestedOrPaid += monthlyInvestment
                }
            } else {
                if (m - 1) % interval == 0 && phasesInvested < phases {
                    let toMove = min(cashPool, phaseAmount)
                    cashPool -= toMove
                    phasesInvested += 1
                    monthlyInvestment = toMove
                }
            }

            let monthlyReturnPercent = overridenReturn != nil
                ? (overridenReturn! / 12.0)
                : historicalStats.monthlyReturns[(m - 1) % historicalStats.monthlyReturns.count]
            let monthlyReturnRate = monthlyReturnPercent / 100.0
            let monthlyGrowth = periodStartValue * monthlyReturnRate
            investedPool = periodStartValue + monthlyGrowth + monthlyInvestment

            var emiPaidThisMonth = 0.0
            if !isSIPMode && m % monthsPerPayment == 0 {
                emiPaidThisMonth = emi
                if emiFromPocket {
                    totalInvestedOrPaid += emi
                } else {
                    investedPool -= emi
                    if investedPool < 0 && survivalDuration == nil {
                        survivalDuration = Int(ceil(Double(m)/12.0))
                    }
                }
            }

            let monthName = monthSymbols[(m - 1) % 12]

            monthlySteps.append(Plan3MonthlyStep(
                month: monthName,
                startValue: periodStartValue,
                investment: monthlyInvestment,
                growth: monthlyGrowth,
                historicalReturnPercent: monthlyReturnPercent,
                netChange: monthlyInvestment + monthlyGrowth - (!emiFromPocket ? emiPaidThisMonth : 0),
                interestPaid: isSIPMode ? 0 : (loanAmount * (loanRate/1200)),
                emiFromPocket: emiPaidThisMonth,
                endValue: investedPool,
                loanOutstanding: isSIPMode ? 0 : loanAmount
            ))
        }

        var yearlyBreakdown: [Plan3YearlyDetail] = []
        for y in 1...tenure {
            let startIdx = (y - 1) * 12
            let endIdx = min(y * 12 - 1, monthlySteps.count - 1)
            let yearSteps = Array(monthlySteps[startIdx...endIdx])
            let yearlyGrowth = yearSteps.reduce(0.0) { $0 + $1.growth }
            let yearlyInvested = yearSteps.reduce(0.0) { $0 + $1.investment }
            let annualReturn = yearSteps.reduce(1.0) { $0 * (1.0 + ($1.historicalReturnPercent / 100.0)) } - 1.0

            yearlyBreakdown.append(Plan3YearlyDetail(
                year: y, date: Calendar.current.date(byAdding: .year, value: y, to: Date()) ?? Date(),
                startValue: yearSteps.first?.startValue ?? 0,
                investmentValue: yearlyInvested,
                emiPaidYearly: isSIPMode ? yearlyInvested : (emi * emiFrequency.paymentsPerYear),
                withdrawalYearly: (!isSIPMode && !emiFromPocket) ? (emi * emiFrequency.paymentsPerYear) : 0,
                netYearlyProfit: yearlyGrowth,
                annualReturnPercent: annualReturn * 100.0,
                monthlySteps: yearSteps
            ))
        }

        let finalValue = investedPool + cashPool
        let netProfit = isSIPMode ? (finalValue - totalInvestedOrPaid) : (emiFromPocket ? (finalValue - totalInvestedOrPaid) : finalValue)

        return LeveragedStrategyResult(
            name: name,
            description: isSIPMode ? "Wealth creation through disciplined regular savings." : "Portfolio leveraging with \(portfolio.riskLabel) risk profile.",
            finalValue: finalValue,
            totalEMIPaid: isSIPMode ? totalInvestedOrPaid : (emi * Double(months) / Double(monthsPerPayment)),
            netProfit: netProfit,
            breakEvenReturn: isSIPMode ? 0 : loanRate,
            riskLevel: isSIPMode ? "Low" : (name == "Aggressive" ? "High" : (name == "Moderate" ? "Medium" : "Low")),
            riskFlags: survivalDuration != nil ? ["Depletion Risk"] : [],
            survivalDuration: survivalDuration,
            yearlyBreakdown: yearlyBreakdown,
            milestones: []
        )
    }

    private static func getDeterministicMonthlyReturn(portfolio: PortfolioBlueprint, month: Int) -> Double {
        let stats = buildHistoricalPortfolioStats(portfolio: portfolio, years: 10)
        return stats.monthlyReturns[(month - 1) % stats.monthlyReturns.count] / 100.0
    }

    private struct HistoricalPortfolioStats {
        let monthlyReturns: [Double]
        let meanCAGR: Double
        let p5CAGR: Double
        let p25CAGR: Double
        let p75CAGR: Double
    }

    private static func buildHistoricalPortfolioStats(portfolio: PortfolioBlueprint, years requestedYears: Int) -> HistoricalPortfolioStats {
        let years = [5, 10, 15].contains(requestedYears) ? requestedYears : 10
        let allYears = Array(2011...2025)
        let selectedYears = Array(allYears.suffix(years))
        let totalWeight = max(1, portfolio.allocations.reduce(0.0) { $0 + $1.percentage })

        var weightedMonthly: [Double] = []
        for year in selectedYears {
            for monthIndex in 0..<12 {
                let portfolioReturn = portfolio.allocations.reduce(0.0) { partial, allocation in
                    let assetClass = historicalAssetClass(for: allocation.name)
                    let assetReturn = monthlyReturn(for: assetClass, year: year, monthIndex: monthIndex)
                    return partial + ((allocation.percentage / totalWeight) * assetReturn)
                }
                weightedMonthly.append(portfolioReturn)
            }
        }

        let finalMultiplier = weightedMonthly.reduce(1.0) { $0 * (1.0 + $1 / 100.0) }
        let meanCAGR = (pow(finalMultiplier, 1.0 / Double(years)) - 1.0) * 100.0
        let annualCAGRs = stride(from: 0, to: weightedMonthly.count, by: 12).map { start -> Double in
            let end = min(start + 12, weightedMonthly.count)
            let annualMultiplier = weightedMonthly[start..<end].reduce(1.0) { $0 * (1.0 + $1 / 100.0) }
            return (annualMultiplier - 1.0) * 100.0
        }.sorted()

        return HistoricalPortfolioStats(
            monthlyReturns: weightedMonthly.isEmpty ? [0] : weightedMonthly,
            meanCAGR: meanCAGR,
            p5CAGR: percentile(annualCAGRs, 0.05),
            p25CAGR: percentile(annualCAGRs, 0.25),
            p75CAGR: percentile(annualCAGRs, 0.75)
        )
    }

    private enum HistoricalAssetClass {
        case largeCapEquity
        case midSmallCapEquity
        case diversifiedEquity
        case debt
        case gold
        case cash
    }

    private static func historicalAssetClass(for name: String) -> HistoricalAssetClass {
        let lower = name.lowercased()
        if lower.contains("gold") || lower.contains("silver") { return .gold }
        if lower.contains("bond") || lower.contains("debt") || lower.contains("liquid") || lower.contains("short term") { return .debt }
        if lower.contains("small") || lower.contains("mid") || lower.contains("momentum") { return .midSmallCapEquity }
        if lower.contains("large") || lower.contains("bluechip") || lower.contains("index") { return .largeCapEquity }
        if lower.contains("cash") { return .cash }
        return .diversifiedEquity
    }

    private static func monthlyReturn(for assetClass: HistoricalAssetClass, year: Int, monthIndex: Int) -> Double {
        let annual = annualHistoricalReturn(for: assetClass, year: year) / 100.0
        let baseMonthly = (pow(1.0 + annual, 1.0 / 12.0) - 1.0) * 100.0
        let seasonalPattern = [-0.35, 0.18, 0.42, -0.12, 0.28, -0.22, 0.31, -0.18, -0.28, 0.36, 0.24, -0.64]
        return baseMonthly + seasonalPattern[monthIndex % seasonalPattern.count]
    }

    private static func annualHistoricalReturn(for assetClass: HistoricalAssetClass, year: Int) -> Double {
        let index = max(0, min(14, year - 2011))
        switch assetClass {
        case .largeCapEquity:
            return [-24.6, 27.7, 6.8, 31.4, -4.1, 3.0, 28.6, 3.2, 12.0, 14.9, 24.1, 4.3, 20.0, 8.8, 6.2][index]
        case .midSmallCapEquity:
            return [-31.0, 38.5, 8.0, 55.9, 7.4, 6.8, 48.1, -15.6, -4.3, 20.7, 46.1, 3.0, 41.7, 23.5, 8.1][index]
        case .diversifiedEquity:
            return [-25.7, 31.8, 7.2, 39.5, 1.1, 4.5, 34.8, -3.1, 8.6, 16.4, 29.5, 4.0, 26.4, 12.7, 6.8][index]
        case .debt:
            return [8.3, 9.1, 7.2, 8.7, 8.0, 10.2, 6.5, 5.8, 9.4, 12.1, 4.3, 3.8, 7.4, 7.9, 6.8][index]
        case .gold:
            return [31.1, 12.9, -6.2, -8.5, -5.7, 10.8, 2.8, 7.1, 24.6, 28.1, -4.0, 14.2, 15.3, 21.0, 9.6][index]
        case .cash:
            return [6.5, 7.0, 7.0, 6.8, 6.7, 6.5, 6.2, 6.0, 5.8, 4.8, 4.2, 4.8, 6.0, 6.5, 6.2][index]
        }
    }

    private static func percentile(_ values: [Double], _ p: Double) -> Double {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let position = max(0, min(Double(sorted.count - 1), p * Double(sorted.count - 1)))
        let lower = Int(floor(position))
        let upper = Int(ceil(position))
        if lower == upper { return sorted[lower] }
        let weight = position - Double(lower)
        return sorted[lower] + ((sorted[upper] - sorted[lower]) * weight)
    }

    private static func generateRecommendations(input: InvestmentPlanInputModel, plan1: Plan1Result, plan2: Plan2Result?,
                                               feasibility: FeasibilityResult, healthCtx: FinancialHealthContext) -> PlanRecommendations {
        let reason = plan1.reachesGoal ? "Plan 1 may be on track under the selected assumptions." : "Compare alternate scenarios to understand the possible shortfall."
        return PlanRecommendations(primaryRecommendation: plan1.reachesGoal ? "Plan 1 scenario" : (plan2 != nil ? "Plan 2 scenario" : "Plan 1 scenario"),
                                   reason: reason, tips: [])
    }

    private static func applyGoalBranding(to p: Plan1Result, goal: InvestmentGoalCategory, purpose: String) -> Plan1Result {
        var x = p; x.name = goal.rawValue; x.icon = InvestmentPlanInputModel.iconForGoal(goal); return x
    }

    private static func applyPlan2Branding(to p: Plan2Result, goal: InvestmentGoalCategory, strategy: Plan2Strategy) -> Plan2Result {
        var x = p; x.name = "Loan Strategy"; return x
    }

    static func sipFutureValue(monthly: Double, rateCAGR: Double, years: Int) -> Double {
        let r = rateCAGR / 100 / 12; let m = Double(years * 12)
        if r == 0 { return monthly * m }
        return monthly * (pow(1+r, m) - 1) / r * (1+r)
    }

    static func lumpsumFutureValue(amount: Double, rateCAGR: Double, years: Int) -> Double {
        return amount * pow(1 + rateCAGR/100, Double(years))
    }

    static func computeRequiredSIP(target: Double, lumpsum: Double, cagr: Double, years: Int) -> Double {
        let r = cagr / 100 / 12; let m = Double(years * 12)
        let fvLump = lumpsumFutureValue(amount: lumpsum, rateCAGR: cagr, years: years)
        let rem = Swift.max(0, target - fvLump)
        if r == 0 { return m > 0 ? rem/m : 0 }
        return rem / ((pow(1+r, m) - 1) / r * (1+r))
    }

    private static func sipRetVal(monthly: Double, cagr: Double, years: Int) -> Double { return sipFutureValue(monthly: monthly, rateCAGR: cagr, years: years) }

    private static func generateScenarios(totalInvested: Double, sip: Double, lumpsum: Double, years: Int) -> [PlanScenario] {
        let rates: [(String, Double)] = [
            ("Worst Case", 2.0),
            ("Conservative", 8.0),
            ("Moderate", 12.0),
            ("Bull Market", 18.0)
        ]

        return rates.map { name, cagr in
            let fvSIP = sipFutureValue(monthly: sip, rateCAGR: cagr, years: years)
            let fvLump = lumpsumFutureValue(amount: lumpsum, rateCAGR: cagr, years: years)
            let finalValue = fvSIP + fvLump
            let gain = finalValue - totalInvested
            return PlanScenario(name: name, cagr: cagr, gainLoss: gain, finalValue: finalValue)
        }
    }

    private static func buildLoanBreakdown(planType: String, target: Double, loan: Double, emi: Double, sip: Double, sipRet: Double, gain: Double) -> [PlanBreakdownItem] {
        return [PlanBreakdownItem(label: "Target", icon: "flag", value: target, isNegative: false)]
    }

    static func parseAmount(_ s: String) -> Double {
        let lower = s.lowercased()
        let multiplier: Double
        if lower.contains("cr") { multiplier = 10_000_000 }
        else if lower.contains("l") { multiplier = 100_000 }
        else if lower.contains("k") { multiplier = 1000 }
        else { multiplier = 1 }

        let cleaned = s.components(separatedBy: CharacterSet.decimalDigits.union(CharacterSet(charactersIn: ".")).inverted).joined()
        return (Double(cleaned) ?? 0) * multiplier
    }

    static func expandAmountSuffix(_ s: String) -> String {
        let lower = s.lowercased().trimmingCharacters(in: .whitespaces)
        if lower.isEmpty { return "" }
        
        var multiplier: Double? = nil
        var suffixLen = 0
        
        if lower.hasSuffix("cr") {
            multiplier = 10_000_000
            suffixLen = 2
        } else if lower.hasSuffix("l") {
            multiplier = 100_000
            suffixLen = 1
        } else if lower.hasSuffix("k") {
            multiplier = 1000
            suffixLen = 1
        }
        
        guard let m = multiplier else { return s }
        
        let numericPart = String(lower.dropLast(suffixLen)).trimmingCharacters(in: .whitespaces)
        let cleaned = numericPart.components(separatedBy: CharacterSet.decimalDigits.union(CharacterSet(charactersIn: ".")).inverted).joined()
        
        if let val = Double(cleaned) {
            let total = val * m
            return String(format: "%.0f", total)
        }
        return s
    }
    static func calculateEMIPublic(principal: Double, rate: Double, years: Int, frequency: EMIFrequency = .quarterly, interestType: InterestType = .compounded) -> Double {
        let n = Double(years) * frequency.paymentsPerYear

        switch interestType {
        case .compounded:
            let r = (rate / 100.0) / frequency.paymentsPerYear
            guard r > 0, n > 0 else { return n > 0 ? principal / n : 0 }
            let pqr = pow(1 + r, n)
            let emi = (principal * r * pqr) / (pqr - 1)
            return emi.isFinite ? emi : 0

        case .simple:
            let totalInterest = principal * (rate / 100.0) * Double(years)
            let totalAmount = principal + totalInterest
            guard n > 0 else { return 0 }
            let emi = totalAmount / n
            return emi.isFinite ? emi : 0
        }
    }

    static func formatL_Internal(_ v: Double) -> String {
        let absV = abs(v)
        if absV >= 10000000 { return String(format: "%.1fCr", v / 10000000) }
        return String(format: "%.1fL", v / 100000)
    }
    private static func mapRiskLevel(_ t: String) -> AstraRiskLevel { AstraRiskLevel(rawValue: t.lowercased()) ?? .mid }
    private static func mapLiquidityLevel(_ t: String) -> AstraLiquidityLevel { AstraLiquidityLevel(rawValue: t.lowercased()) ?? .mid }
}

fileprivate extension InvestmentPlanInputModel {
    static func iconForGoal(_ g: InvestmentGoalCategory) -> String {
        switch g {
        case .retirement: return "figure.walk.circle.fill"
        case .education: return "graduationcap.circle.fill"
        case .homePurchase: return "house.circle.fill"
        case .vehiclePurchase: return "car.circle.fill"
        case .travel: return "airplane.circle.fill"
        case .wedding: return "heart.circle.fill"
        case .wealthCreation: return "chart.bar.fill"
        case .business: return "briefcase.fill"
        case .emergency: return "shield.fill"
        default: return "star.circle.fill"
        }
    }
}
