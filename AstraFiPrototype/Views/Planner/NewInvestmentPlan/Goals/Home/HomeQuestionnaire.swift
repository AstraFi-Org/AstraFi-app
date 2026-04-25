import SwiftUI

struct HomeQuestionnaire: View {
    @Binding var input: InvestmentPlanInputModel
    let stepId: String
    
    var body: some View {
        switch stepId {
        case "home_details":
            VStack(spacing: 20) {
                LabeledField(label: "City Tier", icon: "building.2.fill",
                             note: "Determines property price benchmark") {
                    PlanMenuPicker(
                        selection: Binding(
                            get: { input.educationLocation ?? "Metro" }, // Reusing educationLocation for city
                            set: { input.educationLocation = $0 }
                        ),
                        options: ["Metro (Mumbai/Delhi/Bengaluru)",
                                  "Tier 1 (Pune/Hyd/Chennai)",
                                  "Tier 2 City",
                                  "Tier 3 / Town"])
                }
                .cardStyle()

                LabeledField(label: "BHK Configuration", icon: "bed.double.fill") {
                    PlanSegmentChips(
                        selection: Binding(
                            get: { input.contributionSplit ?? "2 BHK" }, // Reusing contributionSplit for BHK
                            set: { input.contributionSplit = $0 }
                        ),
                        options: ["1 BHK", "2 BHK", "3 BHK", "4+ BHK"])
                }
                .cardStyle()

                LabeledField(label: "Property Type", icon: "house.and.flag.fill") {
                    PlanStackedChips(
                        selection: Binding(
                            get: { input.wealthIntent ?? "Apartment" }, // Reusing wealthIntent for property type
                            set: { input.wealthIntent = $0 }
                        ),
                        options: ["Apartment", "Independent House", "Villa", "Plot"])
                }
                .cardStyle()
            }

        case "home_finance":
            VStack(spacing: 20) {
                AssessmentField(
                    icon: "indianrupeesign.circle",
                    label: "Down Payment You Can Afford (₹)",
                    placeholder: "e.g. 5,00,000",
                    text: Binding(
                        get: { String(format: "%.0f", input.downPaymentAffordable ?? 0) },
                        set: { input.downPaymentAffordable = Double($0) }
                    ),
                    keyboard: .numberPad
                )

                VStack(alignment: .leading, spacing: 10) {
                    Toggle(isOn: $input.openToLoan) {
                        Text("Open to Home Loan?")
                            .font(.subheadline).fontWeight(.medium)
                    }
                    if input.openToLoan {
                        PlanDivider()
                        LabeledField(label: "Preferred Loan Tenure", icon: "calendar") {
                            PlanSliderStepper(value: Binding(
                                get: { input.preferredLoanTenureYears },
                                set: { input.preferredLoanTenureYears = $0 }
                            ), range: 5...30, unit: "yrs")
                        }
                        .cardStyle()
                        PlanDivider()
                        AssessmentField(
                            icon: "percent",
                            label: "Expected Interest Rate (%)",
                            placeholder: "e.g. 8.5",
                            text: Binding(
                                get: { String(format: "%.1f", input.interestRate ?? 8.5) },
                                set: { input.interestRate = Double($0) }
                            ),
                            keyboard: .decimalPad
                        )
                    }
                }
            }

        default:
            EmptyView()
        }
    }
}

#Preview("Details") {
    ZStack {
        AppTheme.appBackground(for: .light).ignoresSafeArea()
        ScrollView {
            HomeQuestionnaire(
                input: .constant(InvestmentPlanInputModel.sampleHome),
                stepId: "home_details"
            )
            .padding()
        }
    }
}

#Preview("Finance") {
    ZStack {
        AppTheme.appBackground(for: .light).ignoresSafeArea()
        ScrollView {
            HomeQuestionnaire(
                input: .constant(InvestmentPlanInputModel.sampleHome),
                stepId: "home_finance"
            )
            .padding()
        }
    }
}
