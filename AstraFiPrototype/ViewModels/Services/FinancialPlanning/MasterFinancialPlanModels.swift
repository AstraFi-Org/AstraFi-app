import Foundation

enum GoalTrackingStatus: String, Codable, CaseIterable {
    case onTrack = "On Track"
    case needsAttention = "Needs Attention"
    case atRisk = "At Risk"
    case completed = "Completed"
    case paused = "Paused"
    
    var icon: String {
        switch self {
        case .onTrack: return "checkmark.seal.fill"
        case .needsAttention: return "exclamationmark.triangle.fill"
        case .atRisk: return "xmark.octagon.fill"
        case .completed: return "flag.checkered.circle.fill"
        case .paused: return "pause.circle.fill"
        }
    }
}

enum MasterPlanTrackingStatus: String, Codable, CaseIterable {
    case fullyResilient = "Fully Resilient"
    case onTrackWithStepUp = "On Track with Step-Up"
    case requiresReview = "Requires Review"
}

struct MasterTimelineItem: Identifiable, Codable, Equatable {
    let id: UUID
    let year: Int
    let title: String
    let category: String
    let targetCorpus: Double
    let date: Date
    let isCompleted: Bool
    
    init(id: UUID = UUID(), year: Int, title: String, category: String, targetCorpus: Double, date: Date, isCompleted: Bool = false) {
        self.id = id
        self.year = year
        self.title = title
        self.category = category
        self.targetCorpus = targetCorpus
        self.date = date
        self.isCompleted = isCompleted
    }
}

struct ActiveGoalPlan: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let category: String
    let targetBaseAmount: Double
    let inflationCorpus: Double
    let currentSaved: Double
    let monthlySIPRequired: Double
    let allocatedMonthlySurplus: Double
    let targetDate: Date
    let strategyName: String
    let status: GoalTrackingStatus
    let notes: String
    
    var progressPercentage: Double {
        guard inflationCorpus > 0 else { return 0 }
        return min(100.0, (currentSaved / inflationCorpus) * 100.0)
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        category: String,
        targetBaseAmount: Double,
        inflationCorpus: Double,
        currentSaved: Double,
        monthlySIPRequired: Double,
        allocatedMonthlySurplus: Double,
        targetDate: Date,
        strategyName: String,
        status: GoalTrackingStatus = .onTrack,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.targetBaseAmount = targetBaseAmount
        self.inflationCorpus = inflationCorpus
        self.currentSaved = currentSaved
        self.monthlySIPRequired = monthlySIPRequired
        self.allocatedMonthlySurplus = allocatedMonthlySurplus
        self.targetDate = targetDate
        self.strategyName = strategyName
        self.status = status
        self.notes = notes
    }
}

struct MasterFinancialPlan: Identifiable, Codable, Equatable {
    let id: UUID
    var version: Int
    let createdAt: Date
    var lastRecalculatedAt: Date
    var planningMode: String // "Sequential Focus" or "Activate All"
    var totalMonthlyPlanningCapacity: Double
    var totalMonthlySIPNeeded: Double
    var totalProjectedWealth: Double
    var activeGoals: [ActiveGoalPlan]
    var timeline: [MasterTimelineItem]
    var trackingStatus: MasterPlanTrackingStatus
    var summaryNotes: String
    
    init(
        id: UUID = UUID(),
        version: Int = 1,
        createdAt: Date = Date(),
        lastRecalculatedAt: Date = Date(),
        planningMode: String = "Sequential Focus",
        totalMonthlyPlanningCapacity: Double = 0,
        totalMonthlySIPNeeded: Double = 0,
        totalProjectedWealth: Double = 0,
        activeGoals: [ActiveGoalPlan] = [],
        timeline: [MasterTimelineItem] = [],
        trackingStatus: MasterPlanTrackingStatus = .onTrackWithStepUp,
        summaryNotes: String = ""
    ) {
        self.id = id
        self.version = version
        self.createdAt = createdAt
        self.lastRecalculatedAt = lastRecalculatedAt
        self.planningMode = planningMode
        self.totalMonthlyPlanningCapacity = totalMonthlyPlanningCapacity
        self.totalMonthlySIPNeeded = totalMonthlySIPNeeded
        self.totalProjectedWealth = totalProjectedWealth
        self.activeGoals = activeGoals
        self.timeline = timeline
        self.trackingStatus = trackingStatus
        self.summaryNotes = summaryNotes
    }
}
