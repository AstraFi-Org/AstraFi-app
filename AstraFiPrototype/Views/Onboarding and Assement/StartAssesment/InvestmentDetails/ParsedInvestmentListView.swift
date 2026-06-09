import SwiftUI

struct ParsedInvestmentListView: View {
    @Binding var investments: [ParsedInvestment]
    var onConfirm: () -> Void
    var onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach($investments) { $investment in
                        HStack(spacing: 12) {
                            Toggle("", isOn: $investment.isSelected)
                                .labelsHidden()
                                .tint(.blue)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(investment.fundName)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)

                                HStack(spacing: 8) {
                                    Text(investment.type)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)

                                    if let units = investment.units {
                                        Text("\(String(format: "%.2f", units)) Units")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                if let cv = investment.currentValue {
                                    Text("₹\(String(format: "%.0f", cv))")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.blue)
                                    
                                    Text("Cost: ₹\(String(format: "%.0f", investment.investedAmount))")
                                        .font(.system(size: 8))
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("₹\(String(format: "%.0f", investment.investedAmount))")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.blue)
                                }

                                if let isin = investment.isin {
                                    Text(isin)
                                        .font(.system(size: 8))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                if let index = investments.firstIndex(where: { $0.id == investment.id }) {
                                    investments.remove(at: index)
                                }
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text("Detected Investments")
                } footer: {
                    Text("Verify and select the investments you want to import.")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        onCancel()
                        dismiss()
                    }, label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.red)
                            
                    })

                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        onConfirm()
                        dismiss()
                    }, label: {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.white)
                            .padding(6.5)
                            .background(Color.blue)
                            .clipShape(Circle())
                            
                    })
                    .fontWeight(.bold)
                }
            }
        }
    }
}

#Preview {
    ParsedInvestmentListView(
        investments: .constant([
            ParsedInvestment(fundName: "Parag Parikh Flexi Cap", type: "Mutual Fund", investedAmount: 50000, currentValue: 65000, units: 120.5, mode: "SIP", dates: [Date()]),
            ParsedInvestment(fundName: "HDFC Top 100", type: "Mutual Fund", investedAmount: 25000, currentValue: 27000, units: 45.2, mode: "Lumpsum", dates: [Date()])
        ]),
        onConfirm: {},
        onCancel: {}
    )
}
