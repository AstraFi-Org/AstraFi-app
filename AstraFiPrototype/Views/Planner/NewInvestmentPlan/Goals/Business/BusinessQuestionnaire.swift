import SwiftUI

struct BusinessQuestionnaire: View {
    @Binding var input: InvestmentPlanInputModel
    let stepId: String
    
    var body: some View {
        switch stepId {
        case "business_details":
            VStack(spacing: 20) {
                LabeledField(label: "Business Type", icon: "building.2.fill") {
                    PlanMenuPicker(
                        selection: Binding(
                            get: { input.educationLocation ?? "Startup" },
                            set: { input.educationLocation = $0 }
                        ),
                        options: ["Startup", "Franchise", "Retail / Shop",
                                  "Manufacturing", "Online Business",
                                  "Professional Practice"])
                }
                .cardStyle()

                LabeledField(label: "Current Stage", icon: "chart.bar.fill",
                             note: "Determines how much capital you need upfront") {
                    PlanStackedChips(
                        selection: Binding(
                            get: { input.wealthIntent ?? "Idea stage" },
                            set: { input.wealthIntent = $0 }
                        ),
                        options: ["Idea stage", "MVP / Planning",
                                  "Revenue generating", "Scaling phase"])
                }
                .cardStyle()

                AssessmentField(
                    icon: "calendar.badge.clock",
                    label: "Monthly Operating Budget Needed (₹)",
                    placeholder: "e.g. 1,00,000",
                    text: Binding(
                        get: { input.savedAmount }, // Reusing savedAmount
                        set: { input.savedAmount = $0 }
                    ),
                    keyboard: .numberPad
                )
                
                VStack(alignment: .leading, spacing: 10) {
                    Toggle(isOn: Binding(
                        get: { input.isFlexibleTimeline ?? false },
                        set: { input.isFlexibleTimeline = $0 }
                    )) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Open to External Investors / Loans?")
                                .font(.subheadline).fontWeight(.medium)
                            Text("Affects Plan 2 & Plan 3 generation")
                                .font(.caption).foregroundColor(.secondary)
                        }
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
            BusinessQuestionnaire(
                input: .constant(InvestmentPlanInputModel.sampleVehicle),
                stepId: "business_details"
            )
            .padding()
        }
    }
}
