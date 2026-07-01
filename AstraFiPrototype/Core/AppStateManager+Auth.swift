import Foundation
import SwiftUI
import Supabase
import AuthenticationServices
import CryptoKit

extension AppStateManager {
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
                            var sanitizedProfile = profile
                            if sanitizedProfile.signUp.email.isEmpty, let email = session.user.email, !email.isEmpty {
                                sanitizedProfile.signUp.email = email
                            }
                            self.currentProfile = sanitizedProfile
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
                    var sanitizedProfile = profile
                    if sanitizedProfile.signUp.email.isEmpty, let email = session.user.email, !email.isEmpty {
                        sanitizedProfile.signUp.email = email
                    }
                    self.currentProfile = sanitizedProfile
                    self.isAuthenticated = true
                    self.hasCompletedOnboarding = true
                    self.showDashboard = true
                    self.isLoading = false
                    self.isGuest = false
                    
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
            setupEmptyProfile(name: name, email: email)
            
            // After successful sign up — load existing data if any
            if let profile = try? await SupabaseRepository.shared.fetchFullProfile(userId: session.user.id) {
                var sanitizedProfile = profile
                if sanitizedProfile.signUp.email.isEmpty, let sessionEmail = session.user.email, !sessionEmail.isEmpty {
                    sanitizedProfile.signUp.email = sessionEmail
                }
                self.currentProfile = sanitizedProfile
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
        hasCompletedOnboarding = true
        isGuest = false
        
        if let pending = pendingGuestAssessment {
            linkGuestAssessmentAndSave(
                data: pending.data,
                score: pending.score,
                status: pending.status,
                insights: pending.insights,
                assessmentInsights: pending.assessmentInsights
            )
            pendingGuestAssessment = nil
        } else {
            showPostAuthOnboarding = true
        }
    }
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
    private static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    func signInWithApple() {
        print("AppStateManager: signInWithApple() triggered")
        let nonce = Self.randomNonce()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
        
        let delegate = AppleSignInDelegate { result in
            Task { @MainActor in
                print("AppStateManager: delegate callback received with result: \(result)")
                await self.handleAppleSignInResult(result)
            }
        }
        // Retain the delegate for the duration of the request
        self.appleSignInDelegate = delegate
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = delegate
        controller.presentationContextProvider = delegate
        controller.performRequests()
        print("AppStateManager: controller.performRequests() executed")
    }
    private func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) async {
        print("AppStateManager: handleAppleSignInResult starting")
        isAuthLoading = true
        authError = nil
        
        switch result {
        case .success(let authorization):
            print("AppStateManager: Apple authorization succeeded, extracting token")
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = appleIDCredential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8),
                  let nonce = currentNonce else {
                print("AppStateManager: Error - Failed to get Apple ID credentials or missing nonce")
                authError = "Failed to get Apple ID credentials."
                isAuthLoading = false
                return
            }
            
            do {
                print("AppStateManager: Attempting Supabase signInWithIdToken")
                let session = try await supabase.auth.signInWithIdToken(
                    credentials: .init(
                        provider: .apple,
                        idToken: identityToken,
                        nonce: nonce
                    )
                )
                print("AppStateManager: Supabase sign in succeeded for user: \(session.user.id)")
                
                // Try to insert user record (will silently fail if already exists)
                try? await supabase.from("users").insert([
                    "id": session.user.id.uuidString,
                    "email": session.user.email ?? ""
                ]).execute()
                
                // Load existing profile or create new one
                if let profile = try? await SupabaseRepository.shared.fetchFullProfile(userId: session.user.id) {
                    print("AppStateManager: Found existing profile for user")
                    var sanitizedProfile = profile
                    if sanitizedProfile.signUp.email.isEmpty, let email = session.user.email, !email.isEmpty {
                        sanitizedProfile.signUp.email = email
                    }
                    self.currentProfile = sanitizedProfile
                    recalculateFinancials()
                    isAuthenticated = true
                    hasCompletedOnboarding = true
                    isGuest = false
                    
                    if let pending = self.pendingGuestAssessment {
                        self.linkGuestAssessmentAndSave(
                            data: pending.data,
                            score: pending.score,
                            status: pending.status,
                            insights: pending.insights,
                            assessmentInsights: pending.assessmentInsights
                        )
                        self.pendingGuestAssessment = nil
                    } else {
                        showPostAuthOnboarding = false
                        showDashboard = true
                    }
                } else {
                    print("AppStateManager: No existing profile found, setting up empty profile")
                    // Build display name from Apple credential if available
                    let fullName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                        .compactMap { $0 }
                        .joined(separator: " ")
                    let displayName = fullName.isEmpty ? (session.user.email ?? "User") : fullName
                    
                    setupEmptyProfile(name: displayName, email: session.user.email ?? "")
                    isAuthenticated = true
                    hasCompletedOnboarding = true
                    isGuest = false
                    
                    if let pending = self.pendingGuestAssessment {
                        self.linkGuestAssessmentAndSave(
                            data: pending.data,
                            score: pending.score,
                            status: pending.status,
                            insights: pending.insights,
                            assessmentInsights: pending.assessmentInsights
                        )
                        self.pendingGuestAssessment = nil
                    } else {
                        showPostAuthOnboarding = true
                    }
                }
                
                if let plans = try? await SupabaseRepository.shared.fetchSavedPlans(userId: session.user.id) {
                    self.savedPlans = plans
                }
                
            } catch {
                print("AppStateManager: Supabase auth error: \(error.localizedDescription)")
                authError = error.localizedDescription
            }
            
        case .failure(let error):
            print("AppStateManager: Apple authorization failed with error: \(error.localizedDescription) (code: \((error as NSError).code))")
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
                var sanitizedProfile = profile
                if sanitizedProfile.signUp.email.isEmpty, let email = session.user.email, !email.isEmpty {
                    sanitizedProfile.signUp.email = email
                }
                self.currentProfile = sanitizedProfile
                recalculateFinancials()
                
                isAuthenticated = true
                hasCompletedOnboarding = true
                isGuest = false
                
                if let pending = pendingGuestAssessment {
                    linkGuestAssessmentAndSave(
                        data: pending.data,
                        score: pending.score,
                        status: pending.status,
                        insights: pending.insights,
                        assessmentInsights: pending.assessmentInsights
                    )
                    pendingGuestAssessment = nil
                } else {
                    showPostAuthOnboarding = false
                    showDashboard = true
                }
            } else {
                setupEmptyProfile(name: session.user.email ?? "User", email: session.user.email ?? "")
                
                isAuthenticated = true
                hasCompletedOnboarding = true
                isGuest = false
                
                if let pending = pendingGuestAssessment {
                    linkGuestAssessmentAndSave(
                        data: pending.data,
                        score: pending.score,
                        status: pending.status,
                        insights: pending.insights,
                        assessmentInsights: pending.assessmentInsights
                    )
                    pendingGuestAssessment = nil
                } else {
                    showPostAuthOnboarding = true
                }
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
                var sanitizedProfile = profile
                if sanitizedProfile.signUp.email.isEmpty, let email = session.user.email, !email.isEmpty {
                    sanitizedProfile.signUp.email = email
                }
                self.currentProfile = sanitizedProfile
                recalculateFinancials()
                
                isAuthenticated = true
                hasCompletedOnboarding = true
                isGuest = false
                
                if let pending = pendingGuestAssessment {
                    linkGuestAssessmentAndSave(
                        data: pending.data,
                        score: pending.score,
                        status: pending.status,
                        insights: pending.insights,
                        assessmentInsights: pending.assessmentInsights
                    )
                    pendingGuestAssessment = nil
                } else {
                    showPostAuthOnboarding = false
                    showDashboard = true
                }
            } else {
                setupEmptyProfile(name: session.user.email ?? "User", email: session.user.email ?? "")
                
                isAuthenticated = true
                hasCompletedOnboarding = true
                isGuest = false
                
                if let pending = pendingGuestAssessment {
                    linkGuestAssessmentAndSave(
                        data: pending.data,
                        score: pending.score,
                        status: pending.status,
                        insights: pending.insights,
                        assessmentInsights: pending.assessmentInsights
                    )
                    pendingGuestAssessment = nil
                } else {
                    showPostAuthOnboarding = true
                }
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
                var sanitizedProfile = profile
                if sanitizedProfile.signUp.email.isEmpty, let email = session.user.email, !email.isEmpty {
                    sanitizedProfile.signUp.email = email
                }
                self.currentProfile = sanitizedProfile
                recalculateFinancials()
                
                isAuthenticated = true
                hasCompletedOnboarding = true
                isGuest = false
                
                if let pending = pendingGuestAssessment {
                    linkGuestAssessmentAndSave(
                        data: pending.data,
                        score: pending.score,
                        status: pending.status,
                        insights: pending.insights,
                        assessmentInsights: pending.assessmentInsights
                    )
                    pendingGuestAssessment = nil
                } else {
                    showPostAuthOnboarding = false
                    showDashboard = true
                }
            } else {
                setupEmptyProfile(name: session.user.email ?? "User", email: session.user.email ?? "")
                
                isAuthenticated = true
                hasCompletedOnboarding = true
                isGuest = false
                
                if let pending = pendingGuestAssessment {
                    linkGuestAssessmentAndSave(
                        data: pending.data,
                        score: pending.score,
                        status: pending.status,
                        insights: pending.insights,
                        assessmentInsights: pending.assessmentInsights
                    )
                    pendingGuestAssessment = nil
                } else {
                    showPostAuthOnboarding = true
                }
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
            isGuest = false
            pendingGuestAssessment = nil
            
            showDashboard = false
            showPostAuthOnboarding = false
            currentProfile = nil
            savedPlans = []
        } catch {
            authError = error.localizedDescription
        }
    }
}
