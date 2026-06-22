//
//  RiskSheet.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI

struct RiskSheet: View {
    let insights: FinancialAssessmentInsights
    let concerns: [AssessmentConcern]

    private var breakdown: InvestmentRiskBreakdown { insights.investmentBreakdown }
    private var total: Double { breakdown.totalAmount }

    private var riskRows: [(String, Double, Color)] {
        [
            ("High Risk", breakdown.highRiskAmount, Color(hex: "#FF453A")),
            ("Medium Risk", breakdown.mediumRiskAmount, Color(hex: "#FF9F0A")),
            ("Low Risk", breakdown.lowRiskAmount, Color(hex: "#30D158")),
        ]
    }

    var body: some View {
        List {

                // Risk Breakdown
                Section(header: Text("Portfolio Breakdown").font(.footnote).textCase(.uppercase)) {
                    if insights.investmentCount == 0 {
                        HStack {
                            Image(systemName: "tray.fill").foregroundStyle(.secondary)
                            Text("No investments recorded yet").font(.subheadline).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                    } else {
                        ForEach(riskRows, id: \.0) { name, amount, color in
                            if total > 0 {
                                RiskAllocationRow(label: name, amount: amount, total: total, color: color)
                            }
                        }

                        // Donut-style visual
                        if total > 0 {
                            RiskDonutView(high: breakdown.highRiskRatio,
                                         medium: (breakdown.mediumRiskAmount / total),
                                         low: (breakdown.lowRiskAmount / total))
                                .frame(height: 160)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    }
                }

                // Diversification status
                Section {
                    let score = insights.investmentBalanceScore
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Diversification Score").font(.subheadline).foregroundStyle(.secondary)
                            Text(score >= 0.7 ? "Well Diversified" : score >= 0.5 ? "Moderate" : "Concentrated")
                                .font(.headline)
                                .foregroundStyle(score >= 0.7 ? Color(hex: "#30D158") : score >= 0.5 ? Color(hex: "#FF9F0A") : Color(hex: "#FF453A"))
                        }
                        Spacer()
                        Text("\((score * 100).safeInt)").font(.largeTitle).bold()
                            .foregroundStyle(score >= 0.7 ? Color(hex: "#30D158") : Color(hex: "#FF9F0A"))
                        Text("/100").font(.callout).foregroundStyle(.secondary).padding(.top, 10)
                    }
                    .padding(.vertical, 4)

                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lightbulb.fill").font(.subheadline).foregroundStyle(Color(hex: "#FF9F0A"))
                        Text(insights.investmentCount < 2
                             ? "You have limited diversification. Start with a low-risk debt or gold fund alongside equity."
                             : "Regularly rebalance between equity and debt based on market conditions and your goals.")
                            .font(.subheadline).foregroundStyle(.secondary).lineSpacing(3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14).background(Color(hex: "#FF9F0A").opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                if !concerns.isEmpty {
                    Section(header: Text("Action Items").font(.footnote).textCase(.uppercase)) {
                        ForEach(concerns) { concern in
                            ConcernCard(concern: concern)
                                .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                                .listRowBackground(Color.clear).listRowSeparator(.hidden)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Investment Risk")
            .navigationBarTitleDisplayMode(.inline)
    }
}
