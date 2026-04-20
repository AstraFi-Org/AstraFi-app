import SwiftUI

// MARK: - Phase 1: Core Vitals (Name, Age, Income, Expenses only)
// Shows saving rate + expense ratio live as user types.
// Emergency Fund question follows on the next screen (Phase1BView).
struct BasicDetailView: View {
    @Bindable var data: CompleteAssessmentData
    @Environment(AppStateManager.self) var appState
    @Environment(\.dismiss) private var dismiss

    @State private var goNext = false

    // ── Live computed values
    private var income: Double   { Double(data.income) ?? 0 }
    private var expenses: Double { Double(data.expenditure) ?? 0 }
    private var age: Int         { Int(data.age) ?? 0 }

    private var surplus: Double    { max(0, income - expenses) }
    private var savingsRate: Double { income > 0 ? (surplus / income) * 100 : 0 }
    private var expenseRatio: Double { income > 0 ? (expenses / income) * 100 : 0 }

    // Show live insight card as soon as income is entered
    private var showCard: Bool { income > 0 }

    private var canContinue: Bool {
        !data.name.trimmingCharacters(in: .whitespaces).isEmpty
        && income > 0
        && expenses > 0
        && age > 0
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── Progress indicator
                    VStack(alignment: .leading, spacing: 12) {
                        AssessmentProgressBar(progress: 0.2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Let's get started")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                            Text("Your basics help us calculate your financial health in real time.")
                                .font(.system(size: 15, design: .rounded))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 24)

                    // ── 4 core fields
                    VStack(spacing: 14) {
                        AssessmentField(
                            icon: "person.fill",
                            label: "Your Name",
                            placeholder: "e.g. Rahul Sharma",
                            text: $data.name,
                            keyboard: .default
                        )
                        AssessmentField(
                            icon: "person.crop.circle",
                            label: "Your Age",
                            placeholder: "e.g. 28",
                            text: $data.age,
                            keyboard: .numberPad
                        )
                        AssessmentField(
                            icon: "indianrupeesign.circle.fill",
                            label: "Monthly Income (₹)",
                            placeholder: "e.g. 75000",
                            text: $data.income,
                            keyboard: .numberPad
                        )
                        AssessmentField(
                            icon: "cart.fill",
                            label: "Monthly Expenses (₹)",
                            placeholder: "e.g. 40000",
                            text: $data.expenditure,
                            keyboard: .numberPad
                        )
                    }
                    .padding(.horizontal, 20)

                    // ── Live insight card (savings rate + expense ratio)
                    if showCard {
                        CoreVitalsCard(
                            income: income,
                            expenses: expenses,
                            surplus: surplus,
                            savingsRate: savingsRate,
                            expenseRatio: expenseRatio
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    Spacer().frame(height: 120)
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: showCard)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: savingsRate)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: expenseRatio)

            // ── Footer
            VStack(spacing: 0) {
                if !canContinue {
                    Text(data.name.trimmingCharacters(in: .whitespaces).isEmpty ? "Enter your name to continue" :
                         income == 0 ? "Enter your monthly income to continue" :
                         expenses == 0 ? "Enter your monthly expenses to continue" :
                         "Enter your age to continue")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }
                AssessmentFooterButton(
                    label: "Next",
                    enabled: canContinue,
                    isLast: false,
                    action: { goNext = true }
                )
            }
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Skip") {
                    appState.setupEmptyProfile(name: "User")
                    appState.isAssessmentSkipped = true
                    appState.showDashboard = true
                }
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
            }
        }
        .navigationDestination(isPresented: $goNext) {
            Phase1BView(data: data)
        }
        .onAppear {
            if data.name.isEmpty && !appState.tempName.isEmpty {
                data.name = appState.tempName
            }
            data.email    = appState.tempEmail
            data.password = appState.tempPassword
        }
    }
}

// MARK: - Core Vitals Card (Savings Rate + Expense Ratio)
private struct CoreVitalsCard: View {
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

// MARK: - Phase 1B: Emergency Fund + deeper context
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
                label: "See My Score",
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
            DeepDiveGateView(data: data)
        }
    }
}

// MARK: - EF Insight Card
private struct EFInsightCard: View {
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

// MARK: - Gate: "Want a deeper picture?"
struct DeepDiveGateView: View {
    @Bindable var data: CompleteAssessmentData
    @Environment(\.dismiss) private var dismiss
    @State private var goDeep = false
    @State private var goReport = false

    private var income: Double { Double(data.income) ?? 0 }
    private var expenses: Double { Double(data.expenditure) ?? 0 }
    private var surplus: Double { max(0, income - expenses) }
    private var savingsRate: Double { income > 0 ? (surplus / income) * 100 : 0 }
    private var scoreEstimate: Int {
        let sr = min(savingsRate / 30.0, 1.0)
        let ef = min((Double(data.emergencyFundAmount) ?? 0) / (income * 6), 1.0)
        return Int(500 + sr * 200 + ef * 100)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Progress
                    AssessmentProgressBar(progress: 0.5)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)

                    // Gate question
                    VStack(spacing: 12) {
                        Text("Where did you invest?")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                        Text("Adding your investments, loans and insurance gives you a complete financial health report — usually takes 2–3 minutes.")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 28)

                    // Choice cards
                    VStack(spacing: 12) {
                        GateChoiceCard(
                            icon: "chart.bar.xaxis.ascending",
                            color: AppTheme.auraIndigo,
                            title: "Provide data to analyse further",
                            subtitle: "Add investments, loans & insurance",
                            isRecommended: true
                        ) {
                            goDeep = true
                        }

                        GateChoiceCard(
                            icon: "",
                            color: AppTheme.auraGreen,
                            title: "Proceed to Report",
                            subtitle: "See results with what I've shared",
                            isRecommended: false
                        ) {
                            goReport = true
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 40)
                }
            }
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
        .navigationDestination(isPresented: $goDeep) {
            InvestmentDetailsScreen(data: data)
        }
        .navigationDestination(isPresented: $goReport) {
            FinancialHealthReportView(data: data)
        }
    }
}

// MARK: - Loan Gate
struct LoanGateView: View {
    @Bindable var data: CompleteAssessmentData
    @State private var goLoans = false
    @State private var goInsuranceGate = false

    var body: some View {
        SectionGateView(
            progress: 4,
            icon: "building.columns.fill",
            iconColor: AppTheme.vibrantOrange,
            question: "Do you have any active loans?",
            detail: "Home loan, car loan, personal loan, education loan, credit card dues — any outstanding debt.",
            yesLabel: "Yes, add my loans",
            noLabel: "No active loans",
            onYes: { goLoans = true },
            onNo:  { goInsuranceGate = true }
        )
        .navigationDestination(isPresented: $goLoans) {
            LoanDetailsScreen(data: data, onComplete: { goInsuranceGate = true })
        }
        .navigationDestination(isPresented: $goInsuranceGate) {
            InsuranceGateView(data: data)
        }
    }
}

// MARK: - Insurance Gate
struct InsuranceGateView: View {
    @Bindable var data: CompleteAssessmentData
    @State private var goInsurance = false
    @State private var goReport = false

    var body: some View {
        SectionGateView(
            progress: 5,
            icon: "heart.text.square.fill",
            iconColor: AppTheme.auraPurple,
            question: "Are you or your family insured?",
            detail: "Health, life, term, motor — any active insurance policy.",
            yesLabel: "Yes, add insurance details",
            noLabel: "No, skip to report",
            onYes: { goInsurance = true },
            onNo:  { goReport = true }
        )
        .navigationDestination(isPresented: $goInsurance) {
            InsuranceDetailsScreen(data: data, onComplete: { goReport = true })
        }
        .navigationDestination(isPresented: $goReport) {
            FinancialHealthReportView(data: data)
        }
    }
}

// MARK: - Reusable Section Gate Screen
struct SectionGateView: View {
    @Environment(\.dismiss) private var dismiss
    let progress: Int
    let icon: String
    let iconColor: Color
    let question: String
    let detail: String
    let yesLabel: String
    let noLabel: String
    let onYes: () -> Void
    let onNo: () -> Void

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 28) {
                // Progress
                AssessmentProgressBar(progress: Double(progress) / 6.0)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 80, height: 80)
                    Image(systemName: icon)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(iconColor)
                }

                // Question
                VStack(spacing: 10) {
                    Text(question)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                    Text(detail)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                // Choices
                VStack(spacing: 12) {
                    GateChoiceCard(
                        icon: "plus.circle.fill",
                        color: iconColor,
                        title: yesLabel,
                        subtitle: "Takes about 1–2 minutes",
                        isRecommended: true,
                        action: onYes
                    )
                    GateChoiceCard(
                        icon: "arrow.right.circle",
                        color: .secondary,
                        title: noLabel,
                        subtitle: "You can add this later from your profile",
                        isRecommended: false,
                        action: onNo
                    )
                }
                .padding(.horizontal, 20)

                Spacer()
            }
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
    }
}
