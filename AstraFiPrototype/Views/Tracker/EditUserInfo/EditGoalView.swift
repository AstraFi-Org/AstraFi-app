import SwiftUI

struct EditGoalView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppStateManager.self) var appState

    let goal: AstraGoal

    @State private var name = ""
    @State private var targetAmount = ""
    @State private var collectedAmount = ""
    @State private var startDate = Date()
    @State private var targetDate = Date()
    @State private var showingInvestmentEditor = false
    @State private var selectedInvestment: AstraInvestment?
    @State private var manualSavings = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 15) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Goal Name").font(.footnote).foregroundColor(.secondary)
                            TextField("e.g. Dream House", text: $name)
                                .textFieldStyle(.plain)
                        }
                        Divider()

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Target Amount (₹)").font(.footnote).foregroundColor(.secondary)
                            TextField("Total Amount", text: $targetAmount)
                                .keyboardType(.decimalPad)
                        }
                        Divider()

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Manual Savings Contribution (₹)").font(.footnote).foregroundColor(.secondary)
                            TextField("Amount", text: $manualSavings)
                                .keyboardType(.decimalPad)
                        }
                        Divider()

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Start Date").font(.footnote).foregroundColor(.secondary)
                            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                                .labelsHidden()
                        }
                        Divider()

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Target Date").font(.footnote).foregroundColor(.secondary)
                            DatePicker("Target Date", selection: $targetDate, displayedComponents: .date)
                                .labelsHidden()
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Goal Details")
                }

                linkedInvestmentsSection

            }
            .navigationTitle("Edit Goal")
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
                    Button(action: saveChanges) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(name.isEmpty || targetAmount.isEmpty ? Color.gray : .blue)
                            .clipShape(Circle())
                    }
                    .disabled(name.isEmpty || targetAmount.isEmpty)
                }
            }
            .onAppear(perform: setupInitial)
            .sheet(item: $selectedInvestment) { inv in
                 InvestmentUpdateView(investment: inv)
                    .environment(appState)
            }
        }
    }

    private func saveChanges() {
        var g = goal
        g.goalName = name
        g.targetAmount = Double(targetAmount) ?? goal.targetAmount
        g.manualSavingsContribution = Double(manualSavings) ?? goal.manualSavingsContribution
        g.startDate = startDate
        g.targetDate = targetDate
        appState.updateGoal(g)
        dismiss()
    }
}

extension EditGoalView {
    private func setupInitial() {
        name = goal.goalName
        targetAmount = String(format: "%.0f", goal.targetAmount)
        manualSavings = String(format: "%.0f", goal.manualSavingsContribution)
        startDate = goal.startDate
        targetDate = goal.targetDate
    }

    private var linkedInvestmentsSection: some View {
        let allInvestments = appState.currentProfile?.investments ?? []
        let linked = allInvestments.filter { $0.associatedGoalID == goal.id }
        let available = allInvestments.filter { $0.associatedGoalID == nil || $0.associatedGoalID == goal.id } // Only show unlinked or already linked
        
        return Section(header: Text("Linked Investments")) {
            if linked.isEmpty {
                Text("No investments linked to this goal.").font(.caption).foregroundColor(.secondary)
            } else {
                ForEach(linked) { inv in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(inv.investmentName).font(.subheadline).fontWeight(.medium)
                            Text(inv.investmentType.rawValue).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Unlink") {
                            var updatedInv = inv
                            updatedInv.associatedGoalID = nil
                            appState.updateInvestment(updatedInv)
                        }
                        .font(.caption).foregroundColor(.red)
                    }
                }
            }
            
            let otherAvailable = available.filter { $0.associatedGoalID == nil }
            if !otherAvailable.isEmpty {
                Divider()
                Text("Link Available Investments").font(.caption).foregroundColor(.secondary).padding(.top, 4)
                ForEach(otherAvailable) { inv in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(inv.investmentName).font(.subheadline).fontWeight(.medium)
                            Text(inv.investmentType.rawValue).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Link") {
                            var updatedInv = inv
                            updatedInv.associatedGoalID = goal.id
                            appState.updateInvestment(updatedInv)
                        }
                        .font(.caption).foregroundColor(.blue)
                    }
                }
            }
        }
    }
}

#Preview {
    EditGoalView(goal: AstraGoal(goalName: "New House", targetAmount: 5000000, currentAmount: 1200000, targetDate: Date().addingTimeInterval(86400 * 365 * 5)))
        .environment(AppStateManager.withSampleData())
}
