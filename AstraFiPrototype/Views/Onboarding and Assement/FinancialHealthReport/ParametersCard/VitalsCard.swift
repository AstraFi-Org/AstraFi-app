//
//  VitalsCard.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI

struct VitalsCard: View {
    @Binding var period: FinancialHealthReportView.VitalsPeriod
    let income: String; let expenses: String; let cashflow: CashflowEntry?

    private let segColors: [Color] = [
        Color(hex: "#5E5CE6"), Color(hex: "#32ADE6"),
        Color(hex: "#FF453A"), Color(hex: "#30D158"), Color(hex: "#FF9F0A")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total \(period == .monthly ? "Expenses" : "Yearly Expenses")")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Text("₹\(expenses)").font(.title2).bold()
                }
                Spacer()
                HStack(spacing: 4) {
                    Picker("", selection: $period) {
                        ForEach(FinancialHealthReportView.VitalsPeriod.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    .pickerStyle(.segmented).frame(width: 160)
                    Image(systemName: "chevron.right").font(.caption).fontWeight(.semibold).foregroundStyle(.tertiary)
                }
            }
            HStack {
                Label {
                    Text("Net Income").font(.subheadline).foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(Color(hex: "#30D158")).font(.system(size: 15))
                }
                Spacer()
                Text("₹\(income)").font(.subheadline).fontWeight(.semibold)
            }
            .padding(12)
            .background(Color(hex: "#30D158").opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            if let cf = cashflow, cf.total > 0 {
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        ForEach(Array(cf.breakdown.enumerated()), id: \.offset) { idx, item in
                            let ratio = cf.total > 0 ? item.1 / cf.total : 0
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(segColors[idx % segColors.count])
                                .frame(width: max(4, geo.size.width * ratio))
                        }
                    }
                }
                .frame(height: 10)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(Array(cf.breakdown.enumerated()), id: \.offset) { idx, item in
                        HStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 3).fill(segColors[idx % segColors.count]).frame(width: 8, height: 8)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.0).font(.caption).fontWeight(.semibold)
                                    .foregroundStyle(segColors[idx % segColors.count]).lineLimit(1)
                                Text("₹\(Int(item.1).formatted())").font(.subheadline).bold()
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(18).background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
    }
}
