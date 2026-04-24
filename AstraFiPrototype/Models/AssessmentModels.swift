import Foundation

struct AssessmentInvestmentEntry: Identifiable {
    let id = UUID()
    var type: InvestmentType = .mutualFund
    var mode: InvestmentMode = .lumpsum
    var fundName: String = ""
    var amount: String = ""
    var startDate: Date = Date()
    var showDatePicker: Bool = false
    var associatedGoal: String = ""

    var schemeCode: String?
    var isin: String?
    var units: String = ""

    var frequency: AssessmentSIPFrequency = .monthly

    var symbol: String?
    var quantity: String = ""
    var livePrice: Double?
    var currentValue: Double?
    var totalInvested: Double?
    var growthRate: Double?
    
    var customData: [String: String] = [:]
    var transactions: [AssessmentInvestmentTransaction] = []

    struct AssessmentInvestmentTransaction: Identifiable, Codable, Equatable {
        var id: UUID = UUID()
        var date: Date
        var type: String // "Buy" or "Sell"
        var amount: Double
        var nav: Double
        var units: Double
    }

    enum InvestmentType: String, CaseIterable, Identifiable, Hashable {
        case mutualFund = "Mutual Fund", stocks = "Stocks / Equity", bonds = "Bonds / Debt", realEstate = "Real Estate", gold = "Gold", crypto = "Cryptocurrency", ppf = "PPF", nps = "NPS"
        var id: String { rawValue }
    }

    enum InvestmentMode: String, CaseIterable, Hashable {
        case lumpsum = "LumpSum", sip = "SIP"
    }

    enum AssessmentSIPFrequency: String, CaseIterable, Identifiable, Hashable {
        case weekly = "Weekly", monthly = "Monthly", quarterly = "Quarterly", yearly = "Yearly"
        var id: String { rawValue }
    }
}

struct AssessmentLoanEntry: Identifiable {
    let id = UUID()
    var type: LoanType = .homeLoan
    var amount: String = ""
    var interestRate: String = ""
    var tenure: String = ""
    var moratorium: String = ""
    var insurancePremium: String = ""
    var loanName: String = ""
    var interestType: AstraInterestType = .compound
    var frequency: AstraCompoundingFrequency = .monthly
    var customData: [String: String] = [:]

    enum LoanType: String, CaseIterable, Identifiable, Hashable {
        case homeLoan = "Home Loan", carLoan = "Car Loan", educationLoan = "Education Loan", businessLoan = "Business Loan", personalLoan = "Personal Loan", creditCard = "Credit Card"
        var id: String { rawValue }
    }
}

struct AssessmentInsuranceEntry: Identifiable {
    let id = UUID()

    var insurer: String = ""
    var coverAmount: String = ""
    var annualPremium: String = ""
    var policyNumber: String = ""
    var startDate: Date = Date()
    var expiryDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    var showStartDatePicker: Bool = false
    var showExpiryDatePicker: Bool = false

    var basePremium: String = ""
    var taxesGST: String = ""
    var addOnCost: String = ""
    var premiumFrequency: AstraPremiumFrequency = .yearly

    var details: InsuranceDetails = .life(LifeDetails())

    var currentType: InsuranceType {
        switch details {
        case .life:            return .life
        case .health:          return .health
        case .motor:           return .motor
        case .term:            return .term
        case .criticalIllness: return .criticalIllness
        case .travel:          return .travel
        case .ulip:            return .ulip
        }
    }

    mutating func switchType(to newType: InsuranceType) {
        details = details.switched(to: newType)
    }

    enum InsuranceDetails: Hashable {
        case life(LifeDetails)
        case health(HealthDetails)
        case motor(MotorDetails)
        case term(TermDetails)
        case criticalIllness(CriticalIllnessDetails)
        case travel(TravelDetails)
        case ulip(ULIPDetails)

        var typeName: String {
            switch self {
            case .life:            return "Life Insurance"
            case .health:          return "Health Insurance"
            case .motor:           return "Motor Insurance"
            case .term:            return "Term Insurance"
            case .criticalIllness: return "Critical Illness"
            case .travel:          return "Travel Insurance"
            case .ulip:            return "ULIP"
            }
        }

        func switched(to newType: InsuranceType) -> InsuranceDetails {
            switch newType {
            case .life:            return .life(LifeDetails())
            case .health:          return .health(HealthDetails())
            case .motor:           return .motor(MotorDetails())
            case .term:            return .term(TermDetails())
            case .criticalIllness: return .criticalIllness(CriticalIllnessDetails())
            case .travel:          return .travel(TravelDetails())
            case .ulip:            return .ulip(ULIPDetails())
            }
        }

        var asLife:            LifeDetails?            { if case .life(let d)            = self { return d }; return nil }
        var asHealth:          HealthDetails?          { if case .health(let d)          = self { return d }; return nil }
        var asMotor:           MotorDetails?           { if case .motor(let d)           = self { return d }; return nil }
        var asTerm:            TermDetails?            { if case .term(let d)            = self { return d }; return nil }
        var asCriticalIllness: CriticalIllnessDetails? { if case .criticalIllness(let d) = self { return d }; return nil }
        var asTravel:          TravelDetails?          { if case .travel(let d)          = self { return d }; return nil }
        var asULIP:            ULIPDetails?            { if case .ulip(let d)            = self { return d }; return nil }
    }

    enum InsuranceType: String, CaseIterable, Identifiable, Hashable {
        case life = "Life Insurance", health = "Health Insurance", criticalIllness = "Critical Illness", term = "Term Insurance", motor = "Motor Insurance", travel = "Travel Insurance", ulip = "ULIP"
        var id: String { rawValue }

        var displayName: String { rawValue }

        var icon: String {
            switch self {
            case .life:            return "heart.fill"
            case .health:          return "cross.case.fill"
            case .motor:           return "car.fill"
            case .term:            return "shield.fill"
            case .criticalIllness: return "waveform.path.ecg"
            case .travel:          return "airplane"
            case .ulip:            return "chart.line.uptrend.xyaxis"
            }
        }
    }

    struct LifeDetails: Hashable {
        var nomineeName: String = ""
        var maturityBenefit: String = ""
        var deathBenefit: String = ""
        var lifeInsuranceType: String = "Endowment"
    }

    struct HealthDetails: Hashable {
        var planType: String = "Individual"
        var roomRentLimit: String = ""
        var prePostHospitalization: String = ""
        var daycareProcedures: Bool = true
        var networkHospitalsCount: String = ""
    }

    struct MotorDetails: Hashable {
        var vehicleModel: String = ""
        var vehicleNumber: String = ""
        var idv: String = ""
        var zeroDep: Bool = false
        var roadsideAssistance: Bool = false
    }

    struct TermDetails: Hashable {
        var nomineeName: String = ""
        var deathBenefit: String = ""
        var returnOfPremium: Bool = false
    }

    struct CriticalIllnessDetails: Hashable {
        var illnessesCovered: String = ""
        var waitingPeriodDays: String = ""
    }

    struct TravelDetails: Hashable {
        var destination: String = ""
        var tripDurationDays: String = ""
        var coversMedical: Bool = true
        var coversCancellation: Bool = false
    }

    struct ULIPDetails: Hashable {
        var nomineeName: String = ""
        var fundType: String = ""
        var surrenderValue: String = ""
        var lockInPeriod: String = ""
        var expectedMaturityAmount: String = ""
    }
}
