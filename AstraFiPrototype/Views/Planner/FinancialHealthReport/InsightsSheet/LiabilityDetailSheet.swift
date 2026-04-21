//
//  LiabilityDetailSheet.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI

struct LiabilityDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let insights: FinancialAssessmentInsights
    let concerns: [AssessmentConcern]

    private var dtiColor: Color {
        insights.debtToIncomeRatio >= 0.45 ? Color(hex: "#FF453A")
            : insights.debtToIncomeRatio >= 0.30 ? Color(hex: "#FF9F0A")
            : Color(hex: "#30D158")
    }
    private var dtiLabel: String {
        insights.debtToIncomeRatio >= 0.45 ? "Stressed" : insights.debtToIncomeRatio >= 0.30 ? "Moderate" : "Healthy"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: "creditcard.fill")
                            .font(.title2).foregroundStyle(Color(hex: "#BF5AF2"))
                            .frame(width: 52, height: 52)
                            .background(Color(hex: "#BF5AF2").opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Liability & Debt Health").font(.title3).bold()
                            Text("Debt load and repayment capacity").font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                }
                .listRowBackground(Color.clear).listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 16, leading: 20, bottom: 12, trailing: 20))

                Section(header: Text("Key Metrics").font(.footnote).textCase(.uppercase)) {
                    // Active loans
                    HStack {
                        Label("Active Loans", systemImage: "list.bullet.rectangle").font(.subheadline)
                        Spacer()
                        Text("\(insights.loanCount)").font(.title3).bold()
                            .foregroundStyle(insights.loanCount > 0 ? Color(hex: "#BF5AF2") : Color(hex: "#30D158"))
                    }
                    .padding(.vertical, 4)

                    // Debt-to-income gauge
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Debt-to-Income Ratio").font(.subheadline)
                            Spacer()
                            Text("\(Int(insights.debtToIncomeRatio * 100))%").font(.subheadline).bold().foregroundStyle(dtiColor)
                            Text(dtiLabel).font(.caption).bold().foregroundStyle(dtiColor)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(dtiColor.opacity(0.1)).clipShape(Capsule())
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color(UIColor.tertiarySystemFill)).frame(height: 8)
                                // Zones
                                Capsule().fill(Color(hex: "#30D158").opacity(0.3)).frame(width: geo.size.width * 0.3, height: 8)
                                Capsule()
                                    .fill(LinearGradient(colors: [Color(hex: "#30D158"), Color(hex: "#FF9F0A"), Color(hex: "#FF453A")],
                                                         startPoint: .leading, endPoint: .trailing))
                                    .opacity(0.2).frame(height: 8)
                                // Indicator
                                Capsule().fill(dtiColor)
                                    .frame(width: max(8, geo.size.width * min(1, insights.debtToIncomeRatio)), height: 8)
                                // Benchmark marker
                                Rectangle().fill(Color.secondary.opacity(0.5))
                                    .frame(width: 2, height: 14)
                                    .offset(x: geo.size.width * 0.3 - 1, y: -3)
                            }
                        }
                        .frame(height: 8)
                        HStack {
                            Text("Safe zone").font(.caption2).foregroundStyle(.secondary)
                            Spacer()
                            Text("30% benchmark").font(.caption2).foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 2)
                    }
                    .padding(.vertical, 6)
                }

                Section {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lightbulb.fill").font(.subheadline)
                            .foregroundStyle(Color(hex: "#FF9F0A")).padding(.top, 1)
                        Text(insights.loanCount == 0
                             ? "Zero debt gives you maximum financial leverage. Explore Plan 3 (Leveraged Investing) to build wealth using structured credit at a rate lower than your investment return."
                             : "Paying even 5% extra on your EMI principal monthly can save you lakhs in interest and clear your debt years earlier. Use the Planner's pre-payment simulator to see the impact.")
                            .font(.subheadline).foregroundStyle(.secondary).lineSpacing(4)
                    }
                    .padding(14).background(Color(hex: "#FF9F0A").opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                if !concerns.isEmpty {
                    Section(header: Text("Action Items").font(.footnote).textCase(.uppercase)) {
                        ForEach(concerns) { concern in
                            ConcernCard(concern: concern)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(Color.clear).listRowSeparator(.hidden)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Liability & Debt Health")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.fontWeight(.semibold) } }
        }
    }
}
