import Foundation

/// Goal-agnostic orchestrator. Views should consume these results instead of embedding formulas.
enum GoalProjectionEngine {

    struct LifeEventLoad: Equatable {
        var yearOffset: Int
        var monthlyCost: Double
    }

    static func project(
        configuration: FinancialGoalConfiguration,
        assumptions: FinancialPlanningAssumptions,
        lifeEvents: [LifeEventLoad] = [],
        selectedStartingSIP: Double? = nil
    ) -> GoalProjectionResult {
        let resolved = assumptions.resolved(using: assumptions.scenarioKind ?? .base)
        let issues = FinancialPlanningValidation.validate(configuration: configuration, assumptions: assumptions)
        let blocking = issues.filter(\.isBlocking).map(\.message)

        let years = max(1, configuration.resolvedYearsToGoal ?? 1)
        let healthcareToday = max(0, configuration.currentMonthlyHealthcareExpenses ?? 0)
        let totalExpensesToday = max(0, configuration.currentMonthlyExpenses ?? 0)
        let retirementLifestyleTotalToday = max(0, configuration.retirementLifestyleExpensesToday ?? totalExpensesToday)
        let lifestyleToday = max(0, retirementLifestyleTotalToday - healthcareToday)
        let incomeToday = max(0, configuration.currentMonthlyIncome ?? 0)
        let otherGoals = max(0, configuration.otherGoalMonthlyAllocations ?? 0)
        let existing = max(0, (configuration.currentInvestments ?? 0) + (configuration.currentSavings ?? 0) + (configuration.existingGoalCorpus ?? 0))
        let stepUp = configuration.annualInvestmentStepUp ?? resolved.annualSIPStepUpRate
        let eventCostByOffset = Dictionary(lifeEvents.map { ($0.yearOffset, $0.monthlyCost) }, uniquingKeysWith: +)

        var presentValue = max(0, configuration.targetAmountToday ?? 0)
        var requiredCorpus = presentValue
        var retirementResult: RetirementProjectionResult?

        if configuration.goalType == .retirement {
            let currentAge = configuration.currentAge ?? 0
            let retireAge = configuration.retirementAge ?? configuration.goalAge ?? (currentAge + years)
            let life = configuration.lifeExpectancy ?? (retireAge + max(1, (configuration.yearsToGoal ?? 25)))
            let inflation = resolved.expenseGrowthRate
            let monthlyLifestyleAtRetirement = FinancialCalculationEngine.grownAmount(
                presentValue: lifestyleToday,
                annualRate: inflation,
                years: Double(years)
            )
            let monthlyHealthcareAtRetirement = FinancialCalculationEngine.grownAmount(
                presentValue: healthcareToday,
                annualRate: resolved.healthcareInflationRate,
                years: Double(years)
            )
            presentValue = (lifestyleToday + healthcareToday) * 12.0
            let healthcareReserveGrown = FinancialCalculationEngine.grownAmount(
                presentValue: max(0, configuration.healthcareReserveToday ?? 0),
                annualRate: resolved.healthcareInflationRate,
                years: Double(years)
            )
            let corpusSolve = RetirementCalculationEngine.requiredStartingCorpus(
                retirementAge: retireAge,
                lifeExpectancy: life,
                firstYearAnnualLifestyleExpense: monthlyLifestyleAtRetirement * 12.0,
                firstYearAnnualHealthcareExpense: monthlyHealthcareAtRetirement * 12.0,
                postRetirementReturn: resolved.postRetirementReturnRate,
                retirementInflation: inflation,
                healthcareInflation: resolved.healthcareInflationRate,
                otherAnnualRetirementIncome: max(0, configuration.otherMonthlyRetirementIncome ?? 0) * 12.0,
                withdrawalRate: configuration.retirementWithdrawalRate ?? resolved.retirementWithdrawalRate
            )
            requiredCorpus = corpusSolve.corpus + healthcareReserveGrown
            retirementResult = RetirementProjectionResult(
                currentAge: currentAge,
                retirementAge: retireAge,
                lifeExpectancy: life,
                yearsToRetirement: years,
                yearsInRetirement: max(0, life - retireAge),
                monthlyLifestyleToday: lifestyleToday,
                monthlyHealthcareToday: healthcareToday,
                estimatedMonthlyLifestyleAtRetirement: monthlyLifestyleAtRetirement,
                estimatedMonthlyHealthcareAtRetirement: monthlyHealthcareAtRetirement,
                requiredCorpus: requiredCorpus,
                withdrawalRateCorpus: corpusSolve.withdrawalFallback + healthcareReserveGrown,
                usedYearByYearSimulation: corpusSolve.usedSimulation,
                drawdown: corpusSolve.drawdown
            )
        } else {
            let inflationForGoal = inflationRate(for: configuration.goalType, resolved: resolved)
            requiredCorpus = FinancialCalculationEngine.inflationAdjustedCost(
                currentCost: presentValue,
                annualInflationRate: inflationForGoal,
                years: Double(years)
            )
        }

        let futureValueExisting = FinancialCalculationEngine.futureValueOfExistingInvestments(
            presentValue: existing,
            annualReturnRate: resolved.investmentReturnRate,
            years: Double(years)
        )

        let requiredSIP = FinancialCalculationEngine.requiredStartingMonthlySIP(
            targetCorpus: requiredCorpus,
            annualReturnRate: resolved.investmentReturnRate,
            years: years,
            annualStepUpRate: stepUp,
            currentInvestments: existing
        )

        let plannedSIP = selectedStartingSIP ?? configuration.startingMonthlyInvestment ?? requiredSIP
        let projectedFromPlan = FinancialCalculationEngine.stepUpFutureValue(
            initialMonthlySIP: plannedSIP,
            annualStepUpRate: stepUp,
            annualReturnRate: resolved.investmentReturnRate,
            years: years,
            initialLumpSum: existing
        )
        let fundingGap = requiredCorpus - projectedFromPlan

        let year0Surplus = max(0, incomeToday - totalExpensesToday - otherGoals - (eventCostByOffset[0] ?? 0))
        let feasibility = feasibility(
            requiredSIP: requiredSIP,
            surplus: year0Surplus,
            selectedStepUp: stepUp,
            incomeGrowth: resolved.incomeGrowthRate
        )

        let yearly = yearlyProjection(
            configuration: configuration,
            resolved: resolved,
            years: years,
            requiredCorpus: requiredCorpus,
            plannedSIP: plannedSIP,
            stepUp: stepUp,
            existing: existing,
            lifestyleToday: lifestyleToday,
            healthcareToday: healthcareToday,
            eventCostByOffset: eventCostByOffset
        )

        let explanations = buildExplanations(
            configuration: configuration,
            resolved: resolved,
            years: years,
            presentValue: presentValue,
            requiredCorpus: requiredCorpus,
            existing: existing,
            futureValueExisting: futureValueExisting,
            requiredSIP: requiredSIP,
            stepUp: stepUp,
            retirement: retirementResult
        )

        return GoalProjectionResult(
            goalType: configuration.goalType,
            goalName: configuration.goalName,
            scenario: resolved.scenarioKind,
            assumptions: resolved,
            yearsToGoal: years,
            presentValue: presentValue,
            futureValue: requiredCorpus,
            existingInvestmentsToday: existing,
            futureValueOfExistingInvestments: futureValueExisting,
            requiredCorpus: requiredCorpus,
            fundingGap: fundingGap,
            requiredStartingSIP: requiredSIP,
            selectedStartingSIP: plannedSIP,
            projectedCorpusFromPlan: projectedFromPlan,
            feasibility: feasibility,
            yearlyProjection: yearly,
            explanations: explanations,
            validationMessages: blocking,
            retirement: retirementResult
        )
    }

    static func compareScenarios(
        configuration: FinancialGoalConfiguration,
        customAssumptions: FinancialPlanningAssumptions,
        lifeEvents: [LifeEventLoad] = []
    ) -> [ScenarioComparisonRow] {
        PlanningScenarioKind.allCases.map { kind in
            var assumptions = PlanningScenarioKind.assumptionSet(for: kind)
            if customAssumptions.scenarioKind == kind {
                assumptions = customAssumptions
                assumptions.scenarioKind = kind
            }
            let result = project(configuration: configuration, assumptions: assumptions, lifeEvents: lifeEvents)
            return ScenarioComparisonRow(
                scenario: kind,
                futureGoalValue: result.futureValue,
                retirementMonthlyExpense: result.retirement.map {
                    $0.estimatedMonthlyLifestyleAtRetirement + $0.estimatedMonthlyHealthcareAtRetirement
                },
                requiredCorpus: result.requiredCorpus,
                requiredStartingSIP: result.requiredStartingSIP,
                projectedCorpus: result.projectedCorpusFromPlan,
                fundingGap: result.fundingGap
            )
        }
    }

    static func lifeEventLoads(
        profile: AstraUserProfile?,
        journey: FinancialPlanningJourney,
        today: Date = Date()
    ) -> [LifeEventLoad] {
        let impacts = FinancialPlanningEngine.eventImpacts(profile: profile, journey: journey, today: today)
        return impacts.compactMap { impact in
            guard let date = impact.date, let futureCost = impact.futureCost else { return nil }
            let years = max(0, Calendar.current.dateComponents([.year], from: today, to: date).year ?? 0)
            let monthly: Double
            if impact.frequency == .recurring {
                monthly = futureCost
            } else {
                monthly = futureCost / 12.0
            }
            return LifeEventLoad(yearOffset: years, monthlyCost: monthly)
        }
    }

    static func otherGoalMonthlyAllocations(
        journey: FinancialPlanningJourney,
        excludingGoalName: String,
        availableCapacity: Double,
        mode: String
    ) -> Double {
        let others = journey.goalDrafts.filter { $0.name.caseInsensitiveCompare(excludingGoalName) != .orderedSame }
        guard !others.isEmpty else { return 0 }
        let optimization = MultiGoalOptimizer.optimize(
            goals: others,
            availableMonthlyCapacity: availableCapacity,
            mode: mode
        )
        return optimization.allocations.reduce(0) { $0 + $1.allocatedMonthlyCapacity }
    }

    // MARK: - Private

    private static func inflationRate(for type: FinancialGoalType, resolved: ResolvedPlanningAssumptions) -> Double {
        switch type {
        case .education: return resolved.educationInflationRate
        case .home: return resolved.housingInflationRate
        case .travel: return resolved.travelInflationRate
        case .healthcare: return resolved.healthcareInflationRate
        case .retirement: return resolved.expenseGrowthRate
        default: return resolved.inflationRate
        }
    }

    private static func feasibility(
        requiredSIP: Double,
        surplus: Double,
        selectedStepUp: Double,
        incomeGrowth: Double
    ) -> PlanFeasibilityResult {
        let recommendedStepUp = min(0.15, max(0, incomeGrowth + 0.02))
        var suggestions: [String] = []
        let status: PlanFeasibility
        if surplus <= 0 && requiredSIP > 0 {
            status = .notCurrentlyFeasible
            suggestions = [
                "Increase savings by reducing non-essential spending",
                "Extend the goal timeline",
                "Reduce the target lifestyle",
                "Allocate existing assets to this goal"
            ]
        } else if requiredSIP <= surplus * 0.70 {
            status = .healthy
        } else if requiredSIP <= surplus {
            status = .manageable
        } else if requiredSIP <= surplus * 1.20 {
            status = .aggressive
            suggestions = [
                "Increase the annual SIP step-up if income growth supports it",
                "Extend the goal timeline",
                "Prioritize this goal and pause lower-priority goals"
            ]
        } else {
            status = .notCurrentlyFeasible
            suggestions = [
                "Increase the annual investment step-up",
                "Extend the goal timeline",
                "Reduce the target lifestyle",
                "Adjust retirement age",
                "Allocate existing assets",
                "Prioritize this goal over others"
            ]
        }

        var notes: [String] = [
            "Based on your expected income growth, a \(Int((recommendedStepUp * 100).rounded()))% annual SIP increase may be sustainable.",
            "Income growth and SIP step-up are separate. The contribution you choose is not forced to match salary growth."
        ]
        if selectedStepUp > incomeGrowth + 0.03 {
            notes.append("Your selected SIP increase is higher than expected income growth. Confirm this remains affordable.")
        }

        return PlanFeasibilityResult(
            status: status,
            requiredStartingSIP: requiredSIP,
            availableMonthlySurplus: surplus,
            recommendedSIPStepUp: recommendedStepUp,
            selectedSIPStepUp: selectedStepUp,
            adjustmentSuggestions: suggestions,
            notes: notes
        )
    }

    private static func yearlyProjection(
        configuration: FinancialGoalConfiguration,
        resolved: ResolvedPlanningAssumptions,
        years: Int,
        requiredCorpus: Double,
        plannedSIP: Double,
        stepUp: Double,
        existing: Double,
        lifestyleToday: Double,
        healthcareToday: Double,
        eventCostByOffset: [Int: Double]
    ) -> [CashflowProjectionYear] {
        let currentAge = configuration.currentAge ?? 0
        let retireAge = configuration.retirementAge ?? configuration.goalAge
        var corpus = existing
        var sip = plannedSIP
        var rows: [CashflowProjectionYear] = []
        rows.reserveCapacity(years + 1)

        for offset in 0...years {
            let income = (configuration.currentMonthlyIncome ?? 0) * pow(1 + resolved.incomeGrowthRate, Double(offset))
            let lifestyle = lifestyleToday * pow(1 + resolved.expenseGrowthRate, Double(offset))
            let healthcare = healthcareToday * pow(1 + resolved.healthcareInflationRate, Double(offset))
            let expenses = lifestyle + healthcare
            let eventCost = eventCostByOffset[offset] ?? 0
            let otherGoals = configuration.otherGoalMonthlyAllocations ?? 0
            let surplus = income - expenses - otherGoals - eventCost
            let age = currentAge + offset
            let isRetire = retireAge.map { age >= $0 } ?? (offset == years)
            let progress = requiredCorpus > 0 ? min(1, corpus / requiredCorpus) : 0

            rows.append(
                CashflowProjectionYear(
                    age: age,
                    yearOffset: offset,
                    monthlyIncome: income,
                    monthlyExpenses: expenses,
                    monthlyHealthcare: healthcare,
                    monthlySurplus: surplus,
                    monthlyContribution: offset == years ? 0 : sip,
                    lifeEventCostMonthly: eventCost,
                    otherGoalAllocation: otherGoals,
                    investmentCorpus: corpus,
                    goalProgress: progress,
                    isRetirementYear: isRetire && configuration.goalType == .retirement
                )
            )

            if offset < years {
                corpus = FinancialCalculationEngine.futureValue(
                    monthlySIP: sip,
                    annualRate: resolved.investmentReturnRate,
                    months: 12,
                    initialLumpSum: corpus
                )
                sip *= (1 + stepUp)
            }
        }
        return rows
    }

    private static func buildExplanations(
        configuration: FinancialGoalConfiguration,
        resolved: ResolvedPlanningAssumptions,
        years: Int,
        presentValue: Double,
        requiredCorpus: Double,
        existing: Double,
        futureValueExisting: Double,
        requiredSIP: Double,
        stepUp: Double,
        retirement: RetirementProjectionResult?
    ) -> [FinancialNumberExplanation] {
        var items: [FinancialNumberExplanation] = []

        if let retirement {
            items.append(
                FinancialNumberExplanation(
                    id: "lifestyle",
                    title: "Estimated retirement lifestyle",
                    resultValue: retirement.estimatedMonthlyLifestyleAtRetirement,
                    resultLabel: "Estimated monthly lifestyle at retirement",
                    steps: [
                        ExplanationStep(id: "today", label: "Today’s lifestyle (excluding separate healthcare)", value: retirement.monthlyLifestyleToday.toCurrency()),
                        ExplanationStep(id: "infl", label: "Expense growth assumption", value: percent(resolved.expenseGrowthRate)),
                        ExplanationStep(id: "years", label: "Years to retirement", value: "\(years)"),
                        ExplanationStep(id: "result", label: "Estimated monthly lifestyle", value: retirement.estimatedMonthlyLifestyleAtRetirement.toCurrency())
                    ],
                    footnote: "Illustrative projection using planning assumptions, not a guaranteed future cost."
                )
            )
            items.append(
                FinancialNumberExplanation(
                    id: "corpus",
                    title: "Estimated retirement corpus",
                    resultValue: requiredCorpus,
                    resultLabel: "Estimated corpus required at retirement",
                    steps: [
                        ExplanationStep(id: "age", label: "Retirement age", value: "\(retirement.retirementAge)"),
                        ExplanationStep(id: "life", label: "Life expectancy", value: "\(retirement.lifeExpectancy)"),
                        ExplanationStep(id: "exp", label: "Retirement-year monthly lifestyle", value: retirement.estimatedMonthlyLifestyleAtRetirement.toCurrency()),
                        ExplanationStep(id: "hc", label: "Retirement-year monthly healthcare", value: retirement.estimatedMonthlyHealthcareAtRetirement.toCurrency()),
                        ExplanationStep(id: "ret", label: "Post-retirement return assumption", value: percent(resolved.postRetirementReturnRate)),
                        ExplanationStep(id: "sim", label: "Method", value: retirement.usedYearByYearSimulation ? "Year-by-year drawdown simulation" : "Withdrawal-rate estimate")
                    ],
                    footnote: "This is the estimated amount needed at retirement so withdrawals can last to the assumed life expectancy."
                )
            )
        } else {
            items.append(
                FinancialNumberExplanation(
                    id: "futureValue",
                    title: "Estimated future cost",
                    resultValue: requiredCorpus,
                    resultLabel: "Inflation-adjusted future value",
                    steps: [
                        ExplanationStep(id: "pv", label: "Today’s estimated cost", value: presentValue.toCurrency()),
                        ExplanationStep(id: "infl", label: "Inflation assumption", value: percent(resolved.inflationRate)),
                        ExplanationStep(id: "years", label: "Years to goal", value: "\(years)"),
                        ExplanationStep(id: "fv", label: "Estimated future value", value: requiredCorpus.toCurrency())
                    ],
                    footnote: "Future value = today’s cost × (1 + inflation)^years. This is a planning estimate."
                )
            )
        }

        items.append(
            FinancialNumberExplanation(
                id: "existing",
                title: "Existing investments at the goal date",
                resultValue: futureValueExisting,
                resultLabel: "Projected value of what you already have",
                steps: [
                    ExplanationStep(id: "now", label: "Current savings and investments", value: existing.toCurrency()),
                    ExplanationStep(id: "ret", label: "Investment return assumption", value: percent(resolved.investmentReturnRate)),
                    ExplanationStep(id: "years", label: "Investment horizon", value: "\(years) years"),
                    ExplanationStep(id: "fv", label: "Estimated future value", value: futureValueExisting.toCurrency())
                ],
                footnote: "Existing money is grown at the assumed return. It is not subtracted from the future target as cash today."
            )
        )

        items.append(
            FinancialNumberExplanation(
                id: "sip",
                title: "Required starting contribution",
                resultValue: requiredSIP,
                resultLabel: "Estimated starting monthly SIP",
                steps: [
                    ExplanationStep(id: "target", label: "Goal target at the deadline", value: requiredCorpus.toCurrency()),
                    ExplanationStep(id: "exist", label: "Current investments", value: existing.toCurrency()),
                    ExplanationStep(id: "ret", label: "Expected investment return", value: percent(resolved.investmentReturnRate)),
                    ExplanationStep(id: "horizon", label: "Horizon", value: "\(years) years"),
                    ExplanationStep(id: "step", label: "Annual SIP increase", value: percent(stepUp)),
                    ExplanationStep(id: "sip", label: "Estimated starting SIP", value: requiredSIP.toCurrency())
                ],
                footnote: "This is the estimated amount to start investing today. It is not a guaranteed path to the target."
            )
        )

        _ = configuration
        return items
    }

    private static func percent(_ rate: Double) -> String {
        String(format: "%.1f%%", rate * 100)
    }
}
