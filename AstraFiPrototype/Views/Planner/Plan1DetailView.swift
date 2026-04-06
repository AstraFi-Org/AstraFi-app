import SwiftUI

struct Plan1DetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(TrackerViewModel.self) var trackerVM
    @Environment(AppStateManager.self) var appState
    @State private var animateChart = false
    @State private var showingSaveAlert = false
    @State private var alertMessage = ""

    var input: InvestmentPlanInputModel
    var result: Plan1Result
    var isFromTracker: Bool = false

    @State private var currentResult: Plan1Result? = nil
    @State private var selectedRisk: String = ""
    @State private var sipOverride: Double = 0
    @State private var tenureOverride: Int = 0

    private var activeResult: Plan1Result { currentResult ?? result }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 24) {
                    goalProgressCard
                    interactiveAdjusters
                    overviewMetrics
                    riskTypeSection
                    totalInvestmentCard
                    scenarioTable
                    investmentRecommendations
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120) 
            }
            .onChange(of: selectedRisk) { _, _ in
                recalculate()
            }

            if !isFromTracker {
                savePlanFooter
            }
        }
        .alert("Action Successful", isPresented: $showingSaveAlert) {
             Button("View in Tracker") { 
                 appState.showDashboard = true
                 dismiss()
             }
             Button("OK", role: .cancel) { }
        } message: {
             Text(alertMessage)
        }
        .navigationTitle("Investment Recommendation")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            setupInitialValues()
            withAnimation(.easeOut(duration: 1.0)) {
                animateChart = true
            }
        }
    }

    private func setupInitialValues() {
        if selectedRisk.isEmpty {
            selectedRisk = result.portfolio.riskLabel
        }
        if tenureOverride == 0 {
            tenureOverride = result.tenure
        }
        if sipOverride == 0 {
            let targetAmt = InvestmentPlannerEngine.parseAmount(input.targetAmount)
            let lumpsum = InvestmentPlannerEngine.parseAmount(input.savedAmount)
            let currentSip = InvestmentPlannerEngine.parseAmount(input.amount)
            let cagr = result.portfolio.blendedCAGR
            
            let reqSip = InvestmentPlannerEngine.computeRequiredSIP(target: targetAmt, lumpsum: lumpsum, cagr: cagr, years: result.tenure)
            
            if reqSip > currentSip {
                sipOverride = ceil(reqSip / 500.0) * 500.0
            } else {
                sipOverride = currentSip
            }
            
            recalculate()
        }
    }

    private var savePlanFooter: some View {
        let planName = result.name
        let isSaved = trackerVM.savedPlanNames.contains(planName)
        let isFollowed = trackerVM.followedPlanNames.contains(planName)

        return HStack(spacing: 12) {
            Button(action: {
                if isSaved {
                    trackerVM.unsavePlan(planName: planName)
                    alertMessage = "Plan removed."
                } else {
                    trackerVM.savePlan(planName: planName, input: input)
                    alertMessage = "Plan saved to 'Your Plans'."
                }
                showingSaveAlert = true
            }) {
                HStack {
                    Image(systemName: isSaved ? "star.fill" : "star")
                    Text(isSaved ? "Saved" : "Save")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isSaved ? Color.gray.opacity(0.1) : Color.blue.opacity(0.1))
                .foregroundColor(isSaved ? .gray : .blue)
                .cornerRadius(12)
            }

            Button(action: {
                if isFollowed {
                    trackerVM.unfollowPlan(planName: planName)
                    alertMessage = "You stopped following this plan."
                } else {
                    trackerVM.followPlan(planName: planName, input: input)

                    let tAmount = result.projectedValue
                    let tenure = Int(input.timePeriod) ?? 5
                    let targetDate = Calendar.current.date(byAdding: .year, value: tenure, to: Date()) ?? Date()
                    let goalName = input.purposeOfInvestment.isEmpty ? result.name : input.purposeOfInvestment
                    appState.addGoal(AstraGoal(goalName: goalName, targetAmount: tAmount, currentAmount: 0, targetDate: targetDate))

                    alertMessage = "Plan is now active! New goal added to your tracker."
                }
                showingSaveAlert = true
            }) {
                HStack {
                    Image(systemName: isFollowed ? "checkmark.circle.fill" : "plus.circle.fill")
                    Text(isFollowed ? "Following" : "Follow Plan")
                }
                .font(.headline).fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isFollowed ? Color.green : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(20)
        .background(
            ZStack {
                BlurView(style: .systemUltraThinMaterial)
                LinearGradient(colors: [.white.opacity(0.8), .white], startPoint: .top, endPoint: .bottom)
            }
            .ignoresSafeArea()
            .frame(height: 100)
        )
    }

    private var interactiveAdjusters: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.blue)
                Text("Interactive Adjustments")
                    .font(.headline)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Monthly SIP")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("₹\(Int(sipOverride).formatted())")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                Slider(value: $sipOverride, in: 500...500000, step: 500) { _ in
                    recalculate()
                }
                .tint(.blue)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Time Period")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(tenureOverride) Years")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                Slider(value: Binding(get: { Double(tenureOverride) }, set: { tenureOverride = Int($0) }), in: 1...30, step: 1) { _ in
                    recalculate()
                }
                .tint(.blue)
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow, radius: 10, x: 0, y: 4)
    }

    private func recalculate() {
        let newResult = InvestmentPlannerEngine.recalculatePlan1(
            input: input,
            overridenRisk: selectedRisk,
            overridenSIP: sipOverride,
            overridenTenure: tenureOverride
        )
        withAnimation {
            currentResult = newResult
        }
    }

    private var goalProgressCard: some View {
        let target = (Double(input.targetAmount.replacingOccurrences(of: ",", with: "")) ?? 1000000)
        let projected = activeResult.projectedValue
        let progress = Swift.min(projected / Swift.max(1.0, target), 1.0)
        let isMet = projected >= target
        let diff = projected - target

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Goal Progress").font(.subheadline).foregroundColor(.secondary)
                    Text("\(Int(progress * 100))% Achieved")
                        .font(.title2).fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                Spacer()
                Image(systemName: isMet ? "checkmark.seal.fill" : "target")
                    .font(.title)
                    .foregroundColor(isMet ? .green : .cyan)
            }

            ProgressView(value: progress)
                .tint(isMet ? .green : .cyan)
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .padding(.vertical, 4)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current Focus").font(.caption).foregroundColor(.secondary)
                    Text("₹\(formatL_Detail(activeResult.totalInvested)) Invested").font(.footnote).fontWeight(.semibold)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(isMet ? "Surplus" : "Gap").font(.caption).foregroundColor(.secondary)
                    Text("₹\(formatL_Detail(abs(diff)))")
                        .font(.footnote).fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }

            Divider()

            HStack {
                Text("Target: ₹\(formatL_Detail(target))")
                    .font(.caption).fontWeight(.medium).foregroundColor(.secondary)
                Spacer()
                Text("Estimated: ₹\(formatL_Detail(projected))")
                    .font(.caption).fontWeight(.bold).foregroundColor(.primary)
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(24)
        .shadow(color: AppTheme.adaptiveShadow, radius: 15, x: 0, y: 8)
    }

    private var overviewMetrics: some View {
        VStack(spacing: 12) {
            MetricRow(label: "Blended return rate",         value: "\(String(format: "%.1f", activeResult.portfolio.blendedCAGR))%", color: .cyan, icon: "percent")
            MetricRow(label: "Monthly SIP amount",          value: "₹\(Int(sipOverride).formatted())",   color: .blue, icon: "calendar.badge.clock")
            MetricRow(label: "Initial Lumpsum",             value: "₹\(input.savedAmount)",  color: .orange, icon: "arrow.down.circle.fill")
            MetricRow(label: "Projected Goal Value",        value: "₹\(formatL_Detail(activeResult.projectedValue))", color: .purple, icon: "chart.line.uptrend.xyaxis")
            MetricRow(label: "Duration",                    value: "\(tenureOverride) Years", color: .secondary, icon: "clock.fill")
            if !activeResult.reachesGoal {
                MetricRow(label: "Shortfall Amount",        value: "₹\(formatL_Detail(activeResult.shortfall))", color: .red, icon: "exclamationmark.triangle.fill")
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow, radius: 12, x: 0, y: 4)
    }

    private var riskTypeSection: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.cyan)
                        .font(.body)
                    Text("Risk Type : ")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Menu {
                    Button("Low") { selectedRisk = "Low" }
                    Button("Mid") { selectedRisk = "Mid" }
                    Button("High") { selectedRisk = "High" }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedRisk)
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Image(systemName: "chevron.up.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            DonutChartView(segments: activeResult.portfolio.allocations.map { ($0.name, $0.percentage, colorForAsset($0.name)) }, animate: animateChart)
                .frame(height: 260)
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow, radius: 12, x: 0, y: 4)
    }

    private var totalInvestmentCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "indianrupeesign.circle.fill")
                    .foregroundColor(.cyan)
                    .font(.title3)
                HStack {
                    Text("Total Investment : ")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("₹\(formatL_Detail(activeResult.totalInvested))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("(in \(input.timePeriod) years)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            VStack(spacing: 8) {
                ScenarioHeaderRow()
                ForEach(activeResult.scenarios) { scenario in
                    ScenarioDataRow(scenario: scenario.name,
                                    gainLoss: "₹\(formatL_Detail(scenario.gainLoss))",
                                    finalValue: "₹\(formatL_Detail(scenario.finalValue))",
                                    isNegative: scenario.gainLoss < 0)
                }
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow, radius: 12, x: 0, y: 4)
    }

    private var scenarioTable: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                TableHeaderCell(text: "Investment Type", alignment: .leading,  flex: 2.5)
                TableHeaderCell(text: "Invested",        alignment: .trailing, flex: 1.5)
                TableHeaderCell(text: "Expected",        alignment: .trailing, flex: 1.5)
                TableHeaderCell(text: "Risk",            alignment: .trailing, flex: 1.2)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(Color.tableHeaderBackground)

            Group {
                ForEach(activeResult.assets) { asset in
                    InvestmentTableRow(type: asset.name,
                                       invested: "₹\(Int(asset.monthlyInvestment))",
                                       expected: "₹\(formatL_Detail(asset.expectedValue))",
                                       risk: riskText(asset.riskLevel),
                                       riskColor: riskColor(asset.riskLevel))
                    if asset.id != activeResult.assets.last?.id {
                        Divider()
                    }
                }
            }
        }
        .background(Color.subtleBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.tableBorder, lineWidth: 1)
        )
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow, radius: 12, x: 0, y: 4)
    }

    private var investmentRecommendations: some View {
        RecommendedFundsCard(
            title: "Recommended High-Growth Funds",
            funds: [
                RecommendedFund(name: "Axis Bluechip Fund", category: "Large Cap", returns: "14.2% p.a.", risk: "Moderate", icon: "shield.fill"),
                RecommendedFund(name: "ICICI Prudential Flexicap Fund", category: "Flexi Cap", returns: "16.8% p.a.", risk: "Moderate", icon: "chart.bar.fill"),
                RecommendedFund(name: "Nippon India Small Cap Fund", category: "Small Cap", returns: "22.4% p.a.", risk: "Very High", icon: "chart.line.uptrend.xyaxis")
            ]
        )
    }

    private func formatL_Detail(_ value: Double) -> String {
        let v = abs(value)
        if v >= 100000 { return String(format: "%.1fL", value / 100000) }
        if v >= 1000 { return String(format: "%.1fK", value / 1000) }
        return String(format: "%.0f", value)
    }

    private func colorForAsset(_ name: String) -> Color {
        let n = name.lowercased()
        if n.contains("debt") || n.contains("corporate") || n.contains("bond") || n.contains("liquid") { return .cyan }
        if n.contains("small cap") || n.contains("crypto") || n.contains("stocks") { return .red }
        if n.contains("index") || n.contains("bluechip") || n.contains("large") || n.contains("flexi") { return .blue }
        if n.contains("gold") || n.contains("silver") { return .yellow }
        return .orange
    }
}

struct MetricRow: View {
    let label: String
    let value: String
    var color: Color = .primary
    var icon: String = "info.circle"

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundColor(.secondary).font(.system(size: 14))
                Text(label).font(.subheadline).foregroundColor(.secondary)
            }
            Spacer()
            Text(value).font(.subheadline).fontWeight(.bold).foregroundColor(.primary)
        }
    }
}

struct DonutChartView: View {
    let segments: [(String, Double, Color)]
    var animate: Bool

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                    DonutSegment(
                        startAngle: startAngle(for: index),
                        endAngle: endAngle(for: index),
                        color: segment.2,
                        animate: animate
                    )
                }

                Circle()
                    .fill(AppTheme.cardBackground)
                    .frame(width: 100, height: 100)

                VStack(spacing: 2) {
                    Text("100%").font(.title3).fontWeight(.bold)
                    Text("Allocated").font(.caption2).foregroundColor(.secondary)
                }
            }
            .frame(width: 180, height: 180)
            .padding()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(segments, id: \.0) { segment in
                        HStack(spacing: 6) {
                            Circle().fill(segment.2).frame(width: 8, height: 8)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(segment.0).font(.system(size: 10)).foregroundColor(.primary)
                                Text("\(Int(segment.1))%").font(.system(size: 9)).foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    private func startAngle(for index: Int) -> Angle {
        let total = segments.reduce(0.0) { $0 + $1.1 }
        let previous = segments[0..<index].reduce(0.0) { $0 + $1.1 }
        return .degrees(previous / total * 360 - 90)
    }

    private func endAngle(for index: Int) -> Angle {
        let total = segments.reduce(0.0) { $0 + $1.1 }
        let current = segments[0...index].reduce(0.0) { $0 + $1.1 }
        return .degrees(current / total * 360 - 90)
    }
}

struct DonutSegment: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    var animate: Bool

    var body: some View {
        Circle()
            .trim(from: 0, to: animate ? CGFloat((endAngle.degrees - startAngle.degrees) / 360) : 0)
            .stroke(color, style: StrokeStyle(lineWidth: 35, lineCap: .round))
            .frame(width: 180, height: 180)
            .rotationEffect(startAngle)
            .animation(.spring(response: 0.8, dampingFraction: 0.7), value: animate)
    }
}

struct ScenarioHeaderRow: View {
    var body: some View {
        HStack(spacing: 8) {
            Text("Scenario").font(.caption).fontWeight(.semibold).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .leading)
            Text("Gain/Loss").font(.caption).fontWeight(.semibold).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .trailing)
            Text("Final Value").font(.caption).fontWeight(.semibold).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

struct ScenarioDataRow: View {
    let scenario: String
    let gainLoss: String
    let finalValue: String
    let isNegative: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(scenario).font(.caption).foregroundColor(.primary).frame(maxWidth: .infinity, alignment: .leading)
            Text(gainLoss).font(.caption).fontWeight(.semibold).foregroundColor(.primary).frame(maxWidth: .infinity, alignment: .trailing)
            Text(finalValue).font(.caption).fontWeight(.medium).foregroundColor(.primary).frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

struct InvestmentTableRow: View {
    let type: String
    let invested: String
    let expected: String
    let risk: String
    let riskColor: Color

    var body: some View {
        HStack(spacing: 0) {
            Text(type).font(.caption).foregroundColor(.primary).frame(maxWidth: .infinity * 2.5, alignment: .leading)
            Text(invested).font(.caption).foregroundColor(.primary).frame(maxWidth: .infinity * 1.5, alignment: .trailing)
            Text(expected).font(.caption).foregroundColor(.secondary).frame(maxWidth: .infinity * 1.5, alignment: .trailing)
            Text(risk).font(.system(size: 10, weight: .bold)).foregroundColor(riskColor).frame(maxWidth: .infinity * 1.2, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
    }
}

#Preview {
    NavigationStack {
        Plan1DetailView(input: InvestmentPlanInputModel(investmentType: "Monthly", amount: "20,000", liquidity: "High", riskType: "Low", timePeriod: "4", scheduleInvestmentDate: Date(), scheduleSIPDate: Date(), purposeOfInvestment: "Car", targetAmount: "14,80,000", savedAmount: "70,000", hasEmergencyFund: true), result: InvestmentPlannerEngine.generateFullPlan(input: InvestmentPlanInputModel(investmentType: "Monthly", amount: "20,000", liquidity: "High", riskType: "Low", timePeriod: "4", scheduleInvestmentDate: Date(), scheduleSIPDate: Date(), purposeOfInvestment: "Car", targetAmount: "14,80,000", savedAmount: "70,000", hasEmergencyFund: true)).plan1)
    }
    .environment(TrackerViewModel())
    .environment(AppStateManager.withSampleData())
}

