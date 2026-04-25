import SwiftUI

struct HomeResultView: View {
    var input: InvestmentPlanInputModel
    
    var body: some View {
        InvestmentPlanResultView(input: input)
            .navigationTitle("Home Purchase Plan")
    }
}

#Preview {
    NavigationStack {
        HomeResultView(input: InvestmentPlanInputModel.sampleHome)
            .environment(AppStateManager.withSampleData())
    }
}
