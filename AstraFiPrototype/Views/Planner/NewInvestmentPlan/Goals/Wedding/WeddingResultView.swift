import SwiftUI

struct WeddingResultView: View {
    var input: InvestmentPlanInputModel
    var isFromFinancialJourney: Bool = false
    
    var body: some View {
        InvestmentPlanResultView(input: input, isFromFinancialJourney: isFromFinancialJourney)
            .navigationTitle("Wedding Plan")
    }
}

#Preview {
    NavigationStack {
        WeddingResultView(input: InvestmentPlanInputModel.sampleVehicle)
            .environment(AppStateManager.withSampleData())
    }
}
