import SwiftUI

struct VehicleResultView: View {
    var input: InvestmentPlanInputModel
    
    var body: some View {
        InvestmentPlanResultView(input: input)
            .navigationTitle("Vehicle Plan")
    }
}

#Preview {
    NavigationStack {
        VehicleResultView(input: InvestmentPlanInputModel.sampleVehicle)
            .environment(AppStateManager.withSampleData())
    }
}
