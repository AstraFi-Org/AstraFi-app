//
//  EmergencyFundInsightSheet.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI

struct EmergencyFundInsightSheet: View {
    @Environment(\.dismiss) private var dismiss
    let insights: FinancialAssessmentInsights

    // Step 1: Ask where funds are
    @State private var step: Int = 0  // 0 = question, 1 = analysis
    @State private var savingsAccount: String = ""
    @State private var fd: String = ""
    @State private var liquidMF: String = ""
    @State private var other: String = ""
    @State private var noneAllocated: Bool = false

    private var declaredTotal: Double {
        (Double(savingsAccount.filter { $0.isNumber }) ?? 0) +
        (Double(fd.filter { $0.isNumber }) ?? 0) +
        (Double(liquidMF.filter { $0.isNumber }) ?? 0) +
        (Double(other.filter { $0.isNumber }) ?? 0)
    }

    private var target: Double { insights.emergencyFundTarget }
    private var current: Double { insights.emergencyFundAmount }
    private var progress: Double { target > 0 ? min(1, current / target) : 0 }

    private var liquidityScore: String {
        let liq = (Double(liquidMF.filter { $0.isNumber }) ?? 0) +
                  (Double(savingsAccount.filter { $0.isNumber }) ?? 0)
        let pct = declaredTotal > 0 ? liq / declaredTotal : 0
        return pct >= 0.5 ? "Good" : pct >= 0.25 ? "Fair" : "Poor"
    }
    private var liquidityColor: Color {
        liquidityScore == "Good" ? Color(hex: "#30D158") : liquidityScore == "Fair" ? Color(hex: "#FF9F0A") : Color(hex: "#FF453A")
    }

    private var allocationAdvice: String {
        let fdAmt    = Double(fd.filter { $0.isNumber }) ?? 0
        let liqMF    = Double(liquidMF.filter { $0.isNumber }) ?? 0
        let savings  = Double(savingsAccount.filter { $0.isNumber }) ?? 0

        if noneAllocated {
            return "Start by parking at least \(target.toCurrency(compact: true)) in a high-yield savings account or liquid mutual fund. These are instantly accessible and earn more than a regular account."
        }
        if fdAmt > declaredTotal * 0.7 {
            return "Over 70% of your emergency fund is in Fixed Deposits, which have lock-in periods and premature withdrawal penalties. Shift at least 40% to a liquid mutual fund or sweep-in FD for faster access."
        }
        if liqMF + savings >= declaredTotal * 0.5 {
            return "Your allocation looks good — over half is in highly liquid instruments. Consider moving the rest to a sweep-in FD to earn better returns while keeping instant access."
        }
        return "Diversify your emergency fund: 50% in savings/liquid MF for instant access, 30% in sweep-in FD, and 20% in a short-duration debt fund for better returns."
    }

    // MARK: - Sub-views

    private var headerView: some View {
        Section {
            HStack(spacing: 14) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.title2).foregroundStyle(Color(hex: "#32ADE6"))
                    .frame(width: 52, height: 52)
                    .background(Color(hex: "#32ADE6").opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Emergency Fund").font(.title3).bold()
                    Text(step == 0 ? "Tell us where your fund is kept" : "Fund analysis & recommendations")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }
        }
        .listRowBackground(Color.clear).listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 16, leading: 20, bottom: 12, trailing: 20))
    }

    private var currentStatusSection: some View {
        Section(header: Text("Current Fund Status").font(.footnote).textCase(.uppercase)) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Emergency Corpus").font(.subheadline).foregroundStyle(.secondary)
                    Text(current.toCurrency(compact: false)).font(.title2).bold()
                }
                Spacer()
                Text("\(Int(progress * 100))% of target")
                    .font(.caption).bold()
                    .foregroundStyle(progress >= 1 ? Color(hex: "#30D158") : progress >= 0.5 ? Color(hex: "#FF9F0A") : Color(hex: "#FF453A"))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background((progress >= 1 ? Color(hex: "#30D158") : progress >= 0.5 ? Color(hex: "#FF9F0A") : Color(hex: "#FF453A")).opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(.vertical, 4)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(UIColor.tertiarySystemFill)).frame(height: 8)
                    Capsule()
                        .fill(progress >= 1 ? Color(hex: "#30D158") : progress >= 0.5 ? Color(hex: "#FF9F0A") : Color(hex: "#FF453A"))
                        .frame(width: max(8, geo.size.width * progress), height: 8)
                }
            }
            .frame(height: 8)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 12, trailing: 16))

            HStack {
                Text("Target (6× income)").font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                Text(target.toCurrency(compact: false)).font(.subheadline).bold()
            }
        }
    }

    private var allocationQuestionSection: some View {
        Section(header: Text("Where is your emergency fund kept?").font(.footnote).textCase(.uppercase)) {
            Toggle(isOn: $noneAllocated) {
                Label("Not allocated yet", systemImage: "tray.fill")
                    .font(.subheadline)
            }
            .onChange(of: noneAllocated) { _, val in
                if val { savingsAccount = ""; fd = ""; liquidMF = ""; other = "" }
            }

            if !noneAllocated {
                AllocationInputRow(icon: "building.columns.fill", color: Color(hex: "#007AFF"),
                                   label: "Savings / Current Account", value: $savingsAccount)
                AllocationInputRow(icon: "lock.fill", color: Color(hex: "#30D158"),
                                   label: "Fixed Deposit (FD / RD)", value: $fd)
                AllocationInputRow(icon: "chart.pie.fill", color: Color(hex: "#FF9F0A"),
                                   label: "Liquid Mutual Fund", value: $liquidMF)
                AllocationInputRow(icon: "ellipsis.circle.fill", color: .secondary,
                                   label: "Other instruments", value: $other)
            }
        }
    }

    private var analyzeButtonSection: some View {
        Section {
            Button(action: { withAnimation { step = 1 } }) {
                HStack {
                    Spacer()
                    Text("Analyse My Allocation")
                        .font(.headline).fontWeight(.semibold).foregroundStyle(.white)
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(Color(hex: "#007AFF"))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
    }

    private var fundCoverageSection: some View {
        Section(header: Text("Fund Coverage").font(.footnote).textCase(.uppercase)) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Target").font(.subheadline).foregroundStyle(.secondary)
                    Text(target.toCurrency(compact: false)).font(.headline)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Shortfall").font(.subheadline).foregroundStyle(.secondary)
                    let gap = max(0, target - current)
                    Text(gap > 0 ? "−\(gap.toCurrency(compact: true))" : "Fully funded")
                        .font(.headline)
                        .foregroundStyle(gap > 0 ? Color(hex: "#FF453A") : Color(hex: "#30D158"))
                }
            }
            .padding(.vertical, 4)
        }
    }

//    private var yourAllocationSection: some View {
//        Group {
//            if !noneAllocated && declaredTotal > 0 {
//                Section(header: Text("Your Allocation").font(.footnote).textCase(.uppercase)) {
//                    ForEach([
//                        ("Savings / Current A/C", Double(savingsAccount.filter { $0.isNumber }) ?? 0, Color(hex: "#007AFF")),
//                        ("Fixed Deposit",          Double(fd.filter { $0.isNumber }) ?? 0,            Color(hex: "#30D158")),
//                        ("Liquid Mutual Fund",     Double(liquidMF.filter { $0.isNumber }) ?? 0,      Color(hex: "#FF9F0A")),
//                        ("Other",                  Double(other.filter { $0.isNumber }) ?? 0,         Color.secondary),
//                    ].filter { $0.1 > 0 }, id: \.0) { name, amt, color in
////                        AllocationBarRow(label: name, amount: amt, total: declaredTotal, color: color)
//                    }
//
//                    HStack {
//                        Image(systemName: "gauge.with.dots.needle.bottom.50percent")
//                            .font(.subheadline).foregroundStyle(liquidityColor)
//                        Text("Liquidity Score").font(.subheadline)
//                        Spacer()
//                        Text(liquidityScore).font(.subheadline).bold().foregroundStyle(liquidityColor)
//                            .padding(.horizontal, 10).padding(.vertical, 4)
//                            .background(liquidityColor.opacity(0.1)).clipShape(Capsule())
//                    }
//                    .padding(.vertical, 4)
//                }
//            }
//        }
//    }

    private var recommendationsSection: some View {
        Section(header: Text("Recommendation").font(.footnote).textCase(.uppercase)) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb.fill").font(.subheadline)
                    .foregroundStyle(Color(hex: "#FF9F0A")).padding(.top, 1)
                Text(allocationAdvice).font(.subheadline).foregroundStyle(.secondary).lineSpacing(4)
            }
            .padding(14).background(Color(hex: "#FF9F0A").opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

            // Ideal split guide
            VStack(alignment: .leading, spacing: 10) {
                Text("Ideal Allocation Split").font(.subheadline).bold()
                IdealSplitRow(label: "Savings / Liquid MF", percent: 50, color: Color(hex: "#007AFF"), reason: "Instant access, 0 penalty")
                IdealSplitRow(label: "Sweep-in FD",         percent: 30, color: Color(hex: "#30D158"), reason: "Better returns, same-day access")
                IdealSplitRow(label: "Short Duration Debt",  percent: 20, color: Color(hex: "#FF9F0A"), reason: "Higher yield, T+1 redemption")
            }
            .padding(14)
        }
    }

    private var actionItemsSection: some View {
        Group {
            if !insights.activeConcerns.filter({ $0.parameter == .emergencyFund }).isEmpty {
                Section(header: Text("Action Items").font(.footnote).textCase(.uppercase)) {
                    ForEach(insights.activeConcerns.filter { $0.parameter == .emergencyFund }) { concern in
                        ConcernCard(concern: concern)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(Color.clear).listRowSeparator(.hidden)
                    }
                }
            }
        }
    }

    private var updateButtonSection: some View {
        Section {
            Button(action: { withAnimation { step = 0 } }) {
                Label("Update Allocation", systemImage: "arrow.left")
                    .font(.subheadline).foregroundStyle(Color(hex: "#007AFF"))
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                headerView

                if step == 0 {
                    currentStatusSection
                    allocationQuestionSection
                    analyzeButtonSection
                } else {
                    fundCoverageSection
                    //yourAllocationSection
                    recommendationsSection
                    actionItemsSection
                    updateButtonSection
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Emergency Fund")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }
}

