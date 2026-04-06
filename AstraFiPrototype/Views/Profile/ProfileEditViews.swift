import SwiftUI

struct _BasicInformationDetailView: View {
    @Environment(AppStateManager.self) var appState
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var age: String = ""
    @State private var gender: AstraGender = .male
    @State private var maritalStatus: AstraMaritalStatus = .single
    @State private var adultDependents: Int = 0
    @State private var childDependents: Int = 0
    @State private var monthlyIncome: String = ""
    @State private var monthlyIncomeAfterTax: String = ""
    @State private var monthlyExpenses: String = ""
    @State private var showingSaveAlert = false

    var body: some View {
        Form {
            Section("Identity") {
                TextField("Name", text: $name)
                TextField("Age", text: $age)
                    .keyboardType(.numberPad)
                Picker("Gender", selection: $gender) {
                    ForEach(AstraGender.allCases, id: \.self) { g in
                        Text(g.rawValue.capitalized).tag(g)
                    }
                }
                Picker("Marital Status", selection: $maritalStatus) {
                    ForEach(AstraMaritalStatus.allCases, id: \.self) { s in
                        Text(s.rawValue.capitalized).tag(s)
                    }
                }
            }

            Section("Family") {
                Stepper("Adult Dependents: \(adultDependents)", value: $adultDependents, in: 0...10)
                Stepper("Child Dependents: \(childDependents)", value: $childDependents, in: 0...10)
            }

            Section("Income & Expenses") {
                TextField("Monthly Income", text: $monthlyIncome)
                    .keyboardType(.decimalPad)
                TextField("After Tax Income", text: $monthlyIncomeAfterTax)
                    .keyboardType(.decimalPad)
                TextField("Avg. Monthly Expenses", text: $monthlyExpenses)
                    .keyboardType(.decimalPad)
            }

            Section {
                Button("Save Changes") {
                    saveChanges()
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.blue)
                .fontWeight(.bold)
            }
        }
        .navigationTitle("Basic Information")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadData()
        }
        .alert("Success", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) { dismiss() }
        } message: {
            Text("Your profile has been updated.")
        }
    }

    private func loadData() {
        if let details = appState.currentProfile?.basicDetails {
            name = details.name
            age = "\(details.age)"
            gender = details.gender
            maritalStatus = details.maritalStatus
            adultDependents = details.adultDependents
            childDependents = details.childDependents
            monthlyIncome = "\(Int(details.monthlyIncome))"
            monthlyIncomeAfterTax = "\(Int(details.monthlyIncomeAfterTax))"
            monthlyExpenses = "\(Int(details.monthlyExpenses))"
        }
    }

    private func saveChanges() {
        guard var profile = appState.currentProfile else { return }

        profile.basicDetails.name = name
        profile.basicDetails.age = Int(age) ?? profile.basicDetails.age
        profile.basicDetails.gender = gender
        profile.basicDetails.maritalStatus = maritalStatus
        profile.basicDetails.adultDependents = adultDependents
        profile.basicDetails.childDependents = childDependents
        profile.basicDetails.monthlyIncome = Double(monthlyIncome) ?? profile.basicDetails.monthlyIncome
        profile.basicDetails.monthlyIncomeAfterTax = Double(monthlyIncomeAfterTax) ?? profile.basicDetails.monthlyIncomeAfterTax
        profile.basicDetails.monthlyExpenses = Double(monthlyExpenses) ?? profile.basicDetails.monthlyExpenses

        appState.currentProfile = profile
        showingSaveAlert = true
    }
}

struct _FinancialProfileDetailView: View {
    @Environment(AppStateManager.self) var appState
    @Environment(\.dismiss) var dismiss

    @State private var risk: AstraRiskTolerance = .medium
    @State private var horizon: AstraInvestmentHorizon = .mediumTerm
    @State private var showingSaveAlert = false

    var body: some View {
        Form {
            Section("Investment Strategy") {
                Picker("Risk Tolerance", selection: $risk) {
                    ForEach(AstraRiskTolerance.allCases, id: \.self) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                Picker("Investment Horizon", selection: $horizon) {
                    ForEach(AstraInvestmentHorizon.allCases, id: \.self) { h in
                        Text(h.rawValue).tag(h)
                    }
                }
            }

            Section("Asset Allocation Breakdown") {
                let assets = appState.currentProfile?.assets
                AllocationRow(label: "Mutual Funds", amount: assets?.mutualFundHoldingAmount ?? 0, color: .blue)
                AllocationRow(label: "Stocks", amount: assets?.stocksHoldingAmount ?? 0, color: .blue)
                AllocationRow(label: "Deposits", amount: assets?.depositsAmount ?? 0, color: .orange)
            }

            Section {
                Button("Update Strategy") {
                    saveStrategy()
                }
                .frame(maxWidth: .infinity)
                .fontWeight(.bold)
            }
        }
        .navigationTitle("Financial Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let details = appState.currentProfile?.basicDetails {
                risk = details.riskTolerance
                horizon = details.investmentHorizon
            }
        }
        .alert("Updated", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) { dismiss() }
        } message: {
            Text("Your financial strategy has been updated.")
        }
    }

    private func saveStrategy() {
        var profile = appState.currentProfile
        profile?.basicDetails.riskTolerance = risk
        profile?.basicDetails.investmentHorizon = horizon
        appState.currentProfile = profile
        showingSaveAlert = true
    }
}

struct AllocationRow: View {
    let label: String
    let amount: Double
    let color: Color

    var body: some View {
        HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
            Spacer()
            Text(String(format: "₹%.0f", amount)).foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        _BasicInformationDetailView()
            .environment(AppStateManager.withSampleData())
    }
}

#Preview {
    NavigationStack {
        _FinancialProfileDetailView()
            .environment(AppStateManager.withSampleData())
    }
}
