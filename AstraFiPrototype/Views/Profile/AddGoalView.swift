import SwiftUI

struct AddGoalView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppStateManager.self) var appState

    @State private var goalName = ""
    @State private var targetAmount = ""
    @State private var targetDate = Date().addingTimeInterval(60 * 60 * 24 * 365)

    @State private var linkInvestment = false

    @State private var invName = ""
    @State private var invType: AstraInvestmentType = .mutualFund
    @State private var invMode: AstraInvestmentMode = .sip
    @State private var invAmount = ""
    @State private var invStartDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                goalSection
                investmentToggleSection
                if linkInvestment { investmentSection }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
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
                    Button(action: saveGoal) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(goalName.isEmpty || targetAmount.isEmpty || (linkInvestment && (invName.isEmpty || invAmount.isEmpty)) ? Color.gray : .blue)
                            .clipShape(Circle())
                    }
                    .disabled(goalName.isEmpty || targetAmount.isEmpty || (linkInvestment && (invName.isEmpty || invAmount.isEmpty)))
                }
            }
        }
    }

    private func saveGoal() {
        let amount = Double(targetAmount) ?? 0
        let newGoal = AstraGoal(goalName: goalName, targetAmount: amount, currentAmount: 0, startDate: Date(), targetDate: targetDate)
        appState.addGoal(newGoal)

        if linkInvestment, !invName.isEmpty, let invAmt = Double(invAmount) {
            let newInv = AstraInvestment(
                investmentType: invType,
                subtype: nil,
                investmentName: invName,
                investmentAmount: invAmt,
                startDate: invStartDate,
                associatedGoalID: newGoal.id,
                mode: invMode
            )
            appState.addInvestment(newInv)
        }
        dismiss()
    }

    private var goalSection: some View {
        Section(header: Text("Goal Details")) {
            TextField("Goal Name (e.g. Dream Car)", text: $goalName)
            HStack {
                Text("₹")
                TextField("Target Amount", text: $targetAmount).keyboardType(.decimalPad)
            }
            DatePicker("Target Date", selection: $targetDate, displayedComponents: .date)
        }
    }

    private var investmentToggleSection: some View {
        Section(header: Text("Linked Investment")) {
            Toggle("Start an Investment for this Goal", isOn: $linkInvestment)
            if !linkInvestment {
                Text("Link a SIP or Lumpsum investment directly to this goal so your savings are tracked automatically.")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
    }

    private var investmentSection: some View {
        Section(header: Text("Investment Details")) {
            TextField("Investment / Fund Name", text: $invName)

            Picker("Investment Type", selection: $invType) {
                ForEach(AstraInvestmentType.allCases, id: \.self) { t in
                    Text(t.rawValue).tag(t)
                }
            }

            Picker("Mode", selection: $invMode) {
                Text("SIP (Monthly)").tag(AstraInvestmentMode.sip)
                Text("Lumpsum").tag(AstraInvestmentMode.lumpsum)
            }
            .pickerStyle(.segmented)

            HStack {
                Text("₹")
                TextField(invMode == .sip ? "Monthly SIP Amount" : "Lumpsum Amount", text: $invAmount)
                    .keyboardType(.decimalPad)
                if invMode == .sip { Text("/month").foregroundColor(.secondary).font(.caption) }
            }

            DatePicker("Investment Start Date", selection: $invStartDate, displayedComponents: .date)
        }
    }

}

#Preview {
    AddGoalView()
        .environment(AppStateManager.withSampleData())
}
