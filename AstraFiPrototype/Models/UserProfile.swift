import Foundation
import SwiftUI

struct AstraUserProfile: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var createdAt: Date? = nil
    var signUp: AstraSignUp
    var basicDetails: AstraBasicDetails
    var assets: AstraAssets
    var liabilities: AstraLiabilities
    var investments: [AstraInvestment]
    var loans: [AstraLoan]
    var insurances: [AstraInsurance]
    var goals: [AstraGoal]
    var financialHealthReport: AstraFinancialHealthReport?
    var cashflowData: CashflowEntry? = nil
    var monthlyCashflowSnapshots: [String: CashflowEntry] = [:] // Key: "yyyy-MM"
    var monthlyHealthAssessments: [AstraHealthAssessment] = []
    var isSetuConnected: Bool = false
    var emergencyFundAllocation: AstraEmergencyFundAllocation?
    // Kept optional so profiles saved before this feature remain decodable.
    var emergencyFundManualAmount: Double? = nil
    var emergencyFundLinkedInvestmentIDs: [UUID]? = nil

    mutating func updateManualAdjustment(for type: AstraInvestmentType, targetAmount: Double) {
        let manualName = "Manual \(type.rawValue) Adjustment"
        let otherInvestments = investments.filter { $0.investmentType == type && $0.investmentName != manualName }
        let otherTotal = otherInvestments.reduce(0.0) { $0 + $1.currentValue.safeFinite }
        
        investments.removeAll { $0.investmentType == type && $0.investmentName == manualName }
        
        let needed = targetAmount - otherTotal
        if needed != 0 {
            let adj = AstraInvestment(
                investmentType: type,
                investmentName: manualName,
                investmentAmount: needed,
                startDate: Date(),
                mode: .lumpsum
            )
            investments.append(adj)
        }
    }
    
    mutating func updateManualLoanAdjustment(for type: AstraLoanType, targetAmount: Double) {
        let manualName = "Manual \(type.rawValue) Adjustment"
        let otherLoans = loans.filter { $0.loanType == type && $0.loanName != manualName }
        let otherTotal = otherLoans.reduce(0.0) { $0 + $1.loanAmount }
        
        loans.removeAll { $0.loanType == type && $0.loanName == manualName }
        
        let needed = targetAmount - otherTotal
        if needed != 0 {
            let adj = AstraLoan(
                loanName: manualName,
                loanType: type,
                lender: .other,
                loanAmount: needed,
                interestRate: 0,
                loanStartDate: Date(),
                loanTenureMonths: 1
            )
            loans.append(adj)
        }
    }
}

struct AstraEmergencyFundAllocation: Codable, Equatable {
    var treasuryBills: Double = 0      // Percentage (0-100)
    var commercialPapers: Double = 0   // Percentage (0-100)
    var savingsAccount: Double = 100   // Percentage (0-100) - Start with 100% in savings
    var sweepInFD: Double = 0          // Percentage (0-100)
    
    var isAllocatedByUser: Bool = false
}

extension Sequence where Element: Identifiable {
    func removeDuplicates() -> [Element] {
        var set = Set<Element.ID>()
        return filter { set.insert($0.id).inserted }
    }
}

struct AstraHealthAssessment: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var date: Date
    var score: Int
    var status: String 
    var keyInsights: [String]
    var insights: FinancialAssessmentInsights?
}

struct AstraSignUp: Codable, Equatable {
    var signUpName: String
    var email: String
    var password: String
}

struct AstraBasicDetails: Codable, Equatable {
    var name: String
    var age: Int
    var gender: AstraGender
    var maritalStatus: AstraMaritalStatus = .single
    var adultDependents: Int
    var childDependents: Int
    var incomeType: AstraIncomeType
    var monthlyIncome: Double
    var monthlyIncomeAfterTax: Double
    var monthlyExpenses: Double
    var emergencyFundAmount: Double
    var activeInvestment: Bool
    var riskTolerance: AstraRiskTolerance = .medium
    var investmentHorizon: AstraInvestmentHorizon = .mediumTerm
    var phoneNumber: String? = nil
}

enum AstraGender: String, Codable, CaseIterable {
    case male, female, other
}

enum AstraMaritalStatus: String, Codable, CaseIterable {
    case single, married, divorced, widowed
}

enum AstraIncomeType: String, Codable, CaseIterable {
    case fixed, variable
}

enum AstraRiskTolerance: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

enum AstraInvestmentHorizon: String, Codable, CaseIterable {
    case shortTerm = "Short Term (1-3 yrs)"
    case mediumTerm = "Medium Term (3-7 yrs)"
    case longTerm = "Long Term (7+ yrs)"
}

struct AstraInvestment: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var investmentType: AstraInvestmentType
    var subtype: AstraInvestmentSubtype?
    var investmentName: String
    var investmentAmount: Double
    var startDate: Date
    var associatedGoalID: UUID?
    var mode: AstraInvestmentMode = .lumpsum

    var schemeCode: String?
    var isin: String?
    var lastNAV: Double?
    var lastUpdated: Date?
    var units: Double?
    var purchaseNAV: Double?

    // Stock specific fields
    var symbol: String?
    var quantity: Double?
    var livePrice: Double?
    var priceChange: Double?
    var priceChangePercentage: Double?
    var createdAt: Date = Date()
    var brokerSource: String?
    var brokerInstrumentID: String?
    
    var installments: [AstraInvestmentTransaction] = []
}

struct AstraInvestmentTransaction: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var date: Date
    var type: TransactionType = .buy
    var amount: Double
    var nav: Double
    var units: Double
    
    enum TransactionType: String, Codable {
        case buy = "Buy"
        case sell = "Sell"
    }
}

enum AstraInvestmentType: String, Codable, CaseIterable {
    case mutualFund = "Mutual Fund"
    case stocks = "Stocks"
    case goldETF = "Gold ETF"
    case cryptocurrency = "Cryptocurrency"
    case deposits = "Deposits"
    case physicalGold = "Physical Gold"
    case ppf = "PPF"
    case nps = "NPS"
    case bonds = "Bonds"
    case realEstate = "Real Estate"
    case cashSavings = "Cash Savings"
    case emergencyFund = "Emergency Fund"
    case other = "Other"
}

enum AstraInvestmentMode: String, Codable {
    case lumpsum = "LumpSum"
    case sip = "SIP"
}

extension AstraInvestment {
    var totalInvestedAmount: Double {
        if !installments.isEmpty {
            return installments.reduce(0.0) { result, tx in
                if tx.type == .buy {
                    return result + tx.amount
                } else {
                    return result - tx.amount
                }
            }
        }
        
        if mode == .sip {
            let calendar = Calendar.current
            let today = Date()

            // Count only SIP instalments that have actually been triggered.
            // Each instalment fires on the same day-of-month as startDate.
            // We walk month-by-month and only count a month if that instalment
            // date is on or before today.
            var count = 0
            var checkDate = startDate
            while checkDate <= today {
                count += 1
                guard let next = calendar.date(byAdding: .month, value: 1, to: checkDate) else { break }
                checkDate = next
            }
            return (investmentAmount * Double(count)).safeFinite
        }
        return investmentAmount.safeFinite
    }

    var currentValue: Double {
        let currentUnits: Double
        if !installments.isEmpty {
            currentUnits = installments.reduce(0.0) { result, tx in
                if tx.type == .buy {
                    return result + tx.units
                } else {
                    return result - tx.units
                }
            }
        } else {
            currentUnits = units ?? quantity ?? 0
        }
        
        let price = livePrice ?? lastNAV ?? 0
        let calculated = (currentUnits.safeFinite * price.safeFinite).safeFinite
        if calculated > 0 {
            return calculated
        }
        return investmentAmount.safeFinite
    }

    var currentGain: Double {
        (currentValue - totalInvestedAmount).safeFinite
    }

    var tenureInYears: Double {
        let diff = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return max(0.1, Double(diff) / 365.0)
    }
    
    var absoluteProfitRatio: Double {
        guard totalInvestedAmount > 0 else { return 0 }
        return (currentGain / totalInvestedAmount).safeFinite
    }
    
    var expectedAnnualRate: Double {
        // Calculate CAGR if tenure is significant (> 6 months)
        let tenure = tenureInYears
        let profitRatio = absoluteProfitRatio
        
        var rate: Double
        if tenure >= 0.5 {
            // Formula: (1 + r)^t = 1 + profitRatio => r = (1 + profitRatio)^(1/t) - 1
            rate = pow(1.0 + profitRatio, 1.0 / tenure) - 1.0
            
            // Sanity check: cap extreme values (e.g. -20% to +40%)
            if rate.isFinite {
                 rate = max(-0.2, min(0.4, rate))
            } else {
                rate = defaultRateForType
            }
        } else {
            // Fallback to asset class defaults for new investments
            rate = defaultRateForType
        }
        
        return rate
    }
    
    private var defaultRateForType: Double {
        switch investmentType {
        case .stocks:         return 0.15
        case .mutualFund:     return 0.12
        case .cryptocurrency: return 0.20
        case .deposits, .bonds, .ppf: return 0.07
        case .goldETF, .physicalGold: return 0.09
        case .realEstate:     return 0.08
        case .nps:            return 0.10
        case .cashSavings, .emergencyFund: return 0.03
        default:              return 0.10
        }
    }
}

enum AstraInvestmentSubtype: String, Codable {
    case equityFund, debtFund, indexFund, hybridFund
    case largeCap, midCap, smallCap, dividend
    case bitcoin, altcoin, token
    case fixedDeposit, recurringDeposit
}

struct MFScheme: Identifiable, Codable, Equatable {
    var id: String { schemeCode }
    let schemeCode: String
    let isin: String
    let alternateISIN: String?
    let name: String
    let nav: Double
    let date: String
}

struct AstraLoan: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    /// Custom name entered by user in assessment (e.g. "Personal Loan", "Car EMI").
    /// Empty string = display uses loanType.rawValue as fallback.
    var loanName: String = ""
    var loanType: AstraLoanType
    var lender: AstraLoanLender
    var loanAmount: Double
    var interestRate: Double
    var interestType: AstraInterestType = .compound
    var compoundingFrequency: AstraCompoundingFrequency = .monthly

    var emiAmount: Double?
    var emiFrequency: AstraEMIFrequency = .monthly
    var loanStartDate: Date
    var firstEMIDate: Date?
    var loanTenureMonths: Int
    var installmentsPaid: Int = 0

    var prepayments: [AstraPrepayment] = []
    var prepaymentPenaltyPercentage: Double = 0.0

    var isFloatingRate: Bool = false
    var interestRateHistory: [AstraRateChange] = []

    var processingFee: Double = 0.0
    var insurancePremium: Double = 0.0
    var latePaymentPenalty: Double = 0.0
    var otherCharges: Double = 0.0

    var moratoriumMonths: Int = 0
    var interestAccrualDuringMoratorium: Bool = true

    var payments: [AstraLoanPayment] = []

    var trackTaxBenefits: Bool = false

    /// Title shown in UI — user's custom name if entered, else the loan type label.
    var displayName: String {
        loanName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? loanType.rawValue
            : loanName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Subtitle shown in UI — bank name if selected, else the loan type (avoids showing "Other").
    var displayLender: String {
        lender == .other ? loanType.rawValue : lender.rawValue
    }
}

enum AstraInterestType: String, Codable, CaseIterable, Hashable {
    case simple = "Simple"
    case compound = "Compound"
}

enum AstraCompoundingFrequency: String, Codable, CaseIterable, Hashable {
    case none = "None"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"
}

enum AstraEMIFrequency: String, Codable, CaseIterable, Hashable {
    case monthly = "Monthly"
    case biWeekly = "Bi-weekly"
}

struct AstraPrepayment: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var amount: Double
    var date: Date
}

struct AstraRateChange: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var newRate: Double
    var effectiveDate: Date
}

struct AstraLoanPayment: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var emiNumber: Int
    var date: Date
    var amountPaid: Double
    var interestComponent: Double
    var principalComponent: Double
    var remainingBalance: Double
    var status: AstraPaymentStatus = .paid
    var penalty: Double = 0.0
}

enum AstraPaymentStatus: String, Codable, CaseIterable {
    case paid = "Paid"
    case missed = "Missed"
    case pending = "Pending"
    case overdue = "Overdue"
}

enum AstraLoanType: String, Codable, CaseIterable {
    case homeLoan = "Home Loan"
    case educationLoan = "Education Loan"
    case carLoan = "Car Loan"
    case businessLoan = "Business Loan"
    case personalLoan = "Personal Loan"
    case creditCard = "Credit Card"
    case other = "Other"
}

enum AstraLoanLender: String, Codable, CaseIterable {
    case stateBankOfIndia = "SBI"
    case hdfcBank = "HDFC Bank"
    case iciciBank = "ICICI Bank"
    case axisBank = "Axis Bank"
    case bankOfBaroda = "Bank of Baroda"
    case punjabNationalBank = "PNB"
    case kotakMahindra = "Kotak Mahindra"
    case bandhanBank = "Bandhan Bank"
    case yesBank = "Yes Bank"
    case other = "Other"
}

enum AstraInsuranceType: String, Codable, CaseIterable {
    case health = "Health"
    case life = "Life"
    case motor = "Motor"
    case travel = "Travel"
    case termLifeInsurance = "Term Life"
    case criticalIllness = "Critical Illness"
    case ulip = "ULIP"
    case other = "Other"
}

enum AstraPremiumFrequency: String, Codable, CaseIterable, Hashable {
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case halfYearly = "Half-Yearly"
    case yearly = "Yearly"
    case single = "Single Premium"
}

enum AstraClaimStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case approved = "Approved"
    case rejected = "Rejected"
}

enum AstraPolicyStatus: String, Codable, CaseIterable {
    case active = "Active"
    case lapsed = "Lapsed"
    case gracePeriod = "Grace Period"
    case matured = "Matured"
}

struct AstraClaim: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var date: Date
    var amount: Double
    var status: AstraClaimStatus
    var description: String? = nil
}

struct AstraRider: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var benefit: String
    var premium: Double
}

struct AstraInsurancePayment: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var date: Date
    var amount: Double
    var status: AstraPaymentStatus
}

struct AstraCoveredMember: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var age: Int
    var relationship: String
}

struct AstraLifeInsuranceDetails: Codable, Equatable {
    var nomineeName: String? = nil
    var maturityBenefit: Double? = nil
    var deathBenefit: Double? = nil
    var lifeInsuranceType: String? = nil 
}

struct AstraHealthInsuranceDetails: Codable, Equatable {
    var planType: String? = nil 
    var coveredMembers: [AstraCoveredMember] = []
    var roomRentLimit: Double? = nil
    var prePostHospitalization: String? = nil
    var daycareProcedures: Bool = false
    var networkHospitalsCount: Int? = nil
}

struct AstraMotorInsuranceDetails: Codable, Equatable {
    var vehicleModel: String? = nil
    var vehicleNumber: String? = nil
    var idv: Double? = nil
    var thirdPartyCoverage: Bool = true
    var ownDamageCoverage: Bool = true
    var zeroDep: Bool = false
    var roadsideAssistance: Bool = false
}

struct AstraInsurance: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var insuranceType: AstraInsuranceType
    var provider: String
    var policyNumber: String
    var sumAssured: Double
    var annualPremium: Double
    var startDate: Date
    var expiryDate: Date? = nil

    var basePremium: Double = 0
    var taxesGST: Double = 0
    var addOnCost: Double = 0

    var premiumFrequency: AstraPremiumFrequency = .yearly

    var lifeDetails: AstraLifeInsuranceDetails? = nil
    var healthDetails: AstraHealthInsuranceDetails? = nil
    var motorDetails: AstraMotorInsuranceDetails? = nil

    var claims: [AstraClaim] = []
    var riders: [AstraRider] = []
    var payments: [AstraInsurancePayment] = []

    var surrenderValue: Double? = nil
    var lockInPeriodMonths: Int? = nil
    var maturityDate: Date? = nil
    var expectedMaturityAmount: Double? = nil

    var status: AstraPolicyStatus {
        let now = Date()
        if let expiry = expiryDate, expiry < now {
            return .lapsed
        }

        return .active
    }
}

struct AstraAssets: Codable, Equatable {
    var savingsAccountAmount: Double = 0
    var currentAccountAmount: Double = 0
    var stocksHoldingAmount: Double = 0
    var mutualFundHoldingAmount: Double = 0
    var otherInvestmentAmount: Double = 0
    var propertyAmount: Double = 0
    var vehiclesAmount: Double = 0
    var depositsAmount: Double = 0
    var jewelleryAmount: Double = 0
    var luxuryBelongingsAmount: Double = 0
    var otherAssetsAmount: Double = 0

    var totalAssets: Double {
        savingsAccountAmount + currentAccountAmount + stocksHoldingAmount +
        mutualFundHoldingAmount + otherInvestmentAmount + propertyAmount +
        vehiclesAmount + depositsAmount + jewelleryAmount +
        luxuryBelongingsAmount + otherAssetsAmount
    }
}

struct AstraLiabilities: Codable, Equatable {
    var homeLoanAmount: Double = 0
    var vehicleLoanAmount: Double = 0
    var creditCardBills: Double = 0
    var educationLoanAmount: Double = 0
    var otherLoanAmount: Double = 0
    var otherDebtAmount: Double = 0

    var totalLiabilities: Double {
        homeLoanAmount + vehicleLoanAmount + creditCardBills +
        educationLoanAmount + otherLoanAmount + otherDebtAmount
    }
}

struct AstraGoal: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var goalName: String
    var targetAmount: Double
    var currentAmount: Double // This will now represent the cached total or be superseded
    var manualSavingsContribution: Double = 0
    var startDate: Date = Date()
    var targetDate: Date

    init(id: UUID = UUID(), goalName: String, targetAmount: Double, currentAmount: Double, manualSavingsContribution: Double = 0, startDate: Date = Date(), targetDate: Date) {
        self.id = id
        self.goalName = goalName
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.manualSavingsContribution = manualSavingsContribution
        self.startDate = startDate
        self.targetDate = targetDate
    }
}

extension AstraGoal {
    var displayGradient: [Color] {
        let lower = goalName.lowercased()
        if lower.contains("home") { return [Color(hex: "#30D158"), Color(hex: "#25A244")] }
        if lower.contains("car")  { return [Color(hex: "#32ADE6"), Color(hex: "#5E5CE6")] }
        if lower.contains("edu")  { return [Color(hex: "#FF9F0A"), Color(hex: "#FF453A")] }
        return [Color(hex: "#BF5AF2"), Color(hex: "#5E5CE6")]
    }
}

struct AstraFinancialHealthReport: Codable, Equatable {
    var netWorth: Double
    var savingsRate: Double
    var debtToIncomeRatio: Double
    var investmentScore: Int
    var emergencyFundMonths: Double
}

extension AstraLoan {
    var calculatedEMI: Double {
        if let directEMI = emiAmount, directEMI > 0 {
            return directEMI
        }

        guard loanTenureMonths > 0 else { return 0 }
        let annualRate = interestRate / 100

        if interestType == .simple {
            let totalInterest = loanAmount * annualRate * (Double(loanTenureMonths) / 12)
            return (loanAmount + totalInterest) / Double(loanTenureMonths)
        } else {

            let r = annualRate / 12
            if r == 0 { return loanAmount / Double(loanTenureMonths) }

            let pqr = pow(1 + r, Double(loanTenureMonths))
            if pqr.isInfinite {

                return (loanAmount * r).isFinite ? (loanAmount * r) : 0
            }

            let emi = (loanAmount * r * pqr) / (pqr - 1)
            return emi.isFinite ? emi : 0
        }
    }

    var estimatedPaidAmount: Double {
        return min(calculatedEMI * Double(max(0, installmentsPaid)), loanAmount)
    }

    var remainingPrincipal: Double {
        return max(0, loanAmount - estimatedPaidAmount)
    }

    var tenureDisplay: String {
        let years  = loanTenureMonths / 12
        let months = loanTenureMonths % 12
        if months == 0 { return "\(years) \(years == 1 ? "Year" : "Years")" }
        if years  == 0 { return "\(months) mo" }
        return "\(years)y \(months)mo"
    }
}

struct CashflowEntry: Codable, Equatable {
    var rent:          Double = 0
    var groceries:     Double = 0
    var utilities:     Double = 0
    var dining:        Double = 0
    var transport:     Double = 0
    var shopping:      Double = 0
    var entertainment: Double = 0
    var misc:          Double = 0

    struct DetailedItem: Identifiable, Codable, Equatable {
        let id: UUID
        var name: String
        var amount: Double
        
        init(id: UUID = UUID(), name: String, amount: Double) {
            self.id = id
            self.name = name
            self.amount = amount
        }
    }
    
    var incomeSources: [DetailedItem] = []
    var expenseSources: [DetailedItem] = []

    var totalIncome: Double {
        incomeSources.reduce(0) { $0 + $1.amount }
    }
    
    var totalExpenses: Double {
        if !expenseSources.isEmpty {
            return expenseSources.reduce(0) { $0 + $1.amount }
        }
        return rent + groceries + utilities + dining + transport + shopping + entertainment + misc
    }

    var total: Double { totalExpenses }

    var breakdown: [(String, Double)] {
        if !expenseSources.isEmpty {
            return expenseSources.map { ($0.name, $0.amount) }
        }
        let items: [(String, Double)] = [
            ("EMIs and Rent",        rent + transport),
            ("Living Expenses",      dailyHouseholdCombined),
            ("Utilities & Other",    utilities + misc),
        ]
        return items.filter { $0.1 > 0 }
    }

    private var dailyHouseholdCombined: Double {
        groceries + dining + shopping + entertainment
    }
}

// MARK: - Normalization & Deduplication Extensions

extension String {
    var normalizedEntityKey: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

extension AstraGoal {
    func isEquivalent(to other: AstraGoal) -> Bool {
        if self.id == other.id { return true }
        let name1 = self.goalName.normalizedEntityKey
        let name2 = other.goalName.normalizedEntityKey
        return !name1.isEmpty && name1 == name2
    }

    func merged(with incoming: AstraGoal) -> AstraGoal {
        var result = self
        result.goalName = incoming.goalName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? self.goalName : incoming.goalName
        result.targetAmount = incoming.targetAmount > 0 ? incoming.targetAmount : self.targetAmount
        result.targetDate = incoming.targetDate
        result.startDate = min(self.startDate, incoming.startDate)
        if incoming.manualSavingsContribution > 0 {
            result.manualSavingsContribution = incoming.manualSavingsContribution
        }
        if incoming.currentAmount > 0 {
            result.currentAmount = incoming.currentAmount
        }
        return result
    }
}

extension AstraInvestment {
    func isEquivalent(to other: AstraInvestment) -> Bool {
        if self.id == other.id { return true }
        
        // Broker instrument match
        if let b1 = self.brokerInstrumentID, !b1.isEmpty,
           let b2 = other.brokerInstrumentID, !b2.isEmpty, b1 == b2 {
            return true
        }

        // Mutual fund scheme code match
        if let s1 = self.schemeCode, !s1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let s2 = other.schemeCode, !s2.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           s1.normalizedEntityKey == s2.normalizedEntityKey {
            return true
        }

        // ISIN match
        if let i1 = self.isin, !i1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let i2 = other.isin, !i2.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           i1.normalizedEntityKey == i2.normalizedEntityKey {
            return true
        }

        // Stock symbol match
        if let sym1 = self.symbol, !sym1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let sym2 = other.symbol, !sym2.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           sym1.normalizedEntityKey == sym2.normalizedEntityKey {
            return true
        }

        // Name + type match
        let n1 = self.investmentName.normalizedEntityKey
        let n2 = other.investmentName.normalizedEntityKey
        if !n1.isEmpty && n1 == n2 && self.investmentType == other.investmentType {
            return true
        }

        return false
    }

    func merged(with incoming: AstraInvestment) -> AstraInvestment {
        var result = self
        result.investmentName = incoming.investmentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? self.investmentName : incoming.investmentName
        result.investmentType = incoming.investmentType
        if let sub = incoming.subtype { result.subtype = sub }
        result.investmentAmount = incoming.investmentAmount > 0 ? incoming.investmentAmount : self.investmentAmount
        result.mode = incoming.mode
        result.startDate = incoming.startDate
        if let sc = incoming.schemeCode, !sc.isEmpty { result.schemeCode = sc }
        if let isin = incoming.isin, !isin.isEmpty { result.isin = isin }
        if let sym = incoming.symbol, !sym.isEmpty { result.symbol = sym }
        if let units = incoming.units, units > 0 { result.units = units }
        if let qty = incoming.quantity, qty > 0 { result.quantity = qty }
        if let nav = incoming.lastNAV, nav > 0 { result.lastNAV = nav }
        if let pNav = incoming.purchaseNAV, pNav > 0 { result.purchaseNAV = pNav }
        if let lp = incoming.livePrice, lp > 0 { result.livePrice = lp }
        if let pc = incoming.priceChange { result.priceChange = pc }
        if let pcp = incoming.priceChangePercentage { result.priceChangePercentage = pcp }
        if let gId = incoming.associatedGoalID { result.associatedGoalID = gId }
        if let bs = incoming.brokerSource { result.brokerSource = bs }
        if let bi = incoming.brokerInstrumentID { result.brokerInstrumentID = bi }

        // Merge transactions idempotently
        var combinedTxs = self.installments
        for tx in incoming.installments {
            if !combinedTxs.contains(where: { $0.id == tx.id || (abs($0.date.timeIntervalSince(tx.date)) < 86400 && $0.amount == tx.amount && $0.type == tx.type) }) {
                combinedTxs.append(tx)
            }
        }
        result.installments = combinedTxs
        return result
    }
}

extension AstraLoan {
    func isEquivalent(to other: AstraLoan) -> Bool {
        if self.id == other.id { return true }

        let n1 = self.displayName.normalizedEntityKey
        let n2 = other.displayName.normalizedEntityKey

        // Specific custom/scheme name match
        if !n1.isEmpty && !n2.isEmpty && n1 == n2 && self.loanType == other.loanType {
            return true
        }

        // Generic loan type + lender match
        if self.loanType == other.loanType && self.lender == other.lender {
            return true
        }

        return false
    }

    func merged(with incoming: AstraLoan) -> AstraLoan {
        var result = self
        if !incoming.loanName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result.loanName = incoming.loanName
        }
        result.loanType = incoming.loanType
        if incoming.lender != .other || result.lender == .other {
            result.lender = incoming.lender
        }
        result.loanAmount = incoming.loanAmount > 0 ? incoming.loanAmount : self.loanAmount
        result.interestRate = incoming.interestRate > 0 ? incoming.interestRate : self.interestRate
        result.interestType = incoming.interestType
        result.compoundingFrequency = incoming.compoundingFrequency
        if let emi = incoming.emiAmount, emi > 0 { result.emiAmount = emi }
        result.emiFrequency = incoming.emiFrequency
        result.loanStartDate = incoming.loanStartDate
        if let firstEmi = incoming.firstEMIDate { result.firstEMIDate = firstEmi }
        result.loanTenureMonths = incoming.loanTenureMonths > 0 ? incoming.loanTenureMonths : self.loanTenureMonths
        result.moratoriumMonths = incoming.moratoriumMonths
        result.insurancePremium = incoming.insurancePremium > 0 ? incoming.insurancePremium : self.insurancePremium

        // Preserve tracking progress & payments
        result.installmentsPaid = max(self.installmentsPaid, incoming.installmentsPaid)
        var combinedPayments = self.payments
        for p in incoming.payments {
            if !combinedPayments.contains(where: { $0.id == p.id || $0.emiNumber == p.emiNumber }) {
                combinedPayments.append(p)
            }
        }
        result.payments = combinedPayments

        var combinedPrepay = self.prepayments
        for prep in incoming.prepayments {
            if !combinedPrepay.contains(where: { $0.id == prep.id }) {
                combinedPrepay.append(prep)
            }
        }
        result.prepayments = combinedPrepay

        return result
    }
}

extension AstraInsurance {
    func isEquivalent(to other: AstraInsurance) -> Bool {
        if self.id == other.id { return true }

        let p1 = self.policyNumber.normalizedEntityKey
        let p2 = other.policyNumber.normalizedEntityKey
        if !p1.isEmpty && !p2.isEmpty && p1 == p2 {
            return true
        }

        let prov1 = self.provider.normalizedEntityKey
        let prov2 = other.provider.normalizedEntityKey
        if self.insuranceType == other.insuranceType && !prov1.isEmpty && prov1 == prov2 {
            return true
        }

        return false
    }

    func merged(with incoming: AstraInsurance) -> AstraInsurance {
        var result = self
        result.insuranceType = incoming.insuranceType
        if !incoming.provider.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result.provider = incoming.provider
        }
        if !incoming.policyNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result.policyNumber = incoming.policyNumber
        }
        result.sumAssured = incoming.sumAssured > 0 ? incoming.sumAssured : self.sumAssured
        result.annualPremium = incoming.annualPremium > 0 ? incoming.annualPremium : self.annualPremium
        if incoming.basePremium > 0 { result.basePremium = incoming.basePremium }
        if incoming.taxesGST > 0 { result.taxesGST = incoming.taxesGST }
        if incoming.addOnCost > 0 { result.addOnCost = incoming.addOnCost }
        result.premiumFrequency = incoming.premiumFrequency
        result.startDate = incoming.startDate
        if let exp = incoming.expiryDate { result.expiryDate = exp }
        if let life = incoming.lifeDetails { result.lifeDetails = life }
        if let health = incoming.healthDetails { result.healthDetails = health }
        if let motor = incoming.motorDetails { result.motorDetails = motor }
        if let surr = incoming.surrenderValue { result.surrenderValue = surr }
        if let mat = incoming.maturityDate { result.maturityDate = mat }
        if let expMat = incoming.expectedMaturityAmount { result.expectedMaturityAmount = expMat }

        var combinedClaims = self.claims
        for c in incoming.claims {
            if !combinedClaims.contains(where: { $0.id == c.id }) {
                combinedClaims.append(c)
            }
        }
        result.claims = combinedClaims

        var combinedPayments = self.payments
        for p in incoming.payments {
            if !combinedPayments.contains(where: { $0.id == p.id }) {
                combinedPayments.append(p)
            }
        }
        result.payments = combinedPayments

        var combinedRiders = self.riders
        for r in incoming.riders {
            if !combinedRiders.contains(where: { $0.id == r.id }) {
                combinedRiders.append(r)
            }
        }
        result.riders = combinedRiders

        return result
    }
}

extension Array where Element == AstraGoal {
    func deduplicated() -> [AstraGoal] {
        var result: [AstraGoal] = []
        for goal in self {
            if let index = result.firstIndex(where: { $0.isEquivalent(to: goal) }) {
                result[index] = result[index].merged(with: goal)
            } else {
                result.append(goal)
            }
        }
        return result
    }
}

extension Array where Element == AstraInvestment {
    func deduplicated() -> [AstraInvestment] {
        var result: [AstraInvestment] = []
        for inv in self {
            if let index = result.firstIndex(where: { $0.isEquivalent(to: inv) }) {
                result[index] = result[index].merged(with: inv)
            } else {
                result.append(inv)
            }
        }
        return result
    }
}

extension Array where Element == AstraLoan {
    func deduplicated() -> [AstraLoan] {
        var result: [AstraLoan] = []
        for loan in self {
            if let index = result.firstIndex(where: { $0.isEquivalent(to: loan) }) {
                result[index] = result[index].merged(with: loan)
            } else {
                result.append(loan)
            }
        }
        return result
    }
}

extension Array where Element == AstraInsurance {
    func deduplicated() -> [AstraInsurance] {
        var result: [AstraInsurance] = []
        for ins in self {
            if let index = result.firstIndex(where: { $0.isEquivalent(to: ins) }) {
                result[index] = result[index].merged(with: ins)
            } else {
                result.append(ins)
            }
        }
        return result
    }
}
