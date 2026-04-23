//
//  InvestmentStatsGrid.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI

struct InvestmentStatsGrid: View {
    let total: Int; let atRisk: Int

    private var stats: [(String, String, Color, String)] {[
        ("Total Investments", "\(total)", .primary, "briefcase.fill"),
        ("Active",            "\(total)", Color(hex: "#30D158"), "checkmark.circle.fill"),
        ("Closed",            "0",        .secondary, "xmark.circle.fill"),
        ("High Risk",         "\(atRisk)", Color(hex: "#FF453A"), "exclamationmark.triangle.fill"),
    ]}

    var body: some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 0) {
                ForEach(Array(stats.enumerated()), id: \.offset) { idx, stat in
                    HStack(spacing: 10) {
                        Image(systemName: stat.3).font(.subheadline).foregroundStyle(stat.2)
                            .frame(width: 28, height: 28)
                            .background((stat.2 == .primary || stat.2 == .secondary ? Color.gray : stat.2).opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stat.0).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            Text(stat.1).font(.title2).bold().foregroundStyle(stat.2)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .overlay(alignment: .trailing) {
                        if idx % 2 == 0 {
                            Rectangle().fill(Color(UIColor.separator).opacity(0.3))
                                .frame(width: 0.5).frame(maxHeight: .infinity).padding(.vertical, 8)
                        }
                    }
                }
            }
        }
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
    }
}
