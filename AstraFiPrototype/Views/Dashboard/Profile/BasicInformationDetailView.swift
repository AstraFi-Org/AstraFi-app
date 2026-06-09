import SwiftUI
import Supabase

struct BasicInformationDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(AppStateManager.self) var appState

    @State private var name: String = ""
    @State private var age: Int = 0
    @State private var gender: AstraGender = .male
    @State private var monthlyIncome: String = ""
    @State private var monthlyExpenses: String = ""
    @State private var maritalStatus: AstraMaritalStatus = .single
    @State private var adultDependents: Int = 0
    @State private var childDependents: Int = 0
    @State private var showingSaveSuccess = false

    var body: some View {
        Form {
            Section(header: Text("Identity")) {
                HStack {
                    Text("Name")
                    Spacer()
                    TextField("Name", text: $name)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Age")
                    Spacer()
                    TextField("Age", value: $age, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("Gender") {
                    Picker("", selection: $gender) {
                        ForEach(AstraGender.allCases, id: \.self) { g in
                            Text(g.rawValue.capitalized).tag(g)
                        }
                    }
                    .labelsHidden()
                }
                LabeledContent("Marital Status") {
                    Picker("", selection: $maritalStatus) {
                        ForEach(AstraMaritalStatus.allCases, id: \.self) { s in
                            Text(s.rawValue.capitalized).tag(s)
                        }
                    }
                    .labelsHidden()
                }
            }

            Section(header: Text("Family")) {
                Stepper("Adult Dependents: \(adultDependents)", value: $adultDependents, in: 0...20)
                Stepper("Child Dependents: \(childDependents)", value: $childDependents, in: 0...20)
            }

            Section(header: Text("Income & Expenses")) {
                HStack {
                    Text("Monthly Income (₹)")
                    Spacer()
                    TextField("Amount", text: $monthlyIncome)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Monthly Expenses (₹)")
                    Spacer()
                    TextField("Amount", text: $monthlyExpenses)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }

            Section {
                Button(action: saveChanges) {
                    Text("Save Details")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(name.isEmpty ? Color.gray : .blue)
                        .cornerRadius(12)
                }
                .disabled(name.isEmpty)
            }
        }
        .navigationTitle("Basic Information")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadData)
        .alert("Success", isPresented: $showingSaveSuccess) {
            Button("OK", role: .cancel) { dismiss() }
        } message: {
            Text("Your profile has been updated.")
        }
    }

    private func loadData() {
        if let basic = appState.currentProfile?.basicDetails {
            name = basic.name
            age = basic.age
            gender = basic.gender
            maritalStatus = basic.maritalStatus
            adultDependents = basic.adultDependents
            childDependents = basic.childDependents
            monthlyIncome = "\(Int(basic.monthlyIncome))"
            monthlyExpenses = "\(Int(basic.monthlyExpenses))"
        }
    }

    private func saveChanges() {
        guard var profile = appState.currentProfile else { return }

        profile.basicDetails.name = name
        profile.basicDetails.age = age
        profile.basicDetails.gender = gender
        profile.basicDetails.maritalStatus = maritalStatus
        profile.basicDetails.adultDependents = adultDependents
        profile.basicDetails.childDependents = childDependents

        let oldIncome = profile.basicDetails.monthlyIncome
        let newIncome = Double(monthlyIncome) ?? oldIncome

        if oldIncome > 0 {
            let ratio = profile.basicDetails.monthlyIncomeAfterTax / oldIncome
            profile.basicDetails.monthlyIncomeAfterTax = newIncome * ratio
        } else {
            profile.basicDetails.monthlyIncomeAfterTax = newIncome * (1.0 - AppStateManager.defaultTaxRate)
        }

        profile.basicDetails.monthlyIncome = newIncome
        profile.basicDetails.monthlyExpenses = Double(monthlyExpenses) ?? profile.basicDetails.monthlyExpenses

        appState.currentProfile = profile

        // Sync updated profile to Supabase
        Task {
            do {
                if let session = try? await supabase.auth.session {
                    try await SupabaseRepository.shared.saveUserProfile(profile, userId: session.user.id)
                }
            } catch {
                print("Failed to sync profile to Supabase: \(error)")
            }
        }

        showingSaveSuccess = true
    }
}

#Preview {
    NavigationStack {
        BasicInformationDetailView()
            .environment(AppStateManager.withSampleData())
    }
}
