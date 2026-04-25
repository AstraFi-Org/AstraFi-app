import SwiftUI

struct TravelResultView: View {
    var input: InvestmentPlanInputModel
    
    var body: some View {
        InvestmentPlanResultView(input: input)
            .navigationTitle("Travel Plan")
    }
}

#Preview {
    NavigationStack {
        TravelResultView(input: InvestmentPlanInputModel.sampleVehicle)
            .environment(AppStateManager.withSampleData())
    }
}
