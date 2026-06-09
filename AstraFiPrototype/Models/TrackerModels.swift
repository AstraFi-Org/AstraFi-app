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
    var yearsUntilEducation: Int?
    var fundingStrategy: String?

    var downPaymentAffordable: Double?
    var vehicleBuyLogic: String?

    var destinationType: String?
    var isFlexibleTimeline: Bool?

    var contributionSplit: String?
    var wealthIntent: String?
    
    var retirementPlanType: String?
    var retirementSIPAmount: String?
    var retirementFDFrequency: String?
    var retirementFDAmount: String?
    
    // Generic planning fields for other goals
    var goalPlanType: String?
    var goalSIPAmount: String?
    var goalFDFrequency: String?
    var goalFDAmount: String?

    // MARK: - Previews
    static var sampleRetirement: InvestmentPlanInputModel {
        InvestmentPlanInputModel(
            investmentType: "Monthly SIP", amount: "20000", liquidity: "Medium", riskType: "Moderate",
            timePeriod: "25", scheduleInvestmentDate: Date(), scheduleSIPDate: Date(),
            purposeOfInvestment: "Retirement", targetAmount: "50000000", savedAmount: "500000",
            hasEmergencyFund: true, retirementAge: 60, yearsPostRetirement: 25, lifestylePreference: "Normal"
        )
    }
    
    static var sampleEducation: InvestmentPlanInputModel {
        InvestmentPlanInputModel(
            investmentType: "Monthly SIP", amount: "15000", liquidity: "Medium", riskType: "Moderate",
            timePeriod: "15", scheduleInvestmentDate: Date(), scheduleSIPDate: Date(),
            purposeOfInvestment: "Education", targetAmount: "2500000", savedAmount: "100000",
            hasEmergencyFund: true, educationFor: "Child", educationDurationYrs: 4, educationLocation: "India"
        )
    }

    static var sampleHome: InvestmentPlanInputModel {
        InvestmentPlanInputModel(
            investmentType: "Monthly SIP", amount: "50000", liquidity: "Low", riskType: "Moderate",
            timePeriod: "10", scheduleInvestmentDate: Date(), scheduleSIPDate: Date(),
            purposeOfInvestment: "Home Purchase", targetAmount: "10000000", savedAmount: "1000000",
            hasEmergencyFund: true, openToLoan: true, preferredLoanTenureYears: 20
        )
    }

    static var sampleVehicle: InvestmentPlanInputModel {
        InvestmentPlanInputModel(
            investmentType: "Monthly SIP", amount: "25000", liquidity: "Medium", riskType: "Moderate",
            timePeriod: "5", scheduleInvestmentDate: Date(), scheduleSIPDate: Date(),
            purposeOfInvestment: "Vehicle", targetAmount: "1500000", savedAmount: "200000",
            hasEmergencyFund: true
        )
    }
}

//struct InvestmentPlanModel: Identifiable, Hashable {
//    let id = UUID()
//    let name: String
//    let dateSaved: String
//    let targetGoal: String
//    let input: InvestmentPlanInputModel
//}

struct InvestmentPlanModel: Identifiable, Hashable {
    var id: UUID = UUID()
    let name: String
    let dateSaved: String
    let targetGoal: String
    let input: InvestmentPlanInputModel
    var isFollowed: Bool = false  // ADD THIS
}
