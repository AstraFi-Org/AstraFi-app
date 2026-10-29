import SwiftUI

struct EducationResultView: View {
    var input: InvestmentPlanInputModel
    var isFromFinancialJourney: Bool = false
    
    var body: some View {
        InvestmentPlanResultView(input: input, isFromFinancialJourney: isFromFinancialJourney)
    }
}

#Preview {
    NavigationStack {
        EducationResultView(input: InvestmentPlanInputModel.sampleEducation)
            .environment(AppStateManager.withSampleData())
    }
}
