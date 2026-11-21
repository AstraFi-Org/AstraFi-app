import XCTest
@testable import AstraFiPrototype

@MainActor
final class RetirementSWPEngineTests: XCTestCase {

    func testAccumulationTimelineCompounding() {
        let input = RetirementSWPInput(
            currentAge: 30,
            retirementAge: 35,
            lifeExpectancyAge: 80,
            currentRetirementCorpus: 1_000_000,
            monthlySIPPreRetirement: 20_000,
            annualSIPStepUpRatePct: 0.0,
            preRetirementReturnPct: 10.0
        )
        let res = RetirementSWPEngine.simulate(input: input)

        XCTAssertEqual(res.accumulationTimeline.count, 5)
        XCTAssertGreaterThan(res.projectedCorpusAtRetirement, 2_500_000)
    }

    func testAdequateCorpusSurvivesRetirement() {
        // High corpus (₹10 Crores), moderate living expenses (₹50k/mo)
        let input = RetirementSWPInput(
            currentAge: 60,
            retirementAge: 60,
            lifeExpectancyAge: 85,
            currentRetirementCorpus: 100_000_000,
            monthlySIPPreRetirement: 0,
            postRetirementReturnPct: 8.0,
            monthlyLifestyleExpenseToday: 50_000,
            monthlyHealthcareExpenseToday: 10_000,
            lifestyleInflationPct: 5.0,
            healthcareInflationPct: 6.0
        )
        let res = RetirementSWPEngine.simulate(input: input)

        XCTAssertTrue(res.isAdequate)
        XCTAssertNil(res.depletionAge)
        XCTAssertEqual(res.yearsCorpusSustained, 25)
        XCTAssertEqual(res.feasibility, PlanFeasibility.healthy)
    }

    func testUnderfundedCorpusDetectsDepletionAge() {
        // Low corpus (₹10 Lakhs) for age 60 to 85 with ₹1 Lakh/month expenses
        let input = RetirementSWPInput(
            currentAge: 60,
            retirementAge: 60,
            lifeExpectancyAge: 85,
            currentRetirementCorpus: 1_000_000,
            monthlySIPPreRetirement: 0,
            postRetirementReturnPct: 6.0,
            monthlyLifestyleExpenseToday: 100_000,
            monthlyHealthcareExpenseToday: 20_000,
            lifestyleInflationPct: 6.0
        )
        let res = RetirementSWPEngine.simulate(input: input)

        XCTAssertFalse(res.isAdequate)
        XCTAssertNotNil(res.depletionAge)
        // At 1.2L/month, 10L is exhausted within ~1-2 years
        XCTAssertLessThanOrEqual(res.depletionAge ?? 100, 62)
        XCTAssertEqual(res.feasibility, PlanFeasibility.notCurrentlyFeasible)
        XCTAssertFalse(res.actionRecommendations.isEmpty)
    }

    func testSequenceOfReturnsCrashAcceleratesDepletion() {
        let input = RetirementSWPInput(
            currentAge: 60,
            retirementAge: 60,
            lifeExpectancyAge: 85,
            currentRetirementCorpus: 40_000_000,
            postRetirementReturnPct: 7.0,
            monthlyLifestyleExpenseToday: 80_000,
            monthlyHealthcareExpenseToday: 20_000,
            lifestyleInflationPct: 6.0
        )
        let baseRes = RetirementSWPEngine.simulate(input: input, appliedStress: nil)

        let stressCrash = RetirementStressScenario(
            id: "crash20",
            title: "Crash",
            description: "20% Year 1 crash",
            earlySequenceOfReturnsShockPct: 20.0
        )
        let crashRes = RetirementSWPEngine.simulate(input: input, appliedStress: stressCrash)

        XCTAssertLessThan(crashRes.terminalCorpusAtLifeExpectancy, baseRes.terminalCorpusAtLifeExpectancy)
    }

    func testPensionIncomeReducesDrawdownFromCorpus() {
        let withoutPensionInput = RetirementSWPInput(
            currentAge: 60,
            retirementAge: 60,
            lifeExpectancyAge: 80,
            currentRetirementCorpus: 20_000_000,
            monthlyLifestyleExpenseToday: 80_000,
            monthlyHealthcareExpenseToday: 0,
            monthlyPensionOrGuaranteedIncome: 0
        )
        let withPensionInput = RetirementSWPInput(
            currentAge: 60,
            retirementAge: 60,
            lifeExpectancyAge: 80,
            currentRetirementCorpus: 20_000_000,
            monthlyLifestyleExpenseToday: 80_000,
            monthlyHealthcareExpenseToday: 0,
            monthlyPensionOrGuaranteedIncome: 50_000
        )

        let resNoPension = RetirementSWPEngine.simulate(input: withoutPensionInput)
        let resWithPension = RetirementSWPEngine.simulate(input: withPensionInput)

        XCTAssertGreaterThan(resWithPension.terminalCorpusAtLifeExpectancy, resNoPension.terminalCorpusAtLifeExpectancy)
    }
}
