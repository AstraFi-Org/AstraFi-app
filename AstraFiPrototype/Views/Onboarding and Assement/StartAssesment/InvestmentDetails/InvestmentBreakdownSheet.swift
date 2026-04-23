//
//  InvestmentBreakdownSheet.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 22/04/26.
//

import SwiftUI

struct InvestmentBreakdownSheet: View {
    let entry: AssessmentInvestmentEntry
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Monthly SIP")
                        Spacer()
                        Text("₹\(entry.amount)")
                    }
                    HStack {
                        Text("Total Invested")
                        Spacer()
                        Text("₹\(String(format: "%.0f", entry.totalInvested ?? 0))")
                    }
                    HStack {
                        Text("Total Units")
                        Spacer()
                        Text(entry.quantity)
                    }
                } header: {
                    Text("Summary")
                }
                
                Section {
                    ForEach(entry.transactions.sorted(by: { $0.date > $1.date })) { tx in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(tx.date, style: .date).font(.subheadline).bold()
                                Text("NAV: ₹\(String(format: "%.2f", tx.nav))").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("₹\(String(format: "%.0f", tx.amount))").font(.subheadline).foregroundColor(.blue)
                                Text("\(String(format: "%.4f", tx.units)) Units").font(.caption).foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Installment History")
                }
            }
            .navigationTitle(entry.fundName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}


//#Preview {
//    InvestmentBreakdownSheet()
//}
