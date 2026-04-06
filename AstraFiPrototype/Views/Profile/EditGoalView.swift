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
                            Text("Collected So Far (₹)").font(.footnote).foregroundColor(.secondary)
                            TextField("Current Amount", text: $collectedAmount)
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

                let linked = appState.currentProfile?.investments.filter { $0.associatedGoalID == goal.id } ?? []
                if !linked.isEmpty {
                    Section(header: Text("Linked Investments (\(linked.count))")) {
                        ForEach(linked) { inv in
                            Button(action: {
                                selectedInvestment = inv
                                showingInvestmentEditor = true
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(inv.investmentName).font(.subheadline).fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text(inv.investmentType.rawValue).font(.caption)
                                            .padding(.horizontal, 8).padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.1)).cornerRadius(4)
                                    }
                                    HStack {
                                        Label(inv.mode == .sip ? "SIP ₹\(Int(inv.investmentAmount))/mo" : "Lumpsum \(inv.investmentAmount.toCurrency())", systemImage: inv.mode == .sip ? "repeat" : "arrow.down")
                                            .font(.caption).foregroundColor(.secondary)
                                        Spacer()
                                        Text("Since \(inv.startDate.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.caption2).foregroundColor(.secondary)
                                        Image(systemName: "chevron.right").font(.caption2).foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

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
        g.currentAmount = Double(collectedAmount) ?? goal.currentAmount
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
        collectedAmount = String(format: "%.0f", goal.currentAmount)
        startDate = goal.startDate
        targetDate = goal.targetDate
    }
}

#Preview {
    EditGoalView(goal: AstraGoal(goalName: "New House", targetAmount: 5000000, currentAmount: 1200000, targetDate: Date().addingTimeInterval(86400 * 365 * 5)))
        .environment(AppStateManager.withSampleData())
}
