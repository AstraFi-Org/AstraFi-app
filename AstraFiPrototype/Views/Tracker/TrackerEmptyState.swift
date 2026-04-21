//
//  TrackerEmptyState.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 20/04/26.
//

import SwiftUI

// MARK: - Tracker Empty State (shared helper)
struct TrackerEmptyState: View {
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.08))
                    .frame(width: 60, height: 60)
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
            }
            Text(message)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 10, x: 0, y: 4)
    }
}
#Preview {
    TrackerEmptyState(icon: "chart.pie.fill", message: "No investments recorded yet. Complete your assessment to get started.")
}
