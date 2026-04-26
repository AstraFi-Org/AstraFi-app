import SwiftUI

struct EducationResultView: View {
    var input: InvestmentPlanInputModel
    
    var body: some View {
        InvestmentPlanResultView(input: input)
    }
}

#Preview {
    NavigationStack {
        EducationResultView(input: InvestmentPlanInputModel.sampleEducation)
            .environment(AppStateManager.withSampleData())
    }
}
