import SwiftUI

struct WeddingResultView: View {
    var input: InvestmentPlanInputModel
    
    var body: some View {
        InvestmentPlanResultView(input: input)
            .navigationTitle("Wedding Plan")
    }
}

#Preview {
    NavigationStack {
        WeddingResultView(input: InvestmentPlanInputModel.sampleVehicle)
            .environment(AppStateManager.withSampleData())
    }
}
