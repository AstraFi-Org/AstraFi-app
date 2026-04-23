//
//  CoreVitalsCard.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 23/04/26.
//

import SwiftUI

// MARK: - Core Vitals Card (Savings Rate + Expense Ratio)
struct CoreVitalsCard: View {
    let income: Double
    let expenses: Double
    let surplus: Double
    let savingsRate: Double
    let expenseRatio: Double

    private var hasExpenses: Bool { expenses > 0 }

    private var savingsColor: Color {
        savingsRate >= 30 ? AppTheme.auraGreen :
        savingsRate >= 15 ? AppTheme.vibrantOrange :
        AppTheme.vibrantRed
    }
    private var expenseColor: Color {
        expenseRatio <= 50 ? AppTheme.auraGreen :
        expenseRatio <= 70 ? AppTheme.vibrantOrange :
        AppTheme.vibrantRed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Section header
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.auraGold)
                Text("Your Financial Snapshot")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            .padding(.bottom, 16)

            if hasExpenses {
                // ── Saving Rate
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        HStack(spacing: 8) {
                            iconCircle("percent", color: savingsColor)
                            Text("Saving Rate")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(String(format: "%.0f%%", savingsRate))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(savingsColor)
                            .contentTransition(.numericText())
                    }
                    // Apple-native ProgressView
                    ProgressView(value: min(savingsRate / 30.0, 1.0))
                        .progressViewStyle(.linear)
                        .tint(savingsColor)
                    Text("Target: 30% of income · Healthy saving discipline")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                divider

                // ── Expense Ratio
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        HStack(spacing: 8) {
                            iconCircle("cart.fill", color: expenseColor)
                            Text("Expense Ratio")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(String(format: "%.0f%%", expenseRatio))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(expenseColor)
                            .contentTransition(.numericText())
                    }
                    // Apple-native ProgressView
                    ProgressView(value: min(expenseRatio / 100.0, 1.0))
                        .progressViewStyle(.linear)
                        .tint(expenseColor)
                    Text("Target: below 50% of income · Lower is better")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                divider

                // ── Monthly Surplus
                HStack {
                    HStack(spacing: 8) {
                        iconCircle("arrow.up.right", color: surplus > 0 ? AppTheme.auraGreen : AppTheme.vibrantRed)
                        Text("Monthly Surplus")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(surplus > 0 ? surplus.toCurrency(compact: true) : "₹0")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(surplus > 0 ? AppTheme.auraGreen : AppTheme.vibrantRed)
                        .contentTransition(.numericText())
                }

                divider

                // ── Health hint
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: savingsRate >= 30 ? "checkmark.seal.fill" : "info.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(savingsRate >= 30 ? AppTheme.auraGreen : AppTheme.vibrantOrange)
                        .padding(.top, 1)
                    Text(savingsRate >= 30
                         ? "Great saving discipline! You're on track for financial health."
                         : surplus <= 0
                           ? "Expenses exceed income — reduce spending to start building wealth."
                           : "Aim for a 30% saving rate to strengthen your financial health.")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .background((savingsRate >= 30 ? AppTheme.auraGreen : AppTheme.vibrantOrange).opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            } else {
                // Hint to fill expenses
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.auraIndigo)
                    Text("Enter monthly expenses to see your saving rate and expense ratio.")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            // Caption
            Text("Based on standard financial planning rules.")
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(Color.secondary.opacity(0.6))
                .padding(.top, 14)
        }
        .padding(18)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.auraIndigo.opacity(0.12), lineWidth: 1)
        )
    }

    private func iconCircle(_ icon: String, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.12))
                .frame(width: 30, height: 30)
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
        }
    }

    private var divider: some View {
        Divider().opacity(0.5).padding(.vertical, 8)
    }
}
