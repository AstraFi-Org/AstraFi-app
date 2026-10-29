import SwiftUI

struct WealthResultView: View {
    var input: InvestmentPlanInputModel
    var isFromFinancialJourney: Bool = false
    
    var body: some View {
        InvestmentPlanResultView(input: input, isFromFinancialJourney: isFromFinancialJourney)
            .navigationTitle("Wealth Plan")
    }
}

#Preview {
    NavigationStack {
        WealthResultView(input: InvestmentPlanInputModel.sampleVehicle)
            .environment(AppStateManager.withSampleData())
    }
}
