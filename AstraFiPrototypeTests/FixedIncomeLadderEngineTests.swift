import XCTest
@testable import AstraFiPrototype

@MainActor
final class FixedIncomeLadderEngineTests: XCTestCase {

    func testEmptyLadderReturnsEmptyResult() {
        let input = FixedIncomeLadderInput(totalCapitalAvailable: 500_000, ladderEntries: [])
        let res = FixedIncomeLadderEngine.simulate(input: input)
        XCTAssertEqual(res.totalCapitalAllocated, 0)
        XCTAssertEqual(res.timelineEvents.count, 0)
    }

    func testSingleCumulativeFDCompoundsQuarterly() {
        // ₹100,000 for 1 year at 8% quarterly compounding
        // A = 100,000 * (1 + 0.08/4)^4 = 100,000 * (1.02)^4 = 108,243.216
        // Interest = 8,243.22
        let entry = FixedIncomeEntry(
            instrumentName: "1-Yr FD",
            instrumentType: .bankFD,
            allocatedAmount: 100_000,
            startYearOffset: 0,
            tenureYears: 1,
            annualInterestRatePct: 8.0,
            payoutFrequency: .quarterlyCompounding,
            compounding: .quarterly,
            taxRatePct: 0.0,
            feePct: 0.0,
            reinvestmentAction: .cashBalance
        )
        let input = FixedIncomeLadderInput(totalCapitalAvailable: 200_000, ladderEntries: [entry])
        let res = FixedIncomeLadderEngine.simulate(input: input)

        XCTAssertEqual(res.totalCapitalAllocated, 100_000)
        XCTAssertEqual(res.totalCumulativeInterestGross, 8_243.22, accuracy: 1.0)
        XCTAssertEqual(res.totalMaturityProceedsGross, 100_000)
        // Ending cash: 100,000 unallocated + 100,000 principal + 8,243.22 interest = 208,243.22
        XCTAssertEqual(res.endingAvailableCash, 208_243.22, accuracy: 1.0)
    }

    func testPeriodicFDDoesNotCompoundPaidInterest() {
        // ₹100,000 for 2 years at 8% periodic payout
        // Gross annual interest = 8,000 per year = 16,000 total (simple, not compounded)
        let entry = FixedIncomeEntry(
            instrumentName: "2-Yr Periodic FD",
            instrumentType: .bankFD,
            allocatedAmount: 100_000,
            startYearOffset: 0,
            tenureYears: 2,
            annualInterestRatePct: 8.0,
            payoutFrequency: .quarterly,
            compounding: .noneSimple,
            taxRatePct: 0.0,
            feePct: 0.0,
            reinvestmentAction: .cashBalance
        )
        let input = FixedIncomeLadderInput(totalCapitalAvailable: 100_000, ladderEntries: [entry])
        let res = FixedIncomeLadderEngine.simulate(input: input)

        XCTAssertEqual(res.totalCumulativeInterestGross, 16_000, accuracy: 1.0)
        XCTAssertEqual(res.totalMaturityProceedsGross, 100_000)
    }

    func testTBillDiscountInstrument() {
        let entry = FixedIncomeEntry(
            instrumentName: "1-Yr T-Bill",
            instrumentType: .treasuryBill,
            allocatedAmount: 100_000,
            startYearOffset: 0,
            tenureYears: 1,
            annualInterestRatePct: 7.0,
            payoutFrequency: .atMaturityDiscount,
            compounding: .noneSimple,
            taxRatePct: 0.0,
            feePct: 0.0,
            reinvestmentAction: .cashBalance
        )
        let input = FixedIncomeLadderInput(totalCapitalAvailable: 100_000, ladderEntries: [entry])
        let res = FixedIncomeLadderEngine.simulate(input: input)

        XCTAssertEqual(res.totalCumulativeInterestGross, 7_000, accuracy: 1.0)
        XCTAssertEqual(res.totalMaturityProceedsGross, 100_000)
    }

    func testLadderReinvestmentKeepsCapitalInvested() {
        let entry = FixedIncomeEntry(
            instrumentName: "1-Yr FD",
            instrumentType: .bankFD,
            allocatedAmount: 200_000,
            startYearOffset: 0,
            tenureYears: 1,
            annualInterestRatePct: 7.0,
            reinvestmentAction: .reinvestLadder
        )
        let input = FixedIncomeLadderInput(totalCapitalAvailable: 200_000, ladderEntries: [entry])
        let res = FixedIncomeLadderEngine.simulate(input: input)

        XCTAssertEqual(res.totalReinvestedAmount, 200_000)
        XCTAssertGreaterThan(res.endingPortfolioValue, 0)
    }

    func testStressScenarioReducesProceeds() {
        let entry = FixedIncomeEntry(
            instrumentName: "Corp Bond",
            instrumentType: .corporateBond,
            allocatedAmount: 200_000,
            startYearOffset: 0,
            tenureYears: 2,
            annualInterestRatePct: 9.0,
            reinvestmentAction: .cashBalance
        )
        let input = FixedIncomeLadderInput(totalCapitalAvailable: 200_000, ladderEntries: [entry])

        let baseRes = FixedIncomeLadderEngine.simulate(input: input, appliedStress: nil)

        // Stressed with 60% corporate recovery
        let stress = LadderStressScenario(
            id: "test_default",
            title: "Default",
            description: "Default stress",
            corporateDefaultRecoveryPct: 60.0
        )
        let stressRes = FixedIncomeLadderEngine.simulate(input: input, appliedStress: stress)

        XCTAssertLessThan(stressRes.endingAvailableCash, baseRes.endingAvailableCash)
        XCTAssertEqual(stressRes.endingAvailableCash + 80_000, baseRes.endingAvailableCash, accuracy: 2.0)
    }

    func testConcentrationWarningWhenAllocationExceedsThreshold() {
        let entry = FixedIncomeEntry(
            instrumentName: "Risky Corp Bond",
            instrumentType: .corporateBond,
            allocatedAmount: 400_000, // 80% of 500,000 allocated
            startYearOffset: 0,
            tenureYears: 1
        )
        let entry2 = FixedIncomeEntry(
            instrumentName: "FD",
            instrumentType: .bankFD,
            allocatedAmount: 100_000,
            startYearOffset: 0,
            tenureYears: 1
        )
        let input = FixedIncomeLadderInput(totalCapitalAvailable: 500_000, ladderEntries: [entry, entry2])
        let res = FixedIncomeLadderEngine.simulate(input: input)

        XCTAssertTrue(res.concentrationWarnings.contains(where: { $0.contains("Concentration Risk") }))
    }

    func testOverallocationTriggersInfeasibleStatus() {
        let entry = FixedIncomeEntry(
            instrumentName: "FD",
            instrumentType: .bankFD,
            allocatedAmount: 600_000,
            startYearOffset: 0,
            tenureYears: 1
        )
        let input = FixedIncomeLadderInput(totalCapitalAvailable: 500_000, ladderEntries: [entry])
        let res = FixedIncomeLadderEngine.simulate(input: input)

        XCTAssertEqual(res.feasibility, .notCurrentlyFeasible)
    }
}
