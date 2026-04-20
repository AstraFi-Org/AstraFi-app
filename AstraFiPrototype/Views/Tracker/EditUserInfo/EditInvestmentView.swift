import SwiftUI

struct EditInvestmentView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppStateManager.self) var appState

    let investment: AstraInvestment

    @State private var name = ""
    @State private var type: AstraInvestmentType = .mutualFund
    @State private var amount = ""
    @State private var mode: AstraInvestmentMode = .sip
    @State private var startDate = Date()
    @State private var selectedGoalID: UUID? = nil
    @State private var units = ""
    @State private var isCalculatingUnits = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 15) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Investment Name").font(.footnote).foregroundColor(.secondary)
                            TextField("e.g. Axis Bluechip Fund", text: $name)
                                .textFieldStyle(.plain)
                        }
                        Divider()

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Investment Type").font(.footnote).foregroundColor(.secondary)
                            Picker("Investment Type", selection: $type) {
                                ForEach(AstraInvestmentType.allCases, id: \.self) { t in
                                    Text(t.rawValue).tag(t)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Investment Mode").font(.footnote).foregroundColor(.secondary)
                            Picker("Mode", selection: $mode) {
                                Text("SIP (Monthly)").tag(AstraInvestmentMode.sip)
                                Text("Lumpsum").tag(AstraInvestmentMode.lumpsum)
                            }
                            .pickerStyle(.segmented)
                        }
                        Divider()

                        VStack(alignment: .leading, spacing: 5) {
                            Text(mode == .sip ? "Monthly SIP Amount" : "Lumpsum Amount").font(.footnote).foregroundColor(.secondary)
                            HStack {
                                Text("₹").foregroundColor(.primary)
                                TextField("Amount", text: $amount)
                                    .keyboardType(.decimalPad)
                                if mode == .sip { Text("/month").foregroundColor(.secondary).font(.caption) }
                            }
                        }
                        Divider()

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Start Date").font(.footnote).foregroundColor(.secondary)
                            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                                .labelsHidden()
                        }
                        Divider()

                        if investment.investmentType == .mutualFund {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Units").font(.footnote).foregroundColor(.secondary)
                                HStack {
                                    TextField("Units", text: $units)
                                        .keyboardType(.decimalPad)
                                    if isCalculatingUnits {
                                        ProgressView()
                                            .scaleEffect(0.6)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Investment Details")
                }

                if let goals = appState.currentProfile?.goals, !goals.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Link to Goal").font(.footnote).foregroundColor(.secondary)
                            Picker("Link to Goal", selection: $selectedGoalID) {
                                Text("None").tag(Optional<UUID>(nil))
                                ForEach(goals) { g in
                                    Text(g.goalName).tag(Optional(g.id))
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    } header: {
                        Text("Linked Goal (Optional)")
                    }
                }

            }
            .navigationTitle("Edit Investment")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: startDate) { _, _ in if investment.investmentType == .mutualFund { performAutoCalculation() } }
            .onChange(of: amount) { _, _ in if investment.investmentType == .mutualFund { performAutoCalculation() } }
            .onChange(of: mode) { _, _ in if investment.investmentType == .mutualFund { performAutoCalculation() } }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveChanges) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(name.isEmpty || amount.isEmpty ? Color.gray : .blue)
                            .clipShape(Circle())
                    }
                    .disabled(name.isEmpty || amount.isEmpty)
                }
            }
            .onAppear {
                name = investment.investmentName
                type = investment.investmentType
                amount = "\(Int(investment.investmentAmount))"
                mode = investment.mode
                startDate = investment.startDate
                selectedGoalID = investment.associatedGoalID
                units = String(format: "%.4f", investment.units ?? 0)
            }
        }
    }

    private func performAutoCalculation() {
        guard let code = investment.schemeCode, let amt = Double(amount), amt > 0 else { return }

        isCalculatingUnits = true
        Task {
            if mode == .sip {
                let result = await MFService.shared.calculateHistoricalSIPUnits(
                    schemeCode: code,
                    monthlyAmount: amt,
                    startDate: startDate
                )
                await MainActor.run {
                    self.units = String(format: "%.4f", result.totalUnits)
                    self.isCalculatingUnits = false
                }
            } else {
                if let nav = await MFService.shared.fetchHistoricalNAV(schemeCode: code, date: startDate) {
                    await MainActor.run {
                        self.units = String(format: "%.4f", amt / nav)
                        self.isCalculatingUnits = false
                    }
                } else {
                    await MainActor.run {
                        self.isCalculatingUnits = false
                    }
                }
            }
        }
    }

    private func saveChanges() {
        var updated = investment

        let hasStartDateChanged = Calendar.current.startOfDay(for: updated.startDate) != Calendar.current.startOfDay(for: startDate)
        let hasAmountChanged = updated.investmentAmount != (Double(amount) ?? 0)
        let hasModeChanged = updated.mode != mode
        let hasNameChanged = updated.investmentName != name

        updated.investmentName = name
        updated.investmentType = type
        updated.investmentAmount = Double(amount) ?? investment.investmentAmount
        updated.mode = mode
        updated.startDate = startDate
        updated.associatedGoalID = selectedGoalID
        updated.units = Double(units)

        if hasStartDateChanged || hasAmountChanged || hasModeChanged || hasNameChanged {
            updated.lastNAV = nil
            // ✅ Bug Fix: Clear cached installments so syncMutualFundNAVs
            // recalculates them with the new amount/date/mode.
            // Previously, stale installments remained (non-empty) so the
            // `if installments.isEmpty` guard in AppStateManager was never
            // entered, leaving totalInvestedAmount and units outdated.
            updated.installments = []
            updated.units = nil
            updated.quantity = nil
            if hasNameChanged {
                updated.schemeCode = nil
            }
        }

        appState.updateInvestment(updated)
        dismiss()
    }
}

#Preview {
    EditInvestmentView(investment: AstraInvestment(
        investmentType: .mutualFund,
        subtype: .equityFund,
        investmentName: "Axis Bluechip Fund",
        investmentAmount: 5000,
        startDate: Date().addingTimeInterval(-86400 * 30),
        associatedGoalID: nil,
        mode: .sip
    ))
    .environment(AppStateManager.withSampleData())
}
