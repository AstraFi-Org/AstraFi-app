import SwiftUI

struct BasicDetailsScreen: View {
    @Bindable var data: CompleteAssessmentData
    @Environment(AppStateManager.self) var appState
    @State private var goNext = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGroupedBackground).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    StepBadge(current: 1, total: 4, title: "Basic Details")
                        .padding(.top, 16).padding(.horizontal, 20).padding(.bottom, 8)

                    FormCard {
                        CardHeader(icon: "person.fill", title: "Personal Info")
                        NativeField(label: "Full Name", placeholder: "e.g. Rahul Sharma", text: $data.name)
                        Divider()
                        NativeField(label: "Age", placeholder: "e.g. 32", text: $data.age, keyboard: .numberPad)
                        Divider()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Gender").font(.footnote).foregroundStyle(.secondary).textCase(.uppercase).tracking(0.5)
                            Picker("Gender", selection: $data.gender) {
                                Text("Male").tag(CompleteAssessmentData.Gender.male)
                                Text("Female").tag(CompleteAssessmentData.Gender.female)
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.top, 4)
                        Hint("Used to personalise coverage and policy benefits.")
                    }

                    FormCard {
                        CardHeader(icon: "person.2.fill", title: "Dependents")
                        Hint("Used to assess financial responsibility and coverage needs.").padding(.bottom, 4)
                        Stepper(value: $data.adultDependents, in: 0...10) {
                            StepperLabel(label: "Adult dependents", count: data.adultDependents)
                        }.tint(.blue)
                        Divider()
                        Stepper(value: $data.childDependents, in: 0...10) {
                            StepperLabel(label: "Child dependents", count: data.childDependents)
                        }.tint(.blue)
                    }

                    FormCard {
                        CardHeader(icon: "indianrupeesign.circle.fill", title: "Income")
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Income Type").font(.footnote).foregroundStyle(.secondary).textCase(.uppercase).tracking(0.5)
                            Picker("Income Type", selection: $data.incomeType) {
                                Text("Fixed").tag(CompleteAssessmentData.IncomeType.fixed)
                                Text("Variable").tag(CompleteAssessmentData.IncomeType.variable)
                            }
                            .pickerStyle(.segmented)
                        }
                        Hint("Fixed = salary; Variable = freelance, business, commission.")
                        Divider()
                        if data.incomeType == .fixed {
                            NativeField(label: "Monthly Income (₹)", placeholder: "e.g. 80000", text: $data.income, keyboard: .numberPad)
                            Hint("Your total gross monthly salary or fixed earnings.")
                            Divider()
                            NativeField(label: "Monthly Income After Tax (₹)", placeholder: "e.g. 68000", text: $data.incomeAfterTax, keyboard: .numberPad)
                            Hint("Your actual take-home pay after all deductions.")
                        } else {
                            HStack(spacing: 12) {
                                NativeField(label: "Min Monthly Income (₹)", placeholder: "e.g. 40000", text: $data.minMonthlyIncome, keyboard: .numberPad)
                                NativeField(label: "Max Monthly Income (₹)", placeholder: "e.g. 120000", text: $data.maxMonthlyIncome, keyboard: .numberPad)
                            }
                            Hint("The typical range of your monthly earnings.")
                            Divider()
                            NativeField(label: "Estimated Tax Rate (%)", placeholder: "e.g. 20", text: $data.taxPercentage, keyboard: .numberPad)
                            Hint("The average percentage of tax you pay on your income.")
                        }
                    }

                    FormCard {
                        CardHeader(icon: "cart.fill", title: "Monthly Expenses")
                        NativeField(label: "Fixed Monthly Expenditure (₹)", placeholder: "e.g. 35000", text: $data.expenditure, keyboard: .numberPad)
                        Hint("Include rent, utilities, subscriptions, groceries.")
                    }

                    FormCard {
                        CardHeader(icon: "umbrella.fill", title: "Emergency Fund")
                        Hint("Ideally 3–6 months of expenses set aside.")
                        Toggle(isOn: $data.hasEmergencyFund.animation()) {
                            Text("I have an emergency fund").font(.subheadline)
                        }.tint(.blue)
                        if data.hasEmergencyFund {
                            Divider()
                            NativeField(label: "Total Amount Saved (₹)", placeholder: "e.g. 200000", text: $data.emergencyFundAmount, keyboard: .numberPad)
                        }
                    }

                    Spacer().frame(height: 90)
                }
            }
            SingleNavFooter(isLast: false, onNext: { goNext = true })
        }
        .navigationTitle("Financial Assessment").navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $goNext) { InvestmentDetailsScreen(data: data) }
        .onAppear {
            if data.name.isEmpty && !appState.tempName.isEmpty { data.name = appState.tempName }
            data.email    = appState.tempEmail
            data.password = appState.tempPassword
        }
    }
}

#Preview {
    NavigationStack {
        BasicDetailsScreen(data: CompleteAssessmentData())
            .environment(AppStateManager.withSampleData())
    }
}
