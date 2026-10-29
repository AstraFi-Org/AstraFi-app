import SwiftUI

struct RetirementResultView: View {
    var input: InvestmentPlanInputModel
    var isFromFinancialJourney: Bool = false

    var body: some View {
        InvestmentPlanResultView(input: input, isFromFinancialJourney: isFromFinancialJourney)
            .navigationTitle("Retirement Plan")
    }
}

#Preview {
    NavigationStack {
        RetirementResultView(input: InvestmentPlanInputModel.sampleRetirement)
            .environment(AppStateManager.withSampleData())
    }
}
