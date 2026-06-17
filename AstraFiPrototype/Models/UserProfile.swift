import Foundation

struct AstraUserProfile: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
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
    case goldETF = "Gold ETF"
    case physicalGold = "Physical Gold"
    case stocks = "Stocks"
    case deposits = "Deposits"
    case cryptocurrency = "Cryptocurrency"
    case realEstate = "Real Estate"
    case bonds = "Bonds"
    case ppf = "PPF"
    case nps = "NPS"
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
            return investmentAmount * Double(count)
        }
        return investmentAmount
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
        return currentUnits * price
    }

    var currentGain: Double {
        currentValue - totalInvestedAmount
    }

    var tenureInYears: Double {
        let diff = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return max(0.1, Double(diff) / 365.0)
    }
    
    var absoluteProfitRatio: Double {
        guard totalInvestedAmount > 0 else { return 0 }
        return currentGain / totalInvestedAmount
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
