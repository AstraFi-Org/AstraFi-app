//
//  CoreVitalsCard.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 23/04/26.
//

import SwiftUI

// MARK: - Financial Knowledge Sheet
struct FinancialKnowledgeSheet: View {
    let savingsRate: Double
    let expenseRatio: Double
    let surplus: Double
    let income: Double
    let expenses: Double
    @Environment(\.dismiss) private var dismiss

    // Personalized message logic
    private var personalizedMessage: (icon: String, color: Color, title: String, body: String) {
        if surplus <= 0 {
            return (
                "exclamationmark.triangle.fill",
                AppTheme.vibrantRed,
                "You're spending more than you earn",
                "Your expenses exceed your income this month. Try cutting discretionary spend by ₹\(Int((expenses - income) * 1.1).formattedWithCommas()) to break even — then build from there."
            )
        } else if savingsRate >= 40 {
            return (
                "star.fill",
                AppTheme.auraGold,
                "Exceptional discipline!",
                "Saving \(Int(savingsRate))% of income puts you in the top tier of savers. Consider channelling this surplus into equity mutual funds or index funds for long-term wealth creation."
            )
        } else if savingsRate >= 30 {
            return (
                "checkmark.seal.fill",
                AppTheme.auraGreen,
                "You're on the right track",
                "A \(Int(savingsRate))% saving rate meets the golden benchmark. Stay consistent — even ₹\(Int(income * 0.30 / 12).formattedWithCommas()) invested monthly can grow substantially over 10 years."
            )
        } else if savingsRate >= 20 {
            return (
                "arrow.up.circle.fill",
                AppTheme.vibrantOrange,
                "Good start — push a little harder",
                "You're saving \(Int(savingsRate))% — just \(Int(30 - savingsRate))% short of the ideal. Try automating an extra ₹\(Int(income * 0.10).formattedWithCommas())/month to hit 30% without feeling the pinch."
            )
        } else if savingsRate >= 10 {
            return (
                "info.circle",
                AppTheme.vibrantOrange,
                "Room for improvement",
                "Your \(Int(savingsRate))% saving rate is a solid start, but the 30% target is within reach. Review your 'wants' spending — small cuts add up to big gains."
            )
        } else {
            return (
                "exclamationmark.circle.fill",
                AppTheme.vibrantRed,
                "Let's build better habits",
                "Saving below 10% leaves little buffer for emergencies. Even saving ₹500/month builds a habit — then scale up. Consider the 'pay yourself first' approach."
            )
        }
    }

    // 50-30-20 breakdown based on user's income
    private var needs: Double { income * 0.50 }
    private var wants: Double { income * 0.30 }
    private var savings20: Double { income * 0.20 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // ── Personalized Message Banner
                    let msg = personalizedMessage
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: msg.icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(msg.color)
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(msg.title)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(msg.color)
                            Text(msg.body)
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(14)
                    .background(msg.color.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(msg.color.opacity(0.25), lineWidth: 1)
                    )

                    // ── 50 / 30 / 20 Rule
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "scale.3d")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(AppTheme.auraIndigo)
                            Text("The 50 / 30 / 20 Rule")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                        }

                        Text("A simple, proven framework for balancing your money — no spreadsheet needed.")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(.secondary)

                        ruleRow(
                            percent: "50%",
                            label: "Needs",
                            sublabel: "Rent, groceries, bills, transport",
                            amount: needs,
                            color: AppTheme.auraIndigo,
                            icon: "house.fill"
                        )
                        ruleRow(
                            percent: "30%",
                            label: "Wants",
                            sublabel: "Dining, subscriptions, hobbies",
                            amount: wants,
                            color: AppTheme.vibrantOrange,
                            icon: "heart.fill"
                        )
                        ruleRow(
                            percent: "20%",
                            label: "Savings & Debt",
                            sublabel: "Investments, EMIs, emergency fund",
                            amount: savings20,
                            color: AppTheme.auraGreen,
                            icon: "leaf.fill"
                        )
                        Text("Expense = Needs+wants")
                            .font(.caption)
                    }
                    .padding(14)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: AppTheme.adaptiveShadow, radius: 6, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(AppTheme.auraIndigo.opacity(0.10), lineWidth: 1)
                    )

                    // ── Key Financial Facts
//                    VStack(alignment: .leading, spacing: 12) {
//                        HStack(spacing: 6) {
//                            Image(systemName: "lightbulb.fill")
//                                .font(.system(size: 13, weight: .bold))
//                                .foregroundStyle(AppTheme.auraGold)
//                            Text("Key Financial Facts")
//                                .font(.system(size: 15, weight: .bold, design: .rounded))
//                        }
//
//                        factRow(
//                            icon: "umbrella.fill",
//                            color: AppTheme.auraIndigo,
//                            title: "Emergency Fund",
//                            detail: "Keep 3–6 months of expenses (≈₹\(Int(expenses * 4).formattedWithCommas())) in a liquid fund or savings account before investing."
//                        )
//                        factRow(
//                            icon: "chart.line.uptrend.xyaxis",
//                            color: AppTheme.auraGreen,
//                            title: "Rule of 72",
//                            detail: "Divide 72 by your return rate to find how fast money doubles. At 12% (equity avg), your money doubles every 6 years."
//                        )
//                        factRow(
//                            icon: "clock.fill",
//                            color: AppTheme.vibrantOrange,
//                            title: "Start Early",
//                            detail: "Investing ₹5,000/month from age 25 vs. age 35 at 12% return gives you nearly 3× more corpus at retirement."
//                        )
//                        factRow(
//                            icon: "percent",
//                            color: AppTheme.vibrantRed,
//                            title: "High-Interest Debt",
//                            detail: "Credit card debt at 36–42% APR destroys wealth faster than any investment can build it. Clear it first, always."
//                        )
//                        factRow(
//                            icon: "person.2.fill",
//                            color: AppTheme.auraIndigo,
//                            title: "Lifestyle Inflation",
//                            detail: "As income rises, resist increasing spending proportionally. Each extra rupee saved now compounds into significantly more later."
//                        )
//                        factRow(
//                            icon: "shield.fill",
//                            color: AppTheme.auraGreen,
//                            title: "Insurance Before Investment",
//                            detail: "Term life (10–15× annual income) and health insurance are non-negotiable financial foundations — before SIPs or stocks."
//                        )
//                    }
                    .padding(14)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: AppTheme.adaptiveShadow, radius: 6, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(AppTheme.auraGold.opacity(0.10), lineWidth: 1)
                    )

                    // ── Your Numbers vs 50/30/20
                    if expenses > 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(AppTheme.auraGreen)
                                Text("Your Numbers vs the Rule")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                            }

                            comparisonRow(
                                label: "Expenses",
                                actual: expenses / income * 100,
                                target: 80,
                                targetLabel: "Keep below 80%",
                                color: expenseRatio <= 80 ? AppTheme.auraGreen : AppTheme.vibrantRed
                            )
                            comparisonRow(
                                label: "Savings",
                                actual: savingsRate,
                                target: 20,
                                targetLabel: "Aim for ≥20%",
                                color: savingsRate >= 20 ? AppTheme.auraGreen : AppTheme.vibrantOrange
                            )
                        }
                        .padding(14)
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: AppTheme.adaptiveShadow, radius: 6, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.auraGreen.opacity(0.10), lineWidth: 1)
                        )
                    }

                    Text("Financial benchmarks are guidelines, not rigid rules. Adjust based on your life stage, goals, and circumstances.")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(Color.secondary.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 8)
                }
                .padding(16)
            }
            .navigationTitle("Financial Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
            }
        }
    }

    // MARK: - Sub-views

    private func ruleRow(percent: String, label: String, sublabel: String, amount: Double, color: Color, icon: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 42, height: 42)
                VStack(spacing: 1) {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(color)
                    Text(percent)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Text(sublabel)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("₹\(Int(amount).formattedWithCommas())")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .padding(10)
        .background(color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func factRow(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
            }
            .padding(.top, 1)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Text(detail)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func comparisonRow(label: String, actual: Double, target: Double, targetLabel: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Spacer()
                Text(String(format: "%.0f%%", actual))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                Text("/ \(targetLabel)")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.15)).frame(height: 6)
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * min(CGFloat(actual / 100), 1), height: 6)
                    // target marker
                    Rectangle()
                        .fill(Color.primary.opacity(0.35))
                        .frame(width: 2, height: 10)
                        .position(x: geo.size.width * CGFloat(target / 100), y: 3)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Int extension for comma formatting
private extension Int {
    func formattedWithCommas() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

// MARK: - Core Vitals Card (Savings Rate + Expense Ratio)
struct CoreVitalsCard: View {
    let income: Double
    let expenses: Double
    let surplus: Double
    let savingsRate: Double
    let expenseRatio: Double

    @State private var showKnowledge = false

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
                Spacer()

                // ── Info Button
                Button {
                    showKnowledge = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundStyle(AppTheme.auraIndigo)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Financial insights and tips")
            }
            .padding(.bottom, 16)

            if hasExpenses {
                // ── Saving Rate
                VStack(spacing: 6) {
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

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 6)
                            Capsule()
                                .fill(savingsColor)
                                .frame(
                                    width: geo.size.width * min(CGFloat(savingsRate / 100), 1),
                                    height: 6
                                )
                            Rectangle()
                                .fill(Color.primary.opacity(0.4))
                                .frame(width: 2, height: 10)
                                .position(x: geo.size.width * 0.30, y: 3)
                        }
                    }
                    .frame(height: 6)

                    Text("Target: 30% of income · Healthy saving discipline")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                    ProgressView(value: min(expenseRatio / 100.0, 1.0))
                        .progressViewStyle(.linear)
                        .tint(expenseColor)

                    Text("Target: below 50% of income · Lower is better")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                    Spacer()
                }
                .padding(10)
                .background((savingsRate >= 30 ? AppTheme.auraGreen : AppTheme.vibrantOrange).opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            } else {
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
            HStack {
                Text("Projected using standard financial assumptions.")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(Color.secondary.opacity(0.6))
                Spacer()
//                Button {
//                    showKnowledge = true
//                } label: {
//                    HStack(spacing: 3) {
//                        Text("Learn more")
//                        Image(systemName: "chevron.right")
//                    }
//                    .font(.system(size: 11, weight: .medium, design: .rounded))
//                    .foregroundStyle(AppTheme.auraIndigo.opacity(0.8))
//                }
//                .buttonStyle(.plain)
            }
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
        .sheet(isPresented: $showKnowledge) {
            FinancialKnowledgeSheet(
                savingsRate: savingsRate,
                expenseRatio: expenseRatio,
                surplus: surplus,
                income: income,
                expenses: expenses
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
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

// MARK: - Previews
#Preview("Healthy State") {
    CoreVitalsCard(
        income: 80000,
        expenses: 40000,
        surplus: 40000,
        savingsRate: 30,
        expenseRatio: 50
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Warning State") {
    CoreVitalsCard(
        income: 80000,
        expenses: 65000,
        surplus: 15000,
        savingsRate: 18.75,
        expenseRatio: 81.25
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Overspending State") {
    CoreVitalsCard(
        income: 50000,
        expenses: 58000,
        surplus: -8000,
        savingsRate: 0,
        expenseRatio: 116
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
