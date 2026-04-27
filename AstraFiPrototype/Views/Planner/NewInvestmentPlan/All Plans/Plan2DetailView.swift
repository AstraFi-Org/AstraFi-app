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
                VStack(spacing: 32) {
                    topHeaderSection
                    
                    //loanEligibilityCard
                    affordabilityWarning
                    interactiveAdjusters
                    bankInfoRow
                    timelineSection
                    combinedEmiTable()
                    loanMetrics
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

    // MARK: - Header Section
    private var topHeaderSection: some View {
        VStack(spacing: 24) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Target Goal")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                    Text("₹\(formatL_Detail(InvestmentPlannerEngine.parseAmount(input.targetAmount)))")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    Text("Monthly EMI")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                    Text("₹\(Int(activeResult.monthlyEMI).formatted())")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.red)
                }
            }
            .padding(.top, 24)
            
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 32, height: 32)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                }
                
                Text("Complete this goal today, repay amount in installments.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.blue.opacity(0.05))
            .cornerRadius(12)
        }
    }

    // MARK: - Footer Section
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

    // MARK: - Components
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
                        Text("Low monthly savings (₹\(Int(availableSurplus).formatted())/mo) relative to EMI (₹\(Int(monthlyEMIEquivalent).formatted())/mo).")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(16)
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
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
            Text("\(String(format: "%.1f", activeResult.loanRate))%")
                .font(.system(size: 20, weight: .bold, design: .rounded))
        }
        .padding(16)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }

    private var loanMetrics: some View {
        let principal = activeResult.loanAmount
        let interest = activeResult.totalInterestPaid
        let chartData = [
            (label: "Principal", value: principal, color: Color.blue),
            (label: "Interest", value: interest, color: Color.red)
        ]

        return VStack(alignment: .leading, spacing: 16) {
            Text("Cost Breakdown")
                .font(.headline)
            
            Chart {
                ForEach(chartData, id: \.label) { item in
                    SectorMark(
                        angle: .value("Value", item.value),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(item.color)
                }
            }
            .frame(height: 180)
            .overlay(
                VStack(spacing: 2) {
                    Text("Total Paid")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("₹\(formatL_Detail(activeResult.totalAmountPaid))")
                        .font(.system(size: 14, weight: .bold))
                }
            )

            VStack(spacing: 12) {
                LoanMetricRow(label: "Loan Amount", value: activeResult.loanAmount.toCurrency(), color: .blue)
                LoanMetricRow(label: "Interest Cost", value: activeResult.totalInterestPaid.toCurrency(), color: .red)
                LoanMetricRow(label: "Tenure", value: "\(tenureOverride) years", color: .secondary)
                LoanMetricRow(label: "ROI", value: "\(String(format: "%.1f", activeResult.loanRate))%", color: .orange)
            }
        }
        .padding(24)
        .background(AppTheme.cardBackground)
        .cornerRadius(24)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.2), radius: 8)
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
                Text("EMI Comparison")
                    .font(.headline)
                Spacer()
                Text("Simple vs Compound").font(.caption).foregroundColor(.secondary)
            }

            VStack(spacing: 24) {
                ForEach(frequencies, id: \.self) { freq in
                    VStack(alignment: .leading, spacing: 16) {
                        Text(freq.rawValue)
                            .font(.system(size: 14, weight: .bold, design: .rounded))

                        VStack(spacing: 12) {
                            emiComparisonRow(freq: freq, type: .compounded, principal: principal, rate: rate, years: years, maxTotal: maxTotal)
                            emiComparisonRow(freq: freq, type: .simple, principal: principal, rate: rate, years: years, maxTotal: maxTotal)
                        }
                    }
                    if freq != frequencies.last { Divider() }
                }
            }
        }
        .padding(24)
        .background(AppTheme.cardBackground)
        .cornerRadius(24)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.2), radius: 8)
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
                    .font(.caption)
                    .fontWeight(.bold)
                Spacer()
                Text(emi.toCurrency())
                    .font(.caption)
                    .fontWeight(.black)
                    .foregroundColor(.primary)
            }

            HStack(spacing: 12) {
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        Capsule().fill(color).frame(width: geo.size.width * wTotal)
                    }
                }.frame(height: 6)
                Text(formatL_Detail(totalPaid)).font(.system(size: 9)).foregroundColor(.secondary)
            }
        }
    }

//    private var loanEligibilityCard: some View {
//        let profile = appState.currentProfile
//        let gender = profile?.basicDetails.gender ?? .male
//        let income = profile?.basicDetails.monthlyIncomeAfterTax ?? input.monthlyIncome
//        let surplus = income * 0.4
//        let emi = activeResult.monthlyEMI
//        let monthlyEquivalent = emi / (12 / emiFrequency.paymentsPerYear)
//        let isAffordable = monthlyEquivalent < (surplus * 1.5)
//        let goalCategory = InvestmentGoalCategory.from(purpose: input.purposeOfInvestment)
//
//        return VStack(alignment: .leading, spacing: 16) {
//            HStack {
//                Image(systemName: "checkmark.shield.fill")
//                    .foregroundColor(.green)
//                Text("Loan Eligibility")
//                    .font(.headline)
//                Spacer()
//                statusBadge(text: isAffordable ? "Eligible" : "Check Savings", color: isAffordable ? .green : .orange)
//            }
//
//            HStack(spacing: 20) {
//                VStack(alignment: .leading, spacing: 4) {
//                    Text("Limit Required").font(.caption).foregroundColor(.secondary)
//                    Text("₹\(formatL_Detail(activeResult.loanAmount))").font(.headline).fontWeight(.bold)
//                }
//                Divider().frame(height: 30)
//                VStack(alignment: .leading, spacing: 4) {
//                    Text("Est. EMI").font(.caption).foregroundColor(.secondary)
//                    Text("₹\(Int(emi).formatted())/\(emiFrequency.rawValue)").font(.headline).fontWeight(.bold).foregroundColor(.red)
//                }
//            }
//
//            VStack(alignment: .leading, spacing: 10) {
//                if gender == .female {
//                    schemeRowView(icon: "person.fill.checkmark", text: "Women's Special: 0.1% Waiver", color: .pink)
//                }
//                if goalCategory == .education {
//                    schemeRowView(icon: "graduationcap.fill", text: "Education Benefit: 80E Tax Deduction", color: .blue)
//                } else if goalCategory == .homePurchase {
//                    schemeRowView(icon: "house.fill", text: "PMAY Subsidy Available", color: .orange)
//                }
//            }
//        }
//        .padding(24)
//        .background(AppTheme.cardBackground)
//        .cornerRadius(24)
//        .shadow(color: AppTheme.adaptiveShadow.opacity(0.2), radius: 8)
//    }

    // MARK: - Helpers
    private func formatL_Detail(_ value: Double) -> String {
        let v = abs(value)
        if v >= 10000000 { return String(format: "%.1fCr", value / 10000000) }
        if v >= 100000 { return String(format: "%.1fL", value / 100000) }
        if v >= 1000 { return String(format: "%.1fK", value / 1000) }
        return String(format: "%.0f", value)
    }

    private func schemeRowView(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundColor(color).font(.caption)
            Text(text).font(.system(size: 11, weight: .medium))
        }
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

// MARK: - Global Components
struct LoanMetricRow: View {
    let label: String
    let value: String
    var color: Color = .primary
    var body: some View {
        HStack {
            Text(label).font(.subheadline).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.subheadline).fontWeight(.bold).foregroundColor(color)
        }
    }
}
