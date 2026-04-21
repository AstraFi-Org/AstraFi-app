import SwiftUI

struct InvestmentUpdateView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppStateManager.self) var appState
    let investment: AstraInvestment

    @State private var name = ""
    @State private var amount = ""
    @State private var mode: AstraInvestmentMode = .sip
    @State private var startDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Investment Details")) {
                    TextField("Investment Name", text: $name)
                    HStack {
                        Text("₹")
                        TextField("Amount", text: $amount).keyboardType(.decimalPad)
                        if mode == .sip { Text("/mo").foregroundColor(.secondary) }
                    }
                    Picker("Investment Mode", selection: $mode) {
                        Text("SIP").tag(AstraInvestmentMode.sip)
                        Text("Lumpsum").tag(AstraInvestmentMode.lumpsum)
                    }
                    .pickerStyle(.segmented)

                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                }

                Section {
                    Button("Update Investment") {
                        var inv = investment
                        inv.investmentName = name
                        inv.investmentAmount = Double(amount) ?? investment.investmentAmount
                        inv.mode = mode
                        inv.startDate = startDate
                        appState.updateInvestment(inv)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Update Investment")
            .onAppear {
                name = investment.investmentName
                amount = String(format: "%.0f", investment.investmentAmount)
                mode = investment.mode
                startDate = investment.startDate
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    InvestmentUpdateView(investment: AppStateManager.withSampleData().currentProfile!.investments[0])
        .environment(AppStateManager.withSampleData())
}
