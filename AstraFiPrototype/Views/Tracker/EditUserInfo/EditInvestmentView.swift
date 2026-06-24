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
            .onChange(of: startDate) { _, _ in if supportsAutoCalculation { performAutoCalculation() } }
            .onChange(of: amount) { _, _ in if supportsAutoCalculation { performAutoCalculation() } }
            .onChange(of: mode) { _, _ in if supportsAutoCalculation { performAutoCalculation() } }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await saveChanges() }
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(name.isEmpty || amount.isEmpty ? .gray : .blue)
                    }
                    .disabled(name.isEmpty || amount.isEmpty)
                }
            }
            .onAppear {
                name = investment.investmentName
                type = investment.investmentType
                amount = "\(investment.investmentAmount.safeInt)"
                mode = investment.mode
                startDate = investment.startDate
                selectedGoalID = investment.associatedGoalID
                units = String(format: "%.4f", investment.units ?? 0)
            }
        }
    }

    private var supportsAutoCalculation: Bool {
        type == .mutualFund || isMarketPricedInvestment(type)
    }

    private func isMarketPricedInvestment(_ investmentType: AstraInvestmentType) -> Bool {
        investmentType == .stocks || investmentType == .goldETF || investmentType == .cryptocurrency
    }

    private func performAutoCalculation() {
        guard let amt = Double(amount), amt > 0 else { return }

        isCalculatingUnits = true
        Task {
            if type == .mutualFund, let code = investment.schemeCode {
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
            } else if isMarketPricedInvestment(type), let symbol = investment.symbol {
                let result: (totalUnits: Double, totalInvested: Double, installments: [AstraInvestmentTransaction])
                if mode == .sip {
                    result = await StockService.shared.calculateHistoricalSIPUnits(
                        symbol: symbol,
                        monthlyAmount: amt,
                        startDate: startDate
                    )
                } else {
                    result = await StockService.shared.calculateLumpsumUnits(
                        symbol: symbol,
                        amount: amt,
                        startDate: startDate
                    )
                }

                await MainActor.run {
                    self.units = String(format: type == .cryptocurrency ? "%.6f" : "%.4f", result.totalUnits)
                    self.isCalculatingUnits = false
                }
            } else {
                await MainActor.run {
                    self.isCalculatingUnits = false
                }
            }
        }
    }

    @MainActor
    private func saveChanges() async {
        var updated = investment

        let hasStartDateChanged = Calendar.current.startOfDay(for: updated.startDate) != Calendar.current.startOfDay(for: startDate)
        let hasAmountChanged = updated.investmentAmount != (Double(amount) ?? 0)
        let hasModeChanged = updated.mode != mode
        let hasNameChanged = updated.investmentName != name
        let hasTypeChanged = updated.investmentType != type
        let needsRecalculation = hasStartDateChanged || hasAmountChanged || hasModeChanged || hasNameChanged || hasTypeChanged

        updated.investmentName = name
        updated.investmentType = type
        updated.investmentAmount = Double(amount) ?? investment.investmentAmount
        updated.mode = mode
        updated.startDate = startDate
        updated.associatedGoalID = selectedGoalID

        if needsRecalculation {
            updated.installments = []
            updated.units = nil
            updated.quantity = nil
            updated.purchaseNAV = nil

            if hasNameChanged && type == .mutualFund {
                updated.schemeCode = nil
            }

            if type == .mutualFund, let code = updated.schemeCode {
                if mode == .sip {
                    let result = await MFService.shared.calculateHistoricalSIPUnits(
                        schemeCode: code,
                        monthlyAmount: updated.investmentAmount,
                        startDate: updated.startDate
                    )
                    updated.installments = result.installments
                    updated.units = result.totalUnits
                } else if let nav = await MFService.shared.fetchHistoricalNAV(schemeCode: code, date: updated.startDate), nav > 0 {
                    let calculatedUnits = updated.investmentAmount / nav
                    updated.installments = [
                        AstraInvestmentTransaction(date: updated.startDate, type: .buy, amount: updated.investmentAmount, nav: nav, units: calculatedUnits)
                    ]
                    updated.units = calculatedUnits
                }

                if let liveScheme = MFService.shared.getScheme(by: code) {
                    updated.lastNAV = liveScheme.nav
                    updated.livePrice = liveScheme.nav
                    updated.lastUpdated = Date()
                }
            } else if isMarketPricedInvestment(type), let symbol = updated.symbol {
                let result: (totalUnits: Double, totalInvested: Double, installments: [AstraInvestmentTransaction])
                if mode == .sip {
                    result = await StockService.shared.calculateHistoricalSIPUnits(
                        symbol: symbol,
                        monthlyAmount: updated.investmentAmount,
                        startDate: updated.startDate
                    )
                } else {
                    result = await StockService.shared.calculateLumpsumUnits(
                        symbol: symbol,
                        amount: updated.investmentAmount,
                        startDate: updated.startDate
                    )
                }

                updated.installments = result.installments
                updated.quantity = result.totalUnits
                updated.units = type == .goldETF ? result.totalUnits : updated.units

                if let live = await StockService.shared.fetchPrice(symbol: symbol), live.currentPrice > 0 {
                    updated.livePrice = live.currentPrice
                    updated.lastNAV = live.currentPrice
                    updated.priceChange = live.priceChange
                    updated.priceChangePercentage = live.priceChangePercentage
                    updated.lastUpdated = Date()
                } else if let fallbackRate = result.installments.last?.nav {
                    updated.livePrice = fallbackRate
                    updated.lastNAV = fallbackRate
                }
            } else {
                updated.units = Double(units)
            }

            if let avg = weightedAverageRate(from: updated.installments) {
                updated.purchaseNAV = avg
            }
        } else {
            if type == .mutualFund || type == .goldETF {
                updated.units = Double(units)
            }
        }

        appState.updateInvestment(updated)
        dismiss()
    }

    private func weightedAverageRate(from installments: [AstraInvestmentTransaction]) -> Double? {
        let totalAmount = installments.reduce(0.0) { $0 + $1.amount }
        let totalUnits = installments.reduce(0.0) { $0 + $1.units }
        guard totalUnits > 0 else { return nil }
        return totalAmount / totalUnits
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
