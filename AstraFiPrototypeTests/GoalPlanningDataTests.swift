import XCTest
@testable import AstraFiPrototype

final class GoalPlanningDataTests: XCTestCase {
    func testEverySupportedCategoryHasExplicitZeroDataBackedDefaults() {
        XCTAssertEqual(GoalPlanningCategory.allCases.count, 10)
        for category in GoalPlanningCategory.allCases {
            let defaults = GoalCostAssumptions.defaults(for: category)
            XCTAssertEqual(defaults.conservativeRate, 0)
            XCTAssertEqual(defaults.moderateRate, 0)
            XCTAssertEqual(defaults.highRate, 0)
            XCTAssertFalse(defaults.rationale.isEmpty)
        }
    }

    func testFutureCostUsesCompoundAnnualGrowth() {
        XCTAssertEqual(GoalPlanningCalculator.futureCost(current: 1_000, annualGrowth: 0.10, years: 2), 1_210, accuracy: 0.001)
    }

    func testFundingPlanIncludesExistingSavingsWithoutDoubleCounting() {
        let plan = GoalPlanningCalculator.investmentScenarios(target: 10_000, months: 12, existingSavings: 4_000)[0]
        XCTAssertGreaterThan(plan.monthlyContribution, 0)
        XCTAssertEqual(plan.projectedValue, 10_000, accuracy: 0.01)
        XCTAssertEqual(plan.totalContribution, plan.monthlyContribution * 12 + 4_000, accuracy: 0.01)
    }

    func testNearTermPlansUseLowerReturnAssumptions() {
        let plans = GoalPlanningCalculator.investmentScenarios(target: 100_000, months: 6, existingSavings: 0)
        XCTAssertEqual(plans.map(\.annualReturn), [0.03, 0.04, 0.05])
        XCTAssertTrue(plans[2].risk.contains("short horizon"))
    }

    func testSourceLinkRequiresHTTPURLWithHost() {
        let valid = GoalDataSource(name: "Example", url: "https://example.org/prices", sourceType: "Provider", retrievedValue: 1,
                                   unit: "INR", retrievedAt: Date(), verification: .unavailable, confidence: "Low", calculationMethod: "Manual")
        XCTAssertEqual(valid.validURL?.host, "example.org")
        var invalid = valid
        invalid.url = "javascript:alert(1)"
        XCTAssertNil(invalid.validURL)
    }
}
