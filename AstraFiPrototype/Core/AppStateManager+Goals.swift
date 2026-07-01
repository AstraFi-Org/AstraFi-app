import Foundation
import SwiftUI
import Supabase
import AuthenticationServices
import CryptoKit

extension AppStateManager {
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
}
