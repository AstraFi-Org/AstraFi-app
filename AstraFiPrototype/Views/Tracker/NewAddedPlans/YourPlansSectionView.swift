import SwiftUI

struct TrackerYourPlansSection: View {
    let plans: [InvestmentPlanModel]

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Saved Illustrations").font(.auraHeader(size: 22))
                Spacer()
                NavigationLink(destination: AllPlansListView(plans: plans)) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(AppTheme.auraIndigo)
                }
            }
            VStack(spacing: 12) {
                ForEach(Array(plans.prefix(3))) { plan in
                    PlanNavigationLink(plan: plan)
                }
            }
        }
    }
}

struct PlanNavigationLink: View {
    let plan: InvestmentPlanModel
    @Environment(TrackerViewModel.self) var trackerVM
    var body: some View {
        let full = InvestmentPlannerEngine.generateFullPlan(input: plan.input, profile: nil)
        
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

struct AllPlansListView: View {
    let plans: [InvestmentPlanModel]
    @Environment(\.colorScheme) private var colorScheme
    
    @Environment(TrackerViewModel.self) var trackerVM
    
    var body: some View {
        List {
            ForEach(plans) { plan in
                PlanNavigationLink(plan: plan)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let plan = plans[index]
                    trackerVM.unsavePlan(planName: plan.name)
                }
            }
        }
        .listStyle(.plain)
        .background(AppTheme.appBackground(for: colorScheme))
        .navigationTitle("Saved Illustrations")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PlanCard: View {
    let plan: InvestmentPlanModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.name).font(.auraHeader(size: 17)).foregroundColor(AppTheme.auraIndigo)
                    Text(plan.targetGoal).font(.auraCaption()).foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text("₹\(plan.input.targetAmount)").font(.auraDigital(size: 18)).foregroundColor(AppTheme.auraIndigo)
                }
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text("Time Period").font(.auraCaption()).foregroundColor(.secondary)
                    Spacer()
                    Text("\(plan.input.timePeriod) Years").font(.auraDigital(size: 14)).foregroundColor(AppTheme.auraIndigo)
                }
            }
        }
        .auraCardStyle(radius: 24)
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
