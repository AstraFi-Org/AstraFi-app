import Foundation
import Observation

@Observable
final class StockIntelligenceViewModel {
    var isLoading = false
    var companyIntelligence: CompanyIntelligence?
    var errorMessage: String?

    private let factsBuilder: StockFactsBuilder
    private let aiService: AIIntelligenceService
    private let cache: AIIntelligenceCache

    init(
        factsBuilder: StockFactsBuilder = StockFactsBuilder(),
        aiService: AIIntelligenceService = AIIntelligenceService(),
        cache: AIIntelligenceCache = .shared
    ) {
        self.factsBuilder = factsBuilder
        self.aiService = aiService
        self.cache = cache
    }

    func loadIntelligence(for asset: InvestmentSummaryAsset) async {
        guard asset.kind == .stock else { return }
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let facts = try await factsBuilder.buildFacts(for: asset)

            if let cached = await cache.cachedIntelligence(for: facts.symbol) {
                companyIntelligence = cached
                print("AI generation completed")
                print("CompanyIntelligence assigned:", companyIntelligence != nil)
                print("Section count:", cached.sectionCount)
                return
            }

            print("Calling AI generation")
            let intelligence = try await aiService.generateIntelligence(from: facts)
            print("AI generation completed")
            await cache.save(intelligence, for: facts.symbol)
            companyIntelligence = intelligence
            print("CompanyIntelligence assigned:", companyIntelligence != nil)
            print("Section count:", intelligence.sectionCount)
        } catch {
            print("AI generation failed:")
            print(error)
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

private extension CompanyIntelligence {
    var sectionCount: Int {
        [
            whyCanGrow,
            biggestRisk,
            eli20,
            revenueModel,
            analystBullishReason,
            whatCanGoWrong,
            addressableMarket,
            employees,
            competitors,
            growthOpportunities
        ]
        .filter { !$0.isEmpty }
        .count
    }
}
