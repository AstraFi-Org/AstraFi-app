import Foundation

struct GoalAllocationItem: Identifiable, Equatable {
    let id: UUID
    let goalName: String
    let targetCorpus: Double
    let targetDate: Date
    let idealMonthlySIP: Double
    let allocatedMonthlyCapacity: Double
    let isFullyFundedFromSurplus: Bool
    let monthlyDeficit: Double
    let projectedCompletionDate: Date
    let isSequentialQueue: Bool
    let queueStartsAfterGoalName: String?
}

struct MultiGoalOptimizationResult: Equatable {
    let mode: String // "Sequential Focus" or "Activate All"
    let totalMonthlyCapacity: Double
    let totalRequiredSIP: Double
    let hasCapacityConflict: Bool
    let totalDeficit: Double
    let allocations: [GoalAllocationItem]
    let conflictResolutionAdvice: [String]
    let simultaneousGoalsCount: Int
}

enum MultiGoalOptimizer {
    
    /// Solves the multi-goal allocation problem under the selected planning mode.
    static func optimize(
        goals: [FinancialPlanningGoalDraft],
        availableMonthlyCapacity: Double,
        mode: String // "Sequential" or "Activate All"
    ) -> MultiGoalOptimizationResult {
        let capacity = max(0, availableMonthlyCapacity)
        
        // Build basic plan metrics per draft
        var calculatedItems: [(draft: FinancialPlanningGoalDraft, idealSIP: Double, corpus: Double, targetDate: Date, months: Int)] = []
        for draft in goals {
            let targetDate = draft.targetDate ?? Calendar.current.date(byAdding: .year, value: 3, to: Date())!
            let months = max(1, Calendar.current.dateComponents([.month], from: Date(), to: targetDate).month ?? 36)
            let baseAmt = max(100_000, draft.targetAmount ?? 1_000_000)
            let inflationCorpus = FinancialCalculationEngine.inflationAdjustedCost(currentCost: baseAmt, annualInflationRate: 0.06, years: Double(months) / 12.0)
            let rate = months < 36 ? 0.07 : (months < 84 ? 0.10 : 0.11)
            let sip = FinancialCalculationEngine.requiredMonthlySIP(targetCorpus: inflationCorpus, annualReturnRate: rate, months: months)
            calculatedItems.append((draft: draft, idealSIP: sip, corpus: inflationCorpus, targetDate: targetDate, months: months))
        }
        
        let totalRequired = calculatedItems.reduce(0.0) { $0 + $1.idealSIP }
        let hasConflict = totalRequired > capacity
        let totalDeficit = max(0, totalRequired - capacity)
        
        var allocations: [GoalAllocationItem] = []
        var advice: [String] = []
        
        if mode == "Sequential" {
            // MODE 2: Priority Goal Funding (Sequential Focus)
            // 100% capacity focused on Goal 1. Subsequent goals queue up.
            var cumulativeMonths = 0
            var priorGoalName: String? = nil
            
            for (index, item) in calculatedItems.enumerated() {
                if index == 0 {
                    // First Priority Goal
                    let allocated = min(capacity, item.idealSIP)
                    let deficit = max(0, item.idealSIP - allocated)
                    let monthsToComplete = FinancialCalculationEngine.monthsToAchieve(targetCorpus: item.corpus, monthlyContribution: allocated > 0 ? allocated : capacity, annualReturnRate: 0.08) ?? item.months
                    cumulativeMonths += monthsToComplete
                    let completionDate = Calendar.current.date(byAdding: .month, value: cumulativeMonths, to: Date()) ?? item.targetDate
                    
                    allocations.append(
                        GoalAllocationItem(
                            id: item.draft.id,
                            goalName: item.draft.name,
                            targetCorpus: item.corpus,
                            targetDate: item.targetDate,
                            idealMonthlySIP: item.idealSIP,
                            allocatedMonthlyCapacity: allocated,
                            isFullyFundedFromSurplus: deficit == 0,
                            monthlyDeficit: deficit,
                            projectedCompletionDate: completionDate,
                            isSequentialQueue: false,
                            queueStartsAfterGoalName: nil
                        )
                    )
                    priorGoalName = item.draft.name
                } else {
                    // Queued Goal: starts after prior goal completes
                    let queuedStart = cumulativeMonths
                    let monthsToComplete = FinancialCalculationEngine.monthsToAchieve(targetCorpus: item.corpus, monthlyContribution: capacity, annualReturnRate: 0.10) ?? item.months
                    cumulativeMonths += monthsToComplete
                    let completionDate = Calendar.current.date(byAdding: .month, value: cumulativeMonths, to: Date()) ?? item.targetDate
                    
                    allocations.append(
                        GoalAllocationItem(
                            id: item.draft.id,
                            goalName: item.draft.name,
                            targetCorpus: item.corpus,
                            targetDate: item.targetDate,
                            idealMonthlySIP: item.idealSIP,
                            allocatedMonthlyCapacity: 0,
                            isFullyFundedFromSurplus: false,
                            monthlyDeficit: item.idealSIP,
                            projectedCompletionDate: completionDate,
                            isSequentialQueue: true,
                            queueStartsAfterGoalName: priorGoalName
                        )
                    )
                    priorGoalName = item.draft.name
                }
            }
            
            advice.append("Priority Focus concentrates 100% of ₹\(Int(capacity).formatted())/mo onto your first goal to guarantee execution without dilution.")
            if let first = calculatedItems.first {
                advice.append("Once \(first.draft.name) is achieved, the full surplus transitions automatically to fund the next priority milestone.")
            }
            
            return MultiGoalOptimizationResult(
                mode: "Sequential Focus",
                totalMonthlyCapacity: capacity,
                totalRequiredSIP: totalRequired,
                hasCapacityConflict: hasConflict,
                totalDeficit: totalDeficit,
                allocations: allocations,
                conflictResolutionAdvice: advice,
                simultaneousGoalsCount: 1
            )
            
        } else {
            // MODE 1: Parallel Goal Funding (Activate All)
            // Distributes monthly capacity across all goals proportionally
            for item in calculatedItems {
                let share = totalRequired > 0 ? (item.idealSIP / totalRequired) : (1.0 / Double(max(1, calculatedItems.count)))
                let allocated = capacity * share
                let deficit = max(0, item.idealSIP - allocated)
                let actualMonths = FinancialCalculationEngine.monthsToAchieve(targetCorpus: item.corpus, monthlyContribution: max(100, allocated), annualReturnRate: 0.10) ?? item.months
                let projDate = Calendar.current.date(byAdding: .month, value: actualMonths, to: Date()) ?? item.targetDate
                
                allocations.append(
                    GoalAllocationItem(
                        id: item.draft.id,
                        goalName: item.draft.name,
                        targetCorpus: item.corpus,
                        targetDate: item.targetDate,
                        idealMonthlySIP: item.idealSIP,
                        allocatedMonthlyCapacity: allocated,
                        isFullyFundedFromSurplus: deficit == 0,
                        monthlyDeficit: deficit,
                        projectedCompletionDate: projDate,
                        isSequentialQueue: false,
                        queueStartsAfterGoalName: nil
                    )
                )
            }
            
            if hasConflict {
                advice.append("All \(calculatedItems.count) goals active simultaneously. Monthly required SIP (₹\(Int(totalRequired).formatted())) exceeds current surplus (₹\(Int(capacity).formatted())).")
                advice.append("Recommended resolutions: 1) Apply 10% annual salary step-up, 2) Extend long-term milestones by 1–2 years, or 3) Switch to Sequential Focus.")
            } else {
                advice.append("Available surplus of ₹\(Int(capacity).formatted()) fully covers all goals running in parallel!")
            }
            
            return MultiGoalOptimizationResult(
                mode: "Activate All (Parallel)",
                totalMonthlyCapacity: capacity,
                totalRequiredSIP: totalRequired,
                hasCapacityConflict: hasConflict,
                totalDeficit: totalDeficit,
                allocations: allocations,
                conflictResolutionAdvice: advice,
                simultaneousGoalsCount: calculatedItems.count
            )
        }
    }
}
