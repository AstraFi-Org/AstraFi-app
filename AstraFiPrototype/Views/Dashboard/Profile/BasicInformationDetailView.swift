import SwiftUI
import Supabase

struct BasicInformationDetailView: View {
    @Environment(AppStateManager.self) private var appState

    @State private var isEditing = false
    @State private var showSavedAlert = false
    @State private var form = ProfileInfoForm()

    private var canSave: Bool {
        !form.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section {
                ProfileInfoSummary(name: form.name, email: form.email)
            }

            Section("Contact") {
                textRow("Email ID", text: $form.email, placeholder: "Email not added", keyboard: .emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                textRow("Phone Number", text: $form.phoneNumber, placeholder: "Phone not added", keyboard: .phonePad)
            }

            Section("Personal Details") {
                textRow("Full Name", text: $form.name, placeholder: "Name not added")
                textRow("Age", text: $form.age, placeholder: "Age not added", keyboard: .numberPad)
                pickerRow("Gender", selection: $form.gender)
                pickerRow("Marital Status", selection: $form.maritalStatus)
            }

            Section("Family") {
                if isEditing {
                    Stepper("Adult Dependents: \(form.adultDependents)", value: $form.adultDependents, in: 0...20)
                    Stepper("Child Dependents: \(form.childDependents)", value: $form.childDependents, in: 0...20)
                } else {
                    LabeledContent("Adult Dependents", value: "\(form.adultDependents)")
                    LabeledContent("Child Dependents", value: "\(form.childDependents)")
                }
            }

            Section("Income & Expenses") {
                textRow("Monthly Income", text: $form.monthlyIncome, placeholder: "Income not added", keyboard: .decimalPad, prefix: "₹")
                textRow("Monthly Expenses", text: $form.monthlyExpenses, placeholder: "Expenses not added", keyboard: .decimalPad, prefix: "₹")
            }
        }
        .navigationTitle("Profile Information")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if isEditing {
                    Button("Cancel") {
                        loadProfile()
                        isEditing = false
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    isEditing ? saveProfile() : beginEditing()
                }
                .fontWeight(isEditing ? .semibold : .regular)
                .disabled(isEditing && !canSave)
            }
        }
        .onAppear(perform: loadProfile)
        .alert("Profile Updated", isPresented: $showSavedAlert) {
            Button("OK", role: .cancel) { }
        }
    }

    @ViewBuilder
    private func textRow(
        _ title: String,
        text: Binding<String>,
        placeholder: String,
        keyboard: UIKeyboardType = .default,
        prefix: String? = nil
    ) -> some View {
        if isEditing {
            HStack {
                Text(title)
                Spacer(minLength: 16)

                HStack(spacing: 2) {
                    if let prefix {
                        Text(prefix).foregroundStyle(.secondary)
                    }

                    TextField(placeholder, text: text)
                        .keyboardType(keyboard)
                        .multilineTextAlignment(.trailing)
                }
                .frame(maxWidth: 190)
            }
        } else {
            LabeledContent(title, value: displayValue(text.wrappedValue, placeholder: placeholder, prefix: prefix))
        }
    }

    @ViewBuilder
    private func pickerRow<T: RawRepresentable & CaseIterable & Hashable>(_ title: String, selection: Binding<T>) -> some View where T.RawValue == String {
        if isEditing {
            Picker(title, selection: selection) {
                ForEach(Array(T.allCases), id: \.self) { value in
                    Text(value.rawValue.capitalized).tag(value)
                }
            }
        } else {
            LabeledContent(title, value: selection.wrappedValue.rawValue.capitalized)
        }
    }

    private func beginEditing() {
        isEditing = true
    }

    private func loadProfile() {
        guard let profile = appState.currentProfile else { return }
        form = ProfileInfoForm(profile: profile)
    }

    private func saveProfile() {
        guard var profile = appState.currentProfile else { return }

        form.apply(to: &profile)
        appState.currentProfile = profile
        isEditing = false
        showSavedAlert = true

        Task {
            do {
                if let session = try? await supabase.auth.session {
                    try await SupabaseRepository.shared.saveUserProfile(profile, userId: session.user.id)
                }
            } catch {
                print("Failed to sync profile to Supabase: \(error)")
            }
        }
    }

    private func displayValue(_ value: String, placeholder: String, prefix: String? = nil) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return placeholder }
        guard let prefix else { return trimmed }
        return "\(prefix)\(trimmed)"
    }
}

private struct ProfileInfoForm {
    var name = ""
    var email = ""
    var phoneNumber = ""
    var age = ""
    var gender: AstraGender = .male
    var maritalStatus: AstraMaritalStatus = .single
    var adultDependents = 0
    var childDependents = 0
    var monthlyIncome = ""
    var monthlyExpenses = ""

    init() { }

    init(profile: AstraUserProfile) {
        let basic = profile.basicDetails

        name = basic.name.isEmpty ? profile.signUp.signUpName : basic.name
        email = profile.signUp.email
        phoneNumber = basic.phoneNumber ?? ""
        age = basic.age > 0 ? "\(basic.age)" : ""
        gender = basic.gender
        maritalStatus = basic.maritalStatus
        adultDependents = basic.adultDependents
        childDependents = basic.childDependents
        monthlyIncome = basic.monthlyIncome > 0 ? "\(Int(basic.monthlyIncome))" : ""
        monthlyExpenses = basic.monthlyExpenses > 0 ? "\(Int(basic.monthlyExpenses))" : ""
    }

    func apply(to profile: inout AstraUserProfile) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPhone = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let newIncome = Double(monthlyIncome) ?? profile.basicDetails.monthlyIncome

        profile.signUp.signUpName = cleanName
        profile.signUp.email = cleanEmail
        profile.basicDetails.name = cleanName
        profile.basicDetails.phoneNumber = cleanPhone.isEmpty ? nil : cleanPhone
        profile.basicDetails.age = Int(age) ?? profile.basicDetails.age
        profile.basicDetails.gender = gender
        profile.basicDetails.maritalStatus = maritalStatus
        profile.basicDetails.adultDependents = adultDependents
        profile.basicDetails.childDependents = childDependents
        profile.basicDetails.monthlyIncomeAfterTax = afterTaxIncome(from: newIncome, oldProfile: profile)
        profile.basicDetails.monthlyIncome = newIncome
        profile.basicDetails.monthlyExpenses = Double(monthlyExpenses) ?? profile.basicDetails.monthlyExpenses
    }

    private func afterTaxIncome(from newIncome: Double, oldProfile profile: AstraUserProfile) -> Double {
        let oldIncome = profile.basicDetails.monthlyIncome
        guard oldIncome > 0 else {
            return newIncome * (1.0 - AppStateManager.defaultTaxRate)
        }

        let taxRatio = profile.basicDetails.monthlyIncomeAfterTax / oldIncome
        return newIncome * taxRatio
    }
}

private struct ProfileInfoSummary: View {
    let name: String
    let email: String

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(LinearGradient(colors: [Color(hex: "#007AFF"), Color(hex: "#34C759")], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 56, height: 56)
                .overlay {
                    Text(initials)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(name.isEmpty ? "AstraFi User" : name)
                    .font(.headline)
                Text(email.isEmpty ? "Email not added" : email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? "A"
        let second = parts.dropFirst().first?.prefix(1) ?? ""
        return "\(first)\(second)".uppercased()
    }
}

#Preview {
    NavigationStack {
        BasicInformationDetailView()
            .environment(AppStateManager.withSampleData())
    }
}
