import SwiftUI

struct TravelQuestionnaire: View {
    @Binding var input: InvestmentPlanInputModel
    let stepId: String
    
    var body: some View {
        switch stepId {
        case "travel_details":
            VStack(spacing: 20) {
                LabeledField(label: "Trip Type", icon: "globe") {
                    PlanSegmentChips(
                        selection: Binding(
                            get: { input.destinationType ?? "Domestic" },
                            set: { input.destinationType = $0 }
                        ),
                        options: ["Domestic", "International"])
                }
                .cardStyle()

                if input.destinationType == "International" {
                    LabeledField(label: "Destination Region", icon: "map.fill",
                                 note: "Helps estimate total trip cost") {
                        PlanMenuPicker(
                            selection: Binding(
                                get: { input.wealthIntent ?? "Europe / USA" }, // Reusing wealthIntent for destination
                                set: { input.wealthIntent = $0 }
                            ),
                            options: ["South-East Asia",
                                      "Europe / USA",
                                      "Middle East",
                                      "Japan / Korea",
                                      "Other"])
                    }
                    .cardStyle()
                }
                
                LabeledField(label: "Number of Travellers", icon: "person.3.fill") {
                    PlanSliderStepper(value: Binding(
                        get: { Int(input.amount) ?? 2 }, // Reusing amount for travellers in this draft or better create a field
                        set: { input.amount = String($0) }
                    ), range: 1...10, unit: "")
                }
                .cardStyle()

                LabeledField(label: "Trip Duration", icon: "clock.fill") {
                    PlanSliderStepper(value: Binding(
                        get: { input.educationDurationYrs ?? 10 }, // Reusing duration field
                        set: { input.educationDurationYrs = $0 }
                    ), range: 3...30, unit: "days")
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 10) {
                    Toggle(isOn: Binding(
                        get: { input.isFlexibleTimeline ?? true },
                        set: { input.isFlexibleTimeline = $0 }
                    )) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Flexible travel date?").font(.subheadline).fontWeight(.medium)
                            Text("Allows us to suggest optimal booking windows").font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
            }

        default:
            EmptyView()
        }
    }
}

//#Preview {
//    ZStack {
//        AppTheme.appBackground(for: .light).ignoresSafeArea()
//        ScrollView {
//            TravelQuestionnaire(
//                input: .constant(InvestmentPlanInputModel), // Using vehicle sample for draft
//                stepId: "travel_details"
//            )
//            .padding()
//        }
//    }
//}
