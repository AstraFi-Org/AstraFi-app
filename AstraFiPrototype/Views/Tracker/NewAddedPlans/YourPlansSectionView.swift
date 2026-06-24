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
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.auraIndigo)
                }
            }
            .padding(.horizontal, 8)
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
    @State private var navigateToPlan = false
    
    var body: some View {
        let full = InvestmentPlannerEngine.generateFullPlan(input: plan.input, profile: nil)
        
        Button {
            navigateToPlan = true
        } label: {
            PlanCard(plan: plan)
        }
        .buttonStyle(PlainButtonStyle())
        .navigationDestination(isPresented: $navigateToPlan) {
            if plan.name.contains("Pure Investment") {
                Plan1DetailView(input: plan.input, result: full.plan1, isFromTracker: true)
            } else if plan.name.contains("Loan Strategy") {
                Plan2DetailView(input: plan.input, result: full.plan2 ?? Plan2Result.empty(), isFromTracker: true)
            } else if plan.name.contains("Leveraged Investing") || plan.name.contains("Loan Stress Test") {
                Plan3DetailView(input: plan.input, result: full.plan3 ?? Plan3Result.empty(), isFromTracker: true)
            } else {
                Plan1DetailView(input: plan.input, result: full.plan1, isFromTracker: true)
            }
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
        HStack(spacing: 12) {
            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.name)
                            .font(.auraHeader(size: 17))
                            .multilineTextAlignment(.leading)
                        Text(plan.targetGoal)
                            .font(.auraCaption())
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 6) {
                        let amountStr = plan.input.targetAmount.replacingOccurrences(of: "₹", with: "").replacingOccurrences(of: ",", with: "")
                        let amountVal = Double(amountStr) ?? 0
                        let formattedAmount = amountVal > 0 ? amountVal.toCurrency() : "₹\(plan.input.targetAmount)"
                        Text(formattedAmount)
                            .font(.auraDigital(size: 18))
                            .foregroundColor(AppTheme.auraIndigo)
                    }
                }
                
                VStack(spacing: 8) {
                    HStack {
                        Text("Time Period")
                            .font(.auraCaption())
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(plan.input.timePeriod) Years")
                            .font(.auraDigital(size: 14))
                            .foregroundColor(AppTheme.auraIndigo)
                    }
                }
            }
            
//            Image(systemName: "chevron.right")
//                .font(.system(size: 14, weight: .bold))
//                .foregroundColor(.secondary.opacity(0.5))
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
