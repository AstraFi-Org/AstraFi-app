import SwiftUI

struct REITSimulatorInputView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppStateManager.self) private var appState

    @State private var assetName: String = "Embassy / Brookfield / Nexus REIT Basket"
    @State private var initialInvestment: Double = 500_000
    @State private var recurringMonthlyContribution: Double = 15_000
    @State private var investmentHorizonYears: Int = 10
    @State private var purchasePricePerUnit: Double = 350.0
    @State private var distributionYieldPct: Double = 6.8
    @State private var expectedDistributionGrowthPct: Double = 4.0
    @State private var expectedPriceAppreciationPct: Double = 5.0
    @State private var reinvestDistributions: Bool = true
    @State private var transactionCostPct: Double = 0.5
    @State private var distributionTaxPct: Double = 10.0
    @State private var capitalGainsTaxPct: Double = 12.5

    @State private var navigateToResult: Bool = false

    init() {}

    private var currentInput: REITSimulatorInput {
        REITSimulatorInput(
            assetName: assetName,
            initialLumpSumInvestment: initialInvestment,
            recurringMonthlyContribution: recurringMonthlyContribution,
            investmentHorizonYears: investmentHorizonYears,
            purchasePricePerUnit: purchasePricePerUnit,
            distributionYieldPct: distributionYieldPct,
            expectedAnnualDistributionGrowthPct: expectedDistributionGrowthPct,
            expectedAnnualPriceAppreciationPct: expectedPriceAppreciationPct,
            reinvestDistributions: reinvestDistributions,
            transactionCostPct: transactionCostPct,
            distributionTaxPct: distributionTaxPct,
            capitalGainsTaxPct: capitalGainsTaxPct,
            scenarioKind: .base
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header card
                headerCard

                // Investment & Horizon Card
                investmentDetailsCard

                // Yield & Market Assumptions Card
                yieldAndGrowthCard

                // Reinvestment & Tax Card
                reinvestmentAndTaxCard

                // Run Simulation CTA
                simulateButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(AppTheme.appBackground(for: colorScheme))
        .navigationTitle("REIT & Listed Assets")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToResult) {
            REITSimulatorResultView(input: currentInput)
        }
        .onAppear {
            seedFromProfile()
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "building.2.crop.circle.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppTheme.auraIndigo)
                Text("REIT & Listed Asset Simulator")
                    .font(.auraHeader(size: 20))
            }

            Text("Simulate rental yields, capital growth, and distribution reinvestment across listed Real Estate Investment Trusts and infrastructure trusts.")
                .font(.auraCaption())
                .foregroundStyle(.secondary)
        }
        .auraCardStyle(radius: 20)
    }

    private var investmentDetailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SimulatorSectionHeader(
                title: "Capital & Horizon",
                subtitle: "Lump sum, monthly SIP, and time frame",
                icon: "banknote.fill"
            )

            TextField("Asset / Basket Name", text: $assetName)
                .font(.system(size: 15, weight: .semibold))
                .padding(12)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            SimulatorInputField(
                title: "Initial Lump Sum Investment",
                value: $initialInvestment,
                step: 50_000,
                range: 0...50_000_000
            )

            SimulatorInputField(
                title: "Monthly Contribution (SIP)",
                value: $recurringMonthlyContribution,
                step: 5_000,
                range: 0...5_000_000
            )

            HStack {
                Text("Investment Horizon")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Stepper("\(investmentHorizonYears) Years", value: $investmentHorizonYears, in: 1...30)
            }
        }
        .auraCardStyle(radius: 20)
    }

    private var yieldAndGrowthCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SimulatorSectionHeader(
                title: "Distribution Yield & Capital Growth",
                subtitle: "Assumed rental yield and unit price appreciation",
                icon: "chart.line.uptrend.xyaxis"
            )

            HStack {
                Text("Unit Purchase Price")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                TextField("Price", value: $purchasePricePerUnit, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text("₹")
            }

            HStack {
                Text("Annual Distribution Yield")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                TextField("Yield", value: $distributionYieldPct, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                Text("%")
            }

            HStack {
                Text("Annual Distribution Growth (Rent Escalation)")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                TextField("Growth", value: $expectedDistributionGrowthPct, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                Text("%")
            }

            HStack {
                Text("Annual Unit Price Appreciation")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                TextField("Growth", value: $expectedPriceAppreciationPct, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                Text("%")
            }
        }
        .auraCardStyle(radius: 20)
    }

    private var reinvestmentAndTaxCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SimulatorSectionHeader(
                title: "Reinvestment & Taxation",
                subtitle: "DRIP compounding and statutory deductions",
                icon: "arrow.triangle.2.circlepath"
            )

            Toggle(isOn: $reinvestDistributions) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reinvest Distributions (DRIP)")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Automatically buy more units with quarterly payouts")
                        .font(.auraCaption())
                        .foregroundStyle(.secondary)
                }
            }
            .tint(AppTheme.auraIndigo)

            HStack {
                Text("Transaction Brokerage / STT")
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                TextField("Fee", value: $transactionCostPct, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 50)
                Text("%")
            }

            HStack {
                Text("Distribution Tax Rate")
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                TextField("Tax", value: $distributionTaxPct, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 50)
                Text("%")
            }
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
                Text("Simulate REIT Strategy")
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
        let totalInvestments = p.investments.reduce(0.0) { $0 + $1.investmentAmount }
        if totalInvestments >= 200_000 {
            initialInvestment = min(1_000_000, (totalInvestments * 0.25 / 50_000).rounded() * 50_000)
        }
        if p.basicDetails.monthlyIncome > 0 {
            let surplus = max(5_000, (p.basicDetails.monthlyIncome - p.basicDetails.monthlyExpenses) * 0.3)
            recurringMonthlyContribution = (surplus / 5_000).rounded() * 5_000
        }
    }
}
