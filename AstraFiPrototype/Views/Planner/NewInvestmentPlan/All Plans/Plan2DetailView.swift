import SwiftUI
import Charts
import UIKit

struct Plan2DetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(TrackerViewModel.self) var trackerVM
    @Environment(AppStateManager.self) var appState
    @State private var animateChart = false
    @State private var showingSaveAlert = false
    @State private var alertMessage = ""

    var input: InvestmentPlanInputModel
    var result: Plan2Result
    var isFromTracker: Bool = false

    @State private var currentResult: Plan2Result? = nil
    @State private var loanOverride: Double = 0
    @State private var tenureOverride: Int = 0
    @State private var emiFrequency: EMIFrequency = .monthly 
    @State private var interestType: InterestType = .compounded

    private var activeResult: Plan2Result { currentResult ?? result }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 24) {
                    loanEligibilityCard
                    affordabilityWarning
                    interactiveAdjusters
                    bankInfoRow
                    timelineSection
                    emiComparisonTables
                    loanMetrics
                    loanRecommendation
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
            .background(AppTheme.appBackground(for: colorScheme))

            if !isFromTracker {
                savePlanFooter
            }
        }
        .alert("Plan Updated", isPresented: $showingSaveAlert) {
             Button("OK", role: .cancel) { }
             Button("Tracker") { 
                 appState.showDashboard = true
                 dismiss()
             }
        } message: {
             Text(alertMessage)
        }
        .navigationTitle("Debt Optimization Plan")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if loanOverride == 0 {
                loanOverride = InvestmentPlannerEngine.parseAmount(input.targetAmount)
            }
            if tenureOverride == 0 {
                tenureOverride = Int(input.timePeriod) ?? 5
                if tenureOverride <= 0 { tenureOverride = 1 }
            }
        }
    }

    private var savePlanFooter: some View {
        let planName = result.name
        let isSaved = trackerVM.savedPlanNames.contains(planName)
        let isFollowed = trackerVM.followedPlanNames.contains(planName)

        return HStack(spacing: 12) {
            Button(action: {
                if isSaved {
                    trackerVM.unsavePlan(planName: planName)
                    alertMessage = "Plan removed."
                } else {
                    trackerVM.savePlan(planName: planName, input: input)
                    alertMessage = "Plan saved to profile."
                }
                showingSaveAlert = true
            }) {
                HStack {
                    Image(systemName: isSaved ? "star.fill" : "star")
                    Text(isSaved ? "Saved" : "Save")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isSaved ? Color.gray.opacity(0.1) : Color.purple.opacity(0.1))
                .foregroundColor(isSaved ? .gray : .purple)
                .cornerRadius(12)
            }

            Button(action: {
                if isFollowed {
                    trackerVM.unfollowPlan(planName: planName)
                    alertMessage = "Unfollowed plan."
                } else {
                    trackerVM.followPlan(planName: planName, input: input)

                    let targetDate = Calendar.current.date(byAdding: .year, value: tenureOverride, to: Date()) ?? Date()
                    let goalName = input.purposeOfInvestment.isEmpty ? result.name : input.purposeOfInvestment
                    appState.addGoal(AstraGoal(goalName: goalName, targetAmount: activeResult.netWealthGain, currentAmount: 0, targetDate: targetDate))

                    alertMessage = "Plan active! Debt optimization goal added."
                }
                showingSaveAlert = true
            }) {
                HStack {
                    Image(systemName: isFollowed ? "checkmark.circle.fill" : "plus.circle.fill")
                    Text(isFollowed ? "Following" : "Follow Plan")
                }
                .font(.headline).fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isFollowed ? Color.green : Color.purple)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(20)
        .background(
            ZStack {
                BlurView(style: UIBlurEffect.Style.systemUltraThinMaterial)
                LinearGradient(colors: [Color(UIColor.systemBackground).opacity(0.8), Color(UIColor.systemBackground)], startPoint: .top, endPoint: .bottom)
            }
            .ignoresSafeArea()
            .frame(height: 100)
        )
    }

    private var interactiveAdjusters: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.cyan)
                        .font(.headline)
                    Text("Interactive Adjustments")
                        .font(.headline)
                    Spacer()
                }
                Text("Fine-tune your loan amount and tenure to see how it impacts your EMI and long-term debt.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            let targetVal = InvestmentPlannerEngine.parseAmount(input.targetAmount)
            let safeMin = max(50000, targetVal * 0.5)
            let safeMax = max(safeMin + 50000, targetVal * 1.5)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Loan Amount")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("₹\(Int(loanOverride).formatted())")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }

                Slider(value: Binding(get: { loanOverride }, set: { 
                    loanOverride = $0
                    recalculate()
                }), in: safeMin...safeMax, step: 50000)
                    .accentColor(.blue)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Time Period")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(tenureOverride) Years")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                Slider(value: Binding(get: { Double(tenureOverride) }, set: { 
                    tenureOverride = Int($0)
                    recalculate()
                }), in: 1...30, step: 1)
                .tint(.blue)
            }
        }
        .padding(24)
        .background(AppTheme.cardBackground)
        .cornerRadius(24)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.5), radius: 12, x: 0, y: 6)
    }

    private func recalculate() {
        let newResult = InvestmentPlannerEngine.recalculatePlan2(
            input: input,
            overridenLoan: loanOverride, 
            overridenSIP: 0,
            overridenTenure: tenureOverride,
            emiFrequency: emiFrequency,
            interestType: interestType
        )
        withAnimation {
            currentResult = newResult
        }
    }

    private var timelineSection: some View {
        Plan2InteractiveTimelineView(
            yearlyData: activeResult.yearlyBreakdown,
            loanAmount: activeResult.loanAmount,
            totalTenure: tenureOverride,
            emiFrequency: $emiFrequency,
            interestType: $interestType,
            onRecalculate: { recalculate() }
        )
    }

    private var loanHeaderCard: some View {
        HStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Loan Amount")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Text("₹\(formatL_Detail(activeResult.loanAmount))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)
                .background(Color.secondary.opacity(0.3))

            VStack(spacing: 8) {
                Text("Interest Rate")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                let displayRate = activeResult.loanRate > 0 ? activeResult.loanRate : (input.interestRate ?? 9.5)
                Text("\(String(format: "%.1f", displayRate))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 24)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow, radius: 10, x: 0, y: 4)
    }

    private var affordabilityWarning: some View {
        let profile = appState.currentProfile
        let income = profile?.basicDetails.monthlyIncomeAfterTax ?? input.monthlyIncome
        let expenses = profile?.basicDetails.monthlyExpenses ?? (income * 0.45)
        let existingEMIs = profile?.loans.reduce(0.0) { $0 + $1.calculatedEMI } ?? input.existingEMIs

        let ongoingSIPs = profile?.investments.filter { $0.mode == .sip }.reduce(0.0) { $0 + $1.investmentAmount } ?? 0.0

        let availableSurplus = income - expenses - existingEMIs - ongoingSIPs

        let monthlyEMIEquivalent = activeResult.monthlyEMI / (12 / emiFrequency.paymentsPerYear)
        let planCommitment = monthlyEMIEquivalent + activeResult.monthlySIPKept

        return Group {
            if planCommitment > availableSurplus && availableSurplus > 0 {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Affordability Warning")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        Text("You don't have enough monthly savings (₹\(Int(availableSurplus).formatted())/mo) after excluding all ongoing EMIs or investment SIPs to cover the monthly equivalent EMI (₹\(Int(monthlyEMIEquivalent).formatted())/mo). You may need to stop any SIP or EMI, or adjust your loan.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(16)
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.3), lineWidth: 1))
            }
        }
    }

    private var bankInfoRow: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "building.columns.fill")
                    .foregroundColor(.blue)
                Text(input.bankName ?? "HDFC Bank")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            Spacer()
            Text("\(String(format: "%.1f", activeResult.loanRate))")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .overlay(
                    Rectangle()
                        .frame(height: 2)
                        .offset(y: 18),
                    alignment: .bottom
                )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }

    private var profitFlowVisual: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.branch")
                    .foregroundColor(.gray).font(.body)
                Text("Money Flow").font(.subheadline).fontWeight(.semibold)
            }

            VStack(spacing: 0) {
                FlowNode(icon: "banknote.fill",           title: "Loan Taken",    value: "₹\(formatL_Detail(activeResult.loanAmount))",       color: .orange,                                       type: .input)
                FlowArrow(direction: .down)
                HStack(spacing: 16) {
                    FlowNode(icon: "arrow.down.circle.fill",  title: "Lumpsum",     value: "₹\(input.savedAmount)",    color: .purple, type: .process).frame(maxWidth: .infinity)
                }
                FlowArrow(direction: .down)
                FlowNode(icon: "checkmark.circle.fill",      title: "Asset Value",    value: "₹\(formatL_Detail(activeResult.loanAmount))",    color: .green, type: .output, isHighlight: true)
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow, radius: 12, x: 0, y: 4)
    }

    private var loanMetrics: some View {
        let principal = activeResult.loanAmount
        let interest = activeResult.totalInterestPaid

        let chartData = [
            (label: "Principal", value: principal, color: Color.blue),
            (label: "Interest", value: interest, color: Color.red)
        ]

        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.pie.fill")
                        .foregroundColor(.cyan).font(.body)
                    Text("Detailed Breakdown").font(.subheadline).fontWeight(.semibold)
                }
                Text("Visualizing the split between your loan principal and the total interest cost.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Chart {
                ForEach(chartData, id: \.label) { item in
                    SectorMark(
                        angle: .value("Value", item.value),
                        innerRadius: .ratio(0.65),
                        angularInset: 2
                    )
                    .foregroundStyle(item.color)
                    .cornerRadius(4)
                }
            }
            .frame(height: 180)
            .overlay(
                VStack(spacing: 2) {
                    Text("Total Cost")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text("₹\(formatL_Detail(activeResult.totalAmountPaid))")
                        .font(.system(size: 14, weight: .bold))
                }
            )

            Divider()

            VStack(spacing: 12) {
                LoanMetricRow(label: "Asset Value",                           value: (Double(input.targetAmount.replacingOccurrences(of: ",", with: "")) ?? 0).toCurrency(),            color: .gray)
                LoanMetricRow(label: "Down Payment",                        value: (Double(input.savedAmount.replacingOccurrences(of: ",", with: "")) ?? 0).toCurrency(),             color: .purple)
                LoanMetricRow(label: "Loan Amount",                         value: activeResult.loanAmount.toCurrency(),              color: .blue)
                LoanMetricRow(label: "Loan Rate",                           value: "\(String(format: "%.1f", activeResult.loanRate))% p.a.",         color: .orange)
                LoanMetricRow(label: "Loan Tenure",                         value: "\(tenureOverride) years", color: .gray)
                LoanMetricRow(label: "Payment per \(emiFrequency.rawValue)",                         value: activeResult.monthlyEMI.toCurrency(),           color: .red)
                LoanMetricRow(label: "Total Amount Paid",                   value: activeResult.totalAmountPaid.formatToLakhs(),            color: .red)
                LoanMetricRow(label: "Total Interest Paid",                 value: activeResult.totalInterestPaid.formatToLakhs(),             color: .red)

                Divider()

                LoanMetricRow(label: "Total Monthly Commitment",            value: activeResult.totalMonthlyCommitment.toCurrency(),           color: .purple)
                LoanMetricRow(label: "Net Wealth Gain/Loss",                value: activeResult.netWealthGain.formatToLakhs(),           color: .primary)
                if !activeResult.reachesGoal {
                    LoanMetricRow(label: "Shortfall Amount",                 value: activeResult.shortfall.toCurrency(),             color: .red)
                }
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow, radius: 12, x: 0, y: 4)
    }

    private var loanRecommendation: some View {
        RecommendedFundsCard(
            title: "Recommended Stable Funds",
            funds: [
                RecommendedFund(name: "ICICI Prudential Bluechip Fund", category: "Large Cap", returns: "13.8% p.a.", risk: "Moderate", icon: "shield.fill"),
                RecommendedFund(name: "Axis Midcap Fund", category: "Mid Cap", returns: "18.5% p.a.", risk: "High", icon: "chart.bar.fill"),
                RecommendedFund(name: "SBI Focused Equity Fund", category: "Focused Cap", returns: "15.2% p.a.", risk: "Moderate", icon: "target")
            ]
        )
        .padding(.top, -8)
        .padding(.bottom, 10)
    }

    private var monthlyOutflowCard: some View {
        let emi = activeResult.monthlyEMI
        let sip = activeResult.monthlySIPKept
        let total = emi + sip

        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "chart.bar.xaxis")
                        .foregroundColor(.purple)
                    Text("Monthly Outflow Breakdown")
                        .font(.headline)
                    Spacer()
                    Text("Total: ₹\(Int(total).formatted())")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
                Text("A visual split of your monthly commitment between Loan EMI and potential savings.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if total > 0 {
                StackedBar(emi: emi, sip: sip, total: total)

                HStack(spacing: 20) {
                    OutflowLegend(label: "EMI", amount: emi, color: .red, total: total)
                    OutflowLegend(label: "SIP", amount: sip, color: .cyan, total: total)
                }
            } else {
                Text("Adjust sliders to see breakdown")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(24)
        .background(AppTheme.cardBackground)
        .cornerRadius(24)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.5), radius: 12, x: 0, y: 6)
    }

    private func formatL_Detail(_ value: Double) -> String {
        let v = abs(value)
        if v >= 10000000 { return String(format: "%.1fCr", value / 10000000) }
        if v >= 100000 { return String(format: "%.1fL", value / 100000) }
        if v >= 1000 { return String(format: "%.1fK", value / 1000) }
        return String(format: "%.0f", value)
    }

    private var emiComparisonTables: some View {
        combinedEmiTable()
    }

    private func combinedEmiTable() -> some View {
        let principal = activeResult.loanAmount
        let rate = activeResult.loanRate > 0 ? activeResult.loanRate : (input.interestRate ?? 10)
        let years = tenureOverride

        let frequencies: [EMIFrequency] = [.monthly, .quarterly, .halfYearly, .yearly]

        let maxTotalCompounded = frequencies.map { 
            InvestmentPlannerEngine.calculateEMIPublic(principal: principal, rate: rate, years: years, frequency: $0, interestType: .compounded) * Double(years) * $0.paymentsPerYear 
        }.max() ?? 1.0

        let maxTotalSimple = frequencies.map { 
            InvestmentPlannerEngine.calculateEMIPublic(principal: principal, rate: rate, years: years, frequency: $0, interestType: .simple) * Double(years) * $0.paymentsPerYear 
        }.max() ?? 1.0

        let maxTotal = max(maxTotalCompounded, maxTotalSimple)

        return VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "arrow.left.arrow.right.square.fill")
                    .foregroundColor(.purple)
                Text("EMI Comparison (Compound vs Simple)")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: "square.on.square")
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 32) {
                ForEach(frequencies, id: \.self) { freq in
                    VStack(alignment: .leading, spacing: 16) {
                        Text(freq.rawValue)
                            .font(.headline)
                            .fontWeight(.bold)

                        emiComparisonRow(freq: freq, type: .compounded, principal: principal, rate: rate, years: years, maxTotal: maxTotal)
                        emiComparisonRow(freq: freq, type: .simple, principal: principal, rate: rate, years: years, maxTotal: maxTotal)
                    }
                    Divider()
                }
            }
        }
        .padding(24)
        .background(AppTheme.cardBackground)
        .cornerRadius(24)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.3), radius: 10, x: 0, y: 4)
    }

    private func emiComparisonRow(freq: EMIFrequency, type: InterestType, principal: Double, rate: Double, years: Int, maxTotal: Double) -> some View {
        let emi = InvestmentPlannerEngine.calculateEMIPublic(principal: principal, rate: rate, years: years, frequency: freq, interestType: type)
        let n = Int(Double(years) * freq.paymentsPerYear)
        let totalPaid = emi * Double(n)
        let interest = totalPaid - principal

        let wTotal = CGFloat(totalPaid / maxTotal)
        let wInterest = CGFloat(max(0, interest) / maxTotal)
        let color = type == .compounded ? Color.blue : Color.green

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(type == .compounded ? "Compound" : "Simple")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(n) pmts • EMI:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(emi.toCurrency())
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }

            HStack(spacing: 12) {
                Text("Total")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 45, alignment: .leading)

                GeometryReader { geo in
                    Capsule()
                        .fill(color.opacity(0.8))
                        .frame(width: max(10, geo.size.width * wTotal), height: 8)
                }
                .frame(height: 8)

                Text(formatL_Detail(totalPaid))
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 45, alignment: .trailing)
            }

            HStack(spacing: 12) {
                Text("Interest")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 45, alignment: .leading)

                GeometryReader { geo in
                    Capsule()
                        .fill(Color.red.opacity(0.6))
                        .frame(width: max(10, geo.size.width * wInterest), height: 8)
                }
                .frame(height: 8)

                Text(formatL_Detail(interest))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 45, alignment: .trailing)
            }
        }
    }

    private var loanEligibilityCard: some View {
        let profile = appState.currentProfile
        let gender = profile?.basicDetails.gender ?? .male
        let income = profile?.basicDetails.monthlyIncomeAfterTax ?? input.monthlyIncome
        let surplus = income * 0.4
        let emi = activeResult.monthlyEMI

        let monthlyEquivalent = emi / (12 / emiFrequency.paymentsPerYear)
        let isAffordable = monthlyEquivalent < (surplus * 1.5)

        let goalCategory = InvestmentGoalCategory.from(purpose: input.purposeOfInvestment)

        let freqSuffix = emiFrequency == .monthly ? "mo" : emiFrequency == .quarterly ? "qtr" : emiFrequency == .halfYearly ? "half-yr" : "yr"

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.green)
                Text("Loan Eligibility & Schemes")
                    .font(.headline)
                Spacer()
                statusBadge(text: isAffordable ? "Eligible" : "Check Savings", color: isAffordable ? .green : .orange)
            }

            Text("Based on your Astra Score, monthly surplus income, and regional banking norms.")
                .font(.system(size: 10))
                .foregroundColor(.secondary)

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Limit Required").font(.caption).foregroundColor(.secondary)
                    Text("₹\(formatL_Detail(activeResult.loanAmount))").font(.headline).fontWeight(.bold)
                }
                Divider().frame(height: 30)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Est. EMI").font(.caption).foregroundColor(.secondary)
                    Text("₹\(Int(emi).formatted())/\(freqSuffix)").font(.headline).fontWeight(.bold).foregroundColor(.red)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Available Schemes & Benefits")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)

                if gender == .female {
                    schemeRowView(icon: "person.fill.checkmark", text: "Women's Special: 0.1% Interest Waiver", color: .pink)
                }

                if goalCategory == .education {
                    schemeRowView(icon: "graduationcap.fill", text: "Education Benefit: 100% Tax Deduction (Sec 80E)", color: .blue)
                } else if goalCategory == .homePurchase {
                    schemeRowView(icon: "house.fill", text: "PMAY: Subsidy up to ₹2.67L available", color: .orange)
                } else {
                    schemeRowView(icon: "star.fill", text: "Pre-approved based on your Astra Score", color: .purple)
                }
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.3), radius: 10, x: 0, y: 4)
    }

    private var planInputSummaryCard: some View {
        let profile = appState.currentProfile
        let income = profile?.basicDetails.monthlyIncomeAfterTax ?? input.monthlyIncome
        let totalSurplus = income * 0.4
        let emi = activeResult.monthlyEMI
        let diff = totalSurplus - emi
        let isShortfall = diff < 0

        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "text.justify.left")
                    .foregroundColor(.blue)
                Text("Your Plan Summary")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }

            HStack(spacing: 20) {
                summaryItemView(label: "Target Goal", value: "₹\(formatL_Detail(InvestmentPlannerEngine.parseAmount(input.targetAmount)))", icon: "flag.fill")
                summaryItemView(label: "Saved Lumpsum", value: "₹\(input.savedAmount)", icon: "banknote.fill")
                summaryItemView(label: "Tenure", value: "\(tenureOverride) Yrs", icon: "clock.fill")
            }

            Divider()

            HStack(spacing: 8) {
                Image(systemName: isShortfall ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .foregroundColor(isShortfall ? .orange : .green)

                Text(isShortfall ? "Shortfall: ₹\(Int(abs(diff)).formatted())/mo in your budget to cover this EMI." : "Surplus: ₹\(Int(diff).formatted())/mo left in your budget after this EMI.")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isShortfall ? .orange : .green)
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground.opacity(0.6))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.blue.opacity(0.1), lineWidth: 1)
        )
    }

    private func schemeRowView(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(color).font(.system(size: 12))
            Text(text).font(.system(size: 11, weight: .medium)).foregroundColor(.primary)
        }
    }

    private func summaryItemView(label: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 10)).foregroundColor(.secondary)
                Text(label).font(.system(size: 10)).foregroundColor(.secondary)
            }
            Text(value).font(.system(size: 13, weight: .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statusBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(6)
    }
}

struct LoanMetricRow: View {
    let label: String
    let value: String
    var color: Color = .primary

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.secondary.opacity(0.5))
                    .frame(width: 8, height: 8)
                Text(label).font(.subheadline).foregroundColor(.secondary)
            }
            Spacer()
            Text(value).font(.subheadline).fontWeight(.bold).foregroundColor(.primary)
        }
    }
}

struct InvestmentBar: View {
    let label: String
    let amount: String
    let percentage: CGFloat
    let color: Color
    var animate: Bool
    var isNegative: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(color).frame(width: 8, height: 8)
                    Text(label).font(.caption).foregroundColor(.primary)
                }
                Spacer()
                Text(amount).font(.caption).fontWeight(.semibold).foregroundColor(color)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.15)).frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [color, color.opacity(0.7)]),
                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: animate ? geometry.size.width * percentage : 0, height: 8)
                        .animation(.spring(response: 1.0, dampingFraction: 0.7).delay(Double(percentage)), value: animate)
                }
            }
            .frame(height: 8)
        }
    }
}

struct FlowNode: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    var type: FlowNodeType = .process
    var isHighlight: Bool = false

    enum FlowNodeType { case input, process, output }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 40, height: 40)
                Image(systemName: icon).foregroundColor(color).font(.body)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundColor(.secondary)
                Text(value).font(.subheadline)
                    .fontWeight(isHighlight ? .bold : .semibold)
                    .foregroundColor(color)
            }
            Spacer()
        }
        .padding(12)
        .background(
            isHighlight
                ? LinearGradient(
                    gradient: Gradient(colors: [color.opacity(0.2), color.opacity(0.1)]),
                    startPoint: .leading, endPoint: .trailing)
                : LinearGradient(
                    gradient: Gradient(colors: [AppTheme.cardBackground, AppTheme.cardBackground]),
                    startPoint: .leading, endPoint: .trailing)
        )
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isHighlight ? color.opacity(0.4) : Color(UIColor.separator).opacity(0.6), 
                    lineWidth: isHighlight ? 2 : 1
                )
        )
    }
}

struct FlowArrow: View {
    var direction: Direction = .down
    var isDashed: Bool = false

    enum Direction { case down, up }

    var body: some View {
        VStack(spacing: 0) {
            if direction == .down {
                Rectangle()
                    .fill(Color(UIColor.tertiaryLabel))
                    .frame(width: 2, height: 20)
                Image(systemName: "arrowtriangle.down.fill")
                    .foregroundColor(Color(UIColor.tertiaryLabel))
                    .font(.caption)
            } else {
                Image(systemName: "arrowtriangle.up.fill")
                    .foregroundColor(Color(UIColor.tertiaryLabel))
                    .font(.caption)
                Rectangle()
                    .fill(Color(UIColor.tertiaryLabel))
                    .frame(width: 2, height: 20)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}

struct NewTimelineRow: View {
    let title: String
    let detail: String
    var amount: String = ""
    var subtitle: String? = nil
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(spacing: 0) {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color.blue.opacity(0.2), lineWidth: 4))

                if !isLast {
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 2, height: 60)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Spacer()
                    if !amount.isEmpty {
                        Text(amount)
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                    }
                }

                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                if let sub = subtitle {
                    Text(sub)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.blue)
                        .padding(.top, 2)
                }
            }
            .padding(.bottom, isLast ? 0 : 24)

            Spacer()
        }
    }
}

struct ScenarioRowSimple: View {
    let name: String
    let roi: String
    let gain: String
    let color: Color

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 6, height: 6)
                Text(name).font(.caption).foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(roi).font(.caption).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .trailing)
            Text(gain).font(.caption).fontWeight(.bold).foregroundColor(color).frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

#Preview {
    let sampleInput = InvestmentPlanInputModel(investmentType: "Monthly", amount: "20,000", liquidity: "High", riskType: "Low", timePeriod: "4", scheduleInvestmentDate: Date(), scheduleSIPDate: Date(), purposeOfInvestment: "Car", targetAmount: "14,80,000", savedAmount: "2,80,000", hasEmergencyFund: true, preferredLoanTenureYears: 4)
    let sampleResult = InvestmentPlannerEngine.generateFullPlan(input: sampleInput).plan2!

    return NavigationStack {
        Plan2DetailView(input: sampleInput, result: sampleResult)
    }
    .environment(TrackerViewModel())
    .environment(AppStateManager.withSampleData())
}

struct StackedBar: View {
    let emi: Double
    let sip: Double
    let total: Double

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 4) {
                if emi > 0 {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.red)
                        .frame(width: max(0, (geometry.size.width - 4) * CGFloat(emi / total)))
                        .overlay(
                            Text("\(Int(emi/total * 100))%")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .opacity(emi/total > 0.15 ? 1 : 0)
                        )
                }

                if sip > 0 {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.cyan)
                        .frame(width: max(0, (geometry.size.width - 4) * CGFloat(sip / total)))
                        .overlay(
                            Text("\(Int(sip/total * 100))%")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .opacity(sip/total > 0.15 ? 1 : 0)
                        )
                }
            }
        }
        .frame(height: 24)
    }
}

struct OutflowLegend: View {
    let label: String
    let amount: Double
    let color: Color
    let total: Double

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color.opacity(0.6))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("₹\(Int(amount).formatted())")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        }
    }
}

struct YearlyBreakdownSheet: View {
    @Environment(\.dismiss) var dismiss
    let details: [Plan2YearlyDetail]

    var body: some View {
        NavigationStack {
            List {
                ForEach(details) { item in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Year \(item.year)")
                                .font(.headline)
                            Spacer()
                            Text(item.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 20) {
                            DetailItem(label: "EMI Paid", value: "₹\(Int(item.emiPaidYearly).formatted())", color: .red)
                            DetailItem(label: "Rem. Principal", value: "₹\(Int(item.remainingPrincipal).formatted())", color: .gray)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Yearly Breakdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct DetailItem: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 10)).foregroundColor(.secondary)
            Text(value).font(.subheadline).fontWeight(.bold).foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
