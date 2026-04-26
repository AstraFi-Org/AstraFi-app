//
//  Phase1BView.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 22/04/26.
//

import SwiftUI

//struct Phase1BView: View {
//    @Bindable var data: CompleteAssessmentData
//    @Environment(AppStateManager.self) var appState
//    @Environment(\.dismiss) private var dismiss
//
//    @State private var goReport       = false   // → ChoiceToReport (skip investments)
//    @State private var goInvestments = false   // → InvestmentDetailsScreen
//
//    // nil = unanswered, true = invests, false = doesn't
//    @State private var doesInvest: Bool? = nil
//
//    private var income: Double  { Double(data.income) ?? 0 }
//    private var expenses: Double { Double(data.expenditure) ?? 0 }
//    private var efSaved: Double { Double(data.emergencyFundAmount) ?? 0 }
//    private var emergencyTarget: Double { income * 6 }
//
//    private var minSavePerMonth: Double {
//        let remaining = max(0, emergencyTarget - efSaved)
//        let toReachTarget = remaining / 12.0
//        let tenPctFloor  = income * 0.10
//        return max(toReachTarget, tenPctFloor)
//    }
//    private var efProgress: Double { emergencyTarget > 0 ? min(1, efSaved / emergencyTarget) : 0 }
//    private var efColor: Color {
//        efProgress >= 1 ? AppTheme.auraGreen :
//        efProgress >= 0.5 ? AppTheme.vibrantOrange :
//        AppTheme.vibrantRed
//    }
//
//    // Show investment question once EF amount is filled (even 0)
//    private var showInvestQuestion: Bool {
//        !data.emergencyFundAmount.trimmingCharacters(in: .whitespaces).isEmpty
//    }
//
//    var body: some View {
//        ZStack(alignment: .bottom) {
//            Color(.systemGroupedBackground).ignoresSafeArea()
//
//            ScrollView(showsIndicators: false) {
//                VStack(spacing: 0) {
//
//                    // ── Page title (scrolls with content)
//                    VStack(alignment: .leading, spacing: 4) {
//                        Text("Almost there")
//                            .font(.system(size: 28, weight: .bold, design: .rounded))
//                        Text("Tell us about your existing safety net so we can give you personalised advice.")
//                            .font(.system(size: 15, design: .rounded))
//                            .foregroundStyle(.secondary)
//                            .fixedSize(horizontal: false, vertical: true)
//                    }
//                    .padding(.horizontal, 20)
//                    .padding(.top, 24)
//                    .padding(.bottom, 24)
//
//                    // ── EF Field
//                    VStack(spacing: 14) {
//                        AssessmentField(
//                            icon: "shield.lefthalf.filled",
//                            label: "Emergency Fund Saved (₹)",
//                            placeholder: "e.g. 100000  (0 if none)",
//                            text: $data.emergencyFundAmount,
//                            keyboard: .numberPad
//                        )
//                    }
//                    .padding(.horizontal, 20)
//
//                    // ── EF Insight Card
//                    if income > 0 {
//                        EFInsightCard(
//                            efSaved: efSaved,
//                            emergencyTarget: emergencyTarget,
//                            minSavePerMonth: minSavePerMonth,
//                            efProgress: efProgress,
//                            efColor: efColor
//                        )
//                        .padding(.horizontal, 20)
//                        .padding(.top, 24)
//                        .transition(.move(edge: .bottom).combined(with: .opacity))
//                    }
//
//                    // ── Investment Question
//                    if showInvestQuestion {
//                        InvestmentQuestionCard(doesInvest: $doesInvest)
//                            .padding(.horizontal, 20)
//                            .padding(.top, 16)
//                            .transition(.move(edge: .bottom).combined(with: .opacity))
//                    }
//
//                    // ── Conditional investment cards
//                    if let invests = doesInvest {
//                        if invests {
//                            InvestmentAnalyseCard(
//                                onAnalyse: { goInvestments = true },
//                                onSkip: { goReport = true }
//                            )
//                                .padding(.horizontal, 20)
//                                .padding(.top, 12)
//                                .transition(.scale(scale: 0.95).combined(with: .opacity))
//                        } else {
//                            InvestmentNecessityCard()
//                                .padding(.horizontal, 20)
//                                .padding(.top, 12)
//                                .transition(.scale(scale: 0.95).combined(with: .opacity))
//                        }
//                    }
//
//                    Spacer().frame(height: 120)
//                }
//            }
//            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: showInvestQuestion)
//            .animation(.spring(response: 0.4,  dampingFraction: 0.8), value: doesInvest)
//            .animation(.spring(response: 0.3,  dampingFraction: 0.75), value: efProgress)
//            .safeAreaInset(edge: .top, spacing: 0) {
//                AssessmentProgressBar(progress: 0.4)
//                    .padding(.horizontal, 20)
//                    .padding(.vertical, 10)
//                    .background(Color(.systemGroupedBackground))
//            }
//
//        }
//        .navigationTitle("Financial Assessment")
//        .navigationBarTitleDisplayMode(.inline)
//        .navigationBarBackButtonHidden(true)
//        .toolbar {
//            ToolbarItem(placement: .navigationBarLeading) {
//                Button { dismiss() } label: {
//                    Image(systemName: "chevron.left")
//                        .fontWeight(.semibold)
//                        .foregroundColor(.primary)
//                }
//            }
//        }
//        .navigationDestination(isPresented: $goReport) {
//            FinancialHealthReportView()
//        }
//        .navigationDestination(isPresented: $goInvestments) {
//            InvestmentDetailsScreen(data: data)
//        }
//    }
//}
// MARK: - Phase1BView (updated)
struct Phase1BView: View {
    @Bindable var data: CompleteAssessmentData
    @Environment(AppStateManager.self) var appState
    @Environment(\.dismiss) private var dismiss

    @State private var goReport       = false
    @State private var goInvestments = false
    @State private var doesInvest: Bool? = nil

    private var income: Double   { Double(data.income) ?? 0 }
    private var expenses: Double { Double(data.expenditure) ?? 0 }
    private var efSaved: Double  { Double(data.emergencyFundAmount) ?? 0 }
    private var emergencyTarget: Double { income * 6 }

    private var minSavePerMonth: Double {
        let remaining = max(0, emergencyTarget - efSaved)
        let toReachTarget = remaining / 12.0
        let tenPctFloor  = income * 0.10
        return max(toReachTarget, tenPctFloor)
    }
    private var efProgress: Double { emergencyTarget > 0 ? min(1, efSaved / emergencyTarget) : 0 }
    private var efColor: Color {
        efProgress >= 1 ? AppTheme.auraGreen :
        efProgress >= 0.5 ? AppTheme.vibrantOrange :
        AppTheme.vibrantRed
    }

    private var showInvestQuestion: Bool {
        !data.emergencyFundAmount.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // Show the bottom CTA only when user picks "Not yet"
    private var showContinueButton: Bool {
        doesInvest == false
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Almost there")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("Tell us about your existing safety net so we can give you personalised advice.")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 24)

                    VStack(spacing: 14) {
                        AssessmentField(
                            icon: "shield.lefthalf.filled",
                            label: "Emergency Fund Saved (₹)",
                            placeholder: "e.g. 100000  (0 if none)",
                            text: $data.emergencyFundAmount,
                            keyboard: .numberPad
                        )
                    }
                    .padding(.horizontal, 20)

                    if income > 0 {
                        EFInsightCard(
                            efSaved: efSaved,
                            emergencyTarget: emergencyTarget,
                            minSavePerMonth: minSavePerMonth,
                            efProgress: efProgress,
                            efColor: efColor
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    if showInvestQuestion {
                        InvestmentQuestionCard(doesInvest: $doesInvest)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    if let invests = doesInvest {
                        if invests {
                            InvestmentAnalyseCard(
                                onAnalyse: {
                                    appState.updateProfile(from: data)
                                    goInvestments = true
                                },
                                onSkip: {
                                    appState.updateProfile(from: data)
                                    goReport = true
                                }
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .transition(.scale(scale: 0.95).combined(with: .opacity))
                        } else {
                            InvestmentNecessityCard()
                                .padding(.horizontal, 20)
                                .padding(.top, 12)
                                .transition(.scale(scale: 0.95).combined(with: .opacity))
                        }
                    }

                    // Extra bottom padding so content isn't hidden behind the sticky button
                    Spacer().frame(height: showContinueButton ? 160 : 120)
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: showInvestQuestion)
            .animation(.spring(response: 0.4,  dampingFraction: 0.8), value: doesInvest)
            .animation(.spring(response: 0.3,  dampingFraction: 0.75), value: efProgress)
            .safeAreaInset(edge: .top, spacing: 0) {
                AssessmentProgressBar(progress: 0.4)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(.systemGroupedBackground))
            }

            // ── Sticky Continue Button (slides up when "Not yet" is tapped)
            if showContinueButton {
                ContinueToReportButton {
                    appState.updateProfile(from: data)
                    goReport = true
                }
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal:   .move(edge: .bottom).combined(with: .opacity)
                    )
                )
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showContinueButton)
        .navigationTitle("Financial Assessment")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
        }
        .navigationDestination(isPresented: $goReport) {
            FinancialHealthReportView(data: data)
        }
        .navigationDestination(isPresented: $goInvestments) {
            InvestmentDetailsScreen(data: data)
        }
    }
}

// MARK: - Sticky Continue Button
private struct ContinueToReportButton: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Soft fade so content blends into the button area
            LinearGradient(
                colors: [
                    Color(.systemGroupedBackground).opacity(0),
                    Color(.systemGroupedBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 28)

            Button(action: action) {
                HStack(spacing: 10) {
                    Text("Continue to Report")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [AppTheme.vibrantOrange, AppTheme.vibrantOrange.opacity(0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: AppTheme.vibrantOrange.opacity(0.35), radius: 10, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)

            Color(.systemGroupedBackground)
                .frame(height: 34) // absorbs home indicator / safe area
        }
        .background(Color(.systemGroupedBackground))
    }
}
// MARK: - Investment Question Card
struct InvestmentQuestionCard: View {
    @Binding var doesInvest: Bool?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.auraGold)
                Text("One more thing")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("What do you do with your savings?")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Text("Money sitting idle in a bank loses value over time due to inflation.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 12) {
                InvestChoiceButton(
                    label: "Yes, I invest",
                    //icon: "chart.bar.fill",
                    color: AppTheme.auraGreen,
                    isSelected: doesInvest == true
                ) { doesInvest = true }

                InvestChoiceButton(
                    label: "Not yet",
                    //icon: "banknote",
                    color: AppTheme.vibrantOrange,
                    isSelected: doesInvest == false
                ) { doesInvest = false }
            }
        }
        .padding(18)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.auraGold.opacity(0.18), lineWidth: 1)
        )
    }
}

// MARK: - Choice Button (reusable)
private struct InvestChoiceButton: View {
    let label: String
//    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
//                Image(systemName: icon)
//                    .font(.system(size: 14, weight: .semibold))
                Text(label)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(isSelected ? .white : color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? color : color.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(color.opacity(isSelected ? 0 : 0.30), lineWidth: 1)
            )
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - "Yes I Invest" → Analyse Card
struct InvestmentAnalyseCard: View {
    let onAnalyse: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Header
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.auraGold)
                Text("That's smart thinking!")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.auraGreen)
            }

            // Message
            VStack(alignment: .leading, spacing: 6) {
                Text("Would you like us to analyse your investments?")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Text("We'll map your portfolio, check diversification, and show you how much your money is actually working — so you can make smarter moves.")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // 3 benefit pills
            HStack(spacing: 8) {
                benefitPill(icon: "chart.pie.fill",          color: AppTheme.auraIndigo,    text: "Diversification")
                benefitPill(icon: "arrow.up.right",          color: AppTheme.auraGreen,     text: "Growth check")
                benefitPill(icon: "exclamationmark.triangle",color: AppTheme.vibrantOrange, text: "Risk alerts")
            }

            // Two side-by-side buttons
            HStack(spacing: 12) {
                Button(action: onAnalyse) {
                    Text("Yes, analyse")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.auraGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: onSkip) {
                    Text("Skip for now")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.vibrantOrange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.vibrantOrange.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AppTheme.vibrantOrange.opacity(0.30), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.auraGreen.opacity(0.20), lineWidth: 1)
        )
    }

    private func benefitPill(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)
            Text(text)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.primary.opacity(0.75))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(color.opacity(0.08))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.18), lineWidth: 1))
    }
}

// MARK: - "Not Investing" → Necessity Card
struct InvestmentNecessityCard: View {
    @State private var barProgress: [CGFloat] = [0, 0, 0]

    // Illustrative: ₹10k/month at 0%, 7%, 12% over 10 years
    private let bars: [(label: String, value: Double, color: Color)] = [
        ("Bank\n(3.5%)",   14.0, AppTheme.vibrantRed),
        ("FD\n(7%)",       17.3, AppTheme.vibrantOrange),
        ("SIP\n(12%)",     23.2, AppTheme.auraGreen)
    ]
    private var maxVal: Double { bars.map(\.value).max() ?? 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Header
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.vibrantOrange)
                Text("Your money is losing value")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                Spacer()
                Text("Inflation ~6%")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.vibrantRed)
                    .clipShape(Capsule())
            }

            // Tagline
            Text("₹10,000/month saved for 10 years — the difference is staggering.")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Bar chart
            HStack(alignment: .bottom, spacing: 16) {
                ForEach(Array(bars.enumerated()), id: \.offset) { i, bar in
                    VStack(spacing: 6) {
                        Text("₹\(bar.value, specifier: "%.1f")L")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(bar.color)

                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(bar.color.opacity(0.85))
                            .frame(
                                width: 44,
                                height: barProgress[i] * 100
                            )
                            .animation(
                                .spring(response: 0.8, dampingFraction: 0.7)
                                .delay(Double(i) * 0.12),
                                value: barProgress[i]
                            )

                        Text(bar.label)
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)

            // 3 quick facts
            VStack(spacing: 8) {
                factRow(icon: "tortoise.fill",   color: AppTheme.vibrantRed,    text: "Savings account (3–4%) barely beats inflation — your real value shrinks.")
                factRow(icon: "chart.bar.fill",   color: AppTheme.auraGreen,     text: "Index funds have historically returned 12–15% over 10+ year periods.")
                factRow(icon: "clock.arrow.2.circlepath", color: AppTheme.auraIndigo, text: "Starting just 5 years later can cost you 40–50% of your final corpus.")
            }

            // Bottom nudge
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.auraIndigo)
                Text("You can add investments later in the app. Hit \"Skip to Report\" below to continue.")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .background(AppTheme.auraIndigo.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(18)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.vibrantOrange.opacity(0.15), lineWidth: 1)
        )
        .onAppear {
            for i in bars.indices {
                barProgress[i] = CGFloat(bars[i].value / maxVal)
            }
        }
    }

    private func factRow(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 16)
                .padding(.top, 1)
            Text(text)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - EF Insight Card (unchanged)
struct EFInsightCard: View {
    let efSaved: Double
    let emergencyTarget: Double
    let minSavePerMonth: Double
    let efProgress: Double
    let efColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.auraGold)
                Text("Emergency Fund Overview")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            .padding(.bottom, 16)

            HStack(spacing: 12) {
                iconCircle("shield.lefthalf.filled", color: AppTheme.vibrantCyan)
                Text("Ideal Emergency Fund")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(emergencyTarget.toCurrency(compact: true))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
            }

            Divider().opacity(0.5).padding(.vertical, 8)

            HStack(spacing: 12) {
                iconCircle("banknote", color: AppTheme.auraGreen)
                Text("Save at least")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(minSavePerMonth.toCurrency(compact: true) + " / month")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
            }

            if efSaved > 0 {
                Divider().opacity(0.5).padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        HStack(spacing: 8) {
                            iconCircle("shield.lefthalf.filled", color: efColor)
                            Text("Emergency Fund Progress")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(String(format: "%.0f%%", efProgress * 100))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(efColor)
                            .contentTransition(.numericText())
                    }
                    ProgressView(value: efProgress)
                        .progressViewStyle(.linear)
                        .tint(efColor)
                    Text("\(efSaved.toCurrency(compact: true)) of \(emergencyTarget.toCurrency(compact: true))")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }
            }

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
}

#Preview {
    var sample = CompleteAssessmentData()
    sample.income = "100000"
    sample.expenditure = "45000"
    sample.emergencyFundAmount = "150000"
    return Phase1BView(data: sample)
}
