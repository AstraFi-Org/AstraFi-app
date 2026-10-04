import Foundation

enum FinancialPlanningPhase: Int, Codable, CaseIterable, Identifiable {
    case today
    case future
    case timeline
    case impact
    case priorities
    case simulation
    case strategy
    case actions

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .today: "Today"
        case .future: "Future"
        case .timeline: "Timeline"
        case .impact: "Impact"
        case .priorities: "Priorities"
        case .simulation: "Simulation"
        case .strategy: "Strategy"
        case .actions: "Actions"
        }
    }

    var heading: String {
        switch self {
        case .today: "Where you are today"
        case .future: "What do you want to achieve?"
        case .timeline: "Build your future timeline"
        case .impact: "Future financial assumptions"
        case .priorities: "Choose your goal priorities"
        case .simulation: "Stress test your plan"
        case .strategy: "Build your financial strategy"
        case .actions: "Your action plan"
        }
    }

    var explanation: String {
        switch self {
        case .today: "Start with the financial details you have already shared. Missing information stays visible."
        case .future: "Choose goals and life events you want to plan for. Nothing is assumed to happen automatically."
        case .timeline: "Dates are based on your goals and the events you add. Nothing is assumed to happen automatically."
        case .impact: "Set transparent inflation, income growth, expense growth, and investment-return assumptions for your scenarios."
        case .priorities: "Choose which goals matter most. AstraFi does not rank your goals for you."
        case .simulation: "Explore hypothetical changes using assumptions you enter. These are scenarios, not predictions."
        case .strategy: "Use your goals, cash flow, and existing investments to explore a strategy."
        case .actions: "Review current priorities and return to update your plan when your information changes."
        }
    }
}

enum PlanningEventStatus: String, Codable, CaseIterable, Identifiable {
    case planned = "Planned"
    case expected = "Expected"
    case possible = "Possible"
    case userDefined = "User-defined"

    var id: String { rawValue }
}

enum PlanningEventFrequency: String, Codable, CaseIterable, Identifiable {
    case oneTime = "One-time"
    case recurring = "Recurring"

    var id: String { rawValue }
}

struct FinancialPlanningEvent: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var targetDate: Date?
    var currentEstimatedCost: Double?
    var currentFunding: Double?
    var linkedGoalID: UUID?
    var fundingFromInvestments: Bool = false
    var status: PlanningEventStatus = .userDefined
    var priority: Int = 2
    var frequency: PlanningEventFrequency = .oneTime
    var durationMonths: Int?
}

struct FinancialPlanningGoalDraft: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var category: String
    var targetDate: Date?
    var targetAmount: Double?
    var priority: Int = 2
}

struct FinancialPlanningAssumptions: Codable, Equatable {
    var version: Int = 1
    var enteredAt: Date?
    var inflationRate: Double?
    var incomeGrowthRate: Double?
    var expenseGrowthRate: Double?
    var investmentReturnRate: Double?
    var source: String = "User-provided"

    var isCompleteForSimulation: Bool {
        [inflationRate, incomeGrowthRate, expenseGrowthRate, investmentReturnRate]
            .compactMap { $0 }
            .count == 4
            && [inflationRate, incomeGrowthRate, expenseGrowthRate, investmentReturnRate]
                .compactMap { $0 }
                .allSatisfy { $0.isFinite && $0 > -1 }
    }
}

struct FinancialPlanningJourney: Codable, Equatable {
    var currentPhase: FinancialPlanningPhase = .today
    var goalDrafts: [FinancialPlanningGoalDraft] = []
    var events: [FinancialPlanningEvent] = []
    var goalPriorityIDs: [UUID] = []
    var assumptions = FinancialPlanningAssumptions()
    var monthlyInvestmentWhatIf: Double?

    enum CodingKeys: String, CodingKey {
        case currentPhase, goalDrafts, events, goalPriorityIDs, assumptions, monthlyInvestmentWhatIf
    }

    init(
        currentPhase: FinancialPlanningPhase = .today,
        goalDrafts: [FinancialPlanningGoalDraft] = [],
        events: [FinancialPlanningEvent] = [],
        goalPriorityIDs: [UUID] = [],
        assumptions: FinancialPlanningAssumptions = FinancialPlanningAssumptions(),
        monthlyInvestmentWhatIf: Double? = nil
    ) {
        self.currentPhase = currentPhase
        self.goalDrafts = goalDrafts
        self.events = events
        self.goalPriorityIDs = goalPriorityIDs
        self.assumptions = assumptions
        self.monthlyInvestmentWhatIf = monthlyInvestmentWhatIf
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        currentPhase = try values.decodeIfPresent(FinancialPlanningPhase.self, forKey: .currentPhase) ?? .today
        goalDrafts = try values.decodeIfPresent([FinancialPlanningGoalDraft].self, forKey: .goalDrafts) ?? []
        events = try values.decodeIfPresent([FinancialPlanningEvent].self, forKey: .events) ?? []
        goalPriorityIDs = try values.decodeIfPresent([UUID].self, forKey: .goalPriorityIDs) ?? []
        assumptions = try values.decodeIfPresent(FinancialPlanningAssumptions.self, forKey: .assumptions) ?? FinancialPlanningAssumptions()
        monthlyInvestmentWhatIf = try values.decodeIfPresent(Double.self, forKey: .monthlyInvestmentWhatIf)
    }
}

struct FinancialPositionSummary: Equatable {
    var monthlyIncome: Double?
    var monthlyExpenses: Double?
    var monthlySurplus: Double?
    var savingRate: Double?
    var investments: Double?
    var monthlyInvestmentContribution: Double?
    var debt: Double?
    var monthlyDebtPayments: Double?
    var insuranceCoverage: Double?
    var emergencyReserve: Double?
    var emergencyTarget: Double?
    var emergencyMonths: Double?
    var dependents: Int?
    var availableInformation: [String]
    var missingInformation: [String]
}

struct FinancialEventImpact: Identifiable, Equatable {
    var id: UUID
    var name: String
    var date: Date?
    var currentCost: Double?
    var futureCost: Double?
    var inflationRate: Double?
    var monthsToTarget: Int?
    var monthlyContributionWithoutGrowth: Double?
    var durationMonths: Int?
    var frequency: PlanningEventFrequency
    var priority: Int
    var missingInputs: [String]
}

struct FinancialProjectionYear: Identifiable, Equatable {
    var year: Int
    var projectedIncome: Double
    var projectedExpenses: Double
    var availableSurplus: Double
    var investmentBalance: Double?
    var currentPathInvestmentBalance: Double?
    var userContribution: Double?
    var eventFunding: Double
    var unfundedEventCosts: Double?

    var id: Int { year }
}

enum FinancialPlanningEngine {
    static func currentPosition(profile: AstraUserProfile?) -> FinancialPositionSummary {
        guard let profile else {
            return FinancialPositionSummary(
                monthlyIncome: nil, monthlyExpenses: nil, monthlySurplus: nil,
                savingRate: nil, investments: nil, monthlyInvestmentContribution: nil,
                debt: nil, monthlyDebtPayments: nil,
                insuranceCoverage: nil, emergencyReserve: nil, emergencyTarget: nil,
                emergencyMonths: nil, dependents: nil, availableInformation: [],
                missingInformation: ["Financial profile"]
            )
        }

        let basic = profile.basicDetails
        let hasIncome = basic.monthlyIncomeAfterTax > 0 || basic.monthlyIncome > 0
        let income = hasIncome ? (basic.monthlyIncomeAfterTax > 0 ? basic.monthlyIncomeAfterTax : basic.monthlyIncome) : nil
        let expenses = basic.monthlyExpenses > 0 ? basic.monthlyExpenses : nil
        let investments = profile.investments.isEmpty ? nil : profile.investments.reduce(0) { $0 + $1.currentValue }
        let monthlyInvestmentContribution = profile.investments.isEmpty ? nil : profile.investments
            .filter { $0.mode == .sip }
            .reduce(0) { $0 + max(0, $1.investmentAmount) }
        let debt = profile.loans.isEmpty ? nil : profile.loans.reduce(0) { $0 + $1.loanAmount }
        let emi = profile.loans.isEmpty ? nil : profile.loans.reduce(0) { $0 + $1.calculatedEMI }
        let coverage = profile.insurances.isEmpty ? nil : profile.insurances.reduce(0) { $0 + $1.sumAssured }
        let reserve = basic.emergencyFundAmount > 0 ? basic.emergencyFundAmount : nil
        let target = FinancialAssessmentInsights.build(profile: profile, data: nil).emergencyFundTarget
        let targetValue = target > 0 ? target : nil
        let dependents = basic.adultDependents + basic.childDependents
        let surplus = income.flatMap { monthlyIncome in expenses.map { monthlyIncome - $0 - (emi ?? 0) } }
        let savingsRate = income.flatMap { monthlyIncome in
            expenses.map { monthlyIncome > 0 ? (monthlyIncome - $0) / monthlyIncome : 0 }
        }

        var available: [String] = []
        var missing: [String] = []
        if income != nil { available.append("Monthly income") } else { missing.append("Monthly income") }
        if expenses != nil { available.append("Monthly expenses") } else { missing.append("Monthly expenses") }
        if investments != nil { available.append("Investments") } else { missing.append("Investments") }
        if debt != nil { available.append("Loans and debt") } else { missing.append("Loans and debt") }
        if coverage != nil { available.append("Insurance coverage") } else { missing.append("Insurance coverage") }
        if reserve != nil { available.append("Emergency reserve") } else { missing.append("Emergency reserve") }
        available.append("Dependents")

        return FinancialPositionSummary(
            monthlyIncome: income,
            monthlyExpenses: expenses,
            monthlySurplus: surplus,
            savingRate: savingsRate,
            investments: investments,
            monthlyInvestmentContribution: monthlyInvestmentContribution,
            debt: debt,
            monthlyDebtPayments: emi,
            insuranceCoverage: coverage,
            emergencyReserve: reserve,
            emergencyTarget: targetValue,
            emergencyMonths: reserve.flatMap { amount in
                guard let expenses, expenses > 0 else { return nil }
                return amount / expenses
            },
            dependents: dependents,
            availableInformation: available,
            missingInformation: missing
        )
    }

    static func eventImpacts(
        profile: AstraUserProfile?,
        journey: FinancialPlanningJourney,
        calendar: Calendar = .current,
        today: Date = Date()
    ) -> [FinancialEventImpact] {
        journey.events.map { event in
            let linkedGoal = profile?.goals.first { $0.id == event.linkedGoalID }
            let currentCost = event.currentEstimatedCost ?? linkedGoal?.targetAmount
            let currentFunding = event.currentFunding ?? linkedGoal?.currentAmount ?? 0
            let months = event.targetDate.flatMap { date -> Int? in
                guard date > today else { return nil }
                return max(1, calendar.dateComponents([.month], from: today, to: date).month ?? 1)
            }
            var missing: [String] = []
            if event.targetDate == nil { missing.append("Target date") }
            if currentCost == nil { missing.append("Estimated cost") }
            if currentCost != nil && event.targetDate != nil && journey.assumptions.inflationRate == nil {
                missing.append("Inflation assumption")
            }
            if event.frequency == .recurring && event.durationMonths == nil {
                missing.append("Duration (otherwise treated as ongoing through the simulation horizon)")
            }

            let futureCost: Double? = {
                guard let currentCost, let targetDate = event.targetDate,
                      let inflation = journey.assumptions.inflationRate else { return nil }
                let years = max(0, targetDate.timeIntervalSince(today) / (365.25 * 24 * 60 * 60))
                let projected = currentCost * pow(1 + inflation, years)
                return projected.isFinite ? projected : nil
            }()

            let contribution: Double? = {
                guard let futureCost else { return nil }
                if event.frequency == .recurring { return futureCost }
                guard let months else { return nil }
                let remaining = max(0, futureCost - currentFunding)
                return remaining / Double(months)
            }()

            return FinancialEventImpact(
                id: event.id,
                name: event.name,
                date: event.targetDate,
                currentCost: currentCost,
                futureCost: futureCost,
                inflationRate: journey.assumptions.inflationRate,
                monthsToTarget: months,
                monthlyContributionWithoutGrowth: contribution,
                durationMonths: event.durationMonths,
                frequency: event.frequency,
                priority: event.priority,
                missingInputs: missing
            )
        }
    }

    static func projection(
        profile: AstraUserProfile?,
        journey: FinancialPlanningJourney,
        throughYear: Int,
        today: Date = Date()
    ) -> [FinancialProjectionYear]? {
        guard throughYear > Calendar.current.component(.year, from: today),
              journey.assumptions.isCompleteForSimulation,
              let incomeGrowth = journey.assumptions.incomeGrowthRate,
              let expenseGrowth = journey.assumptions.expenseGrowthRate,
              let investmentReturn = journey.assumptions.investmentReturnRate,
              let position = profile.map({ currentPosition(profile: $0) }),
              let startingIncome = position.monthlyIncome,
              let startingExpenses = position.monthlyExpenses,
              let startingInvestments = position.investments,
              let baselineContribution = position.monthlyInvestmentContribution else { return nil }

        let firstYear = Calendar.current.component(.year, from: today)
        let baselineMonthlyContribution = max(0, baselineContribution)
        let monthlyContribution = max(0, journey.monthlyInvestmentWhatIf ?? baselineMonthlyContribution)
        let impacts = eventImpacts(profile: profile, journey: journey, today: today)
        guard !impacts.contains(where: { impact in
            journey.events.first(where: { $0.id == impact.id })?.fundingFromInvestments == true
                && impact.futureCost == nil
        }) else { return nil }
        var investmentBalance = startingInvestments
        var currentPathBalance = startingInvestments

        return (firstYear + 1...throughYear).map { year in
            let elapsed = year - firstYear
            let income = startingIncome * 12 * pow(1 + incomeGrowth, Double(elapsed))
            let expenses = startingExpenses * 12 * pow(1 + expenseGrowth, Double(elapsed))
            let eventFunding = impacts.reduce(0.0) { total, impact in
                guard let event = journey.events.first(where: { $0.id == impact.id }),
                      event.fundingFromInvestments,
                      let eventDate = impact.date,
                      let futureCost = impact.futureCost else { return total }
                let eventYear = Calendar.current.component(.year, from: eventDate)
                guard year >= eventYear else { return total }
                if event.frequency == .oneTime {
                    return total + (year == eventYear ? futureCost : 0)
                }
                let durationYears = event.durationMonths.map { Int(ceil(Double($0) / 12)) }
                guard durationYears.map({ year < eventYear + $0 }) ?? true else { return total }
                return total + futureCost
            }
            let contribution = monthlyContribution * 12
            let availableInvestment = investmentBalance + contribution
            let unfundedEventCosts = max(0, eventFunding - availableInvestment)
            investmentBalance = max(0, investmentBalance + contribution - eventFunding) * (1 + investmentReturn)
            currentPathBalance = max(0, currentPathBalance + baselineMonthlyContribution * 12 - eventFunding) * (1 + investmentReturn)
            return FinancialProjectionYear(
                year: year,
                projectedIncome: income,
                projectedExpenses: expenses,
                availableSurplus: income - expenses - (position.monthlyDebtPayments ?? 0) * 12,
                investmentBalance: investmentBalance,
                currentPathInvestmentBalance: currentPathBalance,
                userContribution: contribution,
                eventFunding: eventFunding,
                unfundedEventCosts: unfundedEventCosts
            )
        }
    }
}
