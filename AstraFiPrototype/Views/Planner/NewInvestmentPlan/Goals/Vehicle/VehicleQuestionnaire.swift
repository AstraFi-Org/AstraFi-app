import SwiftUI

struct VehicleQuestionnaire: View {
    @Binding var input: InvestmentPlanInputModel
    let stepId: String
    
    var body: some View {
        switch stepId {
        case "vehicle_details":
            VStack(spacing: 20) {
                LabeledField(label: "Vehicle Type", icon: "car.fill") {
                    PlanStackedChips(
                        selection: Binding(
                            get: { input.destinationType ?? "SUV" }, // Reusing destinationType for vehicle type
                            set: { input.destinationType = $0 }
                        ),
                        options: ["Hatchback", "Sedan", "SUV", "Electric", "Luxury", "Bike"])
                }
                .cardStyle()

                LabeledField(label: "Budget Segment", icon: "indianrupeesign.circle",
                             note: "Sets your savings target") {
                    PlanMenuPicker(
                        selection: Binding(
                            get: { input.wealthIntent ?? "Mid-range (₹5–15L)" }, // Reusing wealthIntent for segment
                            set: { input.wealthIntent = $0 }
                        ),
                        options: ["Entry (< ₹5L)",
                                  "Mid-range (₹5–15L)",
                                  "Premium (₹15–30L)",
                                  "Luxury (₹30L+)"])
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 10) {
                    Toggle(isOn: $input.openToLoan) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Open to Car Loan?").font(.subheadline).fontWeight(.medium)
                            Text("Affects EMI vs SIP strategy").font(.caption).foregroundColor(.secondary)
                        }
                    }
                    if input.openToLoan {
                        PlanDivider()
                        AssessmentField(
                            icon: "indianrupeesign.circle",
                            label: "Down Payment (₹)",
                            placeholder: "e.g. 1,00,000",
                            text: Binding(
                                get: { String(format: "%.0f", input.downPaymentAffordable ?? 0) },
                                set: { input.downPaymentAffordable = Double($0) }
                            ),
                            keyboard: .numberPad
                        )
                    }
                }
                
                PlanDivider()
                
                Toggle(isOn: Binding(
                    get: { input.vehicleBuyLogic == "Funded" },
                    set: { input.vehicleBuyLogic = $0 ? "Funded" : "Loan" }
                )) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Buy only when fully funded?").font(.subheadline).fontWeight(.medium)
                        Text("No loan – 100% savings first").font(.caption).foregroundColor(.secondary)
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
            VehicleQuestionnaire(
                input: .constant(InvestmentPlanInputModel.sampleVehicle),
                stepId: "vehicle_details"
            )
            .padding()
        }
    }
}
