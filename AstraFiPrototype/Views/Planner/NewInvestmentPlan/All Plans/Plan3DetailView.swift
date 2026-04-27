import SwiftUI
import Charts

struct Plan3DetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(AppStateManager.self) var appState

    var input: InvestmentPlanInputModel
    var result: Plan3Result
    var isFromTracker: Bool = false

    @State private var selectedScenario: String = "Moderate"
    @State private var investmentMode: String = "Lumpsum"
    @State private var lumpsumPhases: Int = 5
    @State private var isEMIDeductionOn: Bool = true
    @State private var showingSaveAlert = false
    @State private var alertMessage = ""
    @State private var showAssumptionsAlert = false

    @State private var currentResult: Plan3Result? = nil
    @State private var loanOverride: Double = 0
    @State private var tenureOverride: Int = 5
    @State private var bankName: String = ""
    @State private var interestRate: Double = 10.5
    @State private var emiFrequency: EMIFrequency = .monthly
    @State private var interestType: InterestType = .compounded
    @State private var selectedYearIndex: Int = 0

    private var activeResult: Plan3Result { currentResult ?? result }

    private var currentStrategy: LeveragedStrategyResult {
        switch selectedScenario {
        case "Conservative": return activeResult.conservative
        case "Moderate": return activeResult.moderate
        case "Aggressive": return activeResult.aggressive
        default: return activeResult.moderate
        }
    }

    private var totalInvested: Double {
        let lumpsum = activeResult.loanAmount 
        let totalEMIs = isEMIDeductionOn ? 0 : currentStrategy.totalEMIPaid
        return lumpsum + totalEMIs
    }

    private var planAssets: [PortfolioAsset] {
        guard let p = activeResult.portfolio else { return [] }
        let loanAmt = activeResult.loanAmount
        return p.allocations.map { allocation in
            let invested = loanAmt * (allocation.percentage / 100)
            // Growth is proportional across assets in this simple model
            let growthRatio = currentStrategy.finalValue / loanAmt
            let expectedVal = invested * growthRatio
            
            return PortfolioAsset(
                id: allocation.id,
                name: allocation.name,
                monthlyInvestment: invested,
                expectedValue: expectedVal,
                riskLevel: allocation.riskLevel
            )
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 24) {
                    targetVsEstimatedCard
                    assumptionsWarningSection
                    
                    riskTypeSection
                    totalInvestmentCard
                    scenarioTable
                    
                    interactiveAdjusters
                    repaymentStrategyCard
                    leveragedGraphCard
                    
                    bankDetailsCard
                    emiBreakdownCard
                    amortizationSummaryCard
                    
                    strategyBuilderCard
                    recommendationCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
            .background(AppTheme.appBackground(for: colorScheme))

            if !isFromTracker {
                savePlanFooter
            }
        }
        .onAppear {
            loanOverride = InvestmentPlannerEngine.parseAmount(input.targetAmount)
            tenureOverride = Int(input.timePeriod) ?? 5
            bankName = input.bankName ?? ""
            interestRate = input.interestRate ?? 10.5
            recalculate()
        }
        .navigationTitle("Leveraged Investing")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Action Successful", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .alert("Plan Assumptions", isPresented: $showAssumptionsAlert) {
            Button("Got It", role: .cancel) { }
        } message: {
            Text("This projection assumes steady growth based on historical performance, timely loan repayments, and no significant market crashes. Actual returns may vary.")
        }
    }

    private var savePlanFooter: some View {
        Button(action: {
            let model = InvestmentPlanModel(
                name: "Leveraged: \(activeResult.recommendedStrategy)",
                dateSaved: DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none),
                targetGoal: input.purposeOfInvestment,
                input: input
            )
            appState.savePlan(model)
            appState.showDashboard = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "star.fill")
                Text("Save & Follow Plan")
                    .font(.headline).fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(AppTheme.accentGradient)
            .cornerRadius(16)
            .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .background(
            ZStack {
                BlurView(style: .systemUltraThinMaterial)
                LinearGradient(colors: [Color(UIColor.systemBackground).opacity(0.6), Color(UIColor.systemBackground)], startPoint: .top, endPoint: .bottom)
            }
            .ignoresSafeArea()
            .frame(height: 120)
        )
    }

    private var targetVsEstimatedCard: some View {
        let target = InvestmentPlannerEngine.parseAmount(input.targetAmount)
        let strat = currentStrategy
        // Net Wealth (In-Hand) = finalValue if deduction (already subtracted), or finalValue - totalEMI if pocket
        let netWealth = isEMIDeductionOn ? strat.finalValue : strat.netProfit
        let grossValue = strat.finalValue + (isEMIDeductionOn ? strat.totalEMIPaid : 0)
        
        return HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Target Amount")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("₹\(formatL(target))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
            .shadow(color: AppTheme.adaptiveShadow.opacity(0.3), radius: 6)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("In-Hand (Net)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Image(systemName: "info.circle")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Text("₹\(formatL(netWealth))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text("Overall: ₹\(formatL(grossValue))")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
            .shadow(color: AppTheme.adaptiveShadow.opacity(0.3), radius: 6)
        }
    }

    private var riskTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Investment Profile")
                .font(.headline)
            
            HStack(spacing: 12) {
                RiskOptionCard(title: "Low", icon: "shield.fill", color: .green, isSelected: selectedScenario == "Conservative") {
                    selectedScenario = "Conservative"
                    recalculate()
                }
                RiskOptionCard(title: "Mid", icon: "chart.bar.fill", color: .orange, isSelected: selectedScenario == "Moderate") {
                    selectedScenario = "Moderate"
                    recalculate()
                }
                RiskOptionCard(title: "High", icon: "flame.fill", color: .red, isSelected: selectedScenario == "Aggressive") {
                    selectedScenario = "Aggressive"
                    recalculate()
                }
            }
        }
    }

    private var totalInvestmentCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "indianrupeesign.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                HStack {
                    Text("Overall Growth Summary")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Spacer()
                    Text("₹\(formatL(totalInvested))")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text("Invested")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            VStack(spacing: 8) {
                HStack {
                    Text("Scenario").font(.caption).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                    Text("Gain/Loss").font(.caption).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .trailing)
                    Text("Final Value").font(.caption).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .trailing)
                }
                
                ForEach(activeResult.scenarios) { scenario in
                    HStack {
                        Text(scenario.name).font(.system(size: 11, weight: .medium)).frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(scenario.gainLoss >= 0 ? "+" : "")\(formatL(scenario.gainLoss))")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(scenario.gainLoss >= 0 ? .green : .red)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        Text("₹\(formatL(scenario.finalValue))")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.3), radius: 8)
    }

    private var scenarioTable: some View {
        VStack(spacing: 16) {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    TableHeaderCell(text: "Investment Type", alignment: .leading,  flex: 2.5)
                    TableHeaderCell(text: "Invested",        alignment: .trailing, flex: 1.5)
                    TableHeaderCell(text: "Expected",        alignment: .trailing, flex: 1.5)
                    TableHeaderCell(text: "Risk",            alignment: .trailing, flex: 1.2)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
                .background(Color(UIColor.secondarySystemBackground))

                Group {
                    ForEach(planAssets) { asset in
                        HStack(spacing: 0) {
                            Text(asset.name).font(.caption).foregroundColor(.primary).frame(maxWidth: .infinity * 2.5, alignment: .leading)
                            Text("₹\(Int(asset.monthlyInvestment))").font(.caption).foregroundColor(.primary).frame(maxWidth: .infinity * 1.5, alignment: .trailing)
                            Text("₹\(formatL(asset.expectedValue))").font(.caption).foregroundColor(.secondary).frame(maxWidth: .infinity * 1.5, alignment: .trailing)
                            Text(asset.riskLevel.rawValue.capitalized).font(.system(size: 10, weight: .bold))
                                .foregroundColor(asset.riskLevel == .high ? .red : (asset.riskLevel == .low ? .green : .orange))
                                .frame(maxWidth: .infinity * 1.2, alignment: .trailing)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 8)
                        
                        if asset.id != planAssets.last?.id {
                            Divider()
                        }
                    }
                }
            }
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.3), radius: 8)
    }

    private var repaymentStrategyCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Repayment Strategy")
                .font(.headline)
            
            Text("How would you like to handle your loan EMIs? This selection changes your net wealth outcome.")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                // Option 1: Automated
                StrategyOptionButton(
                    title: "Automated",
                    subtitle: "Pay from Growth",
                    description: "EMIs are deducted from returns.",
                    isSelected: isEMIDeductionOn,
                    action: { 
                        isEMIDeductionOn = true
                        recalculate()
                    }
                )
                
                // Option 2: Manual
                StrategyOptionButton(
                    title: "Manual",
                    subtitle: "Pay from Pocket",
                    description: "Pay EMIs from monthly savings.",
                    isSelected: !isEMIDeductionOn,
                    action: { 
                        isEMIDeductionOn = false
                        recalculate()
                    }
                )
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.3), radius: 8)
    }

    private var assumptionsWarningSection: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Important Notice")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        alertMessage = "This plan assumes steady market growth based on historical data, timely loan repayments, and no major economic crashes. Calculations account for tax-efficient arbitrage spreads where applicable."
                        showingSaveAlert = true // Reusing for generic alerts if needed, or add showAssumptionsAlert
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
                Text("This plan is based on certain assumptions. Kindly pursue this plan at your own risk.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    private var roiSummaryCard: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Expected Market ROI")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(String(format: "%.1f", activeResult.portfolio?.blendedCAGR ?? 0))%")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Arb. Strategy Spread")
                    .font(.caption)
                    .foregroundColor(.secondary)
                let spread = (currentStrategy.netProfit / (activeResult.loanAmount > 0 ? activeResult.loanAmount : 1)) * 100
                Text("\(String(format: "%.1f", spread))%")
                    .font(.headline)
                    .foregroundColor(spread >= 0 ? .green : .red)
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.2), radius: 4)
    }

    private func recalculate() {
        let newResult = InvestmentPlannerEngine.recalculatePlan3(
            input: input,
            overridenLoan: loanOverride,
            overridenTenure: tenureOverride,
            overridenBank: bankName.isEmpty ? nil : bankName,
            overridenRate: interestRate > 0 ? interestRate : nil,
            overridenReturn: nil,
            emiFrequency: emiFrequency,
            interestType: interestType,
            investmentMode: investmentMode,
            lumpsumPhases: lumpsumPhases,
            emiFromPocket: !isEMIDeductionOn
        )
        withAnimation {
            currentResult = newResult
        }
    }



    private var scenarioComparisonCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Strategy Selection")
                .font(.headline)

            Picker("Strategy Selection", selection: $selectedScenario) {
                ForEach(["Conservative", "Moderate", "Aggressive"], id: \.self) { scenario in
                    Text(scenario).tag(scenario)
                }
            }
            .pickerStyle(.segmented)

            let strat = currentStrategy
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Projected Final Value").font(.caption).foregroundColor(.secondary)
                    Text("₹\(formatL(strat.finalValue))").font(.title3).bold()
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Risk Profile").font(.caption).foregroundColor(.secondary)
                    Text(strat.riskLevel).foregroundColor(strat.riskLevel == "High" ? .red : (strat.riskLevel == "Low" ? .green : .orange)).bold()
                }
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.3), radius: 8)
    }

    private var leveragedGraphCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Growth Projection")
                .font(.headline)

            Chart {
                ForEach(currentStrategy.yearlyBreakdown) { year in
                    LineMark(
                        x: .value("Year", year.year),
                        y: .value("Value", year.monthlySteps.last?.endValue ?? 0)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Year", year.year),
                        y: .value("Value", year.monthlySteps.last?.endValue ?? 0)
                    )
                    .foregroundStyle(Color.blue.opacity(0.1).gradient)
                    .interpolationMethod(.catmullRom)
                }

                RuleMark(y: .value("Loan Principal", activeResult.loanAmount))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    .foregroundStyle(.gray.opacity(0.5))
            }
            .frame(height: 180)
            .chartXScale(domain: 1...Swift.max(2, activeResult.tenure))

            HStack {
                HStack(spacing: 4) {
                    Circle().fill(Color.blue).frame(width: 8, height: 8)
                    Text("Portfolio Value").font(.caption2).foregroundColor(.secondary)
                }
                HStack(spacing: 4) {
                    Rectangle().fill(Color.gray.opacity(0.5)).frame(width: 12, height: 1)
                    Text("Loan Principal").font(.caption2).foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.3), radius: 8)
    }

    private var interactiveAdjusters: some View {
        VStack(spacing: 20) {
            Text("Loan Adjustment")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Loan Amount").font(.footnote).foregroundColor(.secondary)
                    Spacer()
                    Text("₹\(Int(loanOverride).formatted())").font(.subheadline).bold()
                }
                Slider(value: $loanOverride, in: 50000...10000000, step: 50000)
                    .onChange(of: loanOverride) { _, _ in recalculate() }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Duration (Years)").font(.footnote).foregroundColor(.secondary)
                    Spacer()
                    Text("\(tenureOverride)").font(.subheadline).bold()
                }
                Slider(value: Binding(get: { Double(tenureOverride) }, set: { tenureOverride = Int($0) }), in: 1...25, step: 1)
                    .onChange(of: tenureOverride) { _, _ in recalculate() }
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
    }

    private var bankDetailsCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 8) {
                Image(systemName: "building.columns.fill")
                    .foregroundColor(.blue)
                Text("Loan Configuration")
                    .font(.headline)
            }
            
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Bank Name").font(.caption).foregroundColor(.secondary)
                        TextField("e.g. HDFC", text: $bankName)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(10)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Interest Rate").font(.caption).foregroundColor(.secondary)
                        HStack {
                            TextField("ROI", value: $interestRate, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.plain)
                            Text("%").font(.subheadline).foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(10)
                        .frame(width: 100)
                    }
                }
                .onChange(of: interestRate) { _, _ in recalculate() }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Payment Frequency").font(.caption).foregroundColor(.secondary)
                    Picker("EMI Type", selection: $emiFrequency) {
                        Text("Monthly").tag(EMIFrequency.monthly)
                        Text("Quarterly").tag(EMIFrequency.quarterly)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: emiFrequency) { _, _ in recalculate() }
                }
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.2), radius: 10)
    }

    private var emiBreakdownCard: some View {
        let monthlyEMI = activeResult.monthlyEMI
        let totalInterest = currentStrategy.totalEMIPaid - activeResult.loanAmount
        
        return VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly EMI")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("₹\(Int(monthlyEMI).formatted())")
                        .font(.title2)
                        .fontWeight(.black)
                        .foregroundColor(.primary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(AppTheme.accentGradient.opacity(0.1))
                        .frame(width: 50, height: 50)
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.blue)
                }
            }
            
            Divider()
            
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Loan Principal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("₹\(formatL(activeResult.loanAmount))")
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Interest")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("₹\(formatL(totalInterest))")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.2), radius: 10)
    }

    private var amortizationSummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.doc.horizontal.fill")
                    .foregroundColor(.orange)
                Text("Repayment Timeline")
                    .font(.headline)
                Spacer()
                Text("\(tenureOverride) Years").font(.caption).foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("Year").font(.caption).foregroundColor(.secondary).frame(width: 40, alignment: .leading)
                    Text("Principal").font(.caption).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .trailing)
                    Text("Interest").font(.caption).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .trailing)
                    Text("Balance").font(.caption).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .trailing)
                }
                
                Divider()
                
                let yearlyData = currentStrategy.yearlyBreakdown
                ForEach(yearlyData.prefix(5)) { year in
                    HStack {
                        Text("\(year.year)").font(.system(size: 11, weight: .bold)).frame(width: 40, alignment: .leading)
                        Text("₹\(formatL(activeResult.loanAmount / Double(tenureOverride)))").font(.system(size: 11)).frame(maxWidth: .infinity, alignment: .trailing)
                        Text("₹\(formatL((currentStrategy.totalEMIPaid - activeResult.loanAmount) / Double(tenureOverride)))").font(.system(size: 11)).foregroundColor(.red).frame(maxWidth: .infinity, alignment: .trailing)
                        let remaining = activeResult.loanAmount - (Double(year.year) * (activeResult.loanAmount / Double(tenureOverride)))
                        Text("₹\(formatL(max(0, remaining)))").font(.system(size: 11, weight: .semibold)).frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                
                if tenureOverride > 5 {
                    Text("+ \(tenureOverride - 5) more years")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.2), radius: 10)
    }

    private var recommendationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("Astra Recommendation").font(.headline)
            }
            Text(activeResult.recommendationReason)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                AppTheme.cardBackground
                LinearGradient(colors: [.purple.opacity(0.05), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        )
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.2), radius: 10)
    }

    private var strategyBuilderCard: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Strategy Builder").font(.headline)
                    Text("Phase-wise capital injection").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Stepper("", value: $lumpsumPhases, in: 1...12)
                    .onChange(of: lumpsumPhases) { _, _ in recalculate() }
            }

            StrategyCircularChart(total: activeResult.loanAmount, phases: lumpsumPhases, mode: "Lumpsum")

            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                Text(isEMIDeductionOn ? "EMI is automatically withdrawn from the investment." : "EMI is paid from your surplus monthly.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(24)
        .background(AppTheme.cardBackground)
        .cornerRadius(24)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.2), radius: 10)
    }

    private func formatL(_ v: Double) -> String {
        let absV = abs(v)
        if absV >= 10000000 { return String(format: "%.1fCr", v / 10000000) }
        if absV >= 100000 { return String(format: "%.1fL", v / 100000) }
        if absV >= 1000 { return String(format: "%.1fK", v / 1000) }
        return String(format: "%.0f", v)
    }

    private func monthLabel(for i: Int) -> String {
        ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][i % 12]
    }
}

struct StrategyCircularChart: View {
    let total: Double
    let phases: Int
    let mode: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.1), lineWidth: 20)
                .frame(width: 170, height: 170)

            ForEach(0..<12) { i in
                let interval = max(1, 12 / max(1, phases))
                let isHighlighted = mode == "Lumpsum" && (i % interval == 0) && (i / interval < phases)

                Circle()
                    .trim(from: CGFloat(i) * 1/12 + 0.005, to: CGFloat(i+1) * 1/12 - 0.005)
                    .stroke(isHighlighted ? Color.blue.gradient : Color.secondary.opacity(0.15).gradient, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 170, height: 170)
                    .rotationEffect(.degrees(-90))
            }

            VStack(spacing: 4) {
                Text("₹\(InvestmentPlannerEngine.formatL_Internal(total))")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Text("\(phases) Injection phases")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
        .frame(height: 200)
    }
}

struct StrategyOptionButton: View {
    let title: String
    let subtitle: String
    let description: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title).font(.subheadline).bold()
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                }
                Text(description).font(.system(size: 10)).foregroundColor(.secondary).multilineTextAlignment(.leading)
            }
            .padding(12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1))
        }
    }
}

#Preview {
    Plan3PreviewWrapper()
}

struct Plan3PreviewWrapper: View {
    var body: some View {
        let sampleInput = InvestmentPlanInputModel(investmentType: "Lumpsum", amount: "5,00,000", liquidity: "Moderate", riskType: "Moderate", timePeriod: "5", scheduleInvestmentDate: Date(), scheduleSIPDate: Date(), purposeOfInvestment: "Wealth Creation", targetAmount: "15,00,000", savedAmount: "50,000", hasEmergencyFund: true)
        let plan3 = InvestmentPlannerEngine.generateFullPlan(input: sampleInput).plan3 ?? Plan3Result.empty()
        Plan3DetailView(input: sampleInput, result: plan3)
            .environment(AppStateManager.withSampleData())
    }
}
