import Foundation

/// Mathematical simulation engine for retirement accumulation and systematic withdrawal plans (SWP).
/// Month-by-month decumulation engine modeling inflation, healthcare costs, sequence risk, and solvency.
enum RetirementSWPEngine {

    // MARK: - Primary Simulation Entry Point

    static func simulate(
        input: RetirementSWPInput,
        appliedStress: RetirementStressScenario? = nil,
        calculateStressScenarios: Bool = true
    ) -> RetirementSWPResult {
        let stress = appliedStress ?? RetirementStressScenario.standardScenarios[0]

        let currentAge = input.currentAge
        let effectiveRetirementAge = max(currentAge, input.retirementAge + stress.retirementAgeShiftYears)
        let effectiveLifeExpectancy = max(effectiveRetirementAge + 1, input.lifeExpectancyAge + stress.longevityShiftYears)

        let yearsToRetirement = max(0, effectiveRetirementAge - currentAge)
        let yearsInRetirement = max(1, effectiveLifeExpectancy - effectiveRetirementAge)

        // 1. Accumulation Phase (Pre-Retirement)
        let (accumulationTimeline, corpusAtRetirement) = simulateAccumulation(
            input: input,
            yearsToRetirement: yearsToRetirement,
            currentAge: currentAge
        )

        // 2. Baseline Required Corpus using existing RetirementCalculationEngine
        let firstYearLifestyle = input.monthlyLifestyleExpenseToday * 12.0 * pow(1.0 + (input.lifestyleInflationPct / 100.0), Double(yearsToRetirement))
        let firstYearHealthcare = input.monthlyHealthcareExpenseToday * 12.0 * pow(1.0 + (input.healthcareInflationPct / 100.0), Double(yearsToRetirement))
        let annualPension = input.monthlyPensionOrGuaranteedIncome * 12.0

        let basePostReturn = max(0.01, (input.postRetirementReturnPct - stress.returnReductionPct) / 100.0)
        let baseLifestyleInf = max(0.0, (input.lifestyleInflationPct + stress.inflationIncreasePct) / 100.0)
        let baseHealthcareInf = max(0.0, (input.healthcareInflationPct + stress.inflationIncreasePct) / 100.0)

        let requiredCorpusRun = RetirementCalculationEngine.requiredStartingCorpus(
            retirementAge: effectiveRetirementAge,
            lifeExpectancy: effectiveLifeExpectancy,
            firstYearAnnualLifestyleExpense: firstYearLifestyle,
            firstYearAnnualHealthcareExpense: firstYearHealthcare,
            postRetirementReturn: basePostReturn,
            retirementInflation: baseLifestyleInf,
            healthcareInflation: baseHealthcareInf,
            otherAnnualRetirementIncome: annualPension,
            withdrawalRate: input.fixedWithdrawalRatePct / 100.0
        )
        let requiredCorpus = requiredCorpusRun.corpus

        // 3. Month-by-Month Withdrawal Phase (Post-Retirement)
        let (withdrawalTimeline, depletionAge, terminalCorpus, lifetimeWithdrawn, lifetimePension, lifetimeTaxesFees) = simulateWithdrawal(
            startingCorpus: corpusAtRetirement,
            retirementAge: effectiveRetirementAge,
            lifeExpectancy: effectiveLifeExpectancy,
            input: input,
            stress: stress,
            firstYearAnnualLifestyle: firstYearLifestyle,
            firstYearAnnualHealthcare: firstYearHealthcare
        )

        let corpusGap = corpusAtRetirement - requiredCorpus
        let isAdequate = (depletionAge == nil) && (corpusGap >= 0)
        let yearsSustained = (depletionAge != nil) ? max(0, depletionAge! - effectiveRetirementAge) : yearsInRetirement

        let firstYearMonthlyDraw = withdrawalTimeline.first?.monthlyDrawdownAmount ?? 0.0
        let finalYearMonthlyDraw = withdrawalTimeline.last?.monthlyDrawdownAmount ?? 0.0

        // 4. Calculate Required Starting SIP if short
        let requiredStartingSIP: Double
        if corpusGap < 0 && yearsToRetirement > 0 {
            requiredStartingSIP = FinancialCalculationEngine.requiredStartingMonthlySIP(
                targetCorpus: requiredCorpus,
                annualReturnRate: input.preRetirementReturnPct / 100.0,
                years: yearsToRetirement,
                annualStepUpRate: input.annualSIPStepUpRatePct / 100.0,
                currentInvestments: input.currentRetirementCorpus
            )
        } else {
            requiredStartingSIP = input.monthlySIPPreRetirement
        }

        // 5. Feasibility Evaluation
        let feasibility: PlanFeasibility
        let feasibilitySummary: String
        var suggestions: [String] = []

        if let depAge = depletionAge {
            feasibility = .notCurrentlyFeasible
            feasibilitySummary = "Your retirement corpus is projected to be exhausted at age \(depAge) (\(depAge - effectiveRetirementAge) years after retirement). Additional funding or expense adjustments are critical."
            let sipDiff = max(0, requiredStartingSIP - input.monthlySIPPreRetirement)
            if sipDiff > 0 {
                suggestions.append("Increase pre-retirement monthly SIP by \(formatCurrency(sipDiff)) (to \(formatCurrency(requiredStartingSIP))/mo).")
            }
            suggestions.append("Consider postponing retirement by 2–3 years to allow further compounding.")
            suggestions.append("Downsize post-retirement discretionary expenses or explore annuity/pension enhancements.")
        } else if corpusGap < 0 {
            feasibility = .manageable
            feasibilitySummary = "Corpus barely covers projected life expectancy with limited buffer for unexpected medical or family shocks."
            suggestions.append("Target a 15–20% safety buffer over required corpus to protect against tail-risk longevity.")
        } else {
            feasibility = .healthy
            feasibilitySummary = "Fully funded retirement plan. Projected corpus at age \(effectiveRetirementAge) covers all inflation-adjusted living expenses through age \(effectiveLifeExpectancy)."
            suggestions.append("Maintain disciplined annual step-up of \(String(format: "%.0f", input.annualSIPStepUpRatePct))% on pre-retirement SIP.")
            suggestions.append("Gradually shift equity exposure to debt/fixed-income 3 years prior to retirement to mitigate sequence risk.")
        }

        // 6. Stress Test Survival Aches
        var stressAges: [String: Int?] = [:]
        if calculateStressScenarios {
            for sc in RetirementStressScenario.standardScenarios {
                let res = simulateSingleStress(input: input, stress: sc)
                stressAges[sc.id] = res
            }
        }

        return RetirementSWPResult(
            projectedCorpusAtRetirement: corpusAtRetirement,
            requiredCorpusAtRetirement: requiredCorpus,
            corpusShortfallOrSurplus: corpusGap,
            isAdequate: isAdequate,
            depletionAge: depletionAge,
            yearsCorpusSustained: yearsSustained,
            terminalCorpusAtLifeExpectancy: terminalCorpus,
            totalLifetimeWithdrawn: lifetimeWithdrawn,
            totalLifetimePensionReceived: lifetimePension,
            totalLifetimeTaxesAndFees: lifetimeTaxesFees,
            firstYearMonthlyWithdrawal: firstYearMonthlyDraw,
            finalYearMonthlyWithdrawal: finalYearMonthlyDraw,
            requiredStartingSIPForFullSolvency: requiredStartingSIP,
            accumulationTimeline: accumulationTimeline,
            withdrawalTimeline: withdrawalTimeline,
            stressTestSurvivalAges: stressAges,
            feasibility: feasibility,
            feasibilitySummary: feasibilitySummary,
            actionRecommendations: suggestions
        )
    }

    // MARK: - Accumulation Engine

    private static func simulateAccumulation(
        input: RetirementSWPInput,
        yearsToRetirement: Int,
        currentAge: Int
    ) -> ([RetirementAccumulationYear], Double) {
        guard yearsToRetirement > 0 else {
            return ([], max(0, input.currentRetirementCorpus))
        }

        var timeline: [RetirementAccumulationYear] = []
        var runningCorpus = max(0, input.currentRetirementCorpus)
        var currentMonthlySIP = max(0, input.monthlySIPPreRetirement)
        let annualReturn = max(0, input.preRetirementReturnPct / 100.0)
        let stepUpRate = max(0, input.annualSIPStepUpRatePct / 100.0)

        for year in 1...yearsToRetirement {
            let beginning = runningCorpus
            let annualContribution = currentMonthlySIP * 12.0

            // Compound using monthly step
            let endOfYearCorpus = FinancialCalculationEngine.futureValue(
                monthlySIP: currentMonthlySIP,
                annualRate: annualReturn,
                months: 12,
                initialLumpSum: beginning
            )

            let growth = max(0, endOfYearCorpus - beginning - annualContribution)
            runningCorpus = endOfYearCorpus

            timeline.append(
                RetirementAccumulationYear(
                    age: currentAge + year,
                    yearOffset: year,
                    beginningBalance: beginning,
                    monthlySIPAmount: currentMonthlySIP,
                    annualContributions: annualContribution,
                    investmentReturns: growth,
                    endingBalance: endOfYearCorpus
                )
            )

            // Step up SIP for next year
            currentMonthlySIP *= (1.0 + stepUpRate)
        }

        return (timeline, runningCorpus)
    }

    // MARK: - Decumulation / SWP Engine

    private static func simulateWithdrawal(
        startingCorpus: Double,
        retirementAge: Int,
        lifeExpectancy: Int,
        input: RetirementSWPInput,
        stress: RetirementStressScenario,
        firstYearAnnualLifestyle: Double,
        firstYearAnnualHealthcare: Double
    ) -> (
        timeline: [RetirementWithdrawalYear],
        depletionAge: Int?,
        terminalCorpus: Double,
        totalWithdrawn: Double,
        totalPension: Double,
        totalTaxesFees: Double
    ) {
        let yearsInRetirement = max(1, lifeExpectancy - retirementAge)
        var currentCorpus = startingCorpus

        // Apply sequence of returns shock if applicable in Year 1
        if stress.earlySequenceOfReturnsShockPct > 0 {
            currentCorpus *= (1.0 - (stress.earlySequenceOfReturnsShockPct / 100.0))
        }

        let postReturnRate = max(0.005, (input.postRetirementReturnPct - stress.returnReductionPct) / 100.0)
        let monthlyReturnRate = postReturnRate / 12.0
        let feeRateMonthly = max(0, (input.managementFeePct / 100.0) / 12.0)
        let taxRate = max(0, input.postRetirementTaxPct / 100.0)

        let lifestyleInfRate = max(0.0, (input.lifestyleInflationPct + stress.inflationIncreasePct) / 100.0)
        let healthcareInfRate = max(0.0, (input.healthcareInflationPct + stress.inflationIncreasePct) / 100.0)

        var annualLifestyleExpense = firstYearAnnualLifestyle
        var annualHealthcareExpense = firstYearAnnualHealthcare
        let annualPensionIncome = input.monthlyPensionOrGuaranteedIncome * 12.0

        var yearlyTimeline: [RetirementWithdrawalYear] = []
        var totalWithdrawnLifetime = 0.0
        var totalPensionLifetime = 0.0
        var totalTaxesFeesLifetime = 0.0
        var detectedDepletionAge: Int? = nil

        for yearOffset in 1...yearsInRetirement {
            let age = retirementAge + yearOffset
            let beginningYearCorpus = currentCorpus

            if currentCorpus <= 0 && detectedDepletionAge == nil {
                detectedDepletionAge = age - 1
            }

            var yearGrossWithdrawal = 0.0
            var yearPension = 0.0
            var yearNetDrawdown = 0.0
            var yearGrowth = 0.0
            var yearFeesAndTaxes = 0.0
            let isDepletedAtStart = currentCorpus <= 0

            // Determine target annual withdrawal based on mode
            let targetAnnualWithdrawal: Double
            switch input.withdrawalMode {
            case .inflationAdjusted:
                targetAnnualWithdrawal = annualLifestyleExpense + annualHealthcareExpense
            case .fixedNominal:
                let initialWithdrawal = input.customInitialMonthlyWithdrawal ?? (input.monthlyLifestyleExpenseToday + input.monthlyHealthcareExpenseToday)
                targetAnnualWithdrawal = initialWithdrawal * 12.0
            case .percentageOfPortfolio:
                let pct = (input.fixedWithdrawalRatePct / 100.0)
                targetAnnualWithdrawal = max(0, beginningYearCorpus * pct)
            }

            let monthlyTargetDraw = targetAnnualWithdrawal / 12.0
            let monthlyPension = annualPensionIncome / 12.0

            // Simulate month-by-month for precision
            for _ in 1...12 {
                guard currentCorpus > 0 else {
                    currentCorpus = 0
                    break
                }

                // Month beginning return
                let monthGrowth = currentCorpus * monthlyReturnRate
                let monthFee = currentCorpus * feeRateMonthly

                // Net cash needed from portfolio = max(0, targetDraw - pension)
                let netCashNeeded = max(0, monthlyTargetDraw - monthlyPension)
                let monthTax = netCashNeeded * taxRate
                let totalDeduction = netCashNeeded + monthTax + monthFee

                yearGrossWithdrawal += monthlyTargetDraw
                yearPension += monthlyPension
                yearNetDrawdown += netCashNeeded
                yearGrowth += monthGrowth
                yearFeesAndTaxes += (monthTax + monthFee)

                currentCorpus = currentCorpus + monthGrowth - totalDeduction
                if currentCorpus <= 0 {
                    currentCorpus = 0
                    if detectedDepletionAge == nil {
                        detectedDepletionAge = age
                    }
                }
            }

            totalWithdrawnLifetime += yearGrossWithdrawal
            totalPensionLifetime += yearPension
            totalTaxesFeesLifetime += yearFeesAndTaxes

            let cumulativeInflationFactor = pow(1.0 + lifestyleInfRate, Double(yearOffset))
            let realPurchasingPower = yearGrossWithdrawal / cumulativeInflationFactor

            yearlyTimeline.append(
                RetirementWithdrawalYear(
                    age: age,
                    yearOffsetInRetirement: yearOffset,
                    beginningCorpus: beginningYearCorpus,
                    grossWithdrawals: yearGrossWithdrawal,
                    pensionIncome: yearPension,
                    netDrawdownFromCorpus: yearNetDrawdown,
                    investmentReturns: yearGrowth,
                    managementFeesAndTaxes: yearFeesAndTaxes,
                    endingCorpus: currentCorpus,
                    monthlyDrawdownAmount: yearGrossWithdrawal / 12.0,
                    realPurchasingPowerValue: realPurchasingPower,
                    isDepleted: isDepletedAtStart || currentCorpus <= 0
                )
            )

            // Step up expenses for subsequent year
            annualLifestyleExpense *= (1.0 + lifestyleInfRate)
            annualHealthcareExpense *= (1.0 + healthcareInfRate)
        }

        return (
            timeline: yearlyTimeline,
            depletionAge: detectedDepletionAge,
            terminalCorpus: max(0, currentCorpus),
            totalWithdrawn: totalWithdrawnLifetime,
            totalPension: totalPensionLifetime,
            totalTaxesFees: totalTaxesFeesLifetime
        )
    }

    private static func simulateSingleStress(
        input: RetirementSWPInput,
        stress: RetirementStressScenario
    ) -> Int? {
        let res = simulate(input: input, appliedStress: stress, calculateStressScenarios: false)
        return res.depletionAge
    }

    private static func formatCurrency(_ value: Double) -> String {
        let absVal = abs(value)
        if absVal >= 10_000_000 {
            return String(format: "₹%.2fCr", value / 10_000_000.0)
        } else if absVal >= 100_000 {
            return String(format: "₹%.2fL", value / 100_000.0)
        } else {
            return String(format: "₹%.0f", value)
        }
    }
}
