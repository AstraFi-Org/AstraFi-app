import SwiftUI
import Observation

@Observable
final class CompleteAssessmentData {

    var name = ""
    var email = ""
    var password = ""
    var age = ""
    var gender: Gender = .male
    var adultDependents = 1
    var childDependents = 0
    var incomeType: IncomeType = .fixed
    var income = ""
    var incomeAfterTax = ""
    var isSetuSelected = false

    var minMonthlyIncome = ""
    var maxMonthlyIncome = ""
    var taxPercentage = ""

    var expenditure = ""
    var hasEmergencyFund = false
    var emergencyFundAmount = ""

    var investmentEntries: [AssessmentInvestmentEntry] = []
    var loanEntries: [AssessmentLoanEntry] = []
    var insuranceEntries: [AssessmentInsuranceEntry] = []

    enum Gender: String, Codable { case male, female }
    enum IncomeType: String, Codable { case fixed, variable }
}
