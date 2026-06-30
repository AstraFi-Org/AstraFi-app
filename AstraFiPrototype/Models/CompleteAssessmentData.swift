import SwiftUI
import Observation

@Observable
final class CompleteAssessmentData {

    var name = ""
    var email = ""
    var password = ""
    var age = ""
    var gender: Gender = .male
    var incomeType: IncomeType = .fixed
    var income = ""
    var expenditure = ""
    var emergencyFundAmount = ""

    // Insurance Flow
    var isInsured = false
    var numberOfDependents = ""
    var areDependentsInsured = false
    var dependentInsuranceEntries: [AssessmentInsuranceEntry] = []
    
    struct DependentProfile: Identifiable, Equatable {
        let id = UUID()
        var relation: String = ""
        var age: String = ""
        var disease: String = ""
    }
    var dependentProfiles: [DependentProfile] = []

    var investmentEntries: [AssessmentInvestmentEntry] = []
    var loanEntries: [AssessmentLoanEntry] = []
    var insuranceEntries: [AssessmentInsuranceEntry] = []

    enum Gender: String, Codable { case male, female }
    enum IncomeType: String, Codable { case fixed, variable }
}

extension CompleteAssessmentData {
    static func prefilled(from profile: AstraUserProfile) -> CompleteAssessmentData {
        let data = CompleteAssessmentData()
        data.name = profile.basicDetails.name
        data.email = profile.signUp.email
        data.password = profile.signUp.password
        data.age = Self.numberString(Double(profile.basicDetails.age))
        data.gender = profile.basicDetails.gender == .female ? .female : .male
        data.incomeType = profile.basicDetails.incomeType == .variable ? .variable : .fixed
        data.income = Self.numberString(profile.basicDetails.monthlyIncomeAfterTax)
        data.expenditure = Self.numberString(profile.basicDetails.monthlyExpenses)
        data.emergencyFundAmount = Self.numberString(profile.basicDetails.emergencyFundAmount)
        data.investmentEntries = profile.investments
            .filter { $0.brokerSource != "Upstox" }
            .map(Self.investmentEntry)
        data.loanEntries = profile.loans.map(Self.loanEntry)
        data.insuranceEntries = profile.insurances.map(Self.insuranceEntry)
        return data
    }

    private static func investmentEntry(from investment: AstraInvestment) -> AssessmentInvestmentEntry {
        var entry = AssessmentInvestmentEntry()
        entry.type = assessmentInvestmentType(from: investment.investmentType)
        entry.mode = investment.mode == .sip ? .sip : .lumpsum
        entry.fundName = investment.investmentName
        entry.amount = numberString(max(investment.totalInvestedAmount, investment.investmentAmount, investment.currentValue))
        entry.startDate = investment.startDate
        entry.schemeCode = investment.schemeCode
        entry.isin = investment.isin
        entry.symbol = investment.symbol
        entry.quantity = numberString(investment.quantity ?? investment.units ?? 0)
        entry.livePrice = investment.livePrice ?? investment.lastNAV
        entry.currentValue = investment.currentValue
        entry.totalInvested = investment.totalInvestedAmount
        entry.transactions = investment.installments.map {
            AssessmentInvestmentEntry.AssessmentInvestmentTransaction(
                id: $0.id,
                date: $0.date,
                type: $0.type.rawValue,
                amount: $0.amount,
                nav: $0.nav,
                units: $0.units
            )
        }
        return entry
    }

    private static func loanEntry(from loan: AstraLoan) -> AssessmentLoanEntry {
        var entry = AssessmentLoanEntry()
        entry.type = assessmentLoanType(from: loan.loanType)
        entry.amount = numberString(loan.loanAmount)
        entry.interestRate = numberString(loan.interestRate)
        entry.tenure = String(loan.loanTenureMonths)
        entry.moratorium = String(loan.moratoriumMonths)
        entry.insurancePremium = numberString(loan.insurancePremium)
        entry.startDate = loan.loanStartDate
        entry.loanName = loan.loanName
        entry.interestType = loan.interestType
        entry.frequency = loan.compoundingFrequency
        return entry
    }

    private static func insuranceEntry(from insurance: AstraInsurance) -> AssessmentInsuranceEntry {
        var entry = AssessmentInsuranceEntry()
        entry.insurer = insurance.provider
        entry.coverAmount = numberString(insurance.sumAssured)
        entry.annualPremium = numberString(insurance.annualPremium)
        entry.policyNumber = insurance.policyNumber
        entry.startDate = insurance.startDate
        entry.expiryDate = insurance.expiryDate ?? Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        entry.basePremium = numberString(insurance.basePremium)
        entry.taxesGST = numberString(insurance.taxesGST)
        entry.addOnCost = numberString(insurance.addOnCost)
        entry.premiumFrequency = insurance.premiumFrequency
        entry.details = assessmentInsuranceDetails(from: insurance)
        return entry
    }

    private static func assessmentInvestmentType(from type: AstraInvestmentType) -> AssessmentInvestmentEntry.InvestmentType {
        switch type {
        case .mutualFund: return .mutualFund
        case .stocks: return .stocks
        case .goldETF, .physicalGold: return .gold
        case .cryptocurrency: return .crypto
        case .deposits, .bonds, .cashSavings, .emergencyFund, .other: return .bonds
        case .ppf: return .ppf
        case .nps: return .nps
        case .realEstate: return .realEstate
        }
    }

    private static func assessmentLoanType(from type: AstraLoanType) -> AssessmentLoanEntry.LoanType {
        switch type {
        case .homeLoan: return .homeLoan
        case .educationLoan: return .educationLoan
        case .carLoan: return .carLoan
        case .businessLoan: return .businessLoan
        case .personalLoan, .other: return .personalLoan
        case .creditCard: return .creditCard
        }
    }

    private static func assessmentInsuranceDetails(from insurance: AstraInsurance) -> AssessmentInsuranceEntry.InsuranceDetails {
        switch insurance.insuranceType {
        case .health:
            var details = AssessmentInsuranceEntry.HealthDetails()
            details.planType = insurance.healthDetails?.planType ?? details.planType
            details.roomRentLimit = numberString(insurance.healthDetails?.roomRentLimit ?? 0)
            details.daycareProcedures = insurance.healthDetails?.daycareProcedures ?? true
            details.networkHospitalsCount = numberString(Double(insurance.healthDetails?.networkHospitalsCount ?? 0))
            return .health(details)
        case .motor:
            var details = AssessmentInsuranceEntry.MotorDetails()
            details.vehicleModel = insurance.motorDetails?.vehicleModel ?? ""
            details.idv = numberString(insurance.motorDetails?.idv ?? 0)
            details.zeroDep = insurance.motorDetails?.zeroDep ?? false
            details.roadsideAssistance = insurance.motorDetails?.roadsideAssistance ?? false
            return .motor(details)
        case .termLifeInsurance:
            var details = AssessmentInsuranceEntry.TermDetails()
            details.nomineeName = insurance.lifeDetails?.nomineeName ?? ""
            details.deathBenefit = numberString(insurance.lifeDetails?.deathBenefit ?? insurance.sumAssured)
            return .term(details)
        case .criticalIllness:
            return .criticalIllness(AssessmentInsuranceEntry.CriticalIllnessDetails())
        case .travel:
            return .travel(AssessmentInsuranceEntry.TravelDetails())
        case .ulip:
            var details = AssessmentInsuranceEntry.ULIPDetails()
            details.nomineeName = insurance.lifeDetails?.nomineeName ?? ""
            details.surrenderValue = numberString(insurance.surrenderValue ?? 0)
            details.expectedMaturityAmount = numberString(insurance.expectedMaturityAmount ?? 0)
            return .ulip(details)
        case .life, .other:
            var details = AssessmentInsuranceEntry.LifeDetails()
            details.nomineeName = insurance.lifeDetails?.nomineeName ?? ""
            details.maturityBenefit = numberString(insurance.lifeDetails?.maturityBenefit ?? 0)
            details.deathBenefit = numberString(insurance.lifeDetails?.deathBenefit ?? insurance.sumAssured)
            details.lifeInsuranceType = insurance.lifeDetails?.lifeInsuranceType ?? details.lifeInsuranceType
            return .life(details)
        }
    }

    private static func numberString(_ value: Double) -> String {
        guard value.isFinite, value > 0 else { return "" }
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(format: "%.2f", value)
    }
}
