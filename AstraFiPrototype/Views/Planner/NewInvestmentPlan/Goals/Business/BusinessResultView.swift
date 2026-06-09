import SwiftUI

struct BusinessResultView: View {
    var input: InvestmentPlanInputModel
    
    var body: some View {
        InvestmentPlanResultView(input: input)
            .navigationTitle("Business Plan")
    }
}

#Preview {
    NavigationStack {
        BusinessResultView(input: InvestmentPlanInputModel.sampleVehicle)
            .environment(AppStateManager.withSampleData())
    }
}
