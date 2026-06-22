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

    private var monthlyIncome:   Double { profile?.basicDetails.monthlyIncome ?? 0 }
    private var monthlyExpenses: Double { profile?.basicDetails.monthlyExpenses ?? 0 }
    private var savingRate:      Int    {
        guard monthlyIncome > 0 else { return 0 }
        return (((monthlyIncome - monthlyExpenses) / monthlyIncome) * 100).safeInt
    }

    private var totalInvested: Double { investments.reduce(0) { $0 + $1.investmentAmount } }

    private func projectedValue(for inv: AstraInvestment, inYears years: Int) -> Double {
        let annualRate = inv.expectedAnnualRate
        let monthlyRate = annualRate / 12
        let months = Double(years * 12)
        var result: Double
        if inv.mode == .sip {
            if monthlyRate == 0 {
                result = inv.investmentAmount * months
            } else {
                let pqr = pow(1 + monthlyRate, months)
                if pqr.isFinite {
                    result = inv.investmentAmount * ((pqr - 1) / monthlyRate) * (1 + monthlyRate)
                } else {
                    result = inv.investmentAmount * 1_000_000
                }
            }
        } else {
            // Matching detail view logic usually implies monthly or annual.
            // Stick to monthly compounding for consistency.
            let pqrMonthly = pow(1 + monthlyRate, months)
            if pqrMonthly.isFinite {
                result = inv.investmentAmount * pqrMonthly
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
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                // MARK: - Financial Vitals Card
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.auraIndigo)
                        Text("Financial Vitals")
                            .font(.system(size: 20, weight: .bold))
                    }

                    VStack(spacing: 14) {
                        HStack(spacing: 10) {
                            PlannerVitalTile(
                                title: "Monthly Income",
                                value: monthlyIncome > 0 ? monthlyIncome.toCurrency() : "—",
                                icon: "arrow.down.circle.fill",
                                color: AppTheme.auraIndigo
                            )
                            NavigationLink(destination: SpendingInsightsView()) {
                                PlannerVitalTile(
                                    title: "Expenses",
                                    value: monthlyExpenses > 0 ? monthlyExpenses.toCurrency() : "—",
                                    icon: "arrow.up.circle.fill",
                                    color: Color(hex: "#FF453A"),
                                    hasChevron: true
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            PlannerVitalTile(
                                title: "Saving Rate",
                                value: savingRate > 0 ? "\(savingRate)%" : "—",
                                icon: "percent",
                                color: AppTheme.auraGreen
                            )
                        }

                        HStack(spacing: 10) {
                            if monthlyIncome == 0 {
                                Image(systemName: "info.circle.fill")
                                    .foregroundStyle(Color(hex: "#FF9F0A"))
                                    .font(.system(size: 14))
                                Text("Complete your assessment to see financial vitals")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                            } else {
                                Image(systemName: savingRate >= 30 ? "checkmark.seal.fill" : "chart.line.uptrend.xyaxis")
                                    .foregroundStyle(savingRate >= 30 ? AppTheme.auraGreen : Color(hex: "#FF9F0A"))
                                    .font(.system(size: 14))
                                Text(savingRate >= 30
                                     ? "Great! Your \(savingRate)% saving rate is above the recommended 30%."
                                     : "Your saving rate is \(savingRate)%. Try to reach at least 30%.")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            (monthlyIncome == 0
                             ? Color(hex: "#FF9F0A")
                             : (savingRate >= 30 ? AppTheme.auraGreen : Color(hex: "#FF9F0A"))
                            ).opacity(0.08)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(18)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: AppTheme.adaptiveShadow, radius: 14, x: 0, y: 5)
                }

                
                // MARK: - EmergencyFund
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.vibrantCyan)
                        Text("Emergency Fund")
                            .font(.system(size: 20, weight: .bold))
                    }
                    EmergencyFundSectionView()
                }
                //New Investment plan and Company Analysis
                actionButtonsSection
                
                // MARK: - Value Forecast
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.bar.xaxis.ascending.badge.clock")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.auraGold)
                        Text("Value Forecast")
                            .font(.system(size: 20, weight: .bold))
                    }

                    if investments.isEmpty {
                        VStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.secondary.opacity(0.08))
                                    .frame(width: 60, height: 60)
                                Image(systemName: "chart.bar.xaxis")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.secondary)
                            }
                            VStack(spacing: 4) {
                                Text("No data to forecast yet")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("Add investments to see projected portfolio growth.")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: AppTheme.adaptiveShadow, radius: 12, x: 0, y: 4)
                    } else {
                        VStack(spacing: 20) {
                            // Segmented year picker
                            HStack(spacing: 8) {
                                ForEach([5, 10], id: \.self) { yr in
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            projectionYears = yr
                                        }
                                    } label: {
                                        Text("\(yr) Years")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(projectionYears == yr ? .white : .secondary)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 8)
                                            .background(
                                                projectionYears == yr
                                                    ? AppTheme.auraIndigo
                                                    : Color(UIColor.secondarySystemFill)
                                            )
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                Spacer()
                            }

                            // Bar chart
                            let barValues: [Double] = (0...projectionYears).map { y in
                                let val = investments.reduce(0) { $0 + projectedValue(for: $1, inYears: y) }
                                return val.isFinite ? val : 0
                            }
                            let maxValRaw = barValues.max() ?? 1
                            let maxVal = maxValRaw > 0 && maxValRaw.isFinite ? maxValRaw : 1

                            HStack(alignment: .bottom, spacing: 5) {
                                ForEach(Array(barValues.enumerated()), id: \.offset) { idx, val in
                                    VStack(spacing: 6) {
                                        if projectionYears == 5 || idx % 2 == 0 || idx == projectionYears {
                                            Text(val.toShortCurrencyPlan())
                                                .font(.system(size: 7, weight: .semibold))
                                                .foregroundStyle(.secondary)
                                        }
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [AppTheme.auraIndigo, Color(hex: "#5E5CE6")],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                            .frame(height: max(160 * CGFloat(val / maxVal), 4.0))
                                            .opacity(idx == projectionYears ? 1.0 : 0.4 + 0.5 * Double(idx) / Double(max(projectionYears, 1)))
                                        Text("Y\(idx)")
                                            .font(.system(size: 9, weight: .medium))
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .frame(height: 200)
                            .padding(.horizontal, 4)

                            // Summary pills
                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "calendar")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.secondary)
                                        Text("1 Year")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.secondary)
                                    }
                                    Text(oneYearProjection.toCurrency())
                                        .font(.system(size: 15, weight: .bold))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(Color(UIColor.secondarySystemFill))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "calendar.badge.clock")
                                            .font(.system(size: 10))
                                            .foregroundStyle(AppTheme.auraIndigo)
                                        Text("\(projectionYears) Years")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.secondary)
                                    }
                                    Text(selectedYearProjection.toCurrency())
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(AppTheme.auraIndigo)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(AppTheme.auraIndigo.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }

                            Divider().opacity(0.5)

                            // Fund breakdown
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Fund Breakdown (\(projectionYears)Y)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)
                                    .tracking(0.8)

                                ForEach(investments) { inv in
                                    HStack(spacing: 12) {
                                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                                            .fill(AppTheme.auraIndigo.opacity(0.75))
                                            .frame(width: 3, height: 36)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(inv.investmentName)
                                                .font(.system(size: 14, weight: .medium))
                                                .lineLimit(1)
                                            Text(inv.mode.rawValue)
                                                .font(.system(size: 12))
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()

                                        VStack(alignment: .trailing, spacing: 2) {
                                            let projected = projectedValue(for: inv, inYears: projectionYears)
                                            Text(projected.toCurrency())
                                                .font(.system(size: 14, weight: .bold))

                                            HStack(spacing: 4) {
                                                Text("Forecast:")
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(.secondary)
                                                Text("+\((inv.expectedAnnualRate * 100).safeInt)% p.a.")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundStyle(AppTheme.auraGreen)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 2)

                                    if inv.id != investments.last?.id {
                                        Divider().opacity(0.4)
                                    }
                                }
                            }
                            .padding(14)
                            .background(Color(UIColor.secondarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .padding(22)
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .shadow(color: AppTheme.adaptiveShadow, radius: 16, x: 0, y: 6)
                    }
                }

                //investment Forecast
                //InvestmentForecast(appState: appState)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .navigationTitle("Planner")
        .navigationBarTitleDisplayMode(.large)
        .background(AppTheme.appBackground(for: colorScheme))
        .navigationDestination(isPresented: $showNewInvestmentPlan) { GoalSelectionView() }
        .sheet(isPresented: $showCompanyAnalyzer)  { CompanyAnalyzerView() }
    }
    // MARK: - Action Buttons
    private var actionButtonsSection: some View {
        VStack(spacing: 10) {
            ActionButton(
                title: "New Investment Plan",
                subtitle: "Plan a new investment strategy",
                icon: "chart.line.uptrend.xyaxis.circle.fill",
                gradientColors: [Color(hex: "#007AFF"), Color(hex: "#5E5CE6")],
                action: { showNewInvestmentPlan = true }
            )
//            ActionButton(
//                title: "Company Analysis",
//                subtitle: "Analyse any listed company",
//                icon: "building.2.fill",
//                gradientColors: [Color(hex: "#30D158"), Color(hex: "#00C7BE")],
//                action: { showCompanyAnalyzer = true }
//            )
        }
    }

    private func plannerCategory(for type: AstraInvestmentType) -> String {
        switch type {
        case .mutualFund:     return "Equity"
        case .stocks:         return "Equity"
        case .deposits:       return "Debt"
        case .goldETF:        return "Commodity"
        case .physicalGold:   return "Commodity"
        case .cryptocurrency: return "Crypto"
        case .realEstate:     return "Asset"
        case .bonds:          return "Debt"
        case .ppf:            return "Debt"
        case .nps:            return "Debt"
        case .cashSavings:    return "Cash"
        case .emergencyFund:  return "Cash"
        case .other:          return "Other"
        }
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
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: gradientColors),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    Image(systemName: icon)
                        .foregroundStyle(.white)
                        .font(.system(size: 20, weight: .semibold))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(16)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: AppTheme.adaptiveShadow, radius: isPressed ? 6 : 12, x: 0, y: isPressed ? 2 : 5)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Short currency helper for bar chart labels
private extension Double {
    func toShortCurrencyPlan() -> String {
        let absVal = abs(self)
        if absVal >= 10_000_000 { return String(format: "%.1fCr", absVal / 10_000_000) }
        if absVal >= 100_000    { return String(format: "%.0fL", absVal / 100_000) }
        if absVal >= 1_000      { return String(format: "%.0fK", absVal / 1_000) }
        return String(format: "%.0f", absVal)
    }
}


#Preview {
    NavigationStack {
        PlannerView().environment(AppStateManager.withSampleData())
    }
}
