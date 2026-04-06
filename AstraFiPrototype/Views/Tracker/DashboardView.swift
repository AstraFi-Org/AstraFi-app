import SwiftUI

struct DashboardView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppStateManager.self) var appState
    @State private var bellAnimate = false

    private var profile: AstraUserProfile? { appState.currentProfile }
    private var investments: [AstraInvestment] { profile?.investments ?? [] }
    private var goals: [AstraGoal] { profile?.goals ?? [] }
    private var loans: [AstraLoan] { profile?.loans ?? [] }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                investmentSummaryCard
                if investments.isEmpty {
                    emptyStateCard(
                        icon: "chart.pie.fill",
                        title: "No investments yet",
                        message: "Complete your assessment or start planning to track your portfolio here.",
                        accentColor: .blue
                    )
                } else {
                    nextStepCard
                }
                financialStatusCard
                goalsSection
                upcomingEMISection
                newsAndTipsSection
                fundTrackingSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
        .background(AppTheme.appBackground(for: colorScheme))
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink(destination: ProfileView()) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("Hi, \(profile?.basicDetails.name ?? "there")")
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: NotificationsView()) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.orange)
                        .symbolEffect(.bounce, value: bellAnimate)
                }
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture().onEnded {
                    withAnimation(.interpolatingSpring(stiffness: 300, damping: 10)) { bellAnimate.toggle() }
                })
            }
        }
    }

    private var investmentSummaryCard: some View {
        let totalInvested = investments.reduce(0) { $0 + $1.investmentAmount }
        let currentVal = investments.reduce(0) { $0 + $1.currentValue }
        let gain = currentVal - totalInvested
        let gainPct = totalInvested > 0 ? (gain / totalInvested) * 100 : 0

        let mfTotal = investments.filter { $0.investmentType == .mutualFund }.reduce(0) { $0 + $1.currentValue }
        let stTotal = investments.filter { $0.investmentType == .stocks }.reduce(0) { $0 + $1.currentValue }

        let mfPerc  = currentVal > 0 ? Int((mfTotal / currentVal) * 100) : 0
        let stPerc  = currentVal > 0 ? Int((stTotal / currentVal) * 100) : 0
        let dpPerc  = 100 - mfPerc - stPerc

        let gainFormat = (abs(gainPct) > 0 && abs(gainPct) < 0.1) ? "%.2f%%" : "%.1f%%"
        let gainString = String(format: "%@\(gainFormat) %@", gain >= 0 ? "+" : "-", abs(gainPct), gain >= 0 ? "profit" : "loss")

        return ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(.blue)
                .shadow(color: AppTheme.accentShadow, radius: 20, x: 0, y: 10)

            VStack(spacing: 20) {
                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Total Portfolio").font(.subheadline).foregroundColor(.white.opacity(0.8))
                        Text(currentVal > 0 ? currentVal.toCurrency() : "₹0")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        Text("\(investments.count) Active investment\(investments.count == 1 ? "" : "s")")
                            .font(.caption).foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Rectangle().fill(Color.white.opacity(0.2)).frame(width: 1, height: 60)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Total Returns").font(.subheadline).foregroundColor(.white.opacity(0.8))
                        HStack(spacing: 6) {
                            Text(currentVal > 0 ? gain.toCurrency() : "₹0")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                            if gain > 0 {
                                Image(systemName: "arrow.up.right.circle.fill")
                                    .font(.title3).foregroundColor(.green)
                            } else if gain < 0 {
                                Image(systemName: "arrow.down.right.circle.fill")
                                    .font(.title3).foregroundColor(.red)
                            }
                        }
                        Text(currentVal > 0 ? gainString : "No returns yet")
                            .font(.caption).foregroundColor(gain >= 0 ? .green : .red)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 24).padding(.top, 24)

                Divider().background(Color.white.opacity(0.3)).padding(.horizontal, 24)

                HStack(spacing: 8) {
                    Image(systemName: "chart.pie.fill").foregroundColor(.yellow).font(.title3)
                    if currentVal > 0 {
                        Text("\(mfPerc)% MF  •  \(stPerc)% Stocks  •  \(dpPerc)% Deposits")
                            .font(.subheadline).foregroundColor(.white.opacity(0.9))
                    } else {
                        Text("No allocation data yet").font(.subheadline).foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                }
                .padding(.horizontal, 24).padding(.bottom, 24)
            }
        }
        .frame(height: 190)
    }

    private func emptyStateCard(icon: String, title: String, message: String, accentColor: Color) -> some View {
        VStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 36)).foregroundColor(accentColor.opacity(0.6))
            Text(title).font(.headline).fontWeight(.semibold)
            Text(message).font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow, radius: 12, x: 0, y: 4)
    }

    private var nextStepCard: some View {
        let behindGoal = goals.min(by: {
            ($0.currentAmount / max($0.targetAmount, 1)) < ($1.currentAmount / max($1.targetAmount, 1))
        })

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Action Required").font(.title2).fontWeight(.bold)
                Spacer()
                ZStack {
                    Circle().fill(Color.orange.opacity(0.15)).frame(width: 36, height: 36)
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange).font(.body)
                }
            }

            VStack(alignment: .leading, spacing: 16) {
                if let goal = behindGoal {
                    let progress = goal.currentAmount / max(goal.targetAmount, 1)
                    HStack(alignment: .top, spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10).fill(Color.red.opacity(0.12)).frame(width: 44, height: 44)
                            Image(systemName: "flag.fill").foregroundColor(.red).font(.title3)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(goal.goalName) Goal — \(Int(progress * 100))% complete")
                                .font(.headline)
                            Text("Current savings may not meet your target date")
                                .font(.subheadline).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(Color.green.opacity(0.12)).frame(width: 44, height: 44)
                        Image(systemName: "chart.line.uptrend.xyaxis").foregroundColor(.green).font(.title3)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Consider increasing your monthly SIP").font(.headline)
                        Text("A 10–15% SIP increase can significantly improve goal timelines")
                            .font(.subheadline).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                }

                NavigationLink(destination: PlannerView()) {
                    Text("Go to Planner")
                        .appAccentButtonStyle()
                }
            }
            .padding(20)
            .background(AppTheme.cardBackground)
            .cornerRadius(20)
            .shadow(color: AppTheme.adaptiveShadow, radius: 15, x: 0, y: 5)
        }
    }

    private var financialStatusCard: some View {
        let hasInvestments = investments.count > 0
        let status = "Excellent Standing"
        let statusMsg = "Your Finances are well-balanced and on track"

        return ZStack {
            RoundedRectangle(cornerRadius: 32)
                .fill(AppTheme.cardBackground)
                .shadow(color: AppTheme.adaptiveShadow, radius: 10, x: 0, y: 4)

            VStack(spacing: 0) {
                ZStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(status).font(.system(size: 24, weight: .bold)).foregroundColor(.primary)
                        Text(statusMsg).font(.system(size: 14, weight: .semibold)).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 24).padding(.horizontal, 20).padding(.bottom, 40)
                }
                .frame(height: 160).padding(.bottom, -60)

                ZStack {
                    VStack(spacing: 0) {
                        ScreenshotMetricRow(
                            icon: "calendar.badge.checkmark", title: "Investment Consistency",
                            status: hasInvestments ? "On Schedule" : "N/A",
                            iconColor: .blue, bgColor: .white,
                            statusColor: hasInvestments ? .blue : .secondary
                        )
                        Divider().padding(.leading, 70).padding(.trailing, 10).opacity(0.6)
                        ScreenshotMetricRow(
                            icon: "chart.line.uptrend.xyaxis", title: "Fund's Performance",
                            status: hasInvestments ? "Growing Overall" : "N/A",
                            iconColor: .blue, bgColor: .white,
                            statusColor: hasInvestments ? .blue : .secondary
                        )
                        Divider().padding(.leading, 70).padding(.trailing, 10).opacity(0.6)
                        ScreenshotMetricRow(
                            icon: "creditcard.fill", title: "Payment Discipline", status: "On Time",
                            iconColor: .blue, bgColor: .white,
                            statusColor: .blue
                        )
                    }
                    .padding(.vertical, 16).padding(.horizontal, 12)
                }
            }
        }
        .padding(.top, 10)
    }

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Goals").font(.title2).fontWeight(.bold)
                Spacer()
                NavigationLink(destination: GoalsView()) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.blue)
                }
            }

            if goals.isEmpty {
                emptyStateCard(icon: "flag.fill", title: "No goals set", message: "Complete your assessment to set financial goals.", accentColor: .orange)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(goals) { goal in
                            let grad = dashGoalGradient(for: goal.goalName)
                            EnhancedGoalCard(title: goal.goalName, percentage: Int(min(goal.currentAmount / max(goal.targetAmount, 1), 1) * 100), targetAmount: goal.targetAmount.toCurrency(), gradient: grad)
                        }
                    }
                }
            }
        }
    }

    private var upcomingEMISection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Upcoming EMIs").font(.title2).fontWeight(.bold)
                Spacer()
                NavigationLink(destination: LoanTrackerView()) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.blue)
                }
            }

            if loans.isEmpty {
                emptyStateCard(icon: "building.columns.fill", title: "No loans recorded", message: "Add your loans during assessment to track EMIs here.", accentColor: .purple)
            } else {
                VStack(spacing: 12) {
                    ForEach(loans.prefix(3)) { loan in
                        EnhancedPaymentRow(title: loan.loanType.rawValue, subtitle: loan.lender.rawValue, amount: String(format: "%.0f", loan.calculatedEMI), iconColor: loan.loanType.displayColor, isDueSoon: isDueSoon(loan: loan))
                    }
                }
            }
        }
    }

    private var newsAndTipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("News & Tips").font(.title2).fontWeight(.bold)
                Spacer()
            }
            VStack(spacing: 12) {
                NewsCardView()
                EnhancedTipCard(category: "Investment Tip", title: "Diversify 10–20% into Gold during market volatility", time: "Today", icon: "lightbulb.fill", accentColor: .yellow)
                EnhancedTipCard(category: "Tax Planning", title: "Check 80C options before March 31 deadline", time: "Today", icon: "doc.text.fill", accentColor: .indigo)
            }
        }
    }

    private var fundTrackingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Market Watch").font(.title2).fontWeight(.bold)
            VStack(spacing: 12) {
                EnhancedIPOCard(name: "Avana Electrosystems", category: "Renewable Energy", status: "Upcoming", statusColor: .orange, date: "Opens Apr 12", minInvestment: "₹1.12L", priceRange: "₹560 - ₹590")
                EnhancedIPOCard(name: "Yajur Fibers", category: "Textile Manufacturing", status: "Active", statusColor: .green, date: "Closes Apr 8", minInvestment: "₹2.96L", priceRange: "₹168 - ₹174", leftShare: "500 lots")
            }
        }
    }

    private func dashGoalGradient(for name: String) -> [Color] {
        let lower = name.lowercased()
        if lower.contains("home") { return [.green, .green] }
        if lower.contains("car")  { return [.cyan, .indigo] }
        if lower.contains("edu")  { return [.orange, .red] }
        return [.purple, .purple.opacity(0.8)]
    }

    private func isDueSoon(loan: AstraLoan) -> Bool {
        let day = Calendar.current.component(.day, from: Date())
        return day >= 25 || day <= 5
    }
}

#Preview {
    NavigationStack {
        DashboardView()
            .environment(AppStateManager.withSampleData())
    }
}
