import SwiftUI

struct OtherResultView: View {
    var input: InvestmentPlanInputModel
    
    var body: some View {
        InvestmentPlanResultView(input: input)
            .navigationTitle("Other Plan")
    }
}

#Preview {
    NavigationStack {
        OtherResultView(input: InvestmentPlanInputModel.sampleVehicle)
            .environment(AppStateManager.withSampleData())
    }
}
