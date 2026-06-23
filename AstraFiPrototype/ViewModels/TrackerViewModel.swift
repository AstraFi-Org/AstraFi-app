import Foundation
import SwiftUI

@Observable
class TrackerViewModel {
    var appState: AppStateManager?

    var netWorth: Double = 0
    var growthAmount: Double = 0

    var accounts: [Account] = []
    var investments: [Investment] = []

    var goals: [Goal] = []
    var loans: [Loan] = []

    var debtToIncomeRatio: Double = 0
    var savingsRate: Double = 0
    var monthlySurplus: Double = 0
    var totalMonthlyEMI: Double = 0
    var totalInvestmentValue: Double = 0
    var moneyFlowData: [MoneyFlowData] = []
    var moneyFlowChartData: [MoneyFlowChartItem] = []
    var fundAllocations: [FundAllocation] = []

    // MARK: – Portfolio summary (synced from profile investments)

    /// Sum of all principal amounts actually deployed (SIP-aware, installment-aware)
    var portfolioTotalInvested: Double = 0
    /// Sum of live current values across all investments
    var portfolioTotalCurrentValue: Double = 0
    /// Net gain  = currentValue − invested  (negative ⇒ loss)
    var portfolioNetGain: Double = 0
    /// Absolute return %  = netGain / totalInvested × 100
    var portfolioReturnPct: Double = 0
    /// CAGR across the whole portfolio (wealth-weighted average)
    var portfolioCAGR: Double = 0

    /// Investments in profit (currentValue > totalInvestedAmount)
    var gainers: [InvestmentSummaryItem] = []
    /// Investments in loss  (currentValue < totalInvestedAmount)
    var losers: [InvestmentSummaryItem] = []

    var yourPlans: [InvestmentPlanModel] = []
    var savedPlanNames: Set<String> = []
    var followedPlanNames: Set<String> = []
   

    func savePlan(planName: String, input: InvestmentPlanInputModel) {
        guard !savedPlanNames.contains(planName) else { return }
        let df = DateFormatter()
        df.dateStyle = .medium
        let newPlan = InvestmentPlanModel(
            name: planName,
            dateSaved: df.string(from: Date()),
            targetGoal: input.purposeOfInvestment,
            input: input
        )
        yourPlans.append(newPlan)
        savedPlanNames.insert(planName)
        appState?.savePlan(newPlan)
    }


    func unsavePlan(planName: String) {
        if let plan = yourPlans.first(where: { $0.name == planName }) {
            appState?.savedPlans.removeAll { $0.id == plan.id }
            Task {
                try? await SupabaseRepository.shared.deleteSavedPlan(plan.id)
            }
        }
        yourPlans.removeAll { $0.name == planName }
        savedPlanNames.remove(planName)
    }

    func followPlan(planName: String, input: InvestmentPlanInputModel) {
        guard !followedPlanNames.contains(planName) else { return }
        let targetAmount = input.targetAmount
        let targetString = targetAmount.contains("₹") ? targetAmount : "₹" + targetAmount
        let goalName = input.purposeOfInvestment
        let newGoal = Goal(name: goalName.isEmpty ? "New Goal" : goalName,
                           associatedFund: planName, targetAmount: targetString,
                           collectedAmount: "₹0", timePeriod: input.timePeriod + " Years", progress: 0)
        goals.append(newGoal)
        followedPlanNames.insert(planName)
        // Persist follow status to Supabase
        if let plan = yourPlans.first(where: { $0.name == planName }) {
            appState?.followPlan(plan)   // ← ADD THIS LINE
        }
    }


    func unfollowPlan(planName: String) {
        goals.removeAll { $0.associatedFund == planName }
        followedPlanNames.remove(planName)
        if let plan = yourPlans.first(where: { $0.name == planName }) {
            appState?.unfollowPlan(plan)   // ← ADD THIS LINE
        }
    }
    func syncWithProfile(_ profile: AstraUserProfile?) {
        guard let profile = profile else { return }

        // Sync saved plans from AppStateManager so they survive logout/login
        if let appState = appState {
            let latestPlans = appState.savedPlans
            DispatchQueue.main.async {
                self.yourPlans = latestPlans
                self.savedPlanNames = Set(latestPlans.map { $0.name })
                self.followedPlanNames = Set(latestPlans.filter { $0.isFollowed }.map { $0.name })
            }
        }

        let df = DateFormatter()
        df.dateStyle = .medium

        let newAccounts = self.calculateAccounts(profile)
        let newLoans = self.calculateLoans(profile, df: df)
        let newInvestments = self.calculateInvestments(profile, df: df)
        let newGoals = self.calculateGoals(profile, df: df)

        let totalAssets = profile.assets.totalAssets.safeFinite
        let totalLiabilities = profile.liabilities.totalLiabilities.safeFinite
        let nw = totalAssets - totalLiabilities

        let calendar = Calendar.current
        let monthIndex = calendar.component(.month, from: Date()) - 1
        let currentMonth = df.shortMonthSymbols[monthIndex]
        let expenses = profile.basicDetails.monthlyExpenses.safeFinite
        let savings = max(0, (profile.basicDetails.monthlyIncomeAfterTax - expenses).safeFinite)
        let emergencyContrib = profile.basicDetails.emergencyFundAmount > 0 ? (profile.basicDetails.emergencyFundAmount / 12.0).safeFinite : 0

        let totalEMI = profile.loans.reduce(0.0) { $0 + $1.calculatedEMI }
        let dti = (profile.basicDetails.monthlyIncome > 0) ? (totalEMI / profile.basicDetails.monthlyIncome) : 0
        self.debtToIncomeRatio = dti.isFinite ? dti : 0
        self.monthlySurplus = savings.isFinite ? savings : 0
        self.totalMonthlyEMI = totalEMI.isFinite ? totalEMI : 0

        let savingsRate = (profile.basicDetails.monthlyIncome > 0) ? (savings / profile.basicDetails.monthlyIncome) : 0
        self.savingsRate = savingsRate.isFinite ? savingsRate : 0

        let currentMoneyFlow = (profile.basicDetails.monthlyIncome > 0) ? [MoneyFlowData(month: currentMonth, savings: savings, emergencyFund: emergencyContrib, expenses: expenses)] : []

        let newAllocations = self.calculateAllocations(profile, totalAssets: totalAssets)

        var totalInvested: Double = 0.0
        for loan in profile.loans {
            let paid = loan.estimatedPaidAmount
            totalInvested += paid.isFinite ? paid : 0
        }
        self.totalInvestmentValue = totalInvested.isFinite ? totalInvested : 0

        DispatchQueue.main.async {
            self.accounts = newAccounts
            self.loans = newLoans
            self.investments = newInvestments
            self.goals = newGoals
            self.netWorth = nw.isFinite ? nw : 0
            self.growthAmount = 0
            self.moneyFlowData = currentMoneyFlow
            self.moneyFlowChartData = self.calculateMoneyFlowChartData(profile, df: df)
            self.fundAllocations = newAllocations

            // ── Portfolio summary ──────────────────────────────────────────
            let allInv = profile.investments

            let totalInv = allInv.reduce(0.0) { $0 + $1.totalInvestedAmount.safeFinite }.safeFinite
            let totalCurr = allInv.reduce(0.0) { $0 + $1.currentValue.safeFinite }.safeFinite
            let netGain = (totalCurr - totalInv).safeFinite
            let returnPct = totalInv > 0 ? ((netGain / totalInv) * 100).safeFinite : 0

            // Portfolio CAGR: weight each investment's CAGR by its invested share
            let cagrWeighted: Double = {
                guard totalInv > 0 else { return 0 }
                let weightedSum = allInv.reduce(0.0) { sum, inv in
                    let w = (inv.totalInvestedAmount.safeFinite / totalInv).safeFinite
                    return sum + (inv.expectedAnnualRate.safeFinite * w)
                }
                return (weightedSum * 100).safeFinite // convert to %
            }()

            // Build per-investment summary items
            let summaryItems: [InvestmentSummaryItem] = allInv.map { inv in
                let risk: String
                switch inv.investmentType {
                case .stocks, .cryptocurrency: risk = "High Risk"
                case .mutualFund, .nps:        risk = "Moderate Risk"
                default:                        risk = "Low Risk"
                }
                return InvestmentSummaryItem(
                    id: inv.id,
                    name: inv.investmentName,
                    category: inv.investmentType.rawValue,
                    risk: risk,
                    invested: inv.totalInvestedAmount.safeFinite,
                    currentValue: inv.currentValue.safeFinite
                )
            }

            self.portfolioTotalInvested     = totalInv.isFinite    ? totalInv    : 0
            self.portfolioTotalCurrentValue = totalCurr.isFinite   ? totalCurr   : 0
            self.portfolioNetGain           = netGain.isFinite     ? netGain     : 0
            self.portfolioReturnPct         = returnPct.isFinite   ? returnPct   : 0
            self.portfolioCAGR              = cagrWeighted.isFinite ? cagrWeighted : 0
            self.gainers = summaryItems.filter {  $0.isGainer }
                                       .sorted { $0.gainLoss  > $1.gainLoss  }
            self.losers  = summaryItems.filter { !$0.isGainer }
                                       .sorted { $0.gainLoss  < $1.gainLoss  }
        }
    }
    
    private func calculateMoneyFlowChartData(_ profile: AstraUserProfile, df: DateFormatter) -> [MoneyFlowChartItem] {
        var items: [MoneyFlowChartItem] = []
        
        // Add current month from cashflowData
        let calendar = Calendar.current
        let currentMonth = df.shortMonthSymbols[calendar.component(.month, from: Date()) - 1]
        
        if let cashflow = profile.cashflowData {
            if cashflow.incomeSources.isEmpty {
                // Fallback to assessment income
                items.append(MoneyFlowChartItem(month: currentMonth, type: "Income", category: "Fixed Salary", amount: profile.basicDetails.monthlyIncome.safeFinite))
            } else {
                for source in cashflow.incomeSources {
                    items.append(MoneyFlowChartItem(month: currentMonth, type: "Income", category: source.name, amount: source.amount.safeFinite))
                }
            }
            
            if cashflow.expenseSources.isEmpty {
                // Fallback to flat expenses
                items.append(MoneyFlowChartItem(month: currentMonth, type: "Expense", category: "Rent/EMI", amount: cashflow.rent.safeFinite))
                items.append(MoneyFlowChartItem(month: currentMonth, type: "Expense", category: "Groceries", amount: cashflow.groceries.safeFinite))
                items.append(MoneyFlowChartItem(month: currentMonth, type: "Expense", category: "Utilities", amount: cashflow.utilities.safeFinite))
                items.append(MoneyFlowChartItem(month: currentMonth, type: "Expense", category: "Entertainment", amount: cashflow.entertainment.safeFinite))
                let others = (cashflow.transport + cashflow.shopping + cashflow.dining + cashflow.misc).safeFinite
                if others > 0 {
                    items.append(MoneyFlowChartItem(month: currentMonth, type: "Expense", category: "Others", amount: others))
                }
            } else {
                for exp in cashflow.expenseSources {
                    items.append(MoneyFlowChartItem(month: currentMonth, type: "Expense", category: exp.name, amount: exp.amount.safeFinite))
                }
            }
        }
        
        // Add historical snapshots (up to last 3 months for simplicity in chart)
        let sortedKeys = profile.monthlyCashflowSnapshots.keys.sorted().suffix(3)
        for key in sortedKeys {
            guard let snap = profile.monthlyCashflowSnapshots[key] else { continue }
            // Extract month from "yyyy-MM"
            let components = key.split(separator: "-")
            if components.count == 2, let m = Int(components[1]) {
                let mName = df.shortMonthSymbols[max(0, min(11, m - 1))]
                
                for src in snap.incomeSources {
                    items.append(MoneyFlowChartItem(month: mName, type: "Income", category: src.name, amount: src.amount.safeFinite))
                }
                for exp in snap.expenseSources {
                    items.append(MoneyFlowChartItem(month: mName, type: "Expense", category: exp.name, amount: exp.amount.safeFinite))
                }
            }
        }
        
        return items.filter { $0.amount.isFinite }
    }

    private func calculateAccounts(_ profile: AstraUserProfile) -> [Account] {
        var newAccounts: [Account] = []
        if profile.assets.mutualFundHoldingAmount > 0 {
            newAccounts.append(Account(name: "Mutual Funds", institution: "Investment", balance: profile.assets.mutualFundHoldingAmount.safeFinite))
        }
        if profile.assets.stocksHoldingAmount > 0 {
            newAccounts.append(Account(name: "Stocks", institution: "Equity", balance: profile.assets.stocksHoldingAmount.safeFinite))
        }
        if profile.assets.depositsAmount > 0 {
            newAccounts.append(Account(name: "Fixed Deposits", institution: "Bank", balance: profile.assets.depositsAmount.safeFinite))
        }
        if profile.assets.savingsAccountAmount > 0 {
            newAccounts.append(Account(name: "Savings Account", institution: "Bank", balance: profile.assets.savingsAccountAmount.safeFinite))
        }
        if profile.assets.currentAccountAmount > 0 {
            newAccounts.append(Account(name: "Current Account", institution: "Bank", balance: profile.assets.currentAccountAmount.safeFinite))
        }
        if profile.assets.propertyAmount > 0 {
            newAccounts.append(Account(name: "Property / Real Estate", institution: "Asset", balance: profile.assets.propertyAmount.safeFinite))
        }
        if profile.assets.vehiclesAmount > 0 {
            newAccounts.append(Account(name: "Vehicles", institution: "Vehicle Asset", balance: profile.assets.vehiclesAmount.safeFinite))
        }
        if profile.assets.jewelleryAmount > 0 {
            newAccounts.append(Account(name: "Gold / Jewellery", institution: "Asset", balance: profile.assets.jewelleryAmount.safeFinite))
        }
        if profile.assets.luxuryBelongingsAmount > 0 {
            newAccounts.append(Account(name: "Luxury Belongings", institution: "Personal Asset", balance: profile.assets.luxuryBelongingsAmount.safeFinite))
        }
        if profile.assets.otherInvestmentAmount > 0 {
            newAccounts.append(Account(name: "Other Investments", institution: "Various", balance: profile.assets.otherInvestmentAmount.safeFinite))
        }
        if profile.assets.otherAssetsAmount > 0 {
            newAccounts.append(Account(name: "Other Assets", institution: "Asset", balance: profile.assets.otherAssetsAmount.safeFinite))
        }

        if profile.liabilities.homeLoanAmount > 0 {
            newAccounts.append(Account(name: "Home Loan", institution: "Liability", balance: -profile.liabilities.homeLoanAmount.safeFinite))
        }
        if profile.liabilities.vehicleLoanAmount > 0 {
            newAccounts.append(Account(name: "Vehicle Loan", institution: "Liability", balance: -profile.liabilities.vehicleLoanAmount.safeFinite))
        }
        if profile.liabilities.educationLoanAmount > 0 {
            newAccounts.append(Account(name: "Education Loan", institution: "Liability", balance: -profile.liabilities.educationLoanAmount.safeFinite))
        }
        if profile.liabilities.creditCardBills > 0 {
            newAccounts.append(Account(name: "Credit Card Dues", institution: "Liability", balance: -profile.liabilities.creditCardBills.safeFinite))
        }
        if profile.liabilities.otherLoanAmount > 0 {
            newAccounts.append(Account(name: "Other Loans", institution: "Liability", balance: -profile.liabilities.otherLoanAmount.safeFinite))
        }
        if profile.liabilities.otherDebtAmount > 0 {
            newAccounts.append(Account(name: "Other Debts", institution: "Liability", balance: -profile.liabilities.otherDebtAmount.safeFinite))
        }
        return newAccounts
    }

    private func calculateLoans(_ profile: AstraUserProfile, df: DateFormatter) -> [Loan] {
        return profile.loans.map { loan in
            let tenure = max(1, loan.loanTenureMonths)
            let monthlyPrincipal = (loan.loanAmount.safeFinite / Double(tenure)).safeFinite
            let paidAmountValue = (Double(loan.installmentsPaid) * monthlyPrincipal).safeFinite
            return Loan(
                name: loan.displayName,
                timePeriod: "\(tenure / 12) Years",
                status: "Active",
                totalAmount: "₹\(loan.loanAmount.safeInt)",
                paidAmount: "₹\(paidAmountValue.safeInt)",
                emisPaid: loan.installmentsPaid,
                totalEmis: loan.loanTenureMonths
            )
        }
    }

    private func calculateInvestments(_ profile: AstraUserProfile, df: DateFormatter) -> [Investment] {
        return profile.investments.map { inv in
            let gainPct = inv.investmentAmount > 0 ? (inv.currentGain / inv.investmentAmount) * 100 : 0
            return Investment(
                name: inv.investmentName,
                category: inv.investmentType.rawValue.capitalized,
                risk: riskLabel(for: inv.investmentType),
                amount: inv.currentValue.safeInt,
                returns: String(format: "%@%.1f%%", gainPct >= 0 ? "+" : "", gainPct.safeFinite),
                startDate: df.string(from: inv.startDate),
                associatedGoal: goalName(for: inv.associatedGoalID, in: profile),
                schemeCode: inv.schemeCode,
                lastNAV: inv.lastNAV,
                source: inv.brokerSource
            )
        }
    }

    private func riskLabel(for type: AstraInvestmentType) -> String {
        switch type {
        case .stocks, .cryptocurrency: return "High"
        case .mutualFund, .nps: return "Moderate"
        default: return "Low"
        }
    }

    private func goalName(for id: UUID?, in profile: AstraUserProfile) -> String {
        guard let id = id else { return "General" }
        return profile.goals.first(where: { $0.id == id })?.goalName ?? "General"
    }

    private func calculateGoals(_ profile: AstraUserProfile, df: DateFormatter) -> [Goal] {
        return profile.goals.map { g in
            let linked = profile.investments.filter { $0.associatedGoalID == g.id }
            let linkedFund = linked.first?.investmentName ?? "None"
            let totalColl = self.calculateTotalCollected(for: g.id, profile: profile)
            let progressRatio = g.targetAmount > 0 ? min(max((totalColl / g.targetAmount).safeFinite, 0), 1.0) : 0
            
            return Goal(
                name: g.goalName,
                associatedFund: linked.count > 1 ? "\(linked.count) Assets" : linkedFund,
                targetAmount: g.targetAmount.toCurrency(),
                collectedAmount: totalColl.toCurrency(),
                timePeriod: df.string(from: g.targetDate),
                progress: progressRatio
            )
        }
    }

    private func calculateTotalCollected(for goalID: UUID, profile: AstraUserProfile) -> Double {
        guard let goal = profile.goals.first(where: { $0.id == goalID }) else { return 0 }
        let linked = profile.investments.filter { $0.associatedGoalID == goalID }
        let linkedTotal = linked.reduce(0.0) { $0 + $1.currentValue.safeFinite }.safeFinite
        return (linkedTotal + goal.manualSavingsContribution.safeFinite).safeFinite
    }

    private func calculateAllocations(_ profile: AstraUserProfile, totalAssets: Double) -> [FundAllocation] {
        let safeTotalAssets = totalAssets.safeFinite
        guard safeTotalAssets > 0 else { return [] }
        var newAllocations: [FundAllocation] = []

        let mf = profile.assets.mutualFundHoldingAmount.safeFinite
        if mf > 0 {
            let pct = (mf / safeTotalAssets) * 100
            newAllocations.append(FundAllocation(name: "MF", percentage: min(max(pct.safeFinite, 0), 100), color: .blue))
        }

        let stocks = profile.assets.stocksHoldingAmount.safeFinite
        if stocks > 0 {
            let pct = (stocks / safeTotalAssets) * 100
            newAllocations.append(FundAllocation(name: "Stocks", percentage: min(max(pct.safeFinite, 0), 100), color: .purple))
        }

        let deposits = profile.assets.depositsAmount.safeFinite
        if deposits > 0 {
            let pct = (deposits / safeTotalAssets) * 100
            newAllocations.append(FundAllocation(name: "Deposits", percentage: min(max(pct.safeFinite, 0), 100), color: .orange))
        }

        let others = (profile.assets.totalAssets.safeFinite - (mf + stocks + deposits)).safeFinite
        if others > 0 {
            let pct = (others / safeTotalAssets) * 100
            newAllocations.append(FundAllocation(name: "Others", percentage: min(max(pct.safeFinite, 0), 100), color: .gray))
        }

        return newAllocations.filter { $0.percentage.isFinite && $0.percentage > 0 }
    }
}
