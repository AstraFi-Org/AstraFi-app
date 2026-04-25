import SwiftUI

struct OtherQuestionnaire: View {
    @Binding var input: InvestmentPlanInputModel
    let stepId: String
    
    var body: some View {
        switch stepId {
        case "other_details":
            VStack(spacing: 20) {
                AssessmentField(
                    icon: "pencil",
                    label: "What is your goal?",
                    placeholder: "Describe your goal",
                    text: Binding(
                        get: { input.wealthIntent ?? "" },
                        set: { input.wealthIntent = $0 }
                    ),
                    keyboard: .default
                )
                PlanDivider()
                Toggle(isOn: Binding(
                    get: { input.isFlexibleTimeline ?? true },
                    set: { input.isFlexibleTimeline = $0 }
                )) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Flexible timeline?").font(.subheadline).fontWeight(.medium)
                        Text("Allows us to optimise SIP amount for you")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
            }

        default:
            EmptyView()
        }
    }
}

#Preview {
    ZStack {
        AppTheme.appBackground(for: .light).ignoresSafeArea()
        ScrollView {
            OtherQuestionnaire(
                input: .constant(InvestmentPlanInputModel.sampleVehicle),
                stepId: "other_details"
            )
            .padding()
        }
    }
}
