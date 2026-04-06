import SwiftUI

private extension Color {
    static let chipBackground = Color(UIColor.secondarySystemFill)
}

struct PlannerView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppStateManager.self) var appState
    @State private var showNewInvestmentPlan = false
    @State private var showCompanyAnalyzer = false
    @State private var projectionYears = 5

    private var profile: AstraUserProfile? { appState.currentProfile }
    private var investments: [AstraInvestment]  { profile?.investments ?? [] }
    private var goals: [AstraGoal]              { profile?.goals ?? [] }

    private var monthlyIncome:   Double { profile?.basicDetails.monthlyIncomeAfterTax ?? 0 }
    private var monthlyExpenses: Double { profile?.basicDetails.monthlyExpenses ?? 0 }
    private var savingRate:      Int    {
        guard monthlyIncome > 0 else { return 0 }
        return Int(((monthlyIncome - monthlyExpenses) / monthlyIncome) * 100)
    }

    private var totalInvested: Double { investments.reduce(0) { $0 + $1.investmentAmount } }

    private func projectedValue(for inv: AstraInvestment, inYears years: Int) -> Double {
        let annualRate = 0.10 
        let monthlyRate = annualRate / 12
        let months = Double(years * 12)

        var result: Double
        if inv.mode == .sip {

            let pqr = pow(1 + monthlyRate, months)
            if pqr.isFinite {
                result = inv.investmentAmount * ((pqr - 1) / monthlyRate) * (1 + monthlyRate)
            } else {

                result = inv.investmentAmount * 1_000_000
            }
        } else {

            let pqr = pow(1 + monthlyRate, months)
            if pqr.isFinite {
                result = inv.investmentAmount * pqr
            } else {

                result = inv.investmentAmount * 1_000_000
            }
        }
        return result.isFinite ? result : 0
    }

    private func totalInvestedAmount(for inv: AstraInvestment, inYears years: Int) -> Double {
        if inv.mode == .sip {
            return inv.investmentAmount * Double(years * 12)
        } else {
            return inv.investmentAmount 
        }
    }

    private var totalProjectedValue: Double {
        investments.reduce(0) { $0 + projectedValue(for: $1, inYears: projectionYears) }
    }

    private var oneYearProjection: Double  { 
        investments.reduce(0) { $0 + projectedValue(for: $1, inYears: 1) }
    }

    private var selectedYearProjection: Double {
        investments.reduce(0) { $0 + projectedValue(for: $1, inYears: projectionYears) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                financialVitalsCard
                currentInvestmentsSection
                actionButtonsSection
                investmentForecastSection
                valueForecastSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
        .navigationTitle("Planner")
        .navigationBarTitleDisplayMode(.large)
        .background(AppTheme.appBackground(for: colorScheme))
        .navigationDestination(isPresented: $showNewInvestmentPlan) { GoalSelectionView() }
        .sheet(isPresented: $showCompanyAnalyzer)  { CompanyAnalyzerView() }
    }

    private var financialVitalsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Financial Vitals").font(.title2).fontWeight(.bold)

            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    VitalMetric(title: "Monthly Income",  value: monthlyIncome > 0   ? monthlyIncome.toCurrency()   : "—", color: .accentColor)
                    NavigationLink(destination: SpendingInsightsView()) {
                        VitalMetric(title: "Expenses",        value: monthlyExpenses > 0 ? monthlyExpenses.toCurrency() : "—", color: .red)
                    }
                    .buttonStyle(PlainButtonStyle())
                    VitalMetric(title: "Saving Rate",     value: savingRate > 0      ? "\(savingRate)%"              : "—", color: .green)
                }

                if monthlyIncome == 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill").foregroundColor(.orange).font(.subheadline)
                        Text("Complete your assessment to see financial vitals")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.08)).cornerRadius(12)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis").foregroundColor(.green).font(.subheadline)
                        Text(savingRate >= 30
                             ? "Great! Your \(savingRate)% saving rate is above the recommended 30%."
                             : "Your saving rate is \(savingRate)%. Try to reach at least 30%.")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.green.opacity(0.08)).cornerRadius(12)
                }
            }
            .padding(20).background(AppTheme.cardBackground).cornerRadius(20)
            .shadow(color: AppTheme.adaptiveShadow, radius: 12, x: 0, y: 4)
        }
    }

    private var currentInvestmentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Current Investments").font(.title2).fontWeight(.bold)

            if investments.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray.fill").font(.system(size: 32)).foregroundColor(.secondary)
                    Text("No investments recorded yet").font(.subheadline).fontWeight(.semibold)
                    Text("Add investments during assessment or start a new plan below.")
                        .font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(32)
                .background(AppTheme.cardBackground).cornerRadius(16)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.04), radius: 8, x: 0, y: 2)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(investments.enumerated()), id: \.element.id) { idx, inv in
                        PlannerInvestmentRow(investment: UserInvestment(
                            name: inv.investmentName,
                            amount: Int(inv.investmentAmount),
                            category: plannerCategory(for: inv.investmentType)
                        ))
                        if idx < investments.count - 1 { Divider().padding(.leading, 16) }
                    }
                }
                .background(AppTheme.cardBackground).cornerRadius(16)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.04), radius: 8, x: 0, y: 2)
            }
        }
    }

    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            ActionButton(title: "New Investment Plan", subtitle: "Plan a new investment",
                         icon: "chart.line.uptrend.xyaxis.circle.fill",
                         gradientColors: [.cyan, .indigo],
                         action: { showNewInvestmentPlan = true })
            ActionButton(title: "Company Analysis", subtitle: "Analyse any company",
                         icon: "building.2.fill",
                         gradientColors: [.gray, .green],
                         action: { showCompanyAnalyzer = true })
        }
    }

    private var investmentForecastSection: some View {
        InvestmentForecast(appState: appState)
    }

    private var valueForecastSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Value Forecast").font(.title2).fontWeight(.bold)

            if investments.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "chart.bar.xaxis").font(.system(size: 32)).foregroundColor(.secondary)
                    Text("No data to forecast yet").font(.subheadline).fontWeight(.semibold)
                    Text("Add investments to see projected portfolio growth.")
                        .font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(32)
                .background(AppTheme.cardBackground).cornerRadius(20)
                .shadow(color: AppTheme.adaptiveShadow, radius: 12, x: 0, y: 4)
            } else {
                VStack(spacing: 20) {

                    Picker("Projection Period", selection: $projectionYears) {
                        Text("5 Years").tag(5)
                        Text("10 Years").tag(10)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 4)

                    let barValues: [Double] = (0...projectionYears).map { y in
                        let val = investments.reduce(0) { $0 + projectedValue(for: $1, inYears: y) }
                        return val.isFinite ? val : 0
                    }
                    let maxValRaw = barValues.max() ?? 1
                    let maxVal = maxValRaw > 0 && maxValRaw.isFinite ? maxValRaw : 1

                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach(Array(barValues.enumerated()), id: \.offset) { idx, val in
                            VStack(spacing: 8) {

                                if projectionYears == 5 || idx % 2 == 0 || idx == projectionYears {
                                    Text(val.toCurrency())
                                        .font(.system(size: 7, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }

                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.blue)
                                    .frame(height: max(160 * CGFloat(val / maxVal), 4.0))

                                Text("Y\(idx)")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 190)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar.badge.clock").font(.caption).foregroundColor(.secondary)
                                Text("1 Year Projection").font(.caption).foregroundColor(.secondary)
                            }
                            Text(oneYearProjection.toCurrency()).font(.headline).fontWeight(.bold)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 6) {
                                Text("\(projectionYears) Year Projection").font(.caption).foregroundColor(.secondary)
                                Image(systemName: "calendar.badge.clock").font(.caption).foregroundColor(.secondary)
                            }
                            Text(selectedYearProjection.toCurrency()).font(.headline).fontWeight(.bold).foregroundColor(.accentColor)
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Fund Breakdown (\(projectionYears)Y)").font(.subheadline).fontWeight(.bold).foregroundColor(.secondary)

                        ForEach(investments) { inv in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(inv.investmentName).font(.subheadline).fontWeight(.medium)
                                    Text(inv.mode.rawValue).font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    let projected = projectedValue(for: inv, inYears: projectionYears)
                                    Text(projected.toCurrency()).font(.subheadline).fontWeight(.bold)

                                    let cost = inv.mode == .sip ? (inv.investmentAmount * Double(projectionYears * 12)) : inv.investmentAmount
                                    let growth = cost > 0 ? (projected / cost - 1) * 100 : 0
                                    let safeGrowth = growth.isFinite ? Int(growth) : 0
                                    Text("+\(safeGrowth)% growth").font(.caption).foregroundColor(.green)
                                }
                            }
                            .padding(.vertical, 8)
                            if inv.id != investments.last?.id {
                                Divider().opacity(0.5)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(12)
                }
                .padding(24).background(AppTheme.cardBackground).cornerRadius(24)
                .shadow(color: AppTheme.adaptiveShadow, radius: 15, x: 0, y: 5)
            }
        }
    }

    private func plannerCategory(for type: AstraInvestmentType) -> String {
        switch type {
        case .mutualFund: return "Equity"
        case .stocks:     return "Equity"
        case .deposits:   return "Debt"
        case .goldETF:    return "Commodity"
        case .physicalGold: return "Commodity"
        case .cryptocurrency: return "Crypto"
        case .realEstate: return "Asset"
        case .bonds:      return "Debt"
        case .ppf:        return "Debt"
        case .nps:        return "Debt"
        case .other:      return "Other"
        }
    }
}

struct StrategyChip: View {
    let title: String; let isSelected: Bool; var icon: String = ""
    var body: some View {
        HStack(spacing: 6) {
            if !icon.isEmpty { Image(systemName: icon).font(.caption) }
            Text(title).font(.caption).fontWeight(.medium)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(isSelected ? Color.accentColor : Color(UIColor.secondarySystemFill))
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .cornerRadius(20)
    }
}

struct UserInvestment: Identifiable {
    let id = UUID(); let name: String; let amount: Int; let category: String
}

struct VitalMetric: View {
    let title: String; let value: String; let color: Color; var icon: String = "circle.fill"
    var body: some View {
        VStack(spacing: 8) {
            Text(title).font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
            Text(value).font(.title3).fontWeight(.bold).foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PlannerInvestmentRow: View {
    let investment: UserInvestment
    var categoryColor: Color {
        switch investment.category {
        case "Equity":    return .cyan
        case "Debt":      return .yellow
        case "Commodity": return .yellow
        case "Crypto":    return .orange
        case "Asset":     return .green
        default:          return Color.gray
        }
    }
    var categoryIcon: String {
        switch investment.category {
        case "Equity":    return "chart.line.uptrend.xyaxis"
        case "Debt":      return "building.columns.fill"
        case "Commodity": return "cube.fill"
        case "Crypto":    return "bitcoinsign.circle.fill"
        case "Asset":     return "house.fill"
        default:          return "dollarsign.circle.fill"
        }
    }
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(categoryColor.opacity(0.15)).frame(width: 44, height: 44)
                Image(systemName: categoryIcon).foregroundColor(categoryColor).font(.title3)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(investment.name).font(.subheadline).fontWeight(.medium)
                Text(investment.category).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Text(Double(investment.amount).toCurrency()).font(.headline).fontWeight(.bold)
        }
        .padding(.vertical, 12).padding(.horizontal, 16)
    }
}

struct ActionButton: View {
    let title: String; let subtitle: String; let icon: String
    let gradientColors: [Color]; var action: () -> Void
    @State private var isPressed = false
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = false }
                action()
            }
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 50, height: 50)
                    Image(systemName: icon).foregroundColor(.white).font(.title3)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline).fontWeight(.bold).foregroundColor(.primary)
                    Text(subtitle).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.secondary).font(.subheadline)
            }
            .padding(16)
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
            .shadow(color: AppTheme.adaptiveShadow, radius: isPressed ? 8 : 10, x: 0, y: isPressed ? 2 : 4)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ForecastPill: View {
    let text: String; let isSelected: Bool; let color: Color
    var body: some View {
        Text(text).font(.caption).fontWeight(isSelected ? .semibold : .regular)
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(isSelected ? color : Color(UIColor.secondarySystemFill))
            .cornerRadius(8)
    }
}

struct ForecastDetailRow: View {
    var icon: String = "info.circle"; var iconColor: Color = .blue
    let title: String; let value: String; var isHighlighted: Bool = false
    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.caption).foregroundColor(iconColor)
                Text(title).font(.subheadline).foregroundColor(.secondary)
            }
            Spacer()
            Text(value).font(.subheadline).fontWeight(isHighlighted ? .bold : .semibold)
                .foregroundColor(isHighlighted ? .green : .primary)
        }
    }
}

#Preview {
    NavigationStack {
        PlannerView().environment(AppStateManager.withSampleData())
    }
}

