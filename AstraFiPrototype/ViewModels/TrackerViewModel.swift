import Foundation
import SwiftUI
import Combine

import Observation

@Observable
class TrackerViewModel {

    var netWorth: Double = 0
    var growthAmount: Double = 0

    var accounts: [Account] = []
    var investments: [Investment] = []

    var goals: [Goal] = []
    var loans: [Loan] = []

    var debtToIncomeRatio: Double = 0
    var savingsRate: Double = 0
    var totalInvestmentValue: Double = 0
    var moneyFlowData: [MoneyFlowData] = []
    var fundAllocations: [FundAllocation] = []

    var yourPlans: [InvestmentPlanModel] = []
    var savedPlanNames: Set<String> = []
    var followedPlanNames: Set<String> = []

    func savePlan(planName: String, input: InvestmentPlanInputModel) {

        guard !savedPlanNames.contains(planName) else { return }

        let newPlan = InvestmentPlanModel(name: planName, dateSaved: "Today", targetGoal: input.purposeOfInvestment, input: input)
        yourPlans.append(newPlan)
        savedPlanNames.insert(planName)
    }

    func unsavePlan(planName: String) {
        yourPlans.removeAll { $0.name == planName }
        savedPlanNames.remove(planName)
    }

    func followPlan(planName: String, input: InvestmentPlanInputModel) {

        guard !followedPlanNames.contains(planName) else { return }

        let targetAmount = input.targetAmount
        let targetString = targetAmount.contains("₹") ? targetAmount : "₹" + targetAmount
        let goalName = input.purposeOfInvestment
        let newGoal = Goal(name: goalName.isEmpty ? "New Goal" : goalName, associatedFund: planName, targetAmount: targetString, collectedAmount: "₹0", timePeriod: input.timePeriod + " Years")
        goals.append(newGoal)
        followedPlanNames.insert(planName)
    }

    func unfollowPlan(planName: String) {
        goals.removeAll { $0.associatedFund == planName }
        followedPlanNames.remove(planName)
    }

    func syncWithProfile(_ profile: AstraUserProfile?) {
        guard let profile = profile else { return }

        let df = DateFormatter()
        df.dateStyle = .medium

        let newAccounts = self.calculateAccounts(profile)
        let newLoans = self.calculateLoans(profile, df: df)
        let newInvestments = self.calculateInvestments(profile, df: df)
        let newGoals = self.calculateGoals(profile, df: df)

        let totalAssets = profile.assets.totalAssets
        let totalLiabilities = profile.liabilities.totalLiabilities
        let nw = totalAssets - totalLiabilities

        let calendar = Calendar.current
        let monthIndex = calendar.component(.month, from: Date()) - 1
        let currentMonth = df.shortMonthSymbols[monthIndex]
        let expenses = profile.basicDetails.monthlyExpenses
        let savings = max(0, profile.basicDetails.monthlyIncomeAfterTax - expenses)
        let emergencyContrib = profile.basicDetails.emergencyFundAmount > 0 ? (profile.basicDetails.emergencyFundAmount / 12.0) : 0

        let totalEMI = profile.loans.reduce(0.0) { $0 + $1.calculatedEMI }
        let dti = (profile.basicDetails.monthlyIncome > 0) ? (totalEMI / profile.basicDetails.monthlyIncome) : 0
        self.debtToIncomeRatio = dti.isFinite ? dti : 0

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
            self.fundAllocations = newAllocations
        }
    }

    private func calculateAccounts(_ profile: AstraUserProfile) -> [Account] {
        var newAccounts: [Account] = []
        if profile.assets.mutualFundHoldingAmount > 0 {
            newAccounts.append(Account(name: "Mutual Funds", institution: "Investment", balance: profile.assets.mutualFundHoldingAmount))
        }
        if profile.assets.stocksHoldingAmount > 0 {
            newAccounts.append(Account(name: "Stocks", institution: "Equity", balance: profile.assets.stocksHoldingAmount))
        }
        if profile.assets.depositsAmount > 0 {
            newAccounts.append(Account(name: "Fixed Deposits", institution: "Bank", balance: profile.assets.depositsAmount))
        }
        if profile.assets.savingsAccountAmount > 0 {
            newAccounts.append(Account(name: "Savings Account", institution: "Bank", balance: profile.assets.savingsAccountAmount))
        }
        if profile.assets.currentAccountAmount > 0 {
            newAccounts.append(Account(name: "Current Account", institution: "Bank", balance: profile.assets.currentAccountAmount))
        }
        if profile.assets.propertyAmount > 0 {
            newAccounts.append(Account(name: "Property / Real Estate", institution: "Asset", balance: profile.assets.propertyAmount))
        }
        if profile.assets.jewelleryAmount > 0 {
            newAccounts.append(Account(name: "Gold / Jewellery", institution: "Asset", balance: profile.assets.jewelleryAmount))
        }
        if profile.assets.otherInvestmentAmount > 0 {
            newAccounts.append(Account(name: "Other Investments", institution: "Various", balance: profile.assets.otherInvestmentAmount))
        }

        if profile.liabilities.homeLoanAmount > 0 {
            newAccounts.append(Account(name: "Home Loan", institution: "Liability", balance: -profile.liabilities.homeLoanAmount))
        }
        if profile.liabilities.vehicleLoanAmount > 0 {
            newAccounts.append(Account(name: "Vehicle Loan", institution: "Liability", balance: -profile.liabilities.vehicleLoanAmount))
        }
        if profile.liabilities.educationLoanAmount > 0 {
            newAccounts.append(Account(name: "Education Loan", institution: "Liability", balance: -profile.liabilities.educationLoanAmount))
        }
        if profile.liabilities.creditCardBills > 0 {
            newAccounts.append(Account(name: "Credit Card Dues", institution: "Liability", balance: -profile.liabilities.creditCardBills))
        }
        if profile.liabilities.otherLoanAmount > 0 {
            newAccounts.append(Account(name: "Other Loans", institution: "Liability", balance: -profile.liabilities.otherLoanAmount))
        }
        if profile.liabilities.otherDebtAmount > 0 {
            newAccounts.append(Account(name: "Other Debts", institution: "Liability", balance: -profile.liabilities.otherDebtAmount))
        }
        return newAccounts
    }

    private func calculateLoans(_ profile: AstraUserProfile, df: DateFormatter) -> [Loan] {
        return profile.loans.map { loan in
            let tenure = max(1, loan.loanTenureMonths)
            let monthlyPrincipal = loan.loanAmount / Double(tenure)
            let paidAmountValue = Double(loan.installmentsPaid) * monthlyPrincipal
            return Loan(
                name: loan.loanType.rawValue,
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
                amount: Int(inv.currentValue),
                returns: String(format: "%@%.1f%%", gainPct >= 0 ? "+" : "", gainPct),
                startDate: df.string(from: inv.startDate),
                associatedGoal: goalName(for: inv.associatedGoalID, in: profile),
                schemeCode: inv.schemeCode,
                lastNAV: inv.lastNAV
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
            let linkedFund = profile.investments.first(where: { $0.associatedGoalID == g.id })?.investmentName ?? "None"
            return Goal(
                name: g.goalName,
                associatedFund: linkedFund,
                targetAmount: g.targetAmount.toCurrency(),
                collectedAmount: g.currentAmount.toCurrency(),
                timePeriod: df.string(from: g.targetDate)
            )
        }
    }

    private func calculateTotalCollected(for goalID: UUID, profile: AstraUserProfile) -> Double {
        let linked = profile.investments.filter { $0.associatedGoalID == goalID }
        return linked.reduce(0) { total, inv in
            if inv.mode == .sip {
                let calendar = Calendar.current
                let components = calendar.dateComponents([.month], from: inv.startDate, to: Date())
                let months = max(components.month ?? 0, 1)
                return total + (inv.investmentAmount * Double(months))
            } else {
                return total + inv.investmentAmount
            }
        }
    }

    private func calculateAllocations(_ profile: AstraUserProfile, totalAssets: Double) -> [FundAllocation] {
        guard totalAssets > 0 else { return [] }
        var newAllocations: [FundAllocation] = []

        let mf = profile.assets.mutualFundHoldingAmount
        if mf > 0 {
            let pct = (mf / totalAssets) * 100
            newAllocations.append(FundAllocation(name: "MF", percentage: pct.isFinite ? pct : 0, color: .blue))
        }

        let stocks = profile.assets.stocksHoldingAmount
        if stocks > 0 {
            let pct = (stocks / totalAssets) * 100
            newAllocations.append(FundAllocation(name: "Stocks", percentage: pct.isFinite ? pct : 0, color: .purple))
        }

        let deposits = profile.assets.depositsAmount
        if deposits > 0 {
            let pct = (deposits / totalAssets) * 100
            newAllocations.append(FundAllocation(name: "Deposits", percentage: pct.isFinite ? pct : 0, color: .orange))
        }

        let others = profile.assets.totalAssets - (mf + stocks + deposits)
        if others > 0 {
            let pct = (others / totalAssets) * 100
            newAllocations.append(FundAllocation(name: "Others", percentage: pct.isFinite ? pct : 0, color: .gray))
        }

        return newAllocations
    }
}
