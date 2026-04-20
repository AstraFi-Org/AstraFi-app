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
