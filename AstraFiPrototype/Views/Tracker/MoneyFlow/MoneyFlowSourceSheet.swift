//
//  MoneyFlowSourceSheet.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI

struct MoneyFlowSourceSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppStateManager.self) var appState

    @State private var incomeSources:  [CashflowEntry.DetailedItem] = []
    @State private var expenseSources: [CashflowEntry.DetailedItem] = []
    @State private var newIncomeName   = ""
    @State private var newIncomeAmount = ""
    @State private var newExpenseName  = ""
    @State private var newExpenseAmount = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // Income
                        sourceSection(
                            title: "Income Sources",
                            icon: "arrow.down.circle.fill",
                            color: Color(hex: "#30D158"),
                            sources: $incomeSources,
                            newName: $newIncomeName,
                            newAmount: $newIncomeAmount
                        ) {
                            addSource(to: &incomeSources,
                                      name: &newIncomeName,
                                      amount: &newIncomeAmount)
                        }

                        // Expenses
                        sourceSection(
                            title: "Expense Sources",
                            icon: "arrow.up.circle.fill",
                            color: Color(hex: "#FF453A"),
                            sources: $expenseSources,
                            newName: $newExpenseName,
                            newAmount: $newExpenseAmount
                        ) {
                            addSource(to: &expenseSources,
                                      name: &newExpenseName,
                                      amount: &newExpenseAmount)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Update Money Flow")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveData(); dismiss() }
                        .fontWeight(.bold)
                }
            }
            .onAppear { loadData() }
        }
    }

    // MARK: Section builder
    @ViewBuilder
    private func sourceSection(
        title: String,
        icon: String,
        color: Color,
        sources: Binding<[CashflowEntry.DetailedItem]>,
        newName: Binding<String>,
        newAmount: Binding<String>,
        onAdd: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)

            // Rows
            VStack(spacing: 0) {
                ForEach(sources) { $source in
                    SourceRow(name: $source.name, amount: $source.amount)
                    if source.id != sources.wrappedValue.last?.id {
                        Divider().padding(.leading, 16)
                    }
                }

                Divider().padding(.leading, 16)

                // Add row
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(color)
                    TextField("Source name", text: newName)
                        .font(.body)
                    Spacer()
                    HStack(spacing: 2) {
                        Text("₹")
                            .foregroundStyle(.secondary)
                        TextField("0", text: newAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 90)
                    }
                    .font(.body.weight(.semibold))
                    Button(action: onAdd) {
                        Text("Add")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(color)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // MARK: Helpers
    private func addSource(to list: inout [CashflowEntry.DetailedItem],
                           name: inout String, amount: inout String) {
        guard let amt = Double(amount), !name.isEmpty else { return }
        list.append(.init(name: name, amount: amt))
        name = ""; amount = ""
    }

    private func loadData() {
        if let cf = appState.currentProfile?.cashflowData {
            incomeSources  = cf.incomeSources
            expenseSources = cf.expenseSources
        }
        if incomeSources.isEmpty {
            incomeSources  = [.init(name: "Job", amount: 0),
                               .init(name: "Rent from tenants", amount: 0)]
        }
        if expenseSources.isEmpty {
            expenseSources = [.init(name: "Daily Household", amount: 0),
                               .init(name: "Entertainment", amount: 0),
                               .init(name: "Transport", amount: 0)]
        }
    }

    private func saveData() {
        var cf = appState.currentProfile?.cashflowData ?? CashflowEntry()
        cf.incomeSources  = incomeSources.filter  { $0.amount > 0 }
        cf.expenseSources = expenseSources.filter { $0.amount > 0 }
        appState.updateCashflow(cf)

//        if var profile = appState.currentProfile {
//            let df = DateFormatter(); df.dateFormat = "yyyy-MM"
//            profile.monthlyCashflowSnapshots[df.string(from: Date())] = cf
//            appState.currentProfile = profile
//        }
    }
}



struct SourceRow: View {
    @Binding var name: String
    @Binding var amount: Double
    
    var body: some View {
        HStack {
            TextField("Name", text: $name)
                .font(.body)
            Spacer()
            HStack(spacing: 4) {
                Text("₹").foregroundStyle(.secondary)
                TextField("0", value: $amount, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
            }
            .font(.body.weight(.semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

struct AddSourceRow: View {
    @Binding var name: String
    @Binding var amount: String
    let onAdd: () -> Void

    var body: some View {
        HStack {
            TextField("Source Name", text: $name)
                .font(.body).foregroundColor(.secondary)
            TextField("Amount", text: $amount)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue).font(.title3)
            }
        }
        .padding()
    }
}
