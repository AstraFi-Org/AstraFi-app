//
//  EmergencyFundCard.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI

// MARK: - Emergency Fund Card
struct EmergencyFundCard: View {
    let currentAmount: Double; let targetAmount: Double
    let lowRiskLiquid: Double; let statusMessage: String

    private var progress: Double { targetAmount > 0 ? min(1.0, currentAmount / targetAmount) : 0 }
    private var progressColor: Color {
        progress >= 1.0 ? Color(hex: "#30D158") : progress >= 0.5 ? Color(hex: "#FF9F0A") : Color(hex: "#FF453A")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Emergency Corpus").font(.subheadline).foregroundStyle(.secondary)
                    Text(currentAmount.toCurrency(compact: true)).font(.title2).bold()
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(progress * 100))% funded").font(.caption).fontWeight(.bold)
                        .foregroundStyle(progressColor).padding(.horizontal, 10).padding(.vertical, 4)
                        .background(progressColor.opacity(0.1)).clipShape(Capsule())
                    Image(systemName: "chevron.right").font(.caption).fontWeight(.semibold).foregroundStyle(.tertiary)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(UIColor.tertiarySystemFill)).frame(height: 8)
                    Capsule().fill(progressColor).frame(width: max(8, geo.size.width * progress), height: 8)
                }
            }
            .frame(height: 8)
            HStack(spacing: 12) {
                EmergencyStatPill(label: "Target (6×)", value: targetAmount.toCurrency(compact: true), color: Color(hex: "#007AFF"))
                EmergencyStatPill(
                    label: "Liquid Assets",
                    value: lowRiskLiquid > 0 ? lowRiskLiquid.toCurrency(compact: true) : "None",
                    color: lowRiskLiquid > 0 ? Color(hex: "#30D158") : Color(hex: "#FF453A")
                )
            }
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle.fill").font(.subheadline)
                    .foregroundStyle(Color(hex: "#007AFF")).padding(.top, 1)
                Text(statusMessage).font(.subheadline).foregroundStyle(.secondary).lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12).background(Color(hex: "#007AFF").opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(18).background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
    }
}

