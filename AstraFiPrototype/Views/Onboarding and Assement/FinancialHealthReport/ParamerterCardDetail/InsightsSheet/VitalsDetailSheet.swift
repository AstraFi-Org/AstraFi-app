//
//  VitalsDetailSheet.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI

struct VitalsDetailSheet: View {
    let income: Double
    let expenses: Double
    let savings: Double
    let ratio: Double
    let concerns: [AssessmentConcern]

    private var savingsColor: Color {
        ratio >= 0.3 ? Color(hex: "#30D158") : ratio >= 0.2 ? Color(hex: "#FF9F0A") : Color(hex: "#FF453A")
    }

    var body: some View {
        List {

                // Key metrics — each in its own grouped row
                Section(header: Text("Monthly Snapshot").font(.footnote).textCase(.uppercase)) {
                    VitalsMetricRow(
                        label: "Monthly Income",
                        value: income.toCurrency(compact: false),
                        barValue: 1.0,
                        barColor: Color(hex: "#30D158"),
                        icon: "arrow.down.circle.fill",
                        iconColor: Color(hex: "#30D158")
                    )
                    VitalsMetricRow(
                        label: "Monthly Expenses",
                        value: expenses.toCurrency(compact: false),
                        barValue: income > 0 ? min(1, expenses / income) : 0,
                        barColor: expenses > income * 0.7 ? Color(hex: "#FF453A") : Color(hex: "#FF9F0A"),
                        icon: "arrow.up.circle.fill",
                        iconColor: Color(hex: "#FF453A")
                    )
                    VitalsMetricRow(
                        label: "Monthly Savings",
                        value: savings.toCurrency(compact: false),
                        barValue: min(1, ratio / 0.3),
                        barColor: savingsColor,
                        icon: "banknote.fill",
                        iconColor: savingsColor
                    )
                }

                // Savings rate pill
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Savings Rate").font(.subheadline).foregroundStyle(.secondary)
                            Text("\((ratio * 100).safeInt)% of income").font(.title3).bold().foregroundStyle(savingsColor)
                        }
                        Spacer()
                        ZStack {
                            Circle().trim(from: 0, to: min(1, ratio / 0.3))
                                .stroke(savingsColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            Circle().stroke(savingsColor.opacity(0.15), lineWidth: 5)
                            Text("\((ratio * 100).safeInt)%").font(.caption).bold().foregroundStyle(savingsColor)
                        }
                        .frame(width: 56, height: 56)
                    }
                    .padding(.vertical, 4)

                    // Benchmark callout
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: ratio >= 0.3 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(ratio >= 0.3 ? Color(hex: "#30D158") : Color(hex: "#FF9F0A"))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(ratio >= 0.3 ? "Above the 30% benchmark" : ratio >= 0.2 ? "Near the 20% benchmark" : "Below the 20% benchmark")
                                .font(.subheadline).bold()
                                .foregroundStyle(ratio >= 0.3 ? Color(hex: "#30D158") : Color(hex: "#FF9F0A"))
                            Text(ratio >= 0.2
                                 ? "Channel these savings into goal-linked investments to build long-term wealth."
                                 : "Trim discretionary expenses and auto-transfer savings to hit 20% first.")
                                .font(.subheadline).foregroundStyle(.secondary).lineSpacing(3)
                        }
                    }
                    .padding(14).background(savingsColor.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                // Action items
                if !concerns.isEmpty {
                    Section(header: Text("Action Items").font(.footnote).textCase(.uppercase)) {
                        ForEach(concerns) { concern in
                            ConcernCard(concern: concern)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Financial Vitals")
            .navigationBarTitleDisplayMode(.inline)
    }
}
