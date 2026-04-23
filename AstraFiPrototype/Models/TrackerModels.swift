import Foundation
import SwiftUI

/// Lightweight summary of a single investment used for the overview breakdown card.
struct InvestmentSummaryItem: Identifiable {
    let id: UUID
    let name: String
    let category: String
    let risk: String
    let invested: Double
    let currentValue: Double
    /// Positive = gain, negative = loss
    var gainLoss: Double { currentValue - invested }
    var gainLossPct: Double { invested > 0 ? (gainLoss / invested) * 100 : 0 }
    var isGainer: Bool { gainLoss >= 0 }
}

struct Account: Identifiable {
    let id = UUID()
    let name: String
    let institution: String
    let balance: Double
}

struct Investment: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let risk: String
    let amount: Int
    let returns: String
    let startDate: String
    let associatedGoal: String

    var schemeCode: String?
    var lastNAV: Double?
}

struct Goal: Identifiable {
    let id = UUID()
    let name: String
    let associatedFund: String
    let targetAmount: String
    let collectedAmount: String
    let timePeriod: String
    let progress: Double // Percentage between 0 and 1
}

struct Loan: Identifiable {
    let id = UUID()
    let name: String
    let timePeriod: String
    let status: String
    let totalAmount: String
    let paidAmount: String
    let emisPaid: Int
    let totalEmis: Int
}

struct MoneyFlowData: Identifiable {
    let id = UUID()
    let month: String
    let savings: Double
    let emergencyFund: Double
    let expenses: Double
}

struct MoneyFlowChartItem: Identifiable, Codable {
    let id: UUID
    let month: String
    let type: String // "Income" or "Expense"
    let category: String
    let amount: Double
    
    init(id: UUID = UUID(), month: String, type: String, category: String, amount: Double) {
        self.id = id
        self.month = month
        self.type = type
        self.category = category
        self.amount = amount
    }
}

struct FundAllocation: Identifiable {
    let id = UUID()
    let name: String
    let percentage: Double
    let color: Color
}

struct InvestmentPlanInputModel: Codable, Hashable {
    var investmentType: String
    var amount: String
    var liquidity: String
    var riskType: String
    var timePeriod: String
    var scheduleInvestmentDate: Date
    var scheduleSIPDate: Date
    var purposeOfInvestment: String
    var targetAmount: String
    var savedAmount: String
    var hasEmergencyFund: Bool
    var investmentMentality: InvestmentMentality = .mutualFunds

    var monthlyIncome: Double = 0
    var existingEMIs: Double = 0
    var openToLoan: Bool = true
    var preferredLoanTenureYears: Int = 4
    var bankName: String?
    var interestRate: Double?
    var loanAmount: Double?

    var currentAge: Int?
    var retirementAge: Int?
    var yearsPostRetirement: Int?
    var lifestylePreference: String?
    var yearlyStepUpPct: Double?
    var withdrawalPreference: String?

    var educationFor: String?
    var educationDurationYrs: Int?
    var educationLocation: String?
    var fundingStrategy: String?

    var downPaymentAffordable: Double?
    var vehicleBuyLogic: String?

    var destinationType: String?
    var isFlexibleTimeline: Bool?

    var contributionSplit: String?
    var wealthIntent: String?
}

struct InvestmentPlanModel: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let dateSaved: String
    let targetGoal: String
    let input: InvestmentPlanInputModel
}
