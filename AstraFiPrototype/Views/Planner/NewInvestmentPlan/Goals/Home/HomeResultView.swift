import SwiftUI

struct HomeResultView: View {
    var input: InvestmentPlanInputModel
    var isFromFinancialJourney: Bool = false
    
    var body: some View {
        InvestmentPlanResultView(input: input, isFromFinancialJourney: isFromFinancialJourney)
            .navigationTitle("Home Purchase Plan")
    }
}

#Preview {
    NavigationStack {
        HomeResultView(input: InvestmentPlanInputModel.sampleHome)
            .environment(AppStateManager.withSampleData())
    }
}
