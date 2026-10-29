import SwiftUI

struct TravelResultView: View {
    var input: InvestmentPlanInputModel
    var isFromFinancialJourney: Bool = false
    
    var body: some View {
        InvestmentPlanResultView(input: input, isFromFinancialJourney: isFromFinancialJourney)
            .navigationTitle("Travel Plan")
    }
}

#Preview {
    NavigationStack {
        TravelResultView(input: InvestmentPlanInputModel.sampleVehicle)
            .environment(AppStateManager.withSampleData())
    }
}
