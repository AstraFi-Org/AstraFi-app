//
//  Phase1BView.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 22/04/26.
//

import SwiftUI

struct Phase1BView: View {
    @Bindable var data: CompleteAssessmentData
    @Environment(AppStateManager.self) var appState
    @Environment(\.dismiss) private var dismiss

    @State private var goGate = false

    private var income: Double { Double(data.income) ?? 0 }
    private var expenses: Double { Double(data.expenditure) ?? 0 }
    private var efSaved: Double { Double(data.emergencyFundAmount) ?? 0 }
    private var emergencyTarget: Double { income * 6 }
    // "Save at least" = needed per month to reach EF target in 12 months,
    // never less than 10% of income (standard personal-finance rule).
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

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── Progress indicator
                    VStack(alignment: .leading, spacing: 12) {
                        AssessmentProgressBar(progress: 0.4)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Almost there")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                            Text("Tell us about your existing safety net so we can give you personalised advice.")
                                .font(.system(size: 15, design: .rounded))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 24)

                    // ── EF field
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

                    // ── EF insight card
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

                    Spacer().frame(height: 120)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: efProgress)

            AssessmentFooterButton(
                label: "Proceed",
                enabled: true,
                isLast: false,
                action: { goGate = true }
            )
        }
        .navigationTitle("Financial Assessment")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
        }
        .navigationDestination(isPresented: $goGate) {
            ChoiceToReport(data: data)
        }
    }
}

// MARK: - EF Insight Card
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

            // Ideal EF row
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

            // Save at least row
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

                // EF Progress
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
                    // Apple-native ProgressView
                    ProgressView(value: efProgress)
                        .progressViewStyle(.linear)
                        .tint(efColor)
                    Text("\(efSaved.toCurrency(compact: true)) of \(emergencyTarget.toCurrency(compact: true))")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
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
}


#Preview {
    // Sample data for preview
    var sample = CompleteAssessmentData()
    sample.income = "100000"
    sample.expenditure = "45000"
    sample.emergencyFundAmount = "150000"
    return Phase1BView(data: sample)
}
