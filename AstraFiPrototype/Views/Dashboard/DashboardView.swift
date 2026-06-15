import SwiftUI

struct DashboardView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppStateManager.self) var appState
    
    private var profile: AstraUserProfile? { appState.currentProfile }
    private var investments: [AstraInvestment] { profile?.investments ?? [] }
    private var goals: [AstraGoal] { profile?.goals ?? [] }
    private var loans: [AstraLoan] { profile?.loans ?? [] }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.auraInterCardSpacing) {
                investmentSummaryCard
                
                if investments.isEmpty {
                    emptyStateCard(
                        icon: "sparkles",
                        title: "Begin Your AstraFi Journey",
                        message: "Complete your assessment to unlock personalised financial insights.",
                        accentColor: AppTheme.auraGold
                    )
                } else {
                    nextStepCard
                }
                
                goalsSection
                upcomingEMISection
            }
            .padding(.horizontal, AppTheme.auraPadding)
            .padding(.bottom, 48)
            .contentShape(Rectangle())
            .onTapGesture { hideKeyboard() }
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
        .background(AppTheme.appBackground(for: colorScheme))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: NotificationsView()) {
                    Image(systemName: "bell.fill")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: ProfileView()) {
                    Image(systemName: "person.circle")
                }
            }
        }
    }
    
    
    // MARK: Portfolio Hero Card
    private var investmentSummaryCard: some View {
        let currentVal     = investments.reduce(0) { $0 + $1.currentValue }
        let totalInvested  = investments.reduce(0) { $0 + $1.totalInvestedAmount }
        let totalReturns   = currentVal - totalInvested
        let returnsPositive = totalReturns >= 0
        let activeCount    = investments.count
        
        return VStack(spacing: 0) {
            // ── Top section: Portfolio value
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Portfolio")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))
                
                Text(currentVal.toCurrency())
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(.white)
                
                HStack(spacing: 6) {
                    Image(systemName: returnsPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 11, weight: .bold))
                    Text(totalReturns.toCurrency())
                        .font(.system(size: 13, weight: .semibold))
                    Text(returnsPositive ? "total returns" : "total loss")
                        .font(.system(size: 13))
                        .opacity(0.8)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.white.opacity(0.15))
                .clipShape(Capsule())
                .foregroundStyle(
                    returnsPositive ? .green : Color(hex: "#FF453A")
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            
            // ── Divider
            Rectangle()
                .fill(.white.opacity(0.15))
                .frame(height: 0.75)
                .padding(.horizontal, 24)
            
            // ── Bottom row: stats
            HStack {
                PortfolioStat(label: "Active", value: "\(activeCount)", icon: "briefcase.fill")
                Divider()
                    .background(.white.opacity(0.25))
                    .frame(height: 28)
                PortfolioStat(label: "Invested", value: totalInvested.toShortCurrency(), icon: "indianrupeesign.circle.fill")
                Divider()
                    .background(.white.opacity(0.25))
                    .frame(height: 28)
                PortfolioStat(
                    label: investments.isEmpty ? "Allocation" : "Optimised",
                    value: investments.isEmpty ? "—" : "✓",
                    icon: "chart.pie.fill"
                )
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#0057E7"), Color(hex: "#1E90FF")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                // Subtle mesh overlay
                Circle()
                    .fill(.white.opacity(0.06))
                    .frame(width: 180)
                    .offset(x: 80, y: -50)
                Circle()
                    .fill(.white.opacity(0.04))
                    .frame(width: 120)
                    .offset(x: -60, y: 60)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color(hex: "#007AFF").opacity(0.35), radius: 20, x: 0, y: 10)
    }
    
    private struct PortfolioStat: View {
        let label: String
        let value: String
        let icon: String
        
        var body: some View {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.7))
                VStack(alignment: .leading, spacing: 1) {
                    Text(value)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    Text(label)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.65))
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: Empty State
    private func emptyStateCard(icon: String, title: String, message: String, accentColor: Color) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundStyle(accentColor)
            }
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 12, x: 0, y: 4)
    }
    
    // MARK: Action Required Card
    private var nextStepCard: some View {
        let insights = FinancialAssessmentInsights.build(profile: profile, data: nil)
        let concerns = insights.activeConcerns
        
        return VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Action Required")
                        .font(.system(size: 18, weight: .bold))
                    Text(concerns.isEmpty ? "All vitals healthy" : "\(concerns.count) item\(concerns.count > 1 ? "s" : "") need attention")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(AppTheme.auraGold.opacity(0.15))
                        .frame(width: 38, height: 38)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(AppTheme.auraGold)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                if concerns.isEmpty {
                    ActionRow(
                        icon: "checkmark.shield.fill",
                        color: Color(hex: "#30D158"),
                        title: "All vitals are healthy",
                        subtitle: "Keep maintaining your current savings rate for optimal growth."
                    )
                } else {
                    ForEach(concerns.prefix(3)) { concern in
                        ActionRow(
                            icon: concernIcon(for: concern.parameter),
                            color: concern.status == .concern ? Color(hex: "#FF453A") : Color(hex: "#FF9F0A"),
                            title: concern.title,
                            subtitle: concern.recommendation
                        )
                    }
                }
            }
            
//            NavigationLink(destination: PlannerView()) {
//                HStack(spacing: 8) {
//                    Text("View Full Analysis")
//                        .font(.system(size: 14, weight: .semibold))
//                    Spacer()
//                    Image(systemName: "arrow.right")
//                        .font(.system(size: 12, weight: .bold))
//                }
//                .foregroundStyle(.white)
//                .padding(.horizontal, 18)
//                .padding(.vertical, 13)
//                .background(AppTheme.accentGradient)
//                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
//                .shadow(color: Color(hex: "#007AFF").opacity(0.3), radius: 10, x: 0, y: 5)
//            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 14, x: 0, y: 5)
    }
    
    private func concernIcon(for parameter: AssessmentParameter) -> String {
        switch parameter {
        case .vitals:         return "heart.text.square.fill"
        case .investment:     return "chart.line.downtrend.xyaxis"
        case .emergencyFund:  return "exclamationmark.shield.fill"
        case .insurance:      return "cross.case.fill"
        case .liabilities:    return "creditcard.trianglebadge.exclamationmark"
        }
    }
    
    private struct ActionRow: View {
        let icon: String
        let color: Color
        let title: String
        let subtitle: String
        
        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(color.opacity(0.12))
                        .frame(width: 42, height: 42)
                    Image(systemName: icon)
                        .foregroundStyle(color)
                        .font(.system(size: 17))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
        }
    }
    
    // MARK: Goals Section
    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Goals", destination: AnyView(GoalListView()))
            
            if goals.isEmpty {
                emptyStateCard(
                    icon: "flag.2.crossed.fill",
                    title: "No goals set",
                    message: "Plan your financial goals.",
                    accentColor: .orange
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(goals) { goal in
                            let grad = dashGoalGradient(for: goal.goalName)
                            EnhancedGoalCard(
                                title: goal.goalName,
                                percentage: Int(min(goal.currentAmount / max(goal.targetAmount, 1), 1) * 100),
                                targetAmount: goal.targetAmount.toCurrency(),
                                gradient: grad
                            )
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
    }
    
    // MARK: EMI Section
    private var upcomingEMISection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Upcoming EMIs", destination: AnyView(LoanTrackerView()))
            
            if loans.isEmpty {
                emptyStateCard(
                    icon: "building.columns.fill",
                    title: "No loans recorded",
                    message: "Add your loans to track EMIs here.",
                    accentColor: Color(hex: "#BF5AF2")
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(loans.prefix(3)) { loan in
                        EnhancedPaymentRow(
                            title: loan.displayName,
                            subtitle: loan.displayLender,
                            amount: String(format: "%.0f", loan.calculatedEMI),
                            iconColor: loan.loanType.displayColor,
                            isDueSoon: isDueSoon(loan: loan)
                        )
                    }
                }
            }
        }
    }
    
    // MARK: Helpers
    private func dashGoalGradient(for name: String) -> [Color] {
        let lower = name.lowercased()
        if lower.contains("home") { return [Color(hex: "#30D158"), Color(hex: "#25A244")] }
        if lower.contains("car")  { return [Color(hex: "#32ADE6"), Color(hex: "#5E5CE6")] }
        if lower.contains("edu")  { return [Color(hex: "#FF9F0A"), Color(hex: "#FF453A")] }
        return [Color(hex: "#BF5AF2"), Color(hex: "#5E5CE6")]
    }
    
    private func isDueSoon(loan: AstraLoan) -> Bool {
        let day = Calendar.current.component(.day, from: Date())
        return day >= 25 || day <= 5
    }
}

// MARK: - Reusable Section Header
private struct SectionHeader: View {
    let title: String
    let destination: AnyView
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 20, weight: .bold))
            Spacer()
            NavigationLink(destination: destination) {
                HStack(spacing: 4) {
                    Text("See all")
                        .font(.system(size: 13, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(Color(hex: "#007AFF"))
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        DashboardView()
            .environment(AppStateManager.withSampleData())
    }
}

// MARK: - Local Formatting Helpers
private extension Double {
    /// Formats the number as a short currency string (e.g., 12500 -> "₹12.5K").
    /// Falls back to standard currency formatting for values under 1,000.
    func toShortCurrency(currencyCode: String = "INR") -> String {
        let absValue = abs(self)
        let sign = self < 0 ? "-" : ""
        
        // Under 1,000 just use normal currency formatting (no decimals)
        if absValue < 1_000 {
            let f = NumberFormatter()
            f.numberStyle = .currency
            f.currencyCode = currencyCode
            f.maximumFractionDigits = 0
            f.minimumFractionDigits = 0
            return sign + (f.string(from: NSNumber(value: absValue)) ?? String(format: "%.0f", absValue))
        }
        
        // Determine suffix and divisor
        let units: [(threshold: Double, divisor: Double, suffix: String)] = [
            (1_000_000_000_000, 1_000_000_000_000, "T"),
            (1_000_000_000,     1_000_000_000,     "B"),
            (1_000_000,         1_000_000,         "M"),
            (1_000,             1_000,             "K")
        ]
        
        let (divisor, suffix): (Double, String) = {
            for unit in units where absValue >= unit.threshold {
                return (unit.divisor, unit.suffix)
            }
            return (1_000, "K")
        }()
        
        let reduced = absValue / divisor
        
        // Format the reduced number with up to one decimal place
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = reduced < 10 ? 1 : 0
        numberFormatter.minimumFractionDigits = 0
        
        let reducedString = numberFormatter.string(from: NSNumber(value: reduced)) ?? String(format: reduced < 10 ? "%.1f" : "%.0f", reduced)
        
        // Get currency symbol for the provided code
        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        currencyFormatter.currencyCode = currencyCode
        currencyFormatter.maximumFractionDigits = 0
        currencyFormatter.minimumFractionDigits = 0
        
        let symbol = currencyFormatter.currencySymbol ?? "₹"
        return "\(sign)\(symbol)\(reducedString)\(suffix)"
    }
}
