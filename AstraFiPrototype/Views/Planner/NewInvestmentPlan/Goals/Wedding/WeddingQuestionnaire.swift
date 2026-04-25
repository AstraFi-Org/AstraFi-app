import SwiftUI

struct WeddingQuestionnaire: View {
    @Binding var input: InvestmentPlanInputModel
    let stepId: String
    
    var body: some View {
        switch stepId {
        case "wedding_details":
            VStack(spacing: 20) {
                LabeledField(label: "Wedding Scale", icon: "person.3.fill",
                             note: "Helps estimate total event cost") {
                    PlanMenuPicker(
                        selection: Binding(
                            get: { input.wealthIntent ?? "Medium (100–300 guests)" },
                            set: { input.wealthIntent = $0 }
                        ),
                        options: ["Intimate (< 100 guests)",
                                  "Medium (100–300 guests)",
                                  "Grand (300–700 guests)",
                                  "Lavish (700+ guests)"])
                }
                .cardStyle()

                LabeledField(label: "Venue City Tier", icon: "building.2.fill") {
                    PlanSegmentChips(
                        selection: Binding(
                            get: { input.educationLocation ?? "Tier 1" },
                            set: { input.educationLocation = $0 }
                        ),
                        options: ["Tier 1", "Tier 2", "Destination", "Home"])
                }
                .cardStyle()

                LabeledField(label: "Who Funds the Wedding?", icon: "person.2.fill",
                             note: "Affects how much you personally need to save") {
                    PlanSegmentChips(
                        selection: Binding(
                            get: { input.contributionSplit ?? "Self-funded" },
                            set: { input.contributionSplit = $0 }
                        ),
                        options: ["Self-funded", "Family Support", "Mixed"])
                }
                .cardStyle()
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
            WeddingQuestionnaire(
                input: .constant(InvestmentPlanInputModel.sampleVehicle),
                stepId: "wedding_details"
            )
            .padding()
        }
    }
}
