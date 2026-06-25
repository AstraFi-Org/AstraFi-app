import SwiftUI
import Charts

struct Plan1DetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(TrackerViewModel.self) var trackerVM
    @Environment(AppStateManager.self) var appState
    @State private var animateChart = false
    @State private var showingSaveAlert = false
    @State private var alertMessage = ""
    @State private var showAssumptionsAlert = false

    var input: InvestmentPlanInputModel
    var result: Plan1Result
    var isFromTracker: Bool = false

    @State private var currentResult: Plan1Result? = nil
    @State private var selectedRisk: AstraRiskLevel = .mid
    @State private var sipOverride: Double = 0
    @State private var tenureOverride: Int = 0
    @State private var showingAllAssetsInfo = false

    private var activeResult: Plan1Result { currentResult ?? result }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 24) {
                    targetVsEstimatedCard
                    assumptionsWarningSection
                    SIPGrowthComparisonCard(monthlySIP: $sipOverride, investmentYears: $tenureOverride, selectedRisk: $selectedRisk)
                        .frame(maxWidth: .infinity)  
                    //interactiveAdjusters
                    riskTypeSection
                    totalInvestmentCard
                    scenarioTable
                    smartTipSection
                    //investmentRecommendations
                }
                .padding(.horizontal, 16)

                .padding(.bottom, 120) 
                .frame(maxWidth: .infinity)
            }
            .background(AppTheme.appBackground(for: colorScheme))
            .onChange(of: selectedRisk) { _, _ in
                recalculate()
            }
            .onChange(of: sipOverride) { _, _ in
                recalculate()
            }
            .onChange(of: tenureOverride) { _, _ in
                recalculate()
            }

            if !isFromTracker {
                savePlanFooter
            }
        }
        .alert("Action Successful", isPresented: $showingSaveAlert) {
             Button("View in Tracker") { 
                 appState.selectedTab = 2
                 dismiss()
             }
             Button("OK", role: .cancel) { }
        } message: {
             Text(alertMessage)
        }
        .alert("Plan Assumptions", isPresented: $showAssumptionsAlert) {
            Button("Got It", role: .cancel) { }
        } message: {
            Text("Educational illustration only. Not investment advice. Values use fixed CAGR assumptions, reinvestment of returns, and no taxes, fees, or severe market drawdowns unless shown. Actual returns may vary.")
        }
        .navigationTitle("Investment Illustration")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            setupInitialValues()
            withAnimation(.easeOut(duration: 1.0)) {
                animateChart = true
            }
        }
    }

    private func setupInitialValues() {
        // if selectedRisk is default, set to portfolio risk
        // In this case .mid is default, we can leave it or try to map riskLabel
        let portfolioRisk = AstraRiskLevel(rawValue: result.portfolio.riskLabel.lowercased()) ?? .mid
        if selectedRisk == .mid && portfolioRisk != .mid {
            selectedRisk = portfolioRisk
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
        let purpose = input.purposeOfInvestment.isEmpty ? "General" : input.purposeOfInvestment
        let planName = "Pure Investment - \(purpose)"
        let isSaved = trackerVM.savedPlanNames.contains(planName)
        let isFollowed = trackerVM.followedPlanNames.contains(planName)

        return HStack(spacing: 12) {
            Button(action: {
                if isSaved {
                    trackerVM.unsavePlan(planName: planName)
                    alertMessage = "Plan removed."
                } else {
                    var inputToSave = input
                    inputToSave.amount = String(Int(sipOverride))
                    inputToSave.timePeriod = String(tenureOverride)
                    inputToSave.riskType = selectedRisk.rawValue.capitalized
                    trackerVM.savePlan(planName: planName, input: inputToSave)
                    alertMessage = "Plan saved to 'Saved Illustrations'."
                }
                showingSaveAlert = true
            }) {
                HStack {
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
                    var inputToFollow = input
                    inputToFollow.amount = String(Int(sipOverride))
                    inputToFollow.timePeriod = String(tenureOverride)
                    inputToFollow.riskType = selectedRisk.rawValue.capitalized
                    trackerVM.followPlan(planName: planName, input: inputToFollow)
                    alertMessage = "Plan added to Followed Plans."
                }
                showingSaveAlert = true
            }) {
                HStack {
                    Text(isFollowed ? "Following" : "Follow")
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
                LinearGradient(colors: [Color(UIColor.systemBackground).opacity(0.6), Color(UIColor.systemBackground)], startPoint: .top, endPoint: .bottom)
            }
            .ignoresSafeArea()
            .frame(height: 100)
        )
    }

//    private var interactiveAdjusters: some View {
//        VStack(spacing: 20) {
//            HStack {
//                Image(systemName: "slider.horizontal.3")
//                    .foregroundColor(.blue)
//                Text("Interactive Adjustments")
//                    .font(.headline)
//                Spacer()
//            }
//            
//            Text("We think you need to maintain this SIP for the given timeline. You can adjust the timeline or SIP amount below to see how it impacts your projected corpus.")
//                .font(.footnote)
//                .foregroundColor(.secondary)
//                .frame(maxWidth: .infinity, alignment: .leading)
//
//            VStack(alignment: .leading, spacing: 10) {
//                HStack {
//                    Text("Monthly SIP")
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                    Spacer()
//                    Text("₹\(Int(sipOverride).formatted())")
//                        .font(.subheadline)
//                        .fontWeight(.bold)
//                        .foregroundColor(.blue)
//                }
//                Slider(value: $sipOverride, in: 500...500000, step: 500) { _ in
//                    recalculate()
//                }
//                .tint(.blue)
//            }
//
//            VStack(alignment: .leading, spacing: 10) {
//                HStack {
//                    Text("Time Period")
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                    Spacer()
//                    Text("\(tenureOverride) Years")
//                        .font(.subheadline)
//                        .fontWeight(.bold)
//                        .foregroundColor(.blue)
//                }
//                Slider(value: Binding(get: { Double(tenureOverride) }, set: { tenureOverride = Int($0) }), in: 1...30, step: 1) { _ in
//                    recalculate()
//                }
//                .tint(.blue)
//            }
//        }
//        .padding(20)
//        .background(AppTheme.cardBackground)
//        .cornerRadius(20)
//        .shadow(color: AppTheme.adaptiveShadow, radius: 10, x: 0, y: 4)
//    }

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

    private var targetVsEstimatedCard: some View {
        let target = InvestmentPlannerEngine.parseAmount(input.targetAmount)
        let projected = activeResult.projectedValue
        
        return HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Target Amount")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("₹\(formatL_Detail(target))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
            .shadow(color: AppTheme.adaptiveShadow.opacity(0.3), radius: 6)

            VStack(alignment: .leading, spacing: 8) {
                Text("Estimated Corpus")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("₹\(formatL_Detail(projected))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
            .shadow(color: AppTheme.adaptiveShadow.opacity(0.3), radius: 6)
        }
    }

    private var assumptionsWarningSection: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Important Notice")
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text("Educational illustration only. This is not investment advice; actual returns, taxes, fees, and market conditions may change the outcome.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            Button(action: {
                showAssumptionsAlert = true
            }) {
                Image(systemName: "info.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(16)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    private var riskTypePicker: some View {
        HStack {
            HStack(spacing: 6) {
//                Image(systemName: "chart.bar.fill")
//                    .foregroundColor(.cyan)
//                    .font(.body)
                Text("Risk Type  ")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Menu {
                Button("Low") { selectedRisk = .low }
                Button("Mid") { selectedRisk = .mid }
                Button("High") { selectedRisk = .high }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedRisk.rawValue.capitalized)
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10))
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .cornerRadius(8)
            }
        }
    }

    private var riskTypeSection: some View {
        VStack(spacing: 16) {
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
        .sheet(isPresented: $showingAllAssetsInfo) {
            AllAssetsInfoSheet(assets: activeResult.assets)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var scenarioTable: some View {
        VStack(spacing: 24) {
            riskTypePicker

            VStack(alignment: .leading, spacing: 16) {
                // Section Title
                HStack(spacing: 8) {
                    Image(systemName: "safari.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                    Text("Illustrative Allocation")
                        .font(.title3)
                        .fontWeight(.black)
                    Spacer()
                    Button(action: { showingAllAssetsInfo = true }) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.blue.opacity(0.8))
                    }
                }
                .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    // Table Headers
                    HStack(spacing: 4) {
                        Text("Asset Category").font(.system(size: 10, weight: .bold)).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                        Text("Allocation").font(.system(size: 10, weight: .bold)).foregroundColor(.secondary).frame(width: 70, alignment: .trailing)
                        Text("Role").font(.system(size: 10, weight: .bold)).foregroundColor(.secondary).frame(width: 80, alignment: .trailing)
                        Text("Risk").font(.system(size: 10, weight: .bold)).foregroundColor(.secondary).frame(width: 50, alignment: .trailing)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.secondary.opacity(0.03))

                    // Table Content
                    VStack(spacing: 0) {
                        ForEach(activeResult.assets) { asset in
                            InvestmentTableRow(asset: asset,
                                               invested: "₹\(formatL_Detail(asset.monthlyInvestment))",
                                               expected: "₹\(formatL_Detail(asset.expectedValue))")
                                .padding(.horizontal, 12)
                            
                            if asset.id != activeResult.assets.last?.id {
                                Divider().padding(.horizontal, 16)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Strategy Insight Card (Footer)
                    HStack(spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 14))
                        
                        Text(selectedRisk.insightText)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.05))
                }
                .background(AppTheme.cardBackground)
                .cornerRadius(20)
                .shadow(color: AppTheme.adaptiveShadow.opacity(0.1), radius: 10)
            }
        }
    }

    private var smartTipSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Smart Tips for Better Growth")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                        .padding(.top, 2)
                    Text("Review your investments periodically. Any extra lumpsum should be based on your surplus, emergency fund, and risk comfort.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .foregroundColor(.green)
                        .frame(width: 20)
                        .padding(.top, 2)
                    Text("Consider testing a SIP step-up when income increases to see how it may affect the goal timeline.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "crown.fill")
                    .foregroundColor(.purple)
                    .font(.title3)
                Text("\(Text("To unlock advanced scenario insights, assumption controls, and automated step-up reminders, upgrade to ").foregroundColor(.secondary))\(Text("AstraPremium.").fontWeight(.bold).foregroundColor(.purple))")
                    .font(.caption)
            }
            .padding(12)
            .background(Color.purple.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow, radius: 10, x: 0, y: 4)
    }

//    private var investmentRecommendations: some View {
//        RecommendedFundsCard(
//            title: "Recommended High-Growth Funds",
//            funds: [
//                RecommendedFund(name: "Axis Bluechip Fund", category: "Large Cap", returns: "14.2% p.a.", risk: "Moderate"),
//                RecommendedFund(name: "ICICI Prudential Flexicap Fund", category: "Flexi Cap", returns: "16.8% p.a.", risk: "Moderate"),
//                RecommendedFund(name: "Nippon India Small Cap Fund", category: "Small Cap", returns: "22.4% p.a.", risk: "Very High")
//            ]
//        )
//    }

    private func formatL_Detail(_ value: Double) -> String {
        let v = abs(value)
        if v >= 10000000 { return String(format: "%.1fCr", value / 10000000) }
        if v >= 100000 { return String(format: "%.1fL", value / 100000) }
        if v >= 1000 { return String(format: "%.1fK", value / 1000) }
        return String(format: "%.0f", value)
    }

    private func colorForAsset(_ name: String) -> Color {
        let n = name.lowercased()
        if n.contains("debt") || n.contains("corporate") || n.contains("bond") || n.contains("liquid") || n.contains("savings") { return .cyan }
        if n.contains("small cap") || n.contains("crypto") || n.contains("thematic") || n.contains("aggressive") { return .red }
        if n.contains("mid cap") || n.contains("multi-cap") || n.contains("flexi") || n.contains("growth") { return .orange }
        if n.contains("large cap") || n.contains("index") || n.contains("bluechip") || n.contains("stable") { return .blue }
        if n.contains("gold") || n.contains("silver") { return .yellow }
        if n.contains("stocks") { return .red } // Default stocks to red (high risk)
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
                Chart {
                    ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                        SectorMark(
                            angle: .value("Allocation", animate ? segment.1 : 0),
                            innerRadius: .ratio(0.62),
                            angularInset: 1.5
                        )
                        .foregroundStyle(segment.2)
                        .cornerRadius(6)
                    }
                }
                .chartLegend(.hidden)
                .frame(width: 180, height: 180)
                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: animate)

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

    private var totalAllocation: Double {
        segments.reduce(0) { $0 + $1.1 }
    }
}

#Preview {
    NavigationStack {
        Plan1DetailView(input: InvestmentPlanInputModel(investmentType: "Monthly", amount: "20,000", liquidity: "High", riskType: "Low", timePeriod: "4", scheduleInvestmentDate: Date(), scheduleSIPDate: Date(), purposeOfInvestment: "Car", targetAmount: "14,80,000", savedAmount: "70,000", hasEmergencyFund: true), result: InvestmentPlannerEngine.generateFullPlan(input: InvestmentPlanInputModel(investmentType: "Monthly", amount: "20,000", liquidity: "High", riskType: "Low", timePeriod: "4", scheduleInvestmentDate: Date(), scheduleSIPDate: Date(), purposeOfInvestment: "Car", targetAmount: "14,80,000", savedAmount: "70,000", hasEmergencyFund: true)).plan1)
    }
    .environment(TrackerViewModel())
    .environment(AppStateManager.withSampleData())
}
