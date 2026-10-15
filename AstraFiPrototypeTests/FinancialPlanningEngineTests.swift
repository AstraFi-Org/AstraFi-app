import XCTest
@testable import AstraFiPrototype

@MainActor
final class FinancialPlanningEngineTests: XCTestCase {
    func testFutureValueForPlanningInflationScenarios() {
        let expected: [(Double, Double)] = [(0.04, 7.90), (0.05, 11.03), (0.06, 15.37), (0.07, 21.35)]
        for (rate, expectedCrore) in expected {
            let value = FinancialCalculationEngine.inflationAdjustedCost(
                currentCost: 20_000_000,
                annualInflationRate: rate,
                years: 35
            ) / 10_000_000
            XCTAssertEqual(value, expectedCrore, accuracy: 0.02, "Unexpected future value at \(rate)")
        }
    }

    func testExistingInvestmentsGrowInsteadOfBeingSubtractedAtFaceValue() {
        let value = FinancialCalculationEngine.futureValueOfExistingInvestments(
            presentValue: 1_000_000,
            annualReturnRate: 0.10,
            years: 10
        )
        XCTAssertGreaterThan(value, 2_500_000)
        XCTAssertLessThan(value, 2_800_000)
    }

    func testFixedSIPProjectionAndRequiredSIPAreInverses() {
        let target = FinancialCalculationEngine.futureValue(monthlySIP: 10_000, annualRate: 0.10, months: 120)
        let required = FinancialCalculationEngine.requiredMonthlySIP(targetCorpus: target, annualReturnRate: 0.10, months: 120)
        XCTAssertEqual(required, 10_000, accuracy: 0.01)
    }

    func testStepUpSIPProjectionAndRequiredStartingSIPAreInverses() {
        let target = FinancialCalculationEngine.stepUpFutureValue(
            initialMonthlySIP: 10_000,
            annualStepUpRate: 0.10,
            annualReturnRate: 0.105,
            years: 25,
            initialLumpSum: 500_000
        )
        let required = FinancialCalculationEngine.requiredStartingMonthlySIP(
            targetCorpus: target,
            annualReturnRate: 0.105,
            years: 25,
            annualStepUpRate: 0.10,
            currentInvestments: 500_000
        )
        XCTAssertEqual(required, 10_000, accuracy: 0.01)
    }

    func testIncomeAndExpenseGrowthUseSeparateRates() {
        let income = FinancialCalculationEngine.grownAmount(presentValue: 80_000, annualRate: 0.08, years: 10)
        let expenses = FinancialCalculationEngine.grownAmount(presentValue: 50_000, annualRate: 0.06, years: 10)
        XCTAssertGreaterThan(income, expenses)
        XCTAssertEqual(income, 172_714.8, accuracy: 1)
        XCTAssertEqual(expenses, 89_542.4, accuracy: 1)
    }

    func testRetirementCorpusSurvivesTheSelectedLifeExpectancy() {
        let result = RetirementCalculationEngine.requiredStartingCorpus(
            retirementAge: 60,
            lifeExpectancy: 85,
            firstYearAnnualLifestyleExpense: 1_200_000,
            firstYearAnnualHealthcareExpense: 120_000,
            postRetirementReturn: 0.06,
            retirementInflation: 0.05,
            healthcareInflation: 0.08,
            otherAnnualRetirementIncome: 0,
            withdrawalRate: 0.04
        )
        XCTAssertTrue(result.usedSimulation)
        XCTAssertEqual(result.drawdown.count, 25)
        XCTAssertGreaterThanOrEqual(result.drawdown.last?.endingCorpus ?? -1, 0)
    }

    func testRetirementDepletionIsDetected() {
        let result = RetirementCalculationEngine.simulateDrawdown(
            startingCorpus: 100_000,
            retirementAge: 60,
            lifeExpectancy: 85,
            firstYearAnnualLifestyleExpense: 500_000,
            firstYearAnnualHealthcareExpense: 0,
            postRetirementReturn: 0.03,
            retirementInflation: 0.05,
            healthcareInflation: 0.08,
            otherAnnualRetirementIncome: 0
        )
        XCTAssertTrue(result.depleted)
    }

    func testScenarioDefaultsUseFivePercentBaseInflationAndSevenPercentStress() {
        XCTAssertEqual(PlanningScenarioKind.assumptionSet(for: .base).inflationRate, 0.05)
        XCTAssertEqual(PlanningScenarioKind.assumptionSet(for: .stress).inflationRate, 0.07)
    }

    func testScenarioComparisonReturnsAllFourIllustrations() {
        let config = FinancialGoalConfiguration(
            goalType: .retirement,
            goalName: "Retirement",
            currentAge: 30,
            yearsToGoal: 30,
            currentMonthlyIncome: 100_000,
            currentMonthlyExpenses: 60_000,
            retirementLifestyleExpensesToday: 60_000,
            retirementAge: 60,
            lifeExpectancy: 85
        )
        let rows = GoalProjectionEngine.compareScenarios(
            configuration: config,
            customAssumptions: PlanningScenarioKind.assumptionSet(for: .base)
        )
        XCTAssertEqual(rows.count, 4)
        XCTAssertEqual(Set(rows.map { $0.scenario }), Set(PlanningScenarioKind.allCases))
        XCTAssertTrue(rows.allSatisfy { $0.requiredCorpus > 0 && $0.requiredStartingSIP >= 0 })
    }

    func testFeasibilityUsesMonthlySurplusAndReportsAdjustmentForUnaffordablePlan() {
        let config = FinancialGoalConfiguration(
            goalType: .retirement,
            goalName: "Retirement",
            currentAge: 30,
            yearsToGoal: 30,
            currentMonthlyIncome: 50_000,
            currentMonthlyExpenses: 45_000,
            retirementLifestyleExpensesToday: 45_000,
            retirementAge: 60,
            lifeExpectancy: 85
        )
        let result = GoalProjectionEngine.project(configuration: config, assumptions: PlanningScenarioKind.assumptionSet(for: .base))
        XCTAssertEqual(result.feasibility.availableMonthlySurplus, 5_000, accuracy: 0.01)
        XCTAssertFalse(result.feasibility.adjustmentSuggestions.isEmpty)
    }

    func testOtherGoalsCanConsumeAllocatedMonthlyCapacity() {
        let date = Calendar.current.date(byAdding: .year, value: 8, to: Date())
        let journey = FinancialPlanningJourney(goalDrafts: [
            FinancialPlanningGoalDraft(name: "Education", category: "Education", targetDate: date, targetAmount: 5_000_000, priority: 1),
            FinancialPlanningGoalDraft(name: "Home", category: "Home", targetDate: date, targetAmount: 10_000_000, priority: 2)
        ])
        let allocation = GoalProjectionEngine.otherGoalMonthlyAllocations(
            journey: journey,
            excludingGoalName: "Retirement",
            availableCapacity: 40_000,
            mode: "Sequential"
        )
        XCTAssertGreaterThan(allocation, 0)
        XCTAssertLessThanOrEqual(allocation, 40_000)
    }

    func testRetirementValidationRequiresARealLifestyleCostAndValidTimeline() {
        let config = FinancialGoalConfiguration(goalType: .retirement, goalName: "Retirement", currentAge: 60, retirementAge: 60, lifeExpectancy: 60)
        let issues = FinancialPlanningValidation.validate(
            configuration: config,
            assumptions: PlanningScenarioKind.assumptionSet(for: .base)
        )
        XCTAssertTrue(issues.contains { $0.id == "retireAge" })
        XCTAssertTrue(issues.contains { $0.id == "lifestyle" })
    }
}
