import SwiftUI

// MARK: - Phase 1: Core Vitals (Name, Age, Income, Expenses only)

struct BasicDetailView: View {
    @Bindable var data: CompleteAssessmentData
    @Environment(AppStateManager.self) var appState
    @Environment(\.dismiss) private var dismiss

    @State private var goNext = false
    @State private var goSkipToInvestment = false
    @State private var goToInvestmentQuestion = false
    // nil = not answered, true = has EF, false = no EF
    @State private var hasEmergencyFund: Bool? = nil
    // nil = not answered, true = wants to share EF amount, false = skipped
    @State private var wantsToShareEF: Bool? = nil

    // ── Live computed values
    private var income: Double   { Double(data.income) ?? 0 }
    private var expenses: Double { Double(data.expenditure) ?? 0 }
    private var age: Int         { Int(data.age) ?? 0 }

    private var surplus: Double      { max(0, income - expenses) }
    private var savingsRate: Double  { income > 0 ? (surplus / income) * 100 : 0 }
    private var expenseRatio: Double { income > 0 ? (expenses / income) * 100 : 0 }

    private var showCard: Bool { income > 0 }

    // Show EF question once income + expenses are entered
    private var showEFQuestion: Bool { income > 0 && expenses > 0 }

    private var canContinue: Bool {
        !data.name.trimmingCharacters(in: .whitespaces).isEmpty
        && income > 0
        && expenses > 0
        && age > 0
        && hasEmergencyFund != nil
        && (hasEmergencyFund == false || wantsToShareEF != nil)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── Page title (scrolls with content)
                    VStack(alignment: .leading) {
                        Text("Let's get started")
                            .font(.system(size: 28, weight: .bold))
                        Text("Your basics help us calculate your financial health in real time.")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
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
                        HStack{
                            AssessmentField(
                                icon: "indianrupeesign.circle.fill",
                                label: "Monthly Disposable Income (₹)",
                                placeholder: "e.g. 75000",
                                text: $data.income,
                                keyboard: .numberPad
                            )
                            Text("Disposable (inhand) income means income after all taxs and other deductions.")
                                .font(.callout)
                        }
                        AssessmentField(
                            icon: "cart.fill",
                            label: "Total Fixed Monthly Expenses (₹)",
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

                    // ── Emergency Fund Question
                    if showEFQuestion {
                        EmergencyFundQuestionCard(
                            income: income,
                            hasEmergencyFund: $hasEmergencyFund
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onChange(of: hasEmergencyFund) { _, _ in
                            wantsToShareEF = nil
                        }
                    }

                    // ── Conditional EF card based on answer
                    if let hasEF = hasEmergencyFund {
                        if hasEF {
                            EFSharePromptCard(
                                wantsToShareEF: $wantsToShareEF,
                                onYes: { goNext = true },
                                onSkip: { goSkipToInvestment = true }
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .transition(.scale(scale: 0.95).combined(with: .opacity))
                        } else {
                            EFNecessityCard(
                                income: income,
                                expenses: expenses,
                                onProceed: { goToInvestmentQuestion = true }
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .transition(.scale(scale: 0.95).combined(with: .opacity))
                        }
                    }

                    Spacer().frame(height: 120)
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: showCard)
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: showEFQuestion)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: hasEmergencyFund)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: wantsToShareEF)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: savingsRate)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: expenseRatio)
            .safeAreaInset(edge: .top, spacing: 0) {
                AssessmentProgressBar(progress: 0.2)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(.systemGroupedBackground))
            }

            // ── Footer
//            VStack(spacing: 0) {
//                if !canContinue {
//                    Text(
//                        data.name.trimmingCharacters(in: .whitespaces).isEmpty ? "Enter your name to continue" :
//                            income == 0 ? "Enter your monthly income to continue" :
//                            expenses == 0 ? "Enter your monthly expenses to continue" :
//                            age == 0 ? "Enter your age to continue" :
//                            hasEmergencyFund == nil ? "Answer the emergency fund question to continue" :
//                            "Choose whether to share your emergency fund amount"
//                    )
//                    .font(.caption)
//                    .foregroundStyle(.secondary)
//                    .multilineTextAlignment(.center)
//                    .padding(.horizontal, 20)
//                    .padding(.bottom, 8)
//                }
//            }
        }
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Skip") {
                    appState.updateProfile(from: data)
                    appState.isAssessmentSkipped = true
                    appState.showDashboard = true
                }
                .font(.system(size: 15))
            }
        }
        .navigationDestination(isPresented: $goNext) {
            Phase1BView(data: data)
        }
        .navigationDestination(isPresented: $goSkipToInvestment) {
            InvestmentQuestionView(data: data)
        }
        .navigationDestination(isPresented: $goToInvestmentQuestion) {
            InvestmentQuestionView(data: data)
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

// MARK: - Emergency Fund Question Card
struct EmergencyFundQuestionCard: View {
    let income: Double
    @Binding var hasEmergencyFund: Bool?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack(spacing: 8) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.vibrantCyan)
                Text("Quick Check")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("The best way to stay financially stable is an emergency fund.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Do you already have Emergency Fund?")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }

            HStack(spacing: 12) {
                EFChoiceButton(
                    label: "Yes, I do",
                    color: AppTheme.auraGreen,
                    isSelected: hasEmergencyFund == true
                ) {
                    hasEmergencyFund = true
                }

                EFChoiceButton(
                    label: "Not yet",
                    color: AppTheme.vibrantRed,
                    isSelected: hasEmergencyFund == false
                ) {
                    hasEmergencyFund = false
                }
            }
        }
        .padding(18)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.vibrantCyan.opacity(0.18), lineWidth: 1)
        )
    }
}

// MARK: - Yes/No Choice Button (no icons)
private struct EFChoiceButton: View {
    let label: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
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

// MARK: - EF Share Prompt Card
// MARK: - Reusable Choice Button
struct EFChoiceButton2: View {
    let label: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? .white : color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? color : color.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(color.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
    }
}

// MARK: - Main Card View
struct EFSharePromptCard: View {
    @Binding var wantsToShareEF: Bool?
    let onYes: () -> Void
    let onSkip: () -> Void

    // Local selection state to drive button appearance
    @State private var selectedChoice: Bool? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(AppTheme.auraGreen)
                VStack(alignment: .leading, spacing: 2) {
                    Text("That's great!")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.auraGreen)
                    Text("Having an emergency fund puts you ahead of most people.")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            Divider().opacity(0.4)

            VStack(alignment: .leading, spacing: 6) {
                Text("Would you like to share the amount of your emergency fund?")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)

                Text("It will help us understand your financial stability and give you a more accurate assessment.")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 12) {
                // YES button
                EFChoiceButton2(
                    label: "Yes, let's do it",
                    color: AppTheme.auraGreen,
                    isSelected: selectedChoice == true
                ) {
                    selectedChoice = true
                    wantsToShareEF = true
                    // Small delay so user sees the selection before navigation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onYes()
                    }
                }

                // SKIP button
                EFChoiceButton2(
                    label: "Skip for now",
                    color: AppTheme.vibrantOrange,
                    isSelected: selectedChoice == false
                ) {
                    selectedChoice = false
                    wantsToShareEF = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onSkip()
                    }
                }
            }
        }
        .padding(18)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.auraGreen.opacity(0.22), lineWidth: 1)
        )
    }
}

// MARK: - "No EF" Necessity Card
struct EFNecessityCard: View {
    let income: Double
    let expenses: Double
    var onProceed: (() -> Void)? = nil

    private var target: Double { income * 6 }
    private var monthlyStep: Double { target / 12 }

    @State private var ringProgress: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack(spacing: 8) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.vibrantCyan)
                Text("Build Your Safety Net")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                Spacer()
                Text("Priority #1")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.vibrantOrange)
                    .clipShape(Capsule())
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Your target")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text(target.toCurrency(compact: true))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.auraGreen)
                            .contentTransition(.numericText())
                        Text("6 × monthly income")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(.secondary)
                    }

                    Divider().opacity(0.4)

                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppTheme.auraGold)
                        Text("Save \(monthlyStep.toCurrency(compact: true))/mo to get there in 1 year")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            HStack(spacing: 8) {
                factPill(icon: "bolt.fill",        color: AppTheme.vibrantOrange, text: "Job loss shield")
                factPill(icon: "cross.fill",       color: AppTheme.vibrantRed,    text: "Medical cover")
                factPill(icon: "lock.shield.fill", color: AppTheme.auraIndigo,    text: "No debt trap")
            }

            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.auraIndigo)
                Text("Park it in a liquid fund — not equities. You'll enter your current amount on the next screen.")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .background(AppTheme.auraIndigo.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            if let proceed = onProceed {
                Button(action: proceed) {
                    HStack(spacing: 8) {
                        Text("Proceed")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                        
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppTheme.auraGreen)
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .padding(18)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.vibrantOrange.opacity(0.15), lineWidth: 1)
        )
        .onAppear { ringProgress = 0.04 }
    }

    private func factPill(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)
            Text(text)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.primary.opacity(0.75))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(color.opacity(0.08))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.18), lineWidth: 1))
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var data = CompleteAssessmentData()
    let appState = AppStateManager.withSampleData()

    NavigationStack {
        BasicDetailView(data: data)
            .environment(appState)
    }
}
