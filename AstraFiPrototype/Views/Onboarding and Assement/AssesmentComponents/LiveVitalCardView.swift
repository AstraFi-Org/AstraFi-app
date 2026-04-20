//
//  LiveVitalCardView.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 20/04/26.
//

import SwiftUI

// MARK: - Live Vitals Card (Phase 2)
struct LiveVitalsCard: View {
    let savingsRate: Double
    let surplus: Double
    let efProgress: Double
    let efSaved: Double
    let efTarget: Double

    private var savingsColor: Color {
        savingsRate >= 30 ? AppTheme.auraGreen :
        savingsRate >= 15 ? AppTheme.vibrantOrange :
        AppTheme.vibrantRed
    }

    private var efColor: Color {
        efProgress >= 1 ? AppTheme.auraGreen :
        efProgress >= 0.5 ? AppTheme.vibrantOrange :
        AppTheme.vibrantRed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.auraIndigo)
                Text("Your Financial Vitals")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }

            // Saving Rate bar
            VitalBar(
                label: "Saving Rate",
                value: String(format: "%.0f%%", savingsRate),
                progress: min(savingsRate / 30.0, 1.0),
                color: savingsColor,
                benchmark: "Target: 30%"
            )

            Divider().opacity(0.5)

            // Surplus
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Monthly Surplus")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(surplus.toCurrency(compact: true))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(surplus > 0 ? AppTheme.auraGreen : AppTheme.vibrantRed)
                        .contentTransition(.numericText())
                }
                Spacer()
                if surplus <= 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                        Text("Expenses exceed income")
                            .font(.caption)
                    }
                    .foregroundStyle(AppTheme.vibrantRed)
                }
            }

            if efTarget > 0 {
                Divider().opacity(0.5)

                // Emergency Fund progress
                VitalBar(
                    label: "Emergency Fund",
                    value: "\(Int(efProgress * 100))%",
                    progress: efProgress,
                    color: efColor,
                    benchmark: "\(efSaved.toCurrency(compact: true)) of \(efTarget.toCurrency(compact: true))"
                )
            }

            // Health hint
            healthHint
        }
        .padding(18)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.auraIndigo.opacity(0.15), lineWidth: 1)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: savingsRate)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: efProgress)
    }

    private var healthHint: some View {
        HStack(spacing: 8) {
            Image(systemName: savingsRate >= 30 ? "checkmark.seal.fill" : "info.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(savingsRate >= 30 ? AppTheme.auraGreen : AppTheme.vibrantOrange)
            Text(savingsRate >= 30
                 ? "Great saving discipline! Continue to see your full score."
                 : "Improving savings to 30% will significantly boost your score.")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background((savingsRate >= 30 ? AppTheme.auraGreen : AppTheme.vibrantOrange).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
private struct VitalBar: View {
    let label: String
    let value: String
    let progress: Double
    let color: Color
    let benchmark: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .contentTransition(.numericText())
            }
            ProgressView(value: max(0, min(progress, 1)))
                .progressViewStyle(.linear)
                .tint(color)
            Text(benchmark)
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("Live Vitals Card") {
    LiveVitalsCard(
        savingsRate: 22,
        surplus: 8500,
        efProgress: 0.45,
        efSaved: 135000,
        efTarget: 300000
    )
    .padding()
    .background(Color(.systemBackground))
}
