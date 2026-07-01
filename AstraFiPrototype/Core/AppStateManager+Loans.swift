import Foundation
import SwiftUI
import Supabase
import AuthenticationServices
import CryptoKit

extension AppStateManager {
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
}
