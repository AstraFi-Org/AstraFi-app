//
//  RiskDonutView.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI
import Charts

private struct RiskDonutSlice: Identifiable {
    let name: String
    let value: Double
    let color: Color

    var id: String { name }
}

struct RiskDonutView: View {
    let high: Double; let medium: Double; let low: Double

    var body: some View {
        HStack(spacing: 24) {
            ZStack {
                Chart(riskSlices) { slice in
                    SectorMark(
                        angle: .value("Risk", slice.value),
                        innerRadius: .ratio(0.72),
                        angularInset: 0
                    )
                    .foregroundStyle(slice.color)
                }
                .chartLegend(.hidden)
                VStack(spacing: 2) {
                    Text("\((high * 100).safeInt)%").font(.title3).bold().foregroundStyle(Color(hex: "#FF453A"))
                    Text("High Risk").font(.caption2).foregroundStyle(.secondary)
                }
            }
            .frame(width: 120, height: 120)

            VStack(alignment: .leading, spacing: 10) {
                ForEach([
                    ("High Risk",   (high * 100).safeInt,   Color(hex: "#FF453A")),
                    ("Medium Risk", (medium * 100).safeInt, Color(hex: "#FF9F0A")),
                    ("Low Risk",    (low * 100).safeInt,    Color(hex: "#30D158")),
                ], id: \.0) { name, pct, color in
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 12, height: 12)
                        Text(name).font(.caption)
                        Spacer()
                        Text("\(pct)%").font(.caption).bold().foregroundStyle(color)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var riskSlices: [RiskDonutSlice] {
        [
            RiskDonutSlice(name: "Low Risk", value: max(0, low.safeFinite), color: Color(hex: "#30D158")),
            RiskDonutSlice(name: "Medium Risk", value: max(0, medium.safeFinite), color: Color(hex: "#FF9F0A")),
            RiskDonutSlice(name: "High Risk", value: max(0, high.safeFinite), color: Color(hex: "#FF453A"))
        ]
    }
}
