import XCTest
@testable import AstraFiPrototype

@MainActor
final class REITSimulatorEngineTests: XCTestCase {

    func testZeroHorizonReturnsEmptyResult() {
        let input = REITSimulatorInput(investmentHorizonYears: 0)
        let res = REITSimulatorEngine.simulate(input: input)
        XCTAssertEqual(res.totalUnitsAccumulated, 0)
        XCTAssertEqual(res.yearlySnapshots.count, 0)
    }

    func testCashDistributionModeKeepsUnitsConstant() {
        // ₹100,000 lump sum at ₹100/unit = 1,000 units (ignoring 0% cost for test)
        let input = REITSimulatorInput(
            initialLumpSumInvestment: 100_000,
            recurringMonthlyContribution: 0,
            investmentHorizonYears: 1,
            purchasePricePerUnit: 100.0,
            distributionYieldPct: 7.0,
            expectedAnnualDistributionGrowthPct: 0.0,
            expectedAnnualPriceAppreciationPct: 0.0,
            reinvestDistributions: false,
            transactionCostPct: 0.0,
            distributionTaxPct: 0.0
        )
        let res = REITSimulatorEngine.simulate(input: input)

        XCTAssertEqual(res.totalUnitsAccumulated, 1_000, accuracy: 0.01)
        XCTAssertEqual(res.finalPortfolioMarketValue, 100_000, accuracy: 1.0)
        XCTAssertEqual(res.cumulativeNetDistributions, 7_000, accuracy: 1.0)
        XCTAssertEqual(res.totalNetEconomicValue, 107_000, accuracy: 1.0)
        XCTAssertEqual(res.netAbsoluteReturnPct, 7.0, accuracy: 0.1)
    }

    func testReinvestmentDRIPIncreasesUnits() {
        let input = REITSimulatorInput(
            initialLumpSumInvestment: 100_000,
            recurringMonthlyContribution: 0,
            investmentHorizonYears: 2,
            purchasePricePerUnit: 100.0,
            distributionYieldPct: 10.0,
            expectedAnnualDistributionGrowthPct: 0.0,
            expectedAnnualPriceAppreciationPct: 0.0,
            reinvestDistributions: true,
            transactionCostPct: 0.0,
            distributionTaxPct: 0.0
        )
        let res = REITSimulatorEngine.simulate(input: input)

        // Starting units: 1,000
        // Year 1 dist: 1,000 * 10 = 10,000 -> bought 100 units at 100 = 1,100 units
        // Year 2 dist: 1,100 * 10 = 11,000 -> bought 110 units at 100 = 1,210 units
        XCTAssertEqual(res.totalUnitsAccumulated, 1_210, accuracy: 0.1)
        XCTAssertEqual(res.finalPortfolioMarketValue, 121_000, accuracy: 1.0)
        XCTAssertEqual(res.totalNetEconomicValue, 121_000, accuracy: 1.0)
    }

    func testPriceAppreciationExpandsEndingValue() {
        let input = REITSimulatorInput(
            initialLumpSumInvestment: 100_000,
            recurringMonthlyContribution: 0,
            investmentHorizonYears: 1,
            purchasePricePerUnit: 100.0,
            distributionYieldPct: 0.0,
            expectedAnnualPriceAppreciationPct: 10.0,
            reinvestDistributions: false,
            transactionCostPct: 0.0,
            distributionTaxPct: 0.0
        )
        let res = REITSimulatorEngine.simulate(input: input)

        XCTAssertEqual(res.finalUnitPrice, 110.0, accuracy: 0.1)
        XCTAssertEqual(res.finalPortfolioMarketValue, 110_000, accuracy: 1.0)
    }

    func testDistributionCutStressReducesReturns() {
        let input = REITSimulatorInput(
            initialLumpSumInvestment: 100_000,
            recurringMonthlyContribution: 0,
            investmentHorizonYears: 3,
            distributionYieldPct: 8.0,
            reinvestDistributions: false
        )
        let baseRes = REITSimulatorEngine.simulate(input: input, appliedStress: nil)

        let stress = REITStressScenario(
            id: "cut_test",
            title: "Cut",
            description: "Test cut",
            distributionCutPct: 3.0
        )
        let stressRes = REITSimulatorEngine.simulate(input: input, appliedStress: stress)

        XCTAssertLessThan(stressRes.cumulativeNetDistributions, baseRes.cumulativeNetDistributions)
        XCTAssertLessThan(stressRes.totalNetEconomicValue, baseRes.totalNetEconomicValue)
    }

    func testSevereDownturnScenarioTriggersAggressiveOrManageableFeasibility() {
        let input = REITSimulatorInput(
            initialLumpSumInvestment: 100_000,
            recurringMonthlyContribution: 0,
            investmentHorizonYears: 2,
            distributionYieldPct: 4.0,
            expectedAnnualPriceAppreciationPct: 0.0
        )
        let stress = REITStressScenario(
            id: "crash",
            title: "Crash",
            description: "Crash",
            distributionCutPct: 2.0,
            unitPriceDropPct: 30.0
        )
        let stressRes = REITSimulatorEngine.simulate(input: input, appliedStress: stress)

        XCTAssertEqual(stressRes.feasibility, .aggressive)
        XCTAssertLessThan(stressRes.totalNetEconomicValue, 100_000)
    }
}
