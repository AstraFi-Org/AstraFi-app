import SwiftUI

struct TrackerYourPlansSection: View {
    let plans: [InvestmentPlanModel]

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Your Plans")
                    .font(.system(size: 22, weight: .bold))
                Spacer()
            }
            VStack(spacing: 12) {
                ForEach(plans) { plan in
                    let full = InvestmentPlannerEngine.generateFullPlan(input: plan.input)
                    
                    if plan.name == "Pure Investment" {
                        NavigationLink(destination: Plan1DetailView(input: plan.input, result: full.plan1, isFromTracker: true)) {
                            PlanCard(plan: plan)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else if plan.name == "Loan Strategy", let p2 = full.plan2 {
                        NavigationLink(destination: Plan2DetailView(input: plan.input, result: p2, isFromTracker: true)) {
                            PlanCard(plan: plan)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else if plan.name == "Leveraged Investing", let p3 = full.plan3 {
                        NavigationLink(destination: Plan3DetailView(input: plan.input, result: p3, isFromTracker: true)) {
                            PlanCard(plan: plan)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        // Fallback
                        NavigationLink(destination: Plan1DetailView(input: plan.input, result: full.plan1, isFromTracker: true)) {
                            PlanCard(plan: plan)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
}

struct PlanCard: View {
    let plan: InvestmentPlanModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(plan.name)
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
            }
            VStack(spacing: 8) {
                GoalSummaryDetailedRow(label: "Target Goal", value: plan.targetGoal)
                GoalSummaryDetailedRow(label: "Target Amt", value: plan.input.targetAmount)
                GoalSummaryDetailedRow(label: "Time Period", value: "\(plan.input.timePeriod) Years")
                GoalSummaryDetailedRow(label: "Date Saved", value: plan.dateSaved)
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: AppTheme.adaptiveShadow, radius: 4, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        TrackerYourPlansSection(plans: [
            InvestmentPlanModel(
                name: "Plan 1 - Growth",
                dateSaved: "10 Mar 2024",
                targetGoal: "Retirement",
                input: InvestmentPlanInputModel(
                    investmentType: "Monthly",
                    amount: "25,000",
                    liquidity: "Moderate",
                    riskType: "Moderate",
                    timePeriod: "15",
                    scheduleInvestmentDate: Date(),
                    scheduleSIPDate: Date(),
                    purposeOfInvestment: "Retirement",
                    targetAmount: "₹2.5Cr",
                    savedAmount: "0",
                    hasEmergencyFund: true
                )
            )
        ])
        .padding()
    }
}
