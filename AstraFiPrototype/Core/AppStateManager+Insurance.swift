import Foundation
import SwiftUI
import Supabase
import AuthenticationServices
import CryptoKit

extension AppStateManager {
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
}
