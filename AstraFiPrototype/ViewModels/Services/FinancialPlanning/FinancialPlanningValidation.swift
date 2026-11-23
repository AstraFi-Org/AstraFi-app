import Foundation

enum FinancialPlanningValidation {
    static let inflationRange = -0.02...0.15
    static let returnRange = -0.05...0.20
    static let growthRange = -0.05...0.30
    static let stepUpRange = 0.0...0.50
    static let withdrawalRange = 0.01...0.10

    static func validate(
        configuration: FinancialGoalConfiguration,
        assumptions: FinancialPlanningAssumptions
    ) -> [PlanningValidationIssue] {
        var issues: [PlanningValidationIssue] = []
        let resolved = assumptions.resolved()

        func add(_ id: String, _ message: String, blocking: Bool = true) {
            issues.append(PlanningValidationIssue(id: id, message: message, isBlocking: blocking))
        }

        if let income = configuration.currentMonthlyIncome, income < 0 {
            add("income", "Income cannot be negative. Enter a realistic monthly income.")
        }
        if let expenses = configuration.currentMonthlyExpenses, expenses < 0 {
            add("expenses", "Expenses cannot be negative. Enter your typical monthly spending.")
        }
        if let lifestyle = configuration.retirementLifestyleExpensesToday, lifestyle < 0 {
            add("retirementLifestyle", "Retirement lifestyle spending cannot be negative.")
        }
        if let healthcare = configuration.currentMonthlyHealthcareExpenses, healthcare < 0 {
            add("healthcare", "Healthcare expenses cannot be negative.")
        }
        if let target = configuration.targetAmountToday, target < 0 {
            add("target", "Goal value cannot be negative.")
        }
        if let savings = configuration.currentSavings, savings < 0 {
            add("savings", "Current savings cannot be negative.")
        }
        if let investments = configuration.currentInvestments, investments < 0 {
            add("investments", "Current investments cannot be negative.")
        }
        if let sip = configuration.startingMonthlyInvestment, sip < 0 {
            add("sip", "Monthly investment cannot be negative.")
        }
        if let stepUp = configuration.annualInvestmentStepUp ?? assumptions.annualSIPStepUpRate, stepUp < 0 {
            add("stepup", "SIP increase cannot be below 0%. Use 0% for a fixed SIP.")
        }

        if !inflationRange.contains(resolved.inflationRate) {
            add("inflation", "Inflation should stay within a planning range of -2% to 15%.")
        }
        if !returnRange.contains(resolved.investmentReturnRate) {
            add("return", "Investment return should stay within a planning range of -5% to 20%.")
        }
        if !growthRange.contains(resolved.incomeGrowthRate) {
            add("incomeGrowth", "Income growth should stay within a planning range of -5% to 30%.")
        }
        if !stepUpRange.contains(resolved.annualSIPStepUpRate) {
            add("sipStep", "Annual SIP increase should stay within 0% to 50%.")
        }
        if !withdrawalRange.contains(resolved.retirementWithdrawalRate) {
            add("withdrawal", "Retirement withdrawal rate should stay within 1% to 10%.", blocking: false)
        }

        if let income = configuration.currentMonthlyIncome,
           let expenses = configuration.currentMonthlyExpenses,
           let other = configuration.otherGoalMonthlyAllocations {
            let surplus = income - expenses - other
            if surplus.isNaN {
                add("surplus", "Monthly surplus could not be calculated. Check income and expenses.")
            }
        }

        if configuration.goalType == .retirement {
            if let current = configuration.currentAge, let retire = configuration.retirementAge ?? configuration.goalAge {
                if retire <= current {
                    add("retireAge", "Retirement age must be later than your current age.")
                }
            }
            if let retire = configuration.retirementAge ?? configuration.goalAge, let life = configuration.lifeExpectancy {
                if life <= retire {
                    add("life", "Life expectancy must be later than retirement age.")
                }
            }
            if configuration.resolvedYearsToGoal == nil {
                add("horizon", "Set current age and retirement age so AstraFi can estimate the timeline.")
            }
            let lifestyleCost = configuration.retirementLifestyleExpensesToday ?? configuration.currentMonthlyExpenses ?? 0
            if lifestyleCost <= 0 && (configuration.targetAmountToday ?? 0) <= 0 {
                add("lifestyle", "Enter today’s monthly lifestyle cost so the plan is based on your life, not a placeholder corpus.")
            }
            if let healthcare = configuration.currentMonthlyHealthcareExpenses, healthcare > lifestyleCost {
                add("healthcareShare", "Healthcare spending cannot be greater than the monthly lifestyle amount.")
            }
        } else {
            if configuration.resolvedYearsToGoal == nil || (configuration.resolvedYearsToGoal ?? 0) <= 0 {
                add("timeline", "This goal needs a valid timeline (years from now or a target age).")
            }
            if (configuration.targetAmountToday ?? 0) <= 0 {
                add("amount", "Enter today’s estimated cost for this goal.")
            }
        }

        return issues
    }
}
