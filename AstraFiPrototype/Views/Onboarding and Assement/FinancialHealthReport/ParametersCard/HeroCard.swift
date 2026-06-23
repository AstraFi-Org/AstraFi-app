//
//  HeroCard.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

//
//  HeroCard.swift
//  AstraFiPrototype
//

import SwiftUI

// MARK: - Radar Info Sheet
private struct RadarChartInfoSheet: View {
    let insights: FinancialAssessmentInsights
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // Live scores — mirror radarValues exactly
    private var incomeScore: Double { insights.hasFixedIncome ? 9.5 : 6.5 }
    private var savingScore: Double { min(10, (insights.savingsRate / 0.30) * 10) }
    private var emergencyScore: Double { min(10, insights.emergencyCoverageRatio * 10) }
    private var investScore: Double  { insights.investmentBalanceScore * 10 }
    private var riskScore: Double {
        insights.insuranceCount >= 2 ? 9.0 : insights.insuranceCount == 1 ? 6.5 : 2.0
    }

    private var savingsPct: Int   { (insights.savingsRate * 100).rounded().safeInt }
    private var coverageMonths: Double { insights.emergencyCoverageRatio * 6 }
    private var highRiskPct: Int  { (insights.investmentBreakdown.highRiskRatio * 100).rounded().safeInt }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // ── Hero header ──
                    headerBanner
                        .padding(.bottom, 24)

                    // ── Parameter cards ──
                    VStack(spacing: 14) {
                        paramCard(
                            title: "Income Stability",
                            icon: "chart.line.uptrend.xyaxis",
                            accentHex: "#007AFF",
                            score: incomeScore,
                            howLabel: insights.hasFixedIncome ? "Fixed salary" : "Variable income",
                            howDetail: insights.hasFixedIncome
                                ? "Fixed income earns 9.5 — the highest band."
                                : "Variable income earns 6.5. A fixed retainer would move you up.",
                            insight: insights.hasFixedIncome
                                ? "Your stable income is a strong financial foundation."
                                : "Consider negotiating a base salary to stabilise your score."
                        )

                        paramCard(
                            title: "Saving Discipline",
                            icon: "banknote",
                            accentHex: "#30D158",
                            score: savingScore,
                            howLabel: "You save \(savingsPct)% of take-home",
                            howDetail: "Benchmark is 30%. Score scales linearly up to that target.",
                            insight: savingsPct >= 30
                                ? "Outstanding — you're well above the 30% savings benchmark."
                                : savingsPct >= 20
                                    ? "Good progress at \(savingsPct)%. Closing the gap to 30% will boost this significantly."
                                    : "At \(savingsPct)% savings, reducing fixed monthly costs would have the biggest impact."
                        )

                        paramCard(
                            title: "Emergency Readiness",
                            icon: "umbrella.fill",
                            accentHex: "#FF9F0A",
                            score: emergencyScore,
                            howLabel: "~\(String(format: "%.1f", coverageMonths)) of 6 months covered",
                            howDetail: "Target is 6× your gross monthly income as a liquid buffer.",
                            insight: coverageMonths >= 6
                                ? "You're fully covered — great financial safety net."
                                : coverageMonths >= 3
                                    ? "Partial coverage. Keep building until you reach 6 months."
                                    : "Under 3 months covered. Prioritise this before new investments."
                        )

                        paramCard(
                            title: "Investment Balance",
                            icon: "chart.pie.fill",
                            accentHex: "#BF5AF2",
                            score: investScore,
                            howLabel: "\(insights.investmentCount) instrument\(insights.investmentCount == 1 ? "" : "s") · \(highRiskPct)% high-risk",
                            howDetail: "Score combines diversification, risk concentration, and liquidity.",
                            insight: insights.investmentCount == 0
                                ? "No investments found. Even a small SIP would move this score immediately."
                                : highRiskPct >= 80
                                    ? "\(highRiskPct)% in high-risk assets caps your score. Rebalancing into debt funds would help."
                                    : insights.investmentCount >= 3
                                        ? "Well diversified across \(insights.investmentCount) instruments with manageable risk."
                                        : "Add a third instrument type to unlock better diversification score."
                        )

                        paramCard(
                            title: "Risk Protection",
                            icon: "shield.fill",
                            accentHex: "#FF453A",
                            score: riskScore,
                            howLabel: "\(insights.insuranceCount) active polic\(insights.insuranceCount == 1 ? "y" : "ies")",
                            howDetail: "2+ policies → 9.0  ·  1 policy → 6.5  ·  None → 2.0",
                            insight: insights.insuranceCount >= 2
                                ? "\(insights.insuranceCount) policies give you a solid coverage baseline."
                                : insights.insuranceCount == 1
                                    ? "One policy is a start. Adding health + term cover pushes you to 9.0."
                                    : "No insurance detected. A basic health policy is the highest-impact addition you can make."
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("5-Parameter Overview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Header banner
    private var headerBanner: some View {
        VStack(spacing: 10) {
            Image(systemName: "pentagon.fill")
                .font(.system(size: 36))
                .foregroundStyle(
                    LinearGradient(colors: [Color(hex: "#007AFF"), Color(hex: "#BF5AF2")],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .padding(.top, 28)

            Text("How your scores are calculated")
                .font(.title3).bold()

            Text("Each axis is scored 0 – 10 from your real financial data. Tap any card to see what's driving your score.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 28)
                .padding(.bottom, 8)
        }
    }

    // MARK: - Parameter card builder
    @ViewBuilder
    private func paramCard(
        title: String,
        icon: String,
        accentHex: String,
        score: Double,
        howLabel: String,
        howDetail: String,
        insight: String
    ) -> some View {
        let accent = Color(hex: accentHex)
        let scoreColor: Color = score >= 7 ? Color(hex: "#30D158") : score >= 4.5 ? Color(hex: "#FF9F0A") : Color(hex: "#FF453A")

        VStack(alignment: .leading, spacing: 0) {

            // ── Title row ──
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 36, height: 36)
                    .background(accent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text(title)
                    .font(.headline)

                Spacer()

                // Score badge
                Text(String(format: "%.1f", score))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(scoreColor.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // ── Score bar ──
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.tertiarySystemBackground))
                        .frame(height: 6)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [accent.opacity(0.7), accent],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * (score / 10), height: 6)
                        .animation(.spring(duration: 0.8), value: score)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 16)
            .padding(.top, 10)

            // ── How it's calculated ──
            VStack(alignment: .leading, spacing: 4) {
                Text(howLabel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(accent)
                Text(howDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)

            Divider()
                .padding(.horizontal, 16)

            // ── Personalized insight ──
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: score >= 7
                      ? "checkmark.circle.fill"
                      : score >= 4.5
                          ? "exclamationmark.circle.fill"
                          : "xmark.circle.fill"
                )
                .foregroundStyle(scoreColor)
                .font(.system(size: 14))
                .padding(.top, 1)

                Text(insight)
                    .font(.subheadline)
                    .foregroundStyle(.primary.opacity(0.8))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - HeroCard
struct HeroCard: View {
    let name: String
    let score: Double
    let radarValues: [(String, Double, Double)]
    let insights: FinancialAssessmentInsights

    @State private var showRadarInfo = false

    private var scoreColor: Color {
        score >= 75 ? Color(hex: "#30D158") : score >= 50 ? Color(hex: "#FF9F0A") : Color(hex: "#FF453A")
    }
    private var scoreLabel: String {
        score >= 80 ? "Excellent" : score >= 65 ? "Good" : score >= 45 ? "Fair" : "Needs Work"
    }

    var body: some View {
        VStack(spacing: 20) {

            // Greeting + score ring
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.text.square.fill")
                            .foregroundStyle(Color(hex: "#007AFF")).font(.system(size: 15))
                        Text("AstraFi Report")
                            .font(.subheadline).fontWeight(.semibold).foregroundStyle(.secondary)
                    }
                    Text("Hi, \(name)").font(.title2).bold()
                    Text("Your financial health assessment is complete.")
                        .font(.subheadline).foregroundStyle(.secondary).lineSpacing(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    Circle().trim(from: 0.1, to: 0.9)
                        .stroke(Color(UIColor.systemFill), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .rotationEffect(.degrees(90))
                    Circle().trim(from: 0.1, to: 0.1 + (score / 100) * 0.8)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .rotationEffect(.degrees(90))
                        .animation(.easeOut(duration: 1.4), value: score)
                    VStack(spacing: 1) {
                        Text("\(score.safeInt)").font(.title3).fontWeight(.black).foregroundStyle(scoreColor)
                        Text(scoreLabel).font(.system(size: 9, weight: .semibold)).foregroundStyle(.secondary)
                    }
                }
                .frame(width: 76, height: 76)
            }

            Divider()

            // Radar chart section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Finanical Health Overview").font(.headline)
                    Spacer()
                    Button { showRadarInfo = true } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 20))
                            .foregroundStyle(Color(hex: "#007AFF"))
                    }
                    .buttonStyle(.plain)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .accessibilityLabel("About this chart")
                }
                RadarChart(values: radarValues).frame(height: 230)
            }
        }
        .padding(22)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 14, x: 0, y: 6)
        .sheet(isPresented: $showRadarInfo) {
            RadarChartInfoSheet(insights: insights)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}
