import SwiftUI

struct RetirementSWPInputView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppStateManager.self) private var appState

    @State private var currentAge: Int = 32
    @State private var retirementAge: Int = 60
    @State private var lifeExpectancyAge: Int = 85
    @State private var currentRetirementCorpus: Double = 1_500_000
    @State private var monthlySIPPreRetirement: Double = 30_000
    @State private var annualSIPStepUpRatePct: Double = 8.0
    @State private var preRetirementReturnPct: Double = 11.0
    @State private var postRetirementReturnPct: Double = 7.0
    @State private var monthlyLifestyleExpenseToday: Double = 60_000
    @State private var monthlyHealthcareExpenseToday: Double = 10_000
    @State private var lifestyleInflationPct: Double = 6.0
    @State private var healthcareInflationPct: Double = 8.0
    @State private var withdrawalMode: RetirementSWPWithdrawalMode = .inflationAdjusted
    @State private var fixedWithdrawalRatePct: Double = 4.0
    @State private var monthlyPensionOrGuaranteedIncome: Double = 15_000
    @State private var managementFeePct: Double = 0.5
    @State private var postRetirementTaxPct: Double = 10.0

    @State private var navigateToResult: Bool = false

    init() {}

    private var currentInput: RetirementSWPInput {
        RetirementSWPInput(
            currentAge: currentAge,
            retirementAge: retirementAge,
            lifeExpectancyAge: lifeExpectancyAge,
            currentRetirementCorpus: currentRetirementCorpus,
            monthlySIPPreRetirement: monthlySIPPreRetirement,
            annualSIPStepUpRatePct: annualSIPStepUpRatePct,
            preRetirementReturnPct: preRetirementReturnPct,
            postRetirementReturnPct: postRetirementReturnPct,
            monthlyLifestyleExpenseToday: monthlyLifestyleExpenseToday,
            monthlyHealthcareExpenseToday: monthlyHealthcareExpenseToday,
            lifestyleInflationPct: lifestyleInflationPct,
            healthcareInflationPct: healthcareInflationPct,
            withdrawalMode: withdrawalMode,
            fixedWithdrawalRatePct: fixedWithdrawalRatePct,
            customInitialMonthlyWithdrawal: nil,
            monthlyPensionOrGuaranteedIncome: monthlyPensionOrGuaranteedIncome,
            managementFeePct: managementFeePct,
            postRetirementTaxPct: postRetirementTaxPct,
            scenarioKind: .base
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header card
                headerCard

                // Age & Horizons
                ageHorizonCard

                // Accumulation & Corpus
                accumulationCard

                // Living Expenses & Inflation
                expensesAndInflationCard

                // SWP Strategy & Pension
                withdrawalStrategyCard

                // Run Simulation CTA
                simulateButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(AppTheme.appBackground(for: colorScheme))
        .navigationTitle("Retirement SWP Simulator")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToResult) {
            RetirementSWPResultView(input: currentInput)
        }
        .onAppear {
            seedFromProfile()
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "figure.walk.arrival")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppTheme.auraIndigo)
                Text("Retirement Income & SWP Engine")
                    .font(.auraHeader(size: 20))
            }

            Text("Calculate required retirement corpus, simulate month-by-month systematic withdrawals, and stress-test sequence of returns risk.")
                .font(.auraCaption())
                .foregroundStyle(.secondary)
        }
        .auraCardStyle(radius: 20)
    }

    private var ageHorizonCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SimulatorSectionHeader(
                title: "Planning Timeline",
                subtitle: "Current age, retirement horizon, and life expectancy",
                icon: "clock.arrow.circlepath"
            )

            HStack {
                Text("Current Age")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Stepper("\(currentAge) Years", value: $currentAge, in: 18...75)
            }

            HStack {
                Text("Planned Retirement Age")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Stepper("\(retirementAge) Years", value: $retirementAge, in: (currentAge + 1)...80)
            }

            HStack {
                Text("Life Expectancy")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Stepper("\(lifeExpectancyAge) Years", value: $lifeExpectancyAge, in: (retirementAge + 1)...100)
            }

            HStack {
                Text("Accumulation Horizon: \(max(0, retirementAge - currentAge)) yrs")
                Spacer()
                Text("Retirement Horizon: \(max(0, lifeExpectancyAge - retirementAge)) yrs")
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(AppTheme.auraIndigo)
        }
        .auraCardStyle(radius: 20)
    }

    private var accumulationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SimulatorSectionHeader(
                title: "Pre-Retirement Accumulation",
                subtitle: "Existing retirement corpus and monthly SIP",
                icon: "arrow.up.right.circle.fill"
            )

            SimulatorInputField(
                title: "Existing Retirement Savings & EPF/NPS",
                value: $currentRetirementCorpus,
                step: 100_000,
                range: 0...100_000_000
            )

            SimulatorInputField(
                title: "Monthly Retirement SIP",
                value: $monthlySIPPreRetirement,
                step: 5_000,
                range: 0...2_000_000
            )

            HStack {
                Text("Annual SIP Step-Up")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                TextField("Step Up", value: $annualSIPStepUpRatePct, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 50)
                Text("%")
            }

            HStack {
                Text("Expected Pre-Retirement Return")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                TextField("Return", value: $preRetirementReturnPct, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 50)
                Text("%")
            }
        }
        .auraCardStyle(radius: 20)
    }

    private var expensesAndInflationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SimulatorSectionHeader(
                title: "Living Expenses & Inflation",
                subtitle: "Today’s monthly costs with healthcare separation",
                icon: "cart.fill"
            )

            SimulatorInputField(
                title: "Monthly Household Lifestyle Cost (Today)",
                value: $monthlyLifestyleExpenseToday,
                step: 5_000,
                range: 10_000...2_000_000
            )

            SimulatorInputField(
                title: "Monthly Healthcare / Insurance Cost (Today)",
                value: $monthlyHealthcareExpenseToday,
                step: 2_500,
                range: 0...500_000
            )

            HStack {
                Text("General Lifestyle Inflation")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                TextField("Inf", value: $lifestyleInflationPct, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 50)
                Text("%")
            }

            HStack {
                Text("Healthcare Inflation (Higher Medical Drag)")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                TextField("Med Inf", value: $healthcareInflationPct, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 50)
                Text("%")
            }
        }
        .auraCardStyle(radius: 20)
    }

    private var withdrawalStrategyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SimulatorSectionHeader(
                title: "Withdrawal & Pension Planning",
                subtitle: "Drawdown mode, post-retirement returns, and other income",
                icon: "arrow.down.right.circle.fill"
            )

            Picker("Withdrawal Strategy", selection: $withdrawalMode) {
                ForEach(RetirementSWPWithdrawalMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }

            Text(withdrawalMode.description)
                .font(.auraCaption())
                .foregroundStyle(.secondary)

            HStack {
                Text("Expected Post-Retirement Portfolio Return")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                TextField("Return", value: $postRetirementReturnPct, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 50)
                Text("%")
            }

            SimulatorInputField(
                title: "Monthly Pension / Guaranteed Annuity Income",
                value: $monthlyPensionOrGuaranteedIncome,
                step: 5_000,
                range: 0...1_000_000
            )
        }
        .auraCardStyle(radius: 20)
    }

    private var simulateButton: some View {
        Button {
            navigateToResult = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 20))
                Text("Run SWP & Retirement Simulation")
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.accentGradient)
            .clipShape(Capsule())
            .shadow(color: AppTheme.auraIndigo.opacity(0.35), radius: 12, x: 0, y: 6)
        }
        .padding(.top, 8)
    }

    private func seedFromProfile() {
        guard let p = appState.currentProfile else { return }
        if p.basicDetails.age > 0 {
            currentAge = p.basicDetails.age
        }
        if p.basicDetails.monthlyExpenses > 0 {
            monthlyLifestyleExpenseToday = max(20_000, p.basicDetails.monthlyExpenses * 0.8)
            monthlyHealthcareExpenseToday = max(5_000, p.basicDetails.monthlyExpenses * 0.12)
        }
        let totalInvestments = p.investments.reduce(0.0) { $0 + $1.investmentAmount }
        if totalInvestments > 0 {
            currentRetirementCorpus = (totalInvestments * 0.6 / 100_000).rounded() * 100_000
        }
        if p.basicDetails.monthlyIncome > 0 {
            let surplus = max(5_000, (p.basicDetails.monthlyIncome - p.basicDetails.monthlyExpenses) * 0.4)
            monthlySIPPreRetirement = (surplus / 5_000).rounded() * 5_000
        }
    }
}
