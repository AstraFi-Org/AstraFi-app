//
//  FinancialVitalTile.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 20/04/26.
//

import SwiftUI

// MARK: - Planner Vital Tile
struct PlannerVitalTile: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var hasChevron: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)
            }
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .minimumScaleFactor(0.65)
                .lineLimit(1)
            HStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                if hasChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    HStack(spacing: 12) {
        PlannerVitalTile(
            title: "Net Worth",
            value: "₹2.5L",
            icon: "chart.line.uptrend.xyaxis",
            color: .blue,
            hasChevron: true
        )

        PlannerVitalTile(
            title: "Monthly EMI",
            value: "₹15K",
            icon: "creditcard",
            color: .red
        )

        PlannerVitalTile(
            title: "Savings",
            value: "₹80K",
            icon: "wallet.pass",
            color: .green
        )
    }
    .padding()
}
