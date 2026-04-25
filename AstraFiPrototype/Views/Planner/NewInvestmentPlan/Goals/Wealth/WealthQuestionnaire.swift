import SwiftUI

struct WealthQuestionnaire: View {
    @Binding var input: InvestmentPlanInputModel
    let stepId: String
    let profileSavings: Double
    
    var body: some View {
        switch stepId {
        case "wealth_details":
            VStack(spacing: 20) {
                LabeledField(label: "Primary Wealth Intent", icon: "sparkles",
                             note: "Shapes portfolio allocation & corpus target") {
                    PlanMenuPicker(
                        selection: Binding(
                            get: { input.wealthIntent ?? "Financial Freedom" },
                            set: { input.wealthIntent = $0 }
                        ),
                        options: ["General Wealth Building",
                                  "Early Retirement (FIRE)",
                                  "Financial Freedom",
                                  "Passive Income Creation",
                                  "Legacy / Generational Wealth"])
                }
                .cardStyle()

                if input.wealthIntent == "Passive Income Creation" {
                    AssessmentField(
                        icon: "arrow.down.circle.fill",
                        label: "Target Monthly Passive Income (₹)",
                        placeholder: "e.g. 50,000",
                        text: Binding(
                            get: { input.savedAmount }, // Reusing savedAmount for target income in this draft
                            set: { input.savedAmount = $0 }
                        ),
                        keyboard: .numberPad
                    )
                }
            }
            if profileSavings > 0 {
                ProfileBanner(icon: "banknote.fill",
                              text: "Existing investments: ₹\(fmtL(profileSavings))",
                              note: "Counted as your starting corpus")
            }
        default:
            EmptyView()
        }
    }
}
//
//#Preview {
//    ZStack {
//        AppTheme.appBackground(for: .light).ignoresSafeArea()
//        ScrollView {
//            WealthQuestionnaire(
//                input: .constant(InvestmentPlanInputModel.sampleVehicle),
//                stepId: "wealth_details",
//                profileSavings: 500000
//            )
//            .padding()
//        }
//    }
//}
