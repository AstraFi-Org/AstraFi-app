//
//  FinancialHealthHistoryComparisonCard.swift
//  AstraFiPrototype
//
//  Created by AstraFi Agent on 10/09/26.
//

import SwiftUI

struct FinancialHealthHistoryComparisonCard: View {
    let history: [AstraHealthAssessment]

    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedMonth1Index: Int = 0
    @State private var selectedMonth2Index: Int = 3

    private var sortedHistory: [AstraHealthAssessment] {
        history
            .filter { (0...100).contains($0.score) }
            .sorted { $0.date < $1.date }
    }

    private var activeItems: [AstraHealthAssessment] {
        sortedHistory.isEmpty ? sampleFallbackHistory : sortedHistory
    }

    private var earliestScore: Int {
        activeItems.first?.score ?? 0
    }

    private var latestScore: Int {
        activeItems.last?.score ?? 0
    }

    private var totalGain: Int {
        latestScore - earliestScore
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppTheme.auraIndigo)

                Text("Financial Health History")
                    .font(.system(size: 20, weight: .bold))

                Spacer()

                Text("\(sortedHistory.count) Months")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.auraIndigo.opacity(0.12))
                    .foregroundStyle(AppTheme.auraIndigo)
                    .clipShape(Capsule())
            }

            // MARK: - Improvement Summary Callout Box
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(totalGain >= 0 ? Color(hex: "#30D158").opacity(0.15) : Color(hex: "#FF453A").opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: totalGain >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(totalGain >= 0 ? Color(hex: "#30D158") : Color(hex: "#FF453A"))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(
                            totalGain >= 0
                            ? "Your financial health improved by \(totalGain) points."
                            : "Your financial health score changed by \(totalGain) points."
                        )
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.primary)

                        Text("Consistent tracking creates momentum and long-term financial freedom.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [
                        totalGain >= 0 ? Color(hex: "#30D158").opacity(0.08) : Color(hex: "#FF453A").opacity(0.08),
                        AppTheme.auraIndigo.opacity(0.04)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(totalGain >= 0 ? Color(hex: "#30D158").opacity(0.3) : Color(hex: "#FF453A").opacity(0.3), lineWidth: 1.5)
            )

            // MARK: - Chronological Score Comparison Table
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("ALLOW USERS TO COMPARE")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("SCORE")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 4)

                VStack(spacing: 8) {
                    ForEach(Array(activeItems.enumerated()), id: \.element.id) { index, assessment in
                        comparisonRow(
                            index: index + 1,
                            monthName: assessment.date.formatted(.dateTime.month(.wide)),
                            score: assessment.score,
                            previousScore: index > 0 ? activeItems[index - 1].score : nil
                        )
                    }
                }
            }

            // MARK: - Visual Trajectory Sparkline Bar Chart
            VStack(alignment: .leading, spacing: 10) {
                Text("Monthly Score Trajectory")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(activeItems) { item in
                        VStack(spacing: 6) {
                            Text("\(item.score)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(scoreColor(item.score))

                            GeometryReader { geo in
                                VStack {
                                    Spacer()
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [scoreColor(item.score), scoreColor(item.score).opacity(0.6)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(height: max(10, geo.size.height * (Double(item.score) / 100.0)))
                                }
                            }
                            .frame(height: 70)

                            Text(item.date.formatted(.dateTime.month(.abbreviated)))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(14)
                .background(Color.primary.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(18)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 10, x: 0, y: 4)
    }

    // MARK: - Row View for Chronological Table
    private func comparisonRow(index: Int, monthName: String, score: Int, previousScore: Int?) -> some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(.tertiary)
                .frame(width: 18)

            Text(monthName)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.primary)

            Spacer()

            if let prev = previousScore {
                let diff = score - prev
                if diff != 0 {
                    HStack(spacing: 2) {
                        Image(systemName: diff > 0 ? "arrow.up.right" : "arrow.down.right")
                        Text("\(diff > 0 ? "+" : "")\(diff)")
                    }
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(diff > 0 ? Color(hex: "#30D158") : Color(hex: "#FF453A"))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background((diff > 0 ? Color(hex: "#30D158") : Color(hex: "#FF453A")).opacity(0.1))
                    .clipShape(Capsule())
                }
            }

            Text("\(score)")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(scoreColor(score))
                .frame(width: 36, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.primary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func scoreColor(_ s: Int) -> Color {
        s >= 80 ? Color(hex: "#30D158") : s >= 70 ? Color(hex: "#FF9F0A") : Color(hex: "#5E5CE6")
    }

    private var sampleFallbackHistory: [AstraHealthAssessment] {
        [
            AstraHealthAssessment(date: Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 1)) ?? Date(), score: 61, status: "Needs Work", keyInsights: []),
            AstraHealthAssessment(date: Calendar.current.date(from: DateComponents(year: 2026, month: 7, day: 1)) ?? Date(), score: 65, status: "Needs Work", keyInsights: []),
            AstraHealthAssessment(date: Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 1)) ?? Date(), score: 69, status: "Good", keyInsights: []),
            AstraHealthAssessment(date: Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 1)) ?? Date(), score: 74, status: "Good", keyInsights: [])
        ]
    }
}

#Preview {
    FinancialHealthHistoryComparisonCard(history: [])
        .padding()
}
