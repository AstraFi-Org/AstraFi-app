import Foundation
import SwiftUI
import Supabase
import AuthenticationServices
import CryptoKit

extension AppStateManager {
    func saveAssessmentToHistory(score: Int, status: String, insights: [String], assessmentInsights: FinancialAssessmentInsights? = nil) {
        if var profile = currentProfile {
            let newAssessment = AstraHealthAssessment(
                date: Date(),
                score: score,
                status: status,
                keyInsights: insights,
                insights: assessmentInsights
            )
            profile.monthlyHealthAssessments.append(newAssessment)
            currentProfile = profile
            Task {
                if let session = try? await supabase.auth.session {
                    _ = try? await SupabaseRepository.shared.saveHealthAssessment(newAssessment, userId: session.user.id)
                }
            }
        }
    }
    func linkGuestAssessmentAndSave(data: CompleteAssessmentData, score: Int, status: String, insights: [String], assessmentInsights: FinancialAssessmentInsights) {
        updateProfile(from: data)
        saveAssessmentToHistory(score: score, status: status, insights: insights, assessmentInsights: assessmentInsights)
        isAssessmentSkipped = false
        isGuest = false
        showDashboard = true
    }
    func deleteAssessmentFromHistory(_ assessment: AstraHealthAssessment) {
        guard var profile = currentProfile else { return }
        profile.monthlyHealthAssessments.removeAll { $0.id == assessment.id }
        currentProfile = profile
        
        Task {
            if (try? await supabase.auth.session) != nil {
                try? await SupabaseRepository.shared.deleteHealthAssessment(assessment.id)
            }
        }
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
                
                let df = DateFormatter()
                df.dateFormat = "yyyy-MM"
                let monthKey = df.string(from: Date())
                profile.monthlyCashflowSnapshots[monthKey] = cashflow
                
                currentProfile = profile
                recalculateFinancials()
                Task {
                    if let session = try? await supabase.auth.session {
                        do {
                            try await SupabaseRepository.shared.saveCashflowSnapshot(
                                cashflow,
                                monthKey: monthKey,
                                userId: session.user.id
                            )
                            try await SupabaseRepository.shared.saveUserProfile(
                                profile,
                                userId: session.user.id
                            )
                            print("Cashflow and UserProfile saved to Supabase")
                        } catch {
                            print("Cashflow/UserProfile save failed: \(error)")
                        }
                    }
                }
            }
        }
}
