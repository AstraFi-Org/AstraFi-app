//
//  GoalSummaryCell.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI

struct GoalSummaryCell: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
#Preview {
    GoalSummaryCell(
        label: "Total Goals",
        value: "5",
        icon: "flag.fill",
        color: .orange
    )
    .padding()
    .background(Color(uiColor: .systemGroupedBackground))
}
