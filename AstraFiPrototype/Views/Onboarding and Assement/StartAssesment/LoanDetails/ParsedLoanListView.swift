import SwiftUI

struct ParsedLoanListView: View {
    @Binding var loans: [ParsedLoan]
    var onConfirm: () -> Void
    var onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach($loans) { $loan in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                Toggle("", isOn: $loan.isSelected)
                                    .labelsHidden()
                                    .tint(.blue)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(loan.lender ?? "Loan extracted")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)

                                    HStack(spacing: 8) {
                                        Text(loan.type.rawValue)
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(4)

                                        if loan.interestRate > 0 {
                                            Text("\(String(format: "%.2f", loan.interestRate))% p.a.")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("₹\(String(format: "%.0f", loan.amount))")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.blue)

                                    if loan.emi > 0 {
                                        Text("EMI: ₹\(String(format: "%.0f", loan.emi))")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }

                            // Requirement 10: Advanced Amortization Breakdown
                            if loan.totalInterestPaid != nil || loan.payoffTimelineMonths != nil {
                                 HStack {
                                     if let tip = loan.totalInterestPaid, tip > 0 {
                                         VStack(alignment: .leading) {
                                             Text("Total Interest")
                                                 .font(.system(size: 8))
                                                 .foregroundStyle(.secondary)
                                             Text("₹\(String(format: "%.0f", tip))")
                                                 .font(.caption2)
                                                 .fontWeight(.bold)
                                         }
                                     }
                                     
                                     Spacer()

                                     if let ptm = loan.payoffTimelineMonths, ptm > 0 {
                                         VStack(alignment: .trailing) {
                                             Text("Payoff Duration")
                                                 .font(.system(size: 8))
                                                 .foregroundStyle(.secondary)
                                             Text("\(ptm) Months")
                                                 .font(.caption2)
                                                 .fontWeight(.bold)
                                         }
                                     }
                                 }
                                 .padding(8)
                                 .background(Color.blue.opacity(0.05))
                                 .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 4)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                if let index = loans.firstIndex(where: { $0.id == loan.id }) {
                                    loans.remove(at: index)
                                }
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text("Detected Loans")
                } footer: {
                    Text("Verify and select the loans you want to import.")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import Selected") {
                        onConfirm()
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}

#Preview {
    ParsedLoanListView(
        loans: .constant([]),
        onConfirm: {},
        onCancel: {}
    )
}
