import Foundation

@MainActor
enum FinancialHealthEngine {
    static func evaluate(
        profile: AstraUserProfile?,
        data: CompleteAssessmentData?,
        history: [AstraHealthAssessment] = []
    ) -> FinancialHealthReportModel {
        let insights = FinancialAssessmentInsights.build(profile: profile, data: data)
        let snapshot = FinancialHealthCalculations.snapshot(from: insights, profile: profile, data: data)
        return assemble(snapshot: snapshot, insights: insights, profile: profile, history: history)
    }

    static func evaluate(
        insights: FinancialAssessmentInsights,
        profile: AstraUserProfile? = nil,
        history: [AstraHealthAssessment] = []
    ) -> FinancialHealthReportModel {
        let snapshot = FinancialHealthCalculations.snapshot(from: insights, profile: profile, data: nil)
        return assemble(snapshot: snapshot, insights: insights, profile: profile, history: history)
    }

    static func assemble(
        snapshot: FinancialHealthSnapshot,
        insights: FinancialAssessmentInsights,
        profile: AstraUserProfile?,
        history: [AstraHealthAssessment]
    ) -> FinancialHealthReportModel {
        let scores = FinancialHealthScoring.scores(for: snapshot)
        let parameters = FinancialHealthDiagnostics.build(snapshot: snapshot, scores: scores)
        let priorities = FinancialHealthPriorities.build(from: parameters, snapshot: snapshot)
        let overall = scores.overall
        let overallInt = overall.rounded().safeInt
        let scenarios = FinancialHealthSimulation.scenarios(from: snapshot, currentScore: overallInt)
        let goals = goalReadiness(from: profile)
        let journey = journeyPoints(history)
        let previous = journey.dropLast().last?.score
        let change = previous.map { overallInt - $0 }
        let first = journey.first?.score
        let gain = first.map { overallInt - $0 }

        return FinancialHealthReportModel(
            insights: insights,
            overallScore: overall,
            overallScoreInt: overallInt,
            statusTitle: FinancialHealthStatusBand.overallTitle(for: overallInt),
            previousScore: previous,
            scoreChange: change,
            parameters: parameters,
            priorities: priorities,
            whatIfScenarios: scenarios,
            goals: goals,
            journey: journey,
            journeyGain: gain,
            nextSteps: Array(priorities.prefix(3))
        )
    }

    static func radarValues(from parameters: [FinancialHealthParameterResult]) -> [(String, Double, Double)] {
        parameters.map { ($0.parameter.title, $0.score, 0.75) }
    }

    static func goalReadiness(from profile: AstraUserProfile?) -> [FinancialHealthGoalReadiness] {
        guard let profile, !profile.goals.isEmpty else { return [] }
        return profile.goals.map { goal in
            let linked = profile.investments.filter { $0.associatedGoalID == goal.id }
            let sip = linked.filter { $0.mode == .sip }.reduce(0) { $0 + max(0, $1.investmentAmount) }
            let monthly = sip + max(0, goal.manualSavingsContribution)
            let remaining = max(0, goal.targetAmount - goal.currentAmount)
            let progress = goal.targetAmount > 0 ? FinancialHealthCalculations.clamp(goal.currentAmount / goal.targetAmount) : 0
            let projected: String
            if remaining <= 0 {
                projected = "Complete"
            } else if monthly > 0 {
                let months = Int((remaining / monthly).rounded(.up))
                projected = months >= 12 ? "~\(months / 12)y \(months % 12)m" : "~\(months) mo"
            } else {
                projected = "Needs contribution"
            }
            let monthsToTarget = Calendar.current.dateComponents([.month], from: Date(), to: goal.targetDate).month ?? 0
            let onTrack = remaining <= 0 || (monthly > 0 && monthsToTarget > 0 && remaining / monthly <= Double(max(monthsToTarget, 1)))
            let status = remaining <= 0 ? "Complete" : onTrack ? "On Track" : "Needs Attention"
            return FinancialHealthGoalReadiness(
                id: goal.id,
                name: goal.goalName,
                targetAmount: goal.targetAmount,
                currentAmount: goal.currentAmount,
                monthlyContribution: monthly,
                projectedCompletion: projected,
                status: status,
                progress: progress
            )
        }
    }

    private static func journeyPoints(_ history: [AstraHealthAssessment]) -> [FinancialHealthJourneyPoint] {
        history
            .filter { (0...100).contains($0.score) }
            .sorted { $0.date < $1.date }
            .map { item in
                FinancialHealthJourneyPoint(
                    id: item.id,
                    date: item.date,
                    score: item.score,
                    label: item.date.formatted(.dateTime.month(.abbreviated))
                )
            }
    }
}
