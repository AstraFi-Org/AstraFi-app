//
//  RiskDonutView.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI

struct RiskDonutView: View {
    let high: Double; let medium: Double; let low: Double

    var body: some View {
        HStack(spacing: 24) {
            ZStack {
                // Low (base)
                Circle().trim(from: 0, to: CGFloat(low + medium + high))
                    .stroke(Color(hex: "#30D158"), style: StrokeStyle(lineWidth: 18, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
                // Medium
                Circle().trim(from: CGFloat(low), to: CGFloat(low + medium))
                    .stroke(Color(hex: "#FF9F0A"), style: StrokeStyle(lineWidth: 18, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
                // High
                Circle().trim(from: CGFloat(low + medium), to: CGFloat(low + medium + high))
                    .stroke(Color(hex: "#FF453A"), style: StrokeStyle(lineWidth: 18, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text("\(Int(high * 100))%").font(.title3).bold().foregroundStyle(Color(hex: "#FF453A"))
                    Text("High Risk").font(.caption2).foregroundStyle(.secondary)
                }
            }
            .frame(width: 120, height: 120)

            VStack(alignment: .leading, spacing: 10) {
                ForEach([
                    ("High Risk",   Int(high * 100),   Color(hex: "#FF453A")),
                    ("Medium Risk", Int(medium * 100), Color(hex: "#FF9F0A")),
                    ("Low Risk",    Int(low * 100),    Color(hex: "#30D158")),
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
}
