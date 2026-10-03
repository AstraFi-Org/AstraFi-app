import SwiftUI

struct RetirementResultView: View {
    var input: InvestmentPlanInputModel
    
    var body: some View {
        InvestmentPlanResultView(input: input)
            .navigationTitle("Retirement Plan")
    }
}

#Preview {
    NavigationStack {
        RetirementResultView(input: InvestmentPlanInputModel.sampleRetirement)
            .environment(AppStateManager.withSampleData())
    }
}
