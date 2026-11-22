import XCTest
@testable import AstraFiPrototype

@MainActor
final class UnifiedFinancialContextEngineTests: XCTestCase {
    func testFreshnessOnlyPromptsForStaleRelevantValues() {
        var profile = AppStateManager.withSampleData().currentProfile!
        let oldDate = Calendar.current.date(byAdding: .day, value: -200, to: Date())!
        profile.financialDataFreshness = [
            FinancialDataFreshnessRecord(domain: .expenses, source: .assessment,
                lastUpdatedAt: oldDate, lastVerifiedAt: oldDate, confidence: 0.8),
            FinancialDataFreshnessRecord(domain: .income, source: .assessment,
                lastUpdatedAt: Date(), lastVerifiedAt: Date(), confidence: 0.9)
        ]

        let prompts = UnifiedFinancialContextEngine.reverificationPrompts(
            profile: profile, purpose: .fixedIncomeMaturity
        )

        XCTAssertEqual(prompts.map(\.domain), [.expenses])
        XCTAssertTrue(prompts[0].currentValueDescription.contains("/month"))
    }

    func testLegacyProfileWithoutFreshnessMetadataIsNotInterrupted() {
        var profile = AppStateManager.withSampleData().currentProfile!
        profile.financialDataFreshness = nil

        let prompts = UnifiedFinancialContextEngine.reverificationPrompts(
            profile: profile, purpose: .generalPlanning
        )

        XCTAssertTrue(prompts.isEmpty)
    }

    func testJourneyEventsReuseStoredGoalsAndLoanCompletionProjection() {
        let profile = AppStateManager.withSampleData().currentProfile!
        let events = UnifiedFinancialContextEngine.journeyEvents(
            profile: profile, journey: profile.planningJourney
        )

        XCTAssertTrue(events.contains { $0.sourceDomain == .goals })
        XCTAssertEqual(events.filter { $0.sourceDomain == .liabilities }.count, profile.loans.count)
    }

    func testContextDoesNotCreateDuplicateFinancialValues() {
        let profile = AppStateManager.withSampleData().currentProfile!
        let context = UnifiedFinancialContextEngine.build(profile: profile)
        let position = FinancialPlanningEngine.currentPosition(profile: profile)

        XCTAssertEqual(context.position, position)
        XCTAssertEqual(context.totalInvestmentValue,
                       profile.investments.reduce(0) { $0 + max(0, $1.currentValue.safeFinite) }, accuracy: 0.01)
    }

    func testSavedContributionBranchDoesNotMutateOriginalJourneyAndKeepsSnapshot() {
        let profile = AppStateManager.withSampleData().currentProfile!
        let journey = profile.planningJourney!
        let baselineWhatIf = journey.monthlyInvestmentWhatIf
        let year = Calendar.current.component(.year, from: Date()) + 5
        let baselineContribution = FinancialPlanningEngine.currentPosition(profile: profile).monthlyInvestmentContribution!

        let branch = UnifiedFinancialContextEngine.makeContributionBranch(
            profile: profile, journey: journey, monthlyContribution: baselineContribution + 10_000,
            throughYear: year
        )

        XCTAssertNotNil(branch)
        XCTAssertEqual(journey.monthlyInvestmentWhatIf, baselineWhatIf)
        XCTAssertEqual(branch?.scenarioMonthlyContribution, baselineContribution + 10_000)
        XCTAssertEqual(branch?.assumptions, journey.assumptions)
        XCTAssertEqual(branch?.startingInvestmentsAtSave, FinancialPlanningEngine.currentPosition(profile: profile).investments)
        XCTAssertEqual(branch?.goalsAtSave.count, profile.goals.count)
    }
}
