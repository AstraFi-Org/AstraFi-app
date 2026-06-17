//
//  AuthManager.swift
//  AstraFiPrototype
//
//  Created by Vipul Kumar Singh on 27/04/26.
//
import Foundation
import Supabase
import Observation

@Observable
class AuthManager {
    var currentUser: User? = nil
    var isLoading = false
    var errorMessage: String? = nil
    
    // MARK: - Sign Up
    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let session = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            currentUser = session.user
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            currentUser = session.user
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Sign Out
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            currentUser = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Listen to auth state
    func observeAuthState() {
        Task {
            for await (event, session) in supabase.auth.authStateChanges {
                switch event {
                case .signedIn:
                    currentUser = session?.user
                case .signedOut:
                    currentUser = nil
                default:
                    break
                }
            }
        }
    }
    
    // MARK: - Multi-Factor Authentication (MFA)
    
    func enrollMFA() async throws -> (factorId: String, qrCodeUri: String) {
        let enrollment = try await supabase.auth.mfa.enroll(params: MFAEnrollParams())
        return (enrollment.id, enrollment.totp?.qrCode ?? "")
    }
    
    func challengeMFA(factorId: String) async throws -> String {
        let challenge = try await supabase.auth.mfa.challenge(params: MFAChallengeParams(factorId: factorId))
        return challenge.id
    }
    
    func verifyMFA(factorId: String, challengeId: String, code: String) async throws -> Bool {
        _ = try await supabase.auth.mfa.verify(
            params: MFAVerifyParams(factorId: factorId, challengeId: challengeId, code: code)
        )
        return true
    }
    
    func unenrollMFA(factorId: String) async throws {
        try await supabase.auth.mfa.unenroll(params: MFAUnenrollParams(factorId: factorId))
    }
    
    func getAuthenticatorAssuranceLevel() async throws -> AuthMFAGetAuthenticatorAssuranceLevelResponse {
        return try await supabase.auth.mfa.getAuthenticatorAssuranceLevel()
    }
}
