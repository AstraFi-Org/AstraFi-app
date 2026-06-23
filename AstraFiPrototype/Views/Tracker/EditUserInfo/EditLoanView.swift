import SwiftUI

struct EditLoanView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppStateManager.self) var appState

    let loan: AstraLoan

    @State private var type: AstraLoanType = .personalLoan
    @State private var lender: AstraLoanLender = .other
    @State private var amount = ""

    @State private var rate = ""
    @State private var tenure = ""
    @State private var interestType: AstraInterestType = .compound
    @State private var compFreq: AstraCompoundingFrequency = .monthly
    @State private var installmentsPaid = ""

    @State private var emiAmount = ""
    @State private var emiFreq: AstraEMIFrequency = .monthly
    @State private var startDate = Date()
    @State private var firstEMIDate = Date()

    @State private var isFloating = false
    @State private var penalty = ""

    @State private var processingFee = ""
    @State private var insuranceCost = ""
    @State private var latePenalty = ""
    @State private var otherCharges = ""

    @State private var moratorium = ""
    @State private var moratoriumAccrual = true
    @State private var taxBenefits = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Details")) {
                    LabeledContent("Loan Type") {
                        Picker("", selection: $type) {
                            ForEach(AstraLoanType.allCases, id: \.self) { t in Text(t.rawValue.capitalized).tag(t) }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                    LabeledContent("Bank / Lender") {
                        Picker("", selection: $lender) {
                            ForEach(AstraLoanLender.allCases, id: \.self) { l in Text(l.rawValue).tag(l) }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                    HStack {
                        Text("Principal (₹)")
                        Spacer()
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section(header: Text("Interest & Tenure")) {
                    HStack {
                        Text("Interest Rate (%)")
                        Spacer()
                        TextField("Rate", text: $rate)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Tenure (Months)")
                        Spacer()
                        TextField("Months", text: $tenure)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Interest Type") {
                        Picker("", selection: $interestType) {
                            ForEach(AstraInterestType.allCases, id: \.self) { t in Text(t.rawValue).tag(t) }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                    LabeledContent("Compounding") {
                        Picker("", selection: $compFreq) {
                            ForEach(AstraCompoundingFrequency.allCases, id: \.self) { t in Text(t.rawValue).tag(t) }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                    HStack {
                        Text("Installments Paid")
                        Spacer()
                        TextField("Count", text: $installmentsPaid)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section(header: Text("EMI Details")) {
                    HStack {
                        Text("EMI Amount (₹)")
                        Spacer()
                        TextField("Optional", text: $emiAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("EMI Frequency") {
                        Picker("", selection: $emiFreq) {
                            ForEach(AstraEMIFrequency.allCases, id: \.self) { t in Text(t.rawValue).tag(t) }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                    DatePicker("Loan Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("First EMI Date", selection: $firstEMIDate, displayedComponents: .date)
                }

                Section(header: Text("Rates & Prepayment")) {
                    Toggle("Floating Interest Rate", isOn: $isFloating)
                    HStack { Text("%"); TextField("Prepayment Penalty", text: $penalty).keyboardType(.decimalPad) }
                }

                Section(header: Text("Charges & Hidden Costs")) {
                    HStack { Text("₹"); TextField("Processing Fee", text: $processingFee).keyboardType(.decimalPad) }
                    HStack { Text("₹"); TextField("Insurance Cost", text: $insuranceCost).keyboardType(.decimalPad) }
                    HStack { Text("₹"); TextField("Late Penalty", text: $latePenalty).keyboardType(.decimalPad) }
                    HStack { Text("₹"); TextField("Other Charges", text: $otherCharges).keyboardType(.decimalPad) }
                }

                Section(header: Text("Advanced Options")) {
                    TextField("Moratorium Period (Months)", text: $moratorium).keyboardType(.numberPad)
                    if !moratorium.isEmpty {
                        Toggle("Interest Accrual during Moratorium", isOn: $moratoriumAccrual)
                    }
                    Toggle("Track Tax Benefits (80C/Sec 24)", isOn: $taxBenefits)
                }

            }
            .navigationTitle("Edit Loan")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadLoan)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveChanges) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(amount.isEmpty || rate.isEmpty || tenure.isEmpty ? .gray : .blue)
                    }
                    .disabled(amount.isEmpty || rate.isEmpty || tenure.isEmpty)
                }
            }
        }
    }

    private func loadLoan() {
        type = loan.loanType
        lender = loan.lender
        amount = "\(loan.loanAmount.safeInt)"
        rate = "\(loan.interestRate)"
        tenure = "\(loan.loanTenureMonths)"
        interestType = loan.interestType
        compFreq = loan.compoundingFrequency
        installmentsPaid = "\(loan.installmentsPaid)"

        if let emi = loan.emiAmount { emiAmount = "\(emi.safeInt)" }
        emiFreq = loan.emiFrequency
        startDate = loan.loanStartDate
        if let fEMIDate = loan.firstEMIDate { firstEMIDate = fEMIDate }

        isFloating = loan.isFloatingRate
        penalty = "\(loan.prepaymentPenaltyPercentage)"

        processingFee = "\(loan.processingFee.safeInt)"
        insuranceCost = "\(loan.insurancePremium.safeInt)"
        latePenalty = "\(loan.latePaymentPenalty.safeInt)"
        otherCharges = "\(loan.otherCharges.safeInt)"

        moratorium = "\(loan.moratoriumMonths)"
        moratoriumAccrual = loan.interestAccrualDuringMoratorium
        taxBenefits = loan.trackTaxBenefits
    }

    private func saveChanges() {
        var updated = loan
        updated.loanType = type
        updated.lender = lender
        updated.loanAmount = Double(amount) ?? loan.loanAmount
        updated.interestRate = Double(rate) ?? loan.interestRate
        updated.loanTenureMonths = Int(tenure) ?? loan.loanTenureMonths
        updated.installmentsPaid = Int(installmentsPaid) ?? loan.installmentsPaid

        updated.interestType = interestType
        updated.compoundingFrequency = compFreq
        updated.emiAmount = Double(emiAmount)
        updated.emiFrequency = emiFreq
        updated.loanStartDate = startDate
        updated.firstEMIDate = firstEMIDate
        updated.isFloatingRate = isFloating
        updated.prepaymentPenaltyPercentage = Double(penalty) ?? 0
        updated.processingFee = Double(processingFee) ?? 0
        updated.insurancePremium = Double(insuranceCost) ?? 0
        updated.latePaymentPenalty = Double(latePenalty) ?? 0
        updated.otherCharges = Double(otherCharges) ?? 0
        updated.moratoriumMonths = Int(moratorium) ?? 0
        updated.interestAccrualDuringMoratorium = moratoriumAccrual
        updated.trackTaxBenefits = taxBenefits

        appState.updateLoan(updated)
        dismiss()
    }
}

#Preview {
    EditLoanView(loan: AstraLoan(
        loanType: .homeLoan,
        lender: .hdfcBank,
        loanAmount: 8500000,
        interestRate: 8.5,
        loanStartDate: Date().addingTimeInterval(-86400 * 30 * 48),
        loanTenureMonths: 240,
        installmentsPaid: 48
    ))
    .environment(AppStateManager.withSampleData())
}
