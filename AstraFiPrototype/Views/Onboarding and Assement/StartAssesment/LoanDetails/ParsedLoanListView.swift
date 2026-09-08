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
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 12) {
                                Toggle("", isOn: $loan.isSelected)
                                    .labelsHidden()
                                    .tint(.blue)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(loan.lender ?? "Sanctioned Loan")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)

                                    if let scheme = loan.loanName, !scheme.isEmpty {
                                        Text(scheme)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    HStack(spacing: 6) {
                                        Text(loan.type.rawValue)
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(4)

                                        if loan.interestRate > 0 {
                                            Text("\(String(format: "%.2f", loan.interestRate))% (\(loan.interestRateType.rawValue))")
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

                                    if let emiVal = loan.emi, emiVal > 0 {
                                        Text("EMI: ₹\(String(format: "%.0f", emiVal))")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("EMI: Pending")
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                            }

                            // Period Breakdown Grid
                            HStack(spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Total Period")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.secondary)
                                    Text("\(loan.tenure) Mo")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                }
                                Spacer()
                                VStack(alignment: .center, spacing: 2) {
                                    Text("Moratorium")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.secondary)
                                    Text("\(loan.moratoriumMonths ?? 0) Mo")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(AppTheme.vibrantOrange)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Repayment")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.secondary)
                                    Text("\(loan.repaymentMonths ?? (loan.tenure - (loan.moratoriumMonths ?? 0))) Mo")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(AppTheme.auraGreen)
                                }
                            }
                            .padding(8)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(8)
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
                    Text("Detected Loans & Sanction Letters")
                } footer: {
                    Text("Verify extracted moratorium, repayment period, and sanctioned amount before importing.")
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
