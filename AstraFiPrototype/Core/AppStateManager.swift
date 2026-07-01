import SwiftUI
import Supabase
import AuthenticationServices
import CryptoKit

@Observable @MainActor
final class AppStateManager {
    
    // MARK: - Financial Constants
    static let defaultTaxRate: Double = 0.0
    
    var isSyncing = false
    
    var isLoading: Bool = true
    var isAssessmentSkipped: Bool = false
    var isLockedByBiometric: Bool = false
    
    struct PendingGuestAssessment {
        let data: CompleteAssessmentData
        let score: Int
        let status: String
        let insights: [String]
        let assessmentInsights: FinancialAssessmentInsights
    }
    
    var isGuest: Bool = false
    var pendingGuestAssessment: PendingGuestAssessment?
    
    static func withSampleData() -> AppStateManager {
        let mgr = AppStateManager()
        let cal = Calendar.current
        func monthsAgo(_ n: Int) -> Date {
            cal.date(byAdding: .month, value: -n, to: Date()) ?? Date()
        }
        func yearsFromNow(_ n: Int) -> Date {
            cal.date(byAdding: .year, value: n, to: Date()) ?? Date()
        }
        
        let goalHome = AstraGoal(goalName: "Home Purchase", targetAmount: 7200000, currentAmount: 5500000, targetDate: yearsFromNow(3))
        let goalCar  = AstraGoal(goalName: "Car",       targetAmount: 2200000, currentAmount: 1800000, targetDate: yearsFromNow(1))
        let goalEdu  = AstraGoal(goalName: "Education", targetAmount: 1200000, currentAmount: 400000,  targetDate: yearsFromNow(6))
        
        mgr.currentProfile = AstraUserProfile(
            signUp: AstraSignUp(signUpName: "Akash Kashyap", email: "akash@example.com", password: ""),
            basicDetails: AstraBasicDetails(
                name: "Akash", age: 30, gender: .male, maritalStatus: .single,
                adultDependents: 1, childDependents: 1,
                incomeType: .fixed,
                monthlyIncome: 120000, monthlyIncomeAfterTax: 95000,
                monthlyExpenses: 55000, emergencyFundAmount: 300000,
                activeInvestment: true,
                riskTolerance: .high,
                investmentHorizon: .longTerm
            ),
            assets: AstraAssets(
                savingsAccountAmount: 250000,
                stocksHoldingAmount: 480000,
                mutualFundHoldingAmount: 800000,
                otherInvestmentAmount: 0,
                propertyAmount: 8500000,
                vehiclesAmount: 900000,
                depositsAmount: 200000,
                jewelleryAmount: 0
            ),
            liabilities: AstraLiabilities(
                homeLoanAmount: 7500000,
                vehicleLoanAmount: 900000,
                creditCardBills: 0,
                educationLoanAmount: 500000,
                otherLoanAmount: 0,
                otherDebtAmount: 0
            ),
            investments: [
                AstraInvestment(investmentType: .mutualFund, subtype: .equityFund,
                                investmentName: "Axis Bluechip MF", investmentAmount: 34000,
                                startDate: Date(), associatedGoalID: goalHome.id, mode: .sip,
                                schemeCode: "120465", units: 500.0, purchaseNAV: 60.0),
                AstraInvestment(investmentType: .stocks, subtype: .smallCap,
                                investmentName: "Parang TVF", investmentAmount: 24000,
                                startDate: Date(), associatedGoalID: goalHome.id, mode: .lumpsum),
                AstraInvestment(investmentType: .mutualFund, subtype: .debtFund,
                                investmentName: "ICICI Prudential MF", investmentAmount: 480000,
                                startDate: monthsAgo(12), associatedGoalID: goalCar.id, mode: .sip,
                                schemeCode: "105703", units: 4500.0, purchaseNAV: 10.0),
                AstraInvestment(investmentType: .stocks, subtype: .largeCap,
                                investmentName: "Reliance Industries", investmentAmount: 180000,
                                startDate: monthsAgo(24), mode: .lumpsum),
                AstraInvestment(investmentType: .goldETF,
                                investmentName: "SBI Gold ETF", investmentAmount: 75000,
                                startDate: monthsAgo(6), mode: .lumpsum),
                AstraInvestment(investmentType: .deposits,
                                investmentName: "HDFC Fixed Deposit", investmentAmount: 200000,
                                startDate: monthsAgo(8), mode: .lumpsum),
            ],
            loans: [
                AstraLoan(loanType: .homeLoan, lender: .hdfcBank,
                          loanAmount: 7500000, interestRate: 8.5,
                          loanStartDate: monthsAgo(5), loanTenureMonths: 180),
                AstraLoan(loanType: .carLoan, lender: .iciciBank,
                          loanAmount: 900000, interestRate: 9.2,
                          loanStartDate: monthsAgo(22), loanTenureMonths: 60),
                AstraLoan(loanType: .educationLoan, lender: .stateBankOfIndia,
                          loanAmount: 500000, interestRate: 7.0,
                          loanStartDate: monthsAgo(12), loanTenureMonths: 84)
            ],
            insurances: [
                AstraInsurance(insuranceType: .health, provider: "Star Health",
                               policyNumber: "SH-2024-00123", sumAssured: 500000,
                               annualPremium: 12000, startDate: monthsAgo(24),
                               expiryDate: yearsFromNow(1),
                               healthDetails: AstraHealthInsuranceDetails(planType: "Family Floater", roomRentLimit: 5000, daycareProcedures: true),
                               claims: [AstraClaim(date: monthsAgo(6), amount: 15000, status: .approved, description: "Fever hospitalization")]),
                AstraInsurance(insuranceType: .termLifeInsurance, provider: "HDFC Life",
                               policyNumber: "HDFC-TL-98765", sumAssured: 10000000,
                               annualPremium: 18500, startDate: monthsAgo(36),
                               expiryDate: yearsFromNow(15),
                               lifeDetails: AstraLifeInsuranceDetails(nomineeName: "Anjali Kashyap", maturityBenefit: 0, deathBenefit: 10000000, lifeInsuranceType: "Term")),
                AstraInsurance(insuranceType: .motor, provider: "Bajaj Allianz",
                               policyNumber: "BA-CAR-55432", sumAssured: 500000,
                               annualPremium: 9000, startDate: monthsAgo(12),
                               expiryDate: monthsAgo(-1),
                               motorDetails: AstraMotorInsuranceDetails(vehicleModel: "Honda City", idv: 450000, zeroDep: true, roadsideAssistance: true))
            ],
            goals: [goalHome, goalCar, goalEdu],
            financialHealthReport: AstraFinancialHealthReport(
                netWorth: 2030000, savingsRate: 42, debtToIncomeRatio: 0.35,
                investmentScore: 72, emergencyFundMonths: 5.5
            ),
            cashflowData: CashflowEntry(rent: 20000, groceries: 8000, utilities: 4000, dining: 6000, transport: 5000, shopping: 7000, entertainment: 3000, misc: 2000),
            monthlyHealthAssessments: [],
            isSetuConnected: false
        )
        return mgr
    }
    
    func setupEmptyProfile(name: String = "User", email: String = "") {
        let signUp = AstraSignUp(signUpName: name, email: email, password: "")
        
        let basic = AstraBasicDetails(
            name: name, age: 0, gender: .male, maritalStatus: .single,
            adultDependents: 0, childDependents: 0,
            incomeType: .fixed,
            monthlyIncome: 0, monthlyIncomeAfterTax: 0,
            monthlyExpenses: 0, emergencyFundAmount: 0,
            activeInvestment: false,
            riskTolerance: .low, investmentHorizon: .shortTerm
        )
        
        let assets = AstraAssets(
            savingsAccountAmount: 0, stocksHoldingAmount: 0,
            mutualFundHoldingAmount: 0, otherInvestmentAmount: 0,
            propertyAmount: 0, vehiclesAmount: 0,
            depositsAmount: 0, jewelleryAmount: 0
        )
        
        let liabilities = AstraLiabilities(
            homeLoanAmount: 0, vehicleLoanAmount: 0,
            creditCardBills: 0, educationLoanAmount: 0,
            otherLoanAmount: 0, otherDebtAmount: 0
        )
        
        let report = AstraFinancialHealthReport(
            netWorth: 0, savingsRate: 0, debtToIncomeRatio: 0,
            investmentScore: 0, emergencyFundMonths: 0
        )
        
        self.currentProfile = AstraUserProfile(
            signUp: signUp,
            basicDetails: basic,
            assets: assets,
            liabilities: liabilities,
            investments: [],
            loans: [],
            insurances: [],
            goals: [],
            financialHealthReport: report,
            cashflowData: nil,
            monthlyHealthAssessments: [],
            isSetuConnected: false
        )
    }
    
    var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    var isAuthenticated: Bool = false
    var authError: String? = nil
    var isAuthLoading: Bool = false
    
    var showDashboard: Bool = false
    var selectedTab: Int = 0
    var showPostAuthOnboarding: Bool = false
    
    var requiresMFAChallenge: Bool = false
    var mfaFactorId: String? = nil
    
    var tempName: String = ""
    var currentNonce: String?
    
    // Apple sign-in is managed by a small delegate object to bridge with ASAuthorizationControllerDelegate.
    class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        let onResult: (Result<ASAuthorization, Error>) -> Void
        init(onResult: @escaping (Result<ASAuthorization, Error>) -> Void) {
            self.onResult = onResult
        }
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            onResult(.success(authorization))
        }
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            onResult(.failure(error))
        }
        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
        }
    }
    
    /// Stored reference to the delegate so it isn't deallocated.
    var appleSignInDelegate: AppleSignInDelegate?
    
    var tempEmail: String = ""
    var tempPassword: String = ""
    var forgotPasswordEmail: String = ""
    
    var currentProfile: AstraUserProfile?
    var savedPlans: [InvestmentPlanModel] = []
    
    
    
    
    
    
    
    init() {
        Task {
            await restoreSession()
        }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // wait 2 seconds
            await syncMutualFundNAVs()
        }
    }
    
    
    
    
    
    // MARK: - Sign in with Apple
    
    /// A random nonce used to verify the Apple ID token.
    
    /// Generates a cryptographically-secure random nonce string.
    
    /// Returns the SHA256 hash of the input string.
    
    /// Initiates the Sign in with Apple flow.
    
    /// Handles the result from Apple Sign-In and authenticates with Supabase.
    
    
    // MARK: - Password Recovery
    
    
    
    
    var mfService = MFService.shared
    
    
        
        
        
        
        
        // MARK: - Derived profile attributes from assessment data
        
        /// Derives risk tolerance from savings behaviour and investment activity.
        /// No hardcoded "medium" default — inferred from real data.
        
        /// Derives investment horizon from age and number of dependents.
        /// Younger users with few dependents → long-term; older or more dependents → shorter.
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        func investments(for goalID: UUID) -> [AstraInvestment] {
            currentProfile?.investments.filter { $0.associatedGoalID == goalID } ?? []
        }
        
        func totalCollected(for goalID: UUID) -> Double {
            guard let goal = currentProfile?.goals.first(where: { $0.id == goalID }) else { return 0 }
            let linked = investments(for: goalID)
            let linkedTotal = linked.reduce(0.0) { $0 + $1.currentValue }
            return linkedTotal + goal.manualSavingsContribution
        }
        
}
