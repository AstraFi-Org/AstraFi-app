//
//  InvestmentForecastDetailRow.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 20/04/26.
//

import SwiftUI


struct InvestmentForecastDetailRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String
    var isBoldValue: Bool = false

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.caption)
                    .frame(width: 20)
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(isBoldValue ? .bold : .regular)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    InvestmentForecastDetailRow(
        icon: "chart.line.uptrend.xyaxis",
        iconColor: .green,
        label: "Expected Return",
        value: "₹12,450",
        isBoldValue: true
    )
    .padding()
}
