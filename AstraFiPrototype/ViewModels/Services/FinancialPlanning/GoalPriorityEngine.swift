import Foundation

/// Explainable priority assessment for goals.
/// Conforms to Section 16 of AstraFi Architecture: Time urgency + funding gap + user preference = explainable score.
enum GoalPriorityCategory: String, Codable, CaseIterable {
    case critical = "Critical"
    case high = "High"
    case medium = "Medium"
    case flexible = "Flexible"
}

struct GoalPriorityEvaluation: Identifiable, Equatable {
    let id: UUID
    let goalName: String
    let score: Double // 0 - 100
    let category: GoalPriorityCategory
    let explainableReason: String
    let isUserOverridden: Bool
}

enum GoalPriorityEngine {
    
    /// Evaluates explainable priority score and category for a goal.
    static func evaluatePriority(
        goalID: UUID,
        name: String,
        category: String,
        targetDate: Date?,
        targetAmount: Double?,
        currentSavings: Double,
        userAssignedPriority: Int,
        userOverrideCategory: GoalPriorityCategory? = nil
    ) -> GoalPriorityEvaluation {
        if let override = userOverrideCategory {
            return GoalPriorityEvaluation(
                id: goalID,
                goalName: name,
                score: override == .critical ? 95 : (override == .high ? 80 : (override == .medium ? 50 : 25)),
                category: override,
                explainableReason: "Set to \(override.rawValue) by your manual preference.",
                isUserOverridden: true
            )
        }
        
        let target = max(1_000, targetAmount ?? 1_000_000)
        let fundingGapPercent = max(0, min(100, ((target - currentSavings) / target) * 100.0))
        
        let monthsToTarget: Int = {
            guard let date = targetDate else { return 36 }
            let months = Calendar.current.dateComponents([.month], from: Date(), to: date).month ?? 36
            return max(1, months)
        }()
        
        // 1. Time urgency score (0 - 40 pts): Closer goals have higher urgency
        let urgencyScore: Double
        if monthsToTarget <= 12 {
            urgencyScore = 40.0
        } else if monthsToTarget <= 24 {
            urgencyScore = 35.0
        } else if monthsToTarget <= 48 {
            urgencyScore = 25.0
        } else if monthsToTarget <= 84 {
            urgencyScore = 15.0
        } else {
            urgencyScore = 5.0
        }
        
        // 2. Funding gap score (0 - 30 pts): Unfunded goals need immediate attention
        let gapScore = (fundingGapPercent / 100.0) * 30.0
        
        // 3. User assigned rank (0 - 30 pts): 1 = High (30 pts), 2 = Medium (20 pts), 3 = Low (10 pts)
        let rankScore: Double
        switch userAssignedPriority {
        case 1: rankScore = 30.0
        case 2: rankScore = 20.0
        default: rankScore = 10.0
        }
        
        let totalScore = min(100.0, urgencyScore + gapScore + rankScore)
        
        let priorityCat: GoalPriorityCategory
        if totalScore >= 75.0 || monthsToTarget <= 15 {
            priorityCat = .high
        } else if totalScore >= 50.0 {
            priorityCat = .medium
        } else {
            priorityCat = .flexible
        }
        
        let reason: String
        let years = max(1, monthsToTarget / 12)
        if monthsToTarget <= 24 {
            reason = "Target is \(monthsToTarget) months away (\(years) yr) and \(Int(fundingGapPercent))% unfunded. Requires immediate capital allocation."
        } else if fundingGapPercent > 70 {
            reason = "Longer horizon (\(years) yrs), but substantial funding gap of \(Int(fundingGapPercent))% warrants regular compounding now."
        } else {
            reason = "Planned for \(years) years from now with comfortable flexibility."
        }
        
        return GoalPriorityEvaluation(
            id: goalID,
            goalName: name,
            score: totalScore,
            category: priorityCat,
            explainableReason: reason,
            isUserOverridden: false
        )
    }
}
