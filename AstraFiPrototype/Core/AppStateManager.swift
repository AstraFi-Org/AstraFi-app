import SwiftUI
import Supabase
import AuthenticationServices
import CryptoKit

@Observable @MainActor
final class AppStateManager {

    // MARK: - Financial Constants
    static let defaultTaxRate: Double = 0.0

    private var isSyncing = false
    
    var isLoading: Bool = true
    var isAssessmentSkipped: Bool = false
    var isLockedByBiometric: Bool = false
    
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
    
    func setupEmptyProfile(name: String = "User") {
        let signUp = AstraSignUp(signUpName: name, email: "", password: "")
        
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
    var tempEmail: String = ""
    var tempPassword: String = ""
    var forgotPasswordEmail: String = ""
    
    var currentProfile: AstraUserProfile?
    var savedPlans: [InvestmentPlanModel] = []
    
    func savePlan(_ plan: InvestmentPlanModel) {
        savedPlans.append(plan)
        Task {
            if let session = try? await supabase.auth.session {
                _ = try? await SupabaseRepository.shared.savePlan(plan, userId: session.user.id)
            }
        }
    }
    
    func followPlan(_ plan: InvestmentPlanModel) {
        if let index = savedPlans.firstIndex(where: { $0.id == plan.id }) {
            savedPlans[index].isFollowed = true
            Task {
                if (try? await supabase.auth.session) != nil {
                    _ = try? await SupabaseRepository.shared.updatePlanFollowStatus(
                        planId: plan.id, isFollowed: true
                    )
                }
            }
        }
    }

    func unfollowPlan(_ plan: InvestmentPlanModel) {
        if let index = savedPlans.firstIndex(where: { $0.id == plan.id }) {
            savedPlans[index].isFollowed = false
            Task {
                if (try? await supabase.auth.session) != nil {
                    _ = try? await SupabaseRepository.shared.updatePlanFollowStatus(
                        planId: plan.id, isFollowed: false
                    )
                }
            }
        }
    }
    
    func saveAssessmentToHistory(score: Int, status: String, insights: [String], assessmentInsights: FinancialAssessmentInsights? = nil) {
        if var profile = currentProfile {
            let newAssessment = AstraHealthAssessment(
                date: Date(),
                score: score,
                status: status,
                keyInsights: insights,
                insights: assessmentInsights
            )
            let cal = Calendar.current
            if let index = profile.monthlyHealthAssessments.firstIndex(where: {
                cal.isDate($0.date, equalTo: Date(), toGranularity: .month) &&
                cal.isDate($0.date, equalTo: Date(), toGranularity: .year)
            }) {
                profile.monthlyHealthAssessments[index] = newAssessment
            } else {
                profile.monthlyHealthAssessments.append(newAssessment)
            }
            currentProfile = profile
            Task {
                if let session = try? await supabase.auth.session {
                    _ = try? await SupabaseRepository.shared.saveHealthAssessment(newAssessment, userId: session.user.id)
                }
            }
        }
    }
    
    init() {
        Task {
            await restoreSession()
        }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // wait 2 seconds
            await syncMutualFundNAVs()
        }
    }

    func restoreSession() async {
        await MainActor.run { isLoading = true }
        async let minimumDelay: () = Task.sleep(nanoseconds: 1_500_000_000)
        do {
            let session = try await supabase.auth.session

            if let profile = try? await SupabaseRepository.shared.fetchFullProfile(userId: session.user.id) {
                if let plans = try? await SupabaseRepository.shared.fetchSavedPlans(userId: session.user.id) {
                    await MainActor.run {
                        self.savedPlans = plans
                    }
                }
                try? await minimumDelay
                
                // Check if biometric lock should be shown
                // Note: requireUnlockOnLaunch defaults to true in @AppStorage,
                // so we must use the same default here since the key may never
                // have been explicitly written to UserDefaults.
                let biometricEnabled = UserDefaults.standard.bool(forKey: "securityBiometricUnlockEnabled")
                let requireOnLaunch = UserDefaults.standard.object(forKey: "securityRequireUnlockOnLaunch") as? Bool ?? true
                
                let aal = try? await supabase.auth.mfa.getAuthenticatorAssuranceLevel()
                if aal?.nextLevel == "aal2" && aal?.currentLevel == "aal1" {
                    if let factors = try? await supabase.auth.mfa.listFactors(), let factor = factors.all.first(where: { $0.status == FactorStatus.verified }) {
                        await MainActor.run {
                            self.mfaFactorId = factor.id
                            self.requiresMFAChallenge = true
                            self.currentProfile = profile
                            self.isAuthenticated = true
                            self.hasCompletedOnboarding = true
                            self.showDashboard = true
                            self.isLoading = false
                            
                            if biometricEnabled && requireOnLaunch {
                                self.isLockedByBiometric = true
                            }
                        }
                        recalculateFinancials()
                        return
                    }
                }
                
                await MainActor.run {
                    self.currentProfile = profile
                    self.isAuthenticated = true
                    self.hasCompletedOnboarding = true
                    self.showDashboard = true
                    self.isLoading = false
                    
                    if biometricEnabled && requireOnLaunch {
                        self.isLockedByBiometric = true
                    }
                }
                recalculateFinancials()
            } else {
                try? await supabase.auth.signOut(scope: .local)
                try? await minimumDelay
                await MainActor.run {
                    self.hasCompletedOnboarding = false
                    self.isLoading = false
                    
                }
            }

        } catch {
            try? await minimumDelay
            await MainActor.run {
                self.hasCompletedOnboarding = false
                isLoading = false
            }
        }
    }
    
    func unlockApp() {
        isLockedByBiometric = false
    }

    func signUp(name: String, email: String, password: String) async -> Bool {
        isAuthLoading = true
        authError = nil
        do {
            let session = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            try? await supabase.from("users").insert([
                "id": session.user.id.uuidString,
                "email": email
            ]).execute()
            
            tempName = name
            tempEmail = email
            tempPassword = password
            setupEmptyProfile(name: name)
            
            // After successful sign up — load existing data if any
            if let profile = try? await SupabaseRepository.shared.fetchFullProfile(userId: session.user.id) {
                self.currentProfile = profile
                recalculateFinancials()
            }
            
            isAuthLoading = false
            return true
            
        } catch {
            authError = error.localizedDescription
            isAuthLoading = false
            return false
        }
    }
    
    func completeSignUp() {
        isAuthenticated = true
        showPostAuthOnboarding = true
        hasCompletedOnboarding = true
    }
    
    // MARK: - Sign in with Apple
    
    /// A random nonce used to verify the Apple ID token.
    private var currentNonce: String?
    
    /// Generates a cryptographically-secure random nonce string.
    private static func randomNonce(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        guard errorCode == errSecSuccess else {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }
    
    /// Returns the SHA256 hash of the input string.
    private static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Initiates the Sign in with Apple flow.
    func signInWithApple() {
        let nonce = Self.randomNonce()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
        
        let delegate = AppleSignInDelegate { result in
            Task { @MainActor in
                await self.handleAppleSignInResult(result)
            }
        }
        // Retain the delegate for the duration of the request
        self.appleSignInDelegate = delegate
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = delegate
        controller.presentationContextProvider = delegate
        controller.performRequests()
    }
    
    /// Stored reference to the delegate so it isn't deallocated.
    private var appleSignInDelegate: AppleSignInDelegate?
    
    /// Handles the result from Apple Sign-In and authenticates with Supabase.
    private func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) async {
        isAuthLoading = true
        authError = nil
        
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = appleIDCredential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8),
                  let nonce = currentNonce else {
                authError = "Failed to get Apple ID credentials."
                isAuthLoading = false
                return
            }
            
            do {
                let session = try await supabase.auth.signInWithIdToken(
                    credentials: .init(
                        provider: .apple,
                        idToken: identityToken,
                        nonce: nonce
                    )
                )
                
                // Try to insert user record (will silently fail if already exists)
                try? await supabase.from("users").insert([
                    "id": session.user.id.uuidString,
                    "email": session.user.email ?? ""
                ]).execute()
                
                // Load existing profile or create new one
                if let profile = try? await SupabaseRepository.shared.fetchFullProfile(userId: session.user.id) {
                    self.currentProfile = profile
                    recalculateFinancials()
                    isAuthenticated = true
                    showPostAuthOnboarding = false
                    hasCompletedOnboarding = true
                    showDashboard = true
                } else {
                    // Build display name from Apple credential if available
                    let fullName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                        .compactMap { $0 }
                        .joined(separator: " ")
                    let displayName = fullName.isEmpty ? (session.user.email ?? "User") : fullName
                    
                    setupEmptyProfile(name: displayName)
                    isAuthenticated = true
                    showPostAuthOnboarding = true
                    hasCompletedOnboarding = true
                }
                
                if let plans = try? await SupabaseRepository.shared.fetchSavedPlans(userId: session.user.id) {
                    self.savedPlans = plans
                }
                
            } catch {
                authError = error.localizedDescription
            }
            
        case .failure(let error):
            // User cancelled — don't show an error
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                // Do nothing
            } else {
                authError = error.localizedDescription
            }
        }
        
        isAuthLoading = false
        appleSignInDelegate = nil
        currentNonce = nil
    }

    func signIn(email: String, password: String) async {
        isAuthLoading = true
        authError = nil
        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            let aal = try? await supabase.auth.mfa.getAuthenticatorAssuranceLevel()
            if aal?.nextLevel == "aal2" && aal?.currentLevel == "aal1" {
                if let factors = try? await supabase.auth.mfa.listFactors(), let factor = factors.all.first(where: { $0.status == FactorStatus.verified }) {
                    await MainActor.run {
                        self.mfaFactorId = factor.id
                        self.requiresMFAChallenge = true
                        self.isAuthLoading = false
                    }
                    return
                }
            }
            
            if let profile = try? await SupabaseRepository.shared.fetchFullProfile(userId: session.user.id) {
                
                self.currentProfile = profile
                recalculateFinancials()
                isAuthenticated = true
                showPostAuthOnboarding = false
                hasCompletedOnboarding = true
                showDashboard = true
            } else {
               
                setupEmptyProfile(name: session.user.email ?? "User")
                isAuthenticated = true
                showPostAuthOnboarding = true
                hasCompletedOnboarding = true
            }
            
            if let plans = try? await SupabaseRepository.shared.fetchSavedPlans(userId: session.user.id) {
                self.savedPlans = plans
            }
            
        } catch {
            authError = error.localizedDescription
        }
        isAuthLoading = false
    }
    
    func completeMFA(code: String) async -> Bool {
        guard let factorId = mfaFactorId else { return false }
        isAuthLoading = true
        authError = nil
        do {
            let challenge = try await supabase.auth.mfa.challenge(params: MFAChallengeParams(factorId: factorId))
            _ = try await supabase.auth.mfa.verify(params: MFAVerifyParams(factorId: factorId, challengeId: challenge.id, code: code))
            
            let session = try await supabase.auth.session
            if let profile = try? await SupabaseRepository.shared.fetchFullProfile(userId: session.user.id) {
                self.currentProfile = profile
                recalculateFinancials()
                isAuthenticated = true
                showPostAuthOnboarding = false
                hasCompletedOnboarding = true
                showDashboard = true
            } else {
                setupEmptyProfile(name: session.user.email ?? "User")
                isAuthenticated = true
                showPostAuthOnboarding = true
                hasCompletedOnboarding = true
            }
            requiresMFAChallenge = false
            mfaFactorId = nil
            isAuthLoading = false
            return true
        } catch {
            authError = error.localizedDescription
            isAuthLoading = false
            return false
        }
    }
    // MARK: - Password Recovery
    func sendPasswordResetOTP(email: String) async -> Bool {
        isAuthLoading = true
        authError = nil
        do {
            try await supabase.auth.resetPasswordForEmail(email)
            forgotPasswordEmail = email
            isAuthLoading = false
            return true
        } catch {
            authError = error.localizedDescription
            isAuthLoading = false
            return false
        }
    }
    
    func verifyPasswordResetOTP(otp: String) async -> Bool {
        isAuthLoading = true
        authError = nil
        do {
            _ = try await supabase.auth.verifyOTP(email: forgotPasswordEmail, token: otp, type: .recovery)
            isAuthLoading = false
            return true
        } catch {
            authError = error.localizedDescription
            isAuthLoading = false
            return false
        }
    }
    
    func updatePassword(newPassword: String) async -> Bool {
        isAuthLoading = true
        authError = nil
        do {
            _ = try await supabase.auth.update(user: UserAttributes(password: newPassword))
            
            let session = try await supabase.auth.session
            if let profile = try? await SupabaseRepository.shared.fetchFullProfile(userId: session.user.id) {
                self.currentProfile = profile
                recalculateFinancials()
                isAuthenticated = true
                showPostAuthOnboarding = false
                hasCompletedOnboarding = true
                showDashboard = true
            } else {
                setupEmptyProfile(name: session.user.email ?? "User")
                isAuthenticated = true
                showPostAuthOnboarding = true
                hasCompletedOnboarding = true
            }
            isAuthLoading = false
            return true
        } catch {
            authError = error.localizedDescription
            isAuthLoading = false
            return false
        }
    }

    func signOut() async {
        do {
            try await supabase.auth.signOut(scope: .local)
            isAuthenticated = false
            
            hasCompletedOnboarding = false
            showDashboard = false
            showPostAuthOnboarding = false
            currentProfile = nil
            savedPlans = []
        } catch {
            authError = error.localizedDescription
        }
    }
    
    var mfService = MFService.shared
    
    func updateProfile(from assessmentData: CompleteAssessmentData) {
        let signUp = AstraSignUp(
            signUpName: assessmentData.name,
            email: assessmentData.email.isEmpty ? "user@example.com" : assessmentData.email,
            password: assessmentData.password
        )
        
        let rawIncome = Double(assessmentData.income) ?? 0
        let incomeValue = rawIncome.isFinite ? rawIncome : 0
        let incomeAfterTaxValue = incomeValue // Removed 20% default tax estimate
        
        let rawExpenses = Double(assessmentData.expenditure) ?? 0
        let expensesValue = rawExpenses.isFinite ? rawExpenses : 0
        
        let rawEmergency = Double(assessmentData.emergencyFundAmount) ?? 0
        let emergencyValue = rawEmergency.isFinite ? rawEmergency : 0
        
        let basic = AstraBasicDetails(
            name: assessmentData.name,
            age: Int(assessmentData.age.trimmingCharacters(in: .whitespaces)) ?? 0,
            gender: assessmentData.gender == .male ? .male : .female,
            maritalStatus: .single,
            adultDependents: self.currentProfile?.basicDetails.adultDependents ?? Int(assessmentData.numberOfDependents) ?? 1,
            childDependents: 0,
            incomeType: assessmentData.incomeType == .fixed ? .fixed : .variable,
            monthlyIncome: incomeValue,
            monthlyIncomeAfterTax: incomeValue, // Removed 20% default tax estimate
            monthlyExpenses: expensesValue,
            emergencyFundAmount: emergencyValue,
            activeInvestment: !assessmentData.investmentEntries.isEmpty,
            riskTolerance: Self.deriveRiskTolerance(
                savingsRate: incomeAfterTaxValue > 0 ? (incomeAfterTaxValue - expensesValue) / incomeAfterTaxValue : 0,
                investmentCount: assessmentData.investmentEntries.count
            ),
            investmentHorizon: Self.deriveInvestmentHorizon(
                age: Int(assessmentData.age.trimmingCharacters(in: .whitespaces)) ?? 30,
                dependents: Int(assessmentData.numberOfDependents) ?? 0
            )
        )
        
        let profileInvestments = assessmentData.investmentEntries.map { entry in
            let rawAmt = Double(entry.amount) ?? 0
            var inv = AstraInvestment(
                investmentType: mapInvestmentType(entry.type),
                investmentName: entry.fundName,
                investmentAmount: rawAmt.isFinite ? rawAmt : 0,
                startDate: entry.startDate,
                mode: entry.mode == .sip ? .sip : .lumpsum,
                schemeCode: entry.schemeCode,
                isin: entry.isin,
                symbol: entry.symbol,
                quantity: Double(entry.quantity),
                livePrice: entry.livePrice
            )
            
            // Map transaction history
            inv.installments = entry.transactions.map { tx in
                AstraInvestmentTransaction(
                    id: tx.id,
                    date: tx.date,
                    type: tx.type.lowercased() == "sell" ? .sell : .buy,
                    amount: tx.amount,
                    nav: tx.nav,
                    units: tx.units
                )
            }
            return inv
        }
        
        let profileLoans = assessmentData.loanEntries.map { entry in
            let rawAmt  = Double(entry.amount)       ?? 0
            let rawRate = Double(entry.interestRate) ?? 0
            // The assessment field is labelled "Tenure (Months)" — store as-is.
            // Do NOT multiply by 12; that would turn 15 months into 180 months.
            let tenureMonths = Int(entry.tenure) ?? 0

            var loan = AstraLoan(
                loanType: mapLoanType(entry.type),
                lender: .other,
                loanAmount: rawAmt.isFinite  ? rawAmt  : 0,
                interestRate: rawRate.isFinite ? rawRate : 0,
                interestType: entry.interestType,
                compoundingFrequency: entry.frequency,
                loanStartDate: entry.startDate,
                loanTenureMonths: tenureMonths
            )
            // Preserve the custom name the user typed (e.g. "My Car Loan").
            // Falls back to loanType.rawValue in the UI via displayName.
            loan.loanName = entry.loanName.trimmingCharacters(in: .whitespacesAndNewlines)
            loan.insurancePremium = Double(entry.insurancePremium) ?? 0
            loan.moratoriumMonths = Int(entry.moratorium) ?? 0
            return loan
        }
        
        let profileInsurances = assessmentData.insuranceEntries.map { entry in
            var ins = AstraInsurance(
                insuranceType: mapInsuranceType(entry.currentType),
                provider: entry.insurer,
                policyNumber: entry.policyNumber,
                sumAssured: Double(entry.coverAmount) ?? 0,
                annualPremium: Double(entry.annualPremium) ?? 0,
                startDate: entry.startDate,
                expiryDate: entry.expiryDate
            )
            
            ins.basePremium = Double(entry.basePremium) ?? (ins.annualPremium * 0.8)
            ins.taxesGST = Double(entry.taxesGST) ?? (ins.annualPremium * 0.18)
            ins.premiumFrequency = entry.premiumFrequency
            
            switch entry.details {
            case .life(let d):
                ins.lifeDetails = AstraLifeInsuranceDetails(
                    nomineeName: d.nomineeName,
                    maturityBenefit: Double(d.maturityBenefit),
                    deathBenefit: Double(d.deathBenefit),
                    lifeInsuranceType: d.lifeInsuranceType
                )
            case .term(let d):
                ins.lifeDetails = AstraLifeInsuranceDetails(
                    nomineeName: d.nomineeName,
                    maturityBenefit: 0,
                    deathBenefit: Double(d.deathBenefit),
                    lifeInsuranceType: "Term"
                )
            case .ulip(let d):
                ins.lifeDetails = AstraLifeInsuranceDetails(
                    nomineeName: d.nomineeName,
                    maturityBenefit: 0,
                    deathBenefit: 0,
                    lifeInsuranceType: "ULIP"
                )
                ins.surrenderValue = Double(d.surrenderValue)
                ins.expectedMaturityAmount = Double(d.expectedMaturityAmount)
            case .health(let d):
                ins.healthDetails = AstraHealthInsuranceDetails(
                    planType: d.planType,
                    roomRentLimit: Double(d.roomRentLimit),
                    daycareProcedures: d.daycareProcedures,
                    networkHospitalsCount: Int(d.networkHospitalsCount)
                )
            case .criticalIllness(_):
                ins.healthDetails = AstraHealthInsuranceDetails(
                    planType: "N/A",
                    roomRentLimit: 0,
                    daycareProcedures: true,
                    networkHospitalsCount: 0
                )
                
            case .motor(let d):
                ins.motorDetails = AstraMotorInsuranceDetails(
                    vehicleModel: d.vehicleModel,
                    idv: Double(d.idv),
                    zeroDep: d.zeroDep,
                    roadsideAssistance: d.roadsideAssistance
                )
            case .travel(_):
                
                break
            }
            
            return ins
        }
        
        let assets = AstraAssets(
            stocksHoldingAmount: profileInvestments.filter { $0.investmentType == .stocks }.map { $0.investmentAmount }.reduce(0, +),
            mutualFundHoldingAmount: profileInvestments.filter { $0.investmentType == .mutualFund }.map { $0.investmentAmount }.reduce(0, +),
            otherInvestmentAmount: profileInvestments.filter { [.cryptocurrency, .other, .nps, .ppf, .bonds, .cashSavings, .emergencyFund].contains($0.investmentType) }.map { $0.investmentAmount }.reduce(0, +),
            propertyAmount: profileInvestments.filter { $0.investmentType == .realEstate }.map { $0.investmentAmount }.reduce(0, +),
            vehiclesAmount: 0,
            depositsAmount: profileInvestments.filter { $0.investmentType == .deposits }.map { $0.investmentAmount }.reduce(0, +),
            jewelleryAmount: profileInvestments.filter { $0.investmentType == .physicalGold }.map { $0.investmentAmount }.reduce(0, +)
        )
        
        let liabilities = AstraLiabilities(
            homeLoanAmount: profileLoans.filter { $0.loanType == .homeLoan }.map { $0.loanAmount }.reduce(0, +),
            vehicleLoanAmount: profileLoans.filter { $0.loanType == .carLoan }.map { $0.loanAmount }.reduce(0, +),
            creditCardBills: profileLoans.filter { $0.loanType == .other && $0.lender == .other }.map { $0.loanAmount }.reduce(0, +),
            educationLoanAmount: profileLoans.filter { $0.loanType == .educationLoan }.map { $0.loanAmount }.reduce(0, +),
            otherLoanAmount: profileLoans.filter { ![.homeLoan, .carLoan, .educationLoan].contains($0.loanType) }.map { $0.loanAmount }.reduce(0, +)
        )
        
        let totalAs = assets.totalAssets
        let totalLi = liabilities.totalLiabilities
        let netWorth = totalAs - totalLi
        
        let savingsRate = incomeAfterTaxValue > 0 ? (((incomeAfterTaxValue - expensesValue) / incomeAfterTaxValue) * 100).safeFinite : 0
        
        let totalEMIs = profileLoans.reduce(0.0) { $0 + $1.calculatedEMI }
        let dti = incomeValue > 0 ? (totalEMIs / incomeValue).safeFinite : 0
        
        let efMonths = expensesValue > 0 ? (emergencyValue / expensesValue).safeFinite : 0
        let investmentScore = min(100, max(0, (savingsRate * 0.5) + (efMonths * 10))).safeInt
        
        let report = AstraFinancialHealthReport(
            netWorth: netWorth,
            savingsRate: savingsRate,
            debtToIncomeRatio: dti,
            investmentScore: investmentScore,
            emergencyFundMonths: efMonths
        )
        
        let initialScore = 400 + report.investmentScore * 4
        let status = initialScore >= 750 ? "Excellent" : initialScore >= 650 ? "Good" : "Needs Work"
        let firstAssessment = AstraHealthAssessment(
            date: Date(),
            score: initialScore,
            status: status,
            keyInsights: ["First assessment generated from initial data",
                          "Emergency fund covers \(String(format: "%.1f", efMonths)) months",
                          "Savings rate stands at \(savingsRate.safeInt)%"]
        )
        
        let newInvestments = profileInvestments
        let newLoans = profileLoans
        let newInsurances = profileInsurances
        
        if var existingProfile = self.currentProfile {
            // MERGE LOGIC
            existingProfile.signUp.email = assessmentData.email.isEmpty
                    ? existingProfile.signUp.email : assessmentData.email
            
            // Merge Investments
            for newInv in newInvestments {
                if !existingProfile.investments.contains(where: {
                    $0.investmentName.lowercased() == newInv.investmentName.lowercased() &&
                    abs($0.investmentAmount - newInv.investmentAmount) < 1.0
                }) {
                    existingProfile.investments.append(newInv)
                }
            }
            
            // Merge Loans
            for newLoan in newLoans {
                if !existingProfile.loans.contains(where: {
                    abs($0.loanAmount - newLoan.loanAmount) < 1.0 &&
                    $0.loanType == newLoan.loanType
                }) {
                    existingProfile.loans.append(newLoan)
                }
            }
            
            // Merge Insurances
            for newIns in newInsurances {
                if !existingProfile.insurances.contains(where: {
                    $0.policyNumber == newIns.policyNumber ||
                    ($0.insuranceType == newIns.insuranceType && abs($0.sumAssured - newIns.sumAssured) < 1.0)
                }) {
                    existingProfile.insurances.append(newIns)
                }
            }
            
            // Update basic details only if assessment data is non-empty
            if !assessmentData.income.isEmpty {
                existingProfile.basicDetails.monthlyIncome = incomeValue
                existingProfile.basicDetails.monthlyIncomeAfterTax = incomeValue
            }
            if !assessmentData.expenditure.isEmpty {
                existingProfile.basicDetails.monthlyExpenses = expensesValue
            }
            if !assessmentData.emergencyFundAmount.isEmpty {
                existingProfile.basicDetails.emergencyFundAmount = emergencyValue
            }
            if !assessmentData.name.trimmingCharacters(in: .whitespaces).isEmpty {
                existingProfile.basicDetails.name = assessmentData.name
            }
            let parsedAge = Int(assessmentData.age.trimmingCharacters(in: .whitespaces)) ?? 0
            if parsedAge > 0 {
                existingProfile.basicDetails.age = parsedAge
            }
            existingProfile.basicDetails.gender = assessmentData.gender == .male ? .male : .female
            existingProfile.basicDetails.incomeType = assessmentData.incomeType == .fixed ? .fixed : .variable
            
            self.currentProfile = existingProfile
        } else {
            // NEW PROFILE
            self.currentProfile = AstraUserProfile(
                signUp: signUp,
                basicDetails: basic,
                assets: assets,
                liabilities: liabilities,
                investments: profileInvestments,
                loans: profileLoans,
                insurances: profileInsurances,
                goals: [],
                financialHealthReport: report,
                monthlyHealthAssessments: [firstAssessment],
                isSetuConnected: false
            )
        }
        
        recalculateFinancials() // Ensure all scores are updated with merged data
        
        Task {
            await syncMutualFundNAVs()
        }
        Task {
            if let session = try? await supabase.auth.session,
               let profile = currentProfile {
                do {
                    try await SupabaseRepository.shared.syncFullProfile(profile, userId: session.user.id)
                    print("Supabase sync successful for user: \(session.user.id)")
                } catch {
                    print("Supabase sync failed: \(error)")
                }
            }
        }
    }
    
    private func mapInvestmentType(_ type: AssessmentInvestmentEntry.InvestmentType) -> AstraInvestmentType {
        switch type {
        case .mutualFund: return .mutualFund
        case .stocks: return .stocks
        case .bonds: return .bonds
        case .realEstate: return .realEstate
        case .gold: return .physicalGold
        case .crypto: return .cryptocurrency
        case .ppf: return .ppf
        case .nps: return .nps
        }
    }
    
    private func mapLoanType(_ type: AssessmentLoanEntry.LoanType) -> AstraLoanType {
        switch type {
        case .homeLoan: return .homeLoan
        case .carLoan: return .carLoan
        case .educationLoan: return .educationLoan
        case .businessLoan: return .businessLoan
        case .personalLoan: return .personalLoan
        case .creditCard: return .other
        }
    }
    
    private func mapLender(_ name: String) -> AstraLoanLender {
        switch name {
        case "SBI": return .stateBankOfIndia
        case "HDFC Bank": return .hdfcBank
        case "ICICI Bank": return .iciciBank
        case "Axis Bank": return .axisBank
        case "Kotak Mahindra": return .kotakMahindra
        case "Other": return .other
        default: return .other
        }
    }
    
    private func mapInsuranceType(_ type: AssessmentInsuranceEntry.InsuranceType) -> AstraInsuranceType {
        switch type {
        case .health: return .health
        case .life: return .life
        case .criticalIllness: return .criticalIllness
        case .term: return .termLifeInsurance
        case .motor: return .motor
        case .travel: return .travel
        case .ulip: return .ulip
        }
    }
    
    // MARK: - Derived profile attributes from assessment data

    /// Derives risk tolerance from savings behaviour and investment activity.
    /// No hardcoded "medium" default — inferred from real data.
    private static func deriveRiskTolerance(savingsRate: Double, investmentCount: Int) -> AstraRiskTolerance {
        switch (savingsRate, investmentCount) {
        case (let s, let c) where s >= 0.35 && c >= 3: return .high
        case (let s, _)     where s >= 0.20:            return .medium
        default:                                         return .low
        }
    }

    /// Derives investment horizon from age and number of dependents.
    /// Younger users with few dependents → long-term; older or more dependents → shorter.
    private static func deriveInvestmentHorizon(age: Int, dependents: Int) -> AstraInvestmentHorizon {
        switch (age, dependents) {
        case (let a, _) where a < 35: return .longTerm
        case (let a, let d) where a < 50 && d <= 2: return .mediumTerm
        default: return .shortTerm
        }
    }

    func recalculateFinancials() {
        guard var profile = currentProfile else { return }
        
        var newAssets = profile.assets
        newAssets.stocksHoldingAmount = profile.investments.filter { $0.investmentType == .stocks }.map { $0.currentValue.safeFinite }.reduce(0, +)
        newAssets.mutualFundHoldingAmount = profile.investments.filter { $0.investmentType == .mutualFund }.map { $0.currentValue.safeFinite }.reduce(0, +)
        newAssets.depositsAmount = profile.investments.filter { $0.investmentType == .deposits }.map { $0.currentValue.safeFinite }.reduce(0, +)
        newAssets.propertyAmount = profile.investments.filter { $0.investmentType == .realEstate }.map { $0.currentValue.safeFinite }.reduce(0, +)
        newAssets.jewelleryAmount = profile.investments.filter { $0.investmentType == .physicalGold }.map { $0.currentValue.safeFinite }.reduce(0, +)
        newAssets.otherInvestmentAmount = profile.investments.filter { [.cryptocurrency, .other, .nps, .ppf, .bonds, .cashSavings, .emergencyFund].contains($0.investmentType) }.map { $0.currentValue.safeFinite }.reduce(0, +)
        profile.assets = newAssets
        
        var newLiabilities = profile.liabilities
        newLiabilities.homeLoanAmount = profile.loans.filter { $0.loanType == .homeLoan }.map { $0.loanAmount }.reduce(0, +)
        newLiabilities.vehicleLoanAmount = profile.loans.filter { $0.loanType == .carLoan }.map { $0.loanAmount }.reduce(0, +)
        newLiabilities.educationLoanAmount = profile.loans.filter { $0.loanType == .educationLoan }.map { $0.loanAmount }.reduce(0, +)
        newLiabilities.otherLoanAmount = profile.loans.filter { ![.homeLoan, .carLoan, .educationLoan].contains($0.loanType) }.map { $0.loanAmount }.reduce(0, +)
        profile.liabilities = newLiabilities
        
        let totalAs = profile.assets.totalAssets
        let totalLi = profile.liabilities.totalLiabilities
        let netWorth = totalAs - totalLi
        
        let incomeAfterTax = profile.basicDetails.monthlyIncomeAfterTax
        let expenses = profile.basicDetails.monthlyExpenses
        let savingsRate = incomeAfterTax > 0 ? (((incomeAfterTax - expenses) / incomeAfterTax) * 100).safeFinite : 0
        
        let totalEMIs = profile.loans.reduce(0.0) { $0 + $1.calculatedEMI }
        let dti = profile.basicDetails.monthlyIncome > 0 ? (totalEMIs / profile.basicDetails.monthlyIncome).safeFinite : 0
        
        let efTarget = profile.basicDetails.monthlyIncome * 6.0
        let efMonths = efTarget > 0 ? ((profile.basicDetails.emergencyFundAmount / efTarget) * 6.0).safeFinite : 0
        let investmentScore = min(100, max(0, (savingsRate * 0.5) + (efMonths * 10))).safeInt
        
        profile.financialHealthReport = AstraFinancialHealthReport(
            netWorth: netWorth,
            savingsRate: savingsRate,
            debtToIncomeRatio: dti,
            investmentScore: investmentScore,
            emergencyFundMonths: efMonths
        )
        
        // Sync goal currentAmount with dynamic total
        for i in 0..<profile.goals.count {
            let gid = profile.goals[i].id
            let linked = profile.investments.filter { $0.associatedGoalID == gid }
            let linkedTotal = linked.reduce(0.0) { $0 + $1.currentValue }
            profile.goals[i].currentAmount = linkedTotal + profile.goals[i].manualSavingsContribution
        }
        
        self.currentProfile = profile
    }
    
    func updateCashflow(_ cashflow: CashflowEntry) {
        if var profile = currentProfile {
            profile.cashflowData = cashflow
            
            // Sync totals with basic details
            profile.basicDetails.monthlyExpenses = cashflow.totalExpenses
            
            let detailedIncome = cashflow.totalIncome
            if detailedIncome > 0 {
                profile.basicDetails.monthlyIncome = detailedIncome
                profile.basicDetails.monthlyIncomeAfterTax = detailedIncome
            }
            
            currentProfile = profile
            recalculateFinancials()
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM"
            let monthKey = df.string(from: Date())
            Task {
                if let session = try? await supabase.auth.session {
                    do {
                        try await SupabaseRepository.shared.saveCashflowSnapshot(
                            cashflow,
                            monthKey: monthKey,
                            userId: session.user.id
                        )
                        print("Cashflow saved to Supabase")
                    } catch {
                        print("Cashflow save failed: \(error)")
                    }
                }
            }
        }
    }
    
    func addGoal(_ goal: AstraGoal) {
        if var profile = currentProfile {
            profile.goals.append(goal)
            currentProfile = profile
            recalculateFinancials()
            Task {
                if let session = try? await supabase.auth.session {
                    try? await SupabaseRepository.shared.saveGoal(goal, userId: session.user.id)
                }
            }
        }
    }
    
    func updateGoal(_ goal: AstraGoal) {
        if var profile = currentProfile,
           let index = profile.goals.firstIndex(where: { $0.id == goal.id }) {
            profile.goals[index] = goal
            currentProfile = profile
            recalculateFinancials()
            Task {
                if let session = try? await supabase.auth.session {
                    try? await SupabaseRepository.shared.saveGoal(goal, userId: session.user.id)
                }
            }
        }
    }
    
    func deleteGoal(at indexSet: IndexSet) {
        if var profile = currentProfile {
            let toDelete = indexSet.map { profile.goals[$0] }
            profile.goals.remove(atOffsets: indexSet)
            currentProfile = profile
            recalculateFinancials()
            Task {
                for goal in toDelete {
                    try? await SupabaseRepository.shared.deleteGoal(goal.id)
                }
            }
        }
    }
    
    func deleteGoal(_ goal: AstraGoal) {
        if var profile = currentProfile,
           let index = profile.goals.firstIndex(where: { $0.id == goal.id }) {
            profile.goals.remove(at: index)
            currentProfile = profile
            recalculateFinancials()
            Task {
                try? await SupabaseRepository.shared.deleteGoal(goal.id)
            }
        }
    }
    
    func addInvestment(_ investment: AstraInvestment) {
        if var profile = currentProfile {
            profile.investments.append(investment)
            currentProfile = profile
            recalculateFinancials()
            Task {
                await syncMutualFundNAVs()
                if let session = try? await supabase.auth.session {
                    try? await SupabaseRepository.shared.saveInvestment(investment, userId: session.user.id)
                }
            }
        }
    }
    
    func updateInvestment(_ investment: AstraInvestment) {
        if var profile = currentProfile,
           let index = profile.investments.firstIndex(where: { $0.id == investment.id }) {
            profile.investments[index] = investment
            currentProfile = profile
            recalculateFinancials()
            Task {
                await syncMutualFundNAVs(force: true)
                if let session = try? await supabase.auth.session {
                    try? await SupabaseRepository.shared.saveInvestment(investment, userId: session.user.id)
                }
            }
        }
    }

    func syncUpstoxHoldings(
        _ holdings: [UpstoxHolding],
        mutualFunds: [UpstoxMutualFundHolding] = [],
        mutualFundOrders: [UpstoxMutualFundOrder] = [],
        mutualFundSIPs: [UpstoxMutualFundSIP] = []
    ) {
        guard var profile = currentProfile else { return }

        let manualInvestments = profile.investments.filter { $0.brokerSource != "Upstox" }
        let existingUpstoxInvestments = Dictionary(
            profile.investments
                .filter { $0.brokerSource == "Upstox" }
                .compactMap { investment in
                    investment.brokerInstrumentID.map { ($0, investment) }
                },
            uniquingKeysWith: { first, _ in first }
        )
        let connectedStockInvestments = holdings
            .filter { $0.quantity > 0 }
            .map { holding in
                return AstraInvestment(
                    id: existingUpstoxInvestments[holding.id]?.id ?? UUID(),
                    investmentType: .stocks,
                    subtype: .largeCap,
                    investmentName: holding.displayName,
                    investmentAmount: holding.investedAmount.safeFinite,
                    startDate: existingUpstoxInvestments[holding.id]?.startDate ?? Date(),
                    mode: .lumpsum,
                    isin: holding.isin,
                    symbol: holding.tradingSymbol,
                    quantity: holding.quantity.safeFinite,
                    livePrice: holding.currentPrice.safeFinite,
                    priceChange: holding.dayChange.safeFinite,
                    priceChangePercentage: holding.dayChangePercentage.safeFinite,
                    brokerSource: "Upstox",
                    brokerInstrumentID: holding.id
                )
            }
        let connectedMutualFundInvestments = mutualFunds
            .filter { $0.quantity > 0 }
            .map { holding in
                let matchedOrders = mutualFundOrders
                    .filter { order in
                        order.isCompleted && mutualFundRecord(
                            instrumentKey: order.instrumentKey,
                            folio: order.folio,
                            matches: holding
                        )
                    }
                    .sorted { ($0.transactionDate ?? .distantPast) < ($1.transactionDate ?? .distantPast) }
                let matchedSIP = mutualFundSIPs.first { sip in
                    normalizedUpstoxKey(sip.instrumentKey) == normalizedUpstoxKey(holding.instrumentKey)
                }
                let isSIP = matchedSIP != nil || matchedOrders.contains(where: \.isSIP)
                let installments = matchedOrders.compactMap { order -> AstraInvestmentTransaction? in
                    guard let date = order.transactionDate else { return nil }
                    let nav = order.executedNAV.safeFinite
                    let amount = order.amount > 0 ? order.amount.safeFinite : (order.quantity * nav).safeFinite
                    return AstraInvestmentTransaction(
                        date: date,
                        type: order.transactionType?.uppercased() == "SELL" ? .sell : .buy,
                        amount: amount,
                        nav: nav,
                        units: order.quantity.safeFinite
                    )
                }
                let startDate = matchedSIP?.createdDate
                    ?? installments.first?.date
                    ?? existingUpstoxInvestments[holding.id]?.startDate
                    ?? Date()
                let recurringAmount = matchedSIP?.instalmentAmount
                    ?? matchedOrders.last(where: { $0.isSIP && $0.transactionType?.uppercased() == "BUY" })?.amount

                return AstraInvestment(
                    id: existingUpstoxInvestments[holding.id]?.id ?? UUID(),
                    investmentType: .mutualFund,
                    subtype: .equityFund,
                    investmentName: holding.displayName,
                    investmentAmount: (isSIP ? (recurringAmount ?? holding.investedAmount) : holding.investedAmount).safeFinite,
                    startDate: startDate,
                    mode: isSIP ? .sip : .lumpsum,
                    isin: holding.instrumentKey,
                    lastNAV: holding.lastPrice.safeFinite,
                    lastUpdated: Date(),
                    units: holding.quantity.safeFinite,
                    purchaseNAV: holding.averagePrice.safeFinite,
                    livePrice: holding.lastPrice.safeFinite,
                    priceChange: holding.pnl.safeFinite,
                    brokerSource: "Upstox",
                    brokerInstrumentID: holding.id,
                    installments: installments
                )
            }

        profile.investments = manualInvestments + connectedStockInvestments + connectedMutualFundInvestments
        currentProfile = profile
        recalculateFinancials()
    }

    private func normalizedUpstoxKey(_ value: String?) -> String {
        value?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased() ?? ""
    }

    private func mutualFundRecord(
        instrumentKey: String?,
        folio: String?,
        matches holding: UpstoxMutualFundHolding
    ) -> Bool {
        guard normalizedUpstoxKey(instrumentKey) == normalizedUpstoxKey(holding.instrumentKey) else {
            return false
        }

        let orderFolio = normalizedUpstoxKey(folio)
        let holdingFolio = normalizedUpstoxKey(holding.folio)
        return orderFolio.isEmpty || holdingFolio.isEmpty || orderFolio == holdingFolio
    }

    func removeUpstoxHoldings() {
        guard var profile = currentProfile else { return }
        profile.investments.removeAll { $0.brokerSource == "Upstox" }
        currentProfile = profile
        recalculateFinancials()
    }
    
    func deleteInvestment(at indexSet: IndexSet) {
        if var profile = currentProfile {
            let toDelete = indexSet.map { profile.investments[$0] }
            profile.investments.remove(atOffsets: indexSet)
            currentProfile = profile
            recalculateFinancials()
            Task {
                for inv in toDelete {
                    try? await SupabaseRepository.shared.deleteInvestment(inv.id)
                }
            }
        }
    }
    
    func deleteInvestment(_ investment: AstraInvestment) {
        if var profile = currentProfile,
           let index = profile.investments.firstIndex(where: { $0.id == investment.id }) {
            profile.investments.remove(at: index)
            currentProfile = profile
            recalculateFinancials()
            Task {
                try? await SupabaseRepository.shared.deleteInvestment(investment.id)
            }
        }
    }
    
    func updateEmergencyFundAllocation(_ allocation: AstraEmergencyFundAllocation) {
        if var profile = currentProfile {
            profile.emergencyFundAllocation = allocation
            currentProfile = profile
            Task {
                if let session = try? await supabase.auth.session {
                    try? await SupabaseRepository.shared.saveEmergencyFundAllocation(allocation, userId: session.user.id)
                }
            }
        }
    }
    func addLoan(_ loan: AstraLoan) {
        if var profile = currentProfile {
            profile.loans.append(loan)
            currentProfile = profile
            recalculateFinancials()
            Task {
                if let session = try? await supabase.auth.session {
                    try? await SupabaseRepository.shared.saveLoan(loan, userId: session.user.id)
                }
            }
        }
    }
    
    func updateLoan(_ loan: AstraLoan) {
        if var profile = currentProfile,
           let index = profile.loans.firstIndex(where: { $0.id == loan.id }) {
            profile.loans[index] = loan
            currentProfile = profile
            recalculateFinancials()
            Task {
                if let session = try? await supabase.auth.session {
                    try? await SupabaseRepository.shared.saveLoan(loan, userId: session.user.id)
                }
            }
        }
    }
    
    func deleteLoan(at indexSet: IndexSet) {
        if var profile = currentProfile {
            let toDelete = indexSet.map { profile.loans[$0] }
            profile.loans.remove(atOffsets: indexSet)
            currentProfile = profile
            recalculateFinancials()
            Task {
                for loan in toDelete {
                    try? await SupabaseRepository.shared.deleteLoan(loan.id)
                }
            }
        }
    }
    
    func deleteLoan(_ loan: AstraLoan) {
        if var profile = currentProfile,
           let index = profile.loans.firstIndex(where: { $0.id == loan.id }) {
            profile.loans.remove(at: index)
            currentProfile = profile
            recalculateFinancials()
            Task {
                try? await SupabaseRepository.shared.deleteLoan(loan.id)
            }
        }
    }
    
    
    func addInsurance(_ insurance: AstraInsurance) {
        if var profile = currentProfile {
            profile.insurances.append(insurance)
            currentProfile = profile
            recalculateFinancials()
            Task {
                if let session = try? await supabase.auth.session {
                    try? await SupabaseRepository.shared.saveInsurance(insurance, userId: session.user.id)
                }
            }
        }
    }
    
    func updateInsurance(_ insurance: AstraInsurance) {
        if var profile = currentProfile,
           let index = profile.insurances.firstIndex(where: { $0.id == insurance.id }) {
            profile.insurances[index] = insurance
            currentProfile = profile
            recalculateFinancials()
            Task {
                if let session = try? await supabase.auth.session {
                    try? await SupabaseRepository.shared.saveInsurance(insurance, userId: session.user.id)
                }
            }
        }
    }
    
    func deleteInsurance(at indexSet: IndexSet) {
        if var profile = currentProfile {
            let toDelete = indexSet.map { profile.insurances[$0] }
            profile.insurances.remove(atOffsets: indexSet)
            currentProfile = profile
            recalculateFinancials()
            Task {
                for ins in toDelete {
                    try? await SupabaseRepository.shared.deleteInsurance(ins.id)
                }
            }
        }
    }
    func investments(for goalID: UUID) -> [AstraInvestment] {
        currentProfile?.investments.filter { $0.associatedGoalID == goalID } ?? []
    }
    
    func totalCollected(for goalID: UUID) -> Double {
        guard let goal = currentProfile?.goals.first(where: { $0.id == goalID }) else { return 0 }
        let linked = investments(for: goalID)
        let linkedTotal = linked.reduce(0.0) { $0 + $1.currentValue }
        return linkedTotal + goal.manualSavingsContribution
    }
    
    func syncMutualFundNAVs(force: Bool = false) async {
        guard !isSyncing else { return }
        isSyncing = true
        
        defer { isSyncing = false }
        
        await mfService.fetchMFData(force: force)
        
        guard var profile = currentProfile else { return }
        var updated = false
        
        // Update Stock Prices
        let marketTypes: Set<AstraInvestmentType> = [.stocks, .goldETF, .cryptocurrency]
        let stockSymbols = profile.investments.compactMap { marketTypes.contains($0.investmentType) ? $0.symbol : nil }
        if !stockSymbols.isEmpty {
            let stockPrices = await StockService.shared.fetchLivePrices(symbols: stockSymbols)
            for i in 0..<profile.investments.count {
                if marketTypes.contains(profile.investments[i].investmentType),
                   let symbol = profile.investments[i].symbol,
                   let price = stockPrices[symbol] {
                    profile.investments[i].livePrice = price
                    profile.investments[i].lastNAV = price
                    profile.investments[i].lastUpdated = Date()
                    updated = true
                }
            }
        }
        
        for i in 0..<profile.investments.count {
            let inv = profile.investments[i]
            
            // 1. Update Market Price/NAV
            if inv.investmentType == .mutualFund {
                if inv.schemeCode == nil {
                    if let code = mfService.findSchemeCode(for: inv.investmentName) {
                        profile.investments[i].schemeCode = code
                    }
                }
                
                guard let code = profile.investments[i].schemeCode else { continue }
                
                if let liveScheme = mfService.getScheme(by: code) {
                    profile.investments[i].lastNAV = liveScheme.nav
                    profile.investments[i].lastUpdated = Date()
                    updated = true
                }
                
                let expectedCount: Int = {
                    let cal = Calendar.current
                    var count = 0
                    var d = inv.startDate
                    let today = Date()
                    while d <= today {
                        count += 1
                        guard let next = cal.date(byAdding: .month, value: 1, to: d) else { break }
                        d = next
                    }
                    return count
                }()
                let actualCount = profile.investments[i].installments.count
                let needsRecalc = profile.investments[i].installments.isEmpty || (inv.mode == .sip && actualCount < expectedCount)

                if needsRecalc {
                    if inv.mode == .sip {
                        let (sipUnits, _, simulatedInstallments) = await mfService.calculateHistoricalSIPUnits(
                            schemeCode: code,
                            monthlyAmount: inv.investmentAmount,
                            startDate: inv.startDate
                        )
                        profile.investments[i].installments = simulatedInstallments
                        profile.investments[i].units = sipUnits
                        // Recalculate weighted-average purchase NAV
                        let totalPaid = simulatedInstallments.reduce(0.0) { $0 + $1.amount }
                        let totalUnits2 = simulatedInstallments.reduce(0.0) { $0 + $1.units }
                        if totalUnits2 > 0 {
                            profile.investments[i].purchaseNAV = totalPaid / totalUnits2
                        }
                        updated = true
                    } else {
                        // Lumpsum
                        if let histNAV = await mfService.fetchHistoricalNAV(schemeCode: code, date: inv.startDate) {
                            let units = inv.investmentAmount / histNAV
                            profile.investments[i].installments = [
                                AstraInvestmentTransaction(date: inv.startDate, type: .buy, amount: inv.investmentAmount, nav: histNAV, units: units)
                            ]
                            profile.investments[i].units = units
                            profile.investments[i].purchaseNAV = histNAV
                            updated = true
                        }
                    }
                }
            } else if marketTypes.contains(inv.investmentType) {
                guard let symbol = inv.symbol else { continue }

                let expectedCount: Int = {
                    guard inv.mode == .sip else { return 1 }
                    let cal = Calendar.current
                    var count = 0
                    var d = inv.startDate
                    let today = Date()
                    while d <= today {
                        count += 1
                        guard let next = cal.date(byAdding: .month, value: 1, to: d) else { break }
                        d = next
                    }
                    return max(count, 1)
                }()
                let needsRecalc = profile.investments[i].installments.isEmpty || (inv.mode == .sip && profile.investments[i].installments.count < expectedCount)

                // Populate Missing Installments for Stocks, Gold ETFs, and Crypto
                if needsRecalc {
                    if inv.mode == .sip {
                        let (sipUnits, _, simulatedInstallments) = await StockService.shared.calculateHistoricalSIPUnits(
                            symbol: symbol,
                            monthlyAmount: inv.investmentAmount,
                            startDate: inv.startDate
                        )
                        profile.investments[i].installments = simulatedInstallments
                        profile.investments[i].quantity = sipUnits

                        let totalPaid = simulatedInstallments.reduce(0.0) { $0 + $1.amount }
                        let totalUnits = simulatedInstallments.reduce(0.0) { $0 + $1.units }
                        if totalUnits > 0 {
                            profile.investments[i].purchaseNAV = totalPaid / totalUnits
                        }
                        updated = true
                    } else {
                        // Lumpsum
                        let (units, _, simulatedInstallments) = await StockService.shared.calculateLumpsumUnits(
                            symbol: symbol,
                            amount: inv.investmentAmount,
                            startDate: inv.startDate
                        )
                        profile.investments[i].installments = simulatedInstallments
                        profile.investments[i].quantity = units

                        if let tx = simulatedInstallments.first {
                            profile.investments[i].purchaseNAV = tx.nav
                        }
                        updated = true
                    }
                }
            }
        }
    
            if updated {
                await MainActor.run {
                    self.currentProfile = profile
                    self.recalculateFinancials()
                }
            }
        }
    
}
