//
//  InvestmentForecastPill.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 20/04/26.
//

import SwiftUI

struct InvestmentForecastPill: View {
    let icon: String
    let text: String
    let isSelected: Bool
    let activeColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(text)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? activeColor : Color(uiColor: .systemGray5))
            .cornerRadius(20)
        }
    }
}


#Preview {
    VStack(spacing: 12) {
        InvestmentForecastPill(
            icon: "chart.line.uptrend.xyaxis",
            text: "1Y",
            isSelected: true,
            activeColor: .blue,
            action: {}
        )

        InvestmentForecastPill(
            icon: "chart.line.uptrend.xyaxis",
            text: "5Y",
            isSelected: false,
            activeColor: .blue,
            action: {}
        )
    }
    .padding()
}
