import SwiftUI

struct AddInvestmentView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppStateManager.self) var appState

    @State private var name = ""
    @State private var type: AstraInvestmentType = .mutualFund
    @State private var amount = ""
    @State private var units = ""
    @State private var mode: AstraInvestmentMode = .sip
    @State private var startDate = Date()
    @State private var selectedGoalID: UUID? = nil

    @State private var searchResults: [MFScheme] = []
    @State private var selectedSchemeCode: String?
    @State private var selectedISIN: String?
    @State private var showSearch = false
    @State private var isCalculatingUnits = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Investment Details")) {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Fund / Investment Name", text: $name)
                            .onChange(of: name) { _, newValue in
                                if type == .mutualFund && !newValue.isEmpty && selectedSchemeCode == nil {
                                    searchResults = MFService.shared.searchSchemes(query: newValue)
                                    showSearch = !searchResults.isEmpty
                                } else {
                                    showSearch = false
                                }
                            }

                        if showSearch && type == .mutualFund {
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 10) {
                                    ForEach(searchResults) { scheme in
                                        Button {
                                            name = scheme.name
                                            selectedSchemeCode = scheme.schemeCode
                                            selectedISIN = scheme.isin
                                            showSearch = false
                                        } label: {
                                            VStack(alignment: .leading) {
                                                Text(scheme.name)
                                                    .font(.subheadline)
                                                    .foregroundColor(.primary)
                                                Text("NAV: ₹\(String(format: "%.2f", scheme.nav)) | \(scheme.isin)")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(.vertical, 4)
                                        }
                                        Divider()
                                    }
                                }
                                .padding(.horizontal, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            .frame(maxHeight: 200)
                        }
                    }

                    Picker("Investment Type", selection: $type) {
                        ForEach(AstraInvestmentType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }

                    Picker("Mode", selection: $mode) {
                        Text("SIP (Monthly)").tag(AstraInvestmentMode.sip)
                        Text("Lumpsum").tag(AstraInvestmentMode.lumpsum)
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text("₹")
                        TextField(mode == .sip ? "Monthly SIP Amount" : "Lumpsum Amount", text: $amount)
                            .keyboardType(.decimalPad)
                        if mode == .sip { Text("/month").foregroundColor(.secondary).font(.caption) }
                    }

                    if type == .mutualFund {
                        HStack {
                            TextField("Units", text: $units)
                                .keyboardType(.decimalPad)
                            if isCalculatingUnits {
                                ProgressView()
                                    .scaleEffect(0.6)
                            }
                        }
                    }

                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                }

                if let goals = appState.currentProfile?.goals, !goals.isEmpty {
                    Section(header: Text("Link to a Goal (Optional)")) {
                        Picker("Goal", selection: $selectedGoalID) {
                            Text("None").tag(Optional<UUID>(nil))
                            ForEach(goals) { g in
                                Text(g.goalName).tag(Optional(g.id))
                            }
                        }
                    }
                }

            }
            .navigationTitle("New Investment")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: startDate) { _, _ in if type == .mutualFund { performAutoCalculation() } }
            .onChange(of: amount) { _, _ in if type == .mutualFund { performAutoCalculation() } }
            .onChange(of: selectedSchemeCode) { _, _ in if type == .mutualFund { performAutoCalculation() } }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveInvestment) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .disabled(name.isEmpty || amount.isEmpty)
                    .tint(
                        name.isEmpty || amount.isEmpty ? Color.gray : Color.blue
                    )
                }
                .sharedBackgroundVisibility(.visible)
            }
        }
    }

    private func saveInvestment() {
        let newInv = AstraInvestment(
            investmentType: type,
            subtype: nil,
            investmentName: name,
            investmentAmount: Double(amount) ?? 0,
            startDate: startDate,
            associatedGoalID: selectedGoalID,
            mode: mode,
            schemeCode: selectedSchemeCode,
            isin: selectedISIN,
            lastNAV: nil, 
            lastUpdated: nil,
            units: Double(units),
            purchaseNAV: (Double(amount) ?? 0) / (Double(units) ?? 1)
        )
        appState.addInvestment(newInv)
        dismiss()
    }

    private func performAutoCalculation() {
        guard let code = selectedSchemeCode, let amt = Double(amount), amt > 0 else { return }

        isCalculatingUnits = true
        Task {
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

#Preview {
    AddInvestmentView()
        .environment(AppStateManager.withSampleData())
}
