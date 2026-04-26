import SwiftUI

// RBI benchmark rates for short-duration liquid instruments (updated periodically)
// T-Bills: ~6.9-7.1% (91-day, as of 2024 auctions)
// Savings A/C: ~3.5% (major bank average, per RBI data)
// Sweep-in FD: ~5.0-5.5% (average 7-day sweep, SBI/HDFC/ICICI)
enum EFInstrumentRate {
    static let treasuryBills: Double = 0.069
    static let savingsAccount: Double = 0.035
    static let sweepInFD: Double = 0.052
}

// MARK: - Graph Data Model
struct GraphPoint: Identifiable {
    let id = UUID()
    let month: Int
    let amount: Double
}

// MARK: - Emergency Fund Line Graph
struct EFLineGraphView: View {
    let points: [GraphPoint]
    let target: Double
    let currentSaved: Double
    let accentColor: Color

    private var maxY: Double { max(target * 1.08, 1) }
    private var maxX: Int    { max(points.last?.month ?? 1, 1) }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height - 16   // leave 16pt at bottom for x labels
            let pad: CGFloat = 4

            ZStack(alignment: .topLeading) {
                // Target dashed line (green)
                if target > 0 {
                    let ty = yPos(amount: target, height: h)
                    Path { p in p.move(to: .init(x: pad, y: ty)); p.addLine(to: .init(x: w - pad, y: ty)) }
                        .stroke(Color(hex: "#30D158"), style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
                    Text(target.toCurrency(compact: true))
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: "#30D158"))
                        .position(x: w - 30, y: ty - 9)
                }

                // Current saved dotted line (orange)
                if currentSaved > 0 && currentSaved < target {
                    let cy = yPos(amount: currentSaved, height: h)
                    Path { p in p.move(to: .init(x: pad, y: cy)); p.addLine(to: .init(x: w - pad, y: cy)) }
                        .stroke(Color(hex: "#FF9F0A"), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
                    Text(currentSaved.toCurrency(compact: true))
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "#FF9F0A"))
                        .position(x: 34, y: cy - 9)
                }

                // Area fill
                if points.count > 1 {
                    areaPath(w: w, h: h, pad: pad)
                        .fill(LinearGradient(colors: [accentColor.opacity(0.22), accentColor.opacity(0.03)], startPoint: .top, endPoint: .bottom))
                    linePath(w: w, h: h, pad: pad)
                        .stroke(accentColor, style: StrokeStyle(lineWidth: 2.2, lineJoin: .round))

                    // End dot
                    if let last = points.last {
                        let lx = xPos(month: last.month, w: w, pad: pad)
                        let ly = yPos(amount: last.amount, height: h)
                        Circle().fill(accentColor.opacity(0.22)).frame(width: 16, height: 16).position(x: lx, y: ly)
                        Circle().fill(accentColor).frame(width: 8, height: 8).position(x: lx, y: ly)
                    }
                }

                // Start dot
                if let first = points.first {
                    Circle()
                        .fill(currentSaved > 0 ? Color(hex: "#FF9F0A") : accentColor.opacity(0.5))
                        .frame(width: 7, height: 7)
                        .position(x: xPos(month: first.month, w: w, pad: pad),
                                  y: yPos(amount: first.amount, height: h))
                }

                // X-axis labels
                ForEach(xTicks, id: \.self) { m in
                    Text(m == 0 ? "Now" : "\(m)m")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .position(x: xPos(month: m, w: w, pad: pad), y: h + 10)
                }
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.75), value: points.count)
    }

    private func xPos(month: Int, w: CGFloat, pad: CGFloat) -> CGFloat {
        pad + CGFloat(month) / CGFloat(maxX) * (w - 2 * pad)
    }
    private func yPos(amount: Double, height: CGFloat) -> CGFloat {
        height - CGFloat(amount / maxY) * height
    }
    private func linePath(w: CGFloat, h: CGFloat, pad: CGFloat) -> Path {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: .init(x: xPos(month: first.month, w: w, pad: pad), y: yPos(amount: first.amount, height: h)))
            for pt in points.dropFirst() { path.addLine(to: .init(x: xPos(month: pt.month, w: w, pad: pad), y: yPos(amount: pt.amount, height: h))) }
        }
    }
    private func areaPath(w: CGFloat, h: CGFloat, pad: CGFloat) -> Path {
        Path { path in
            guard let first = points.first else { return }
            let sx = xPos(month: first.month, w: w, pad: pad)
            path.move(to: .init(x: sx, y: h))
            path.addLine(to: .init(x: sx, y: yPos(amount: first.amount, height: h)))
            for pt in points.dropFirst() { path.addLine(to: .init(x: xPos(month: pt.month, w: w, pad: pad), y: yPos(amount: pt.amount, height: h))) }
            if let last = points.last { path.addLine(to: .init(x: xPos(month: last.month, w: w, pad: pad), y: h)) }
            path.closeSubpath()
        }
    }
    private var xTicks: [Int] {
        guard maxX > 0 else { return [0] }
        if maxX <= 6  { return Array(stride(from: 0, through: maxX, by: 1)) }
        if maxX <= 12 { return Array(stride(from: 0, through: maxX, by: 2)) }
        if maxX <= 24 { return Array(stride(from: 0, through: maxX, by: 4)) }
        if maxX <= 60 { return Array(stride(from: 0, through: maxX, by: 6)) }
        return Array(stride(from: 0, through: maxX, by: 12))
    }
}

// MARK: - Emergency Fund Section View
struct EmergencyFundSectionView: View {
    @Environment(AppStateManager.self) var appState
    @Environment(\.colorScheme) var colorScheme

    /// Monthly contribution slider — user drags this to see projection
    @State private var monthlyContribution: Double = 0

    @State private var pTBills:  Double = 0
    @State private var pSavings: Double = 0
    @State private var pSweepFD: Double = 0

    @State private var showManage:         Bool = false
    @State private var showEditSheet:      Bool = false
    @State private var showRecommendSheet: Bool = false

    // MARK: Profile accessors
    private var profile: AstraUserProfile? { appState.currentProfile }
    private var monthlyIncome: Double   { profile?.basicDetails.monthlyIncome ?? 0 }
    private var monthlyExpenses: Double { profile?.basicDetails.monthlyExpenses ?? 0 }
    private var incomeAfterTax: Double  { profile?.basicDetails.monthlyIncomeAfterTax ?? 0 }

    /// What the user has already saved toward emergency fund
    private var currentSaved: Double { profile?.basicDetails.emergencyFundAmount ?? 0 }

    // MARK: Emergency Fund Target Calculation
    // Rule: 6× monthly income (user request)
    // Fallback: 6× monthly expenses
    private var emergencyFundTarget: Double {
        if monthlyIncome > 0   { return monthlyIncome * 6 }
        if monthlyExpenses > 0 { return monthlyExpenses * 6 }
        return 0
    }

    /// Amount still left to save (0 if goal already met)
    private var remainingNeeded: Double { max(0, emergencyFundTarget - currentSaved) }

    private var goalMet: Bool { remainingNeeded <= 0 && emergencyFundTarget > 0 }
    private var hasData: Bool { emergencyFundTarget > 0 }

    // MARK: Surplus & Slider Bounds
    private var monthlySurplus: Double {
        let emi  = profile?.loans.reduce(0.0) { $0 + $1.calculatedEMI } ?? 0
        let base = incomeAfterTax > 0 ? incomeAfterTax : monthlyIncome
        return max(500, base - monthlyExpenses - emi)
    }
    private var sliderMin: Double { 500 }
    private var sliderMax: Double {
        let cap = remainingNeeded > 0 ? min(monthlySurplus, remainingNeeded) : monthlySurplus
        return max(sliderMin + 500, cap)
    }

    // MARK: Timeline
    private var monthsToGoal: Int {
        guard monthlyContribution > 0, remainingNeeded > 0 else { return 0 }
        return Int(ceil(remainingNeeded / monthlyContribution))
    }
    private var completionDate: String {
        guard monthsToGoal > 0 else { return "" }
        let d = Calendar.current.date(byAdding: .month, value: monthsToGoal, to: Date()) ?? Date()
        let df = DateFormatter(); df.dateFormat = "MMM yyyy"
        return df.string(from: d)
    }
    private var progressRatio: Double {
        emergencyFundTarget > 0 ? min(1.0, currentSaved / emergencyFundTarget) : 0
    }

    // MARK: Graph Data
    private var graphPoints: [GraphPoint] {
        guard emergencyFundTarget > 0 else {
            return [GraphPoint(month: 0, amount: currentSaved),
                    GraphPoint(month: 12, amount: currentSaved)]
        }
        guard monthlyContribution > 0 else {
            // Flat line at current saved
            return [GraphPoint(month: 0, amount: currentSaved),
                    GraphPoint(month: 12, amount: currentSaved)]
        }
        let months = min(monthsToGoal, 120)
        return (0...months).map { m in
            GraphPoint(month: m, amount: min(currentSaved + Double(m) * monthlyContribution, emergencyFundTarget))
        }
    }

    // MARK: Allocation
    private var hasAllocation: Bool { profile?.emergencyFundAllocation?.isAllocatedByUser == true }

    private struct InstrumentInfo: Identifiable {
        let id = UUID()
        let name, icon: String; let color: Color
        let pct, annualRate, holding: Double
        var invested: Double     { holding * (pct / 100) }
        var annualReturn: Double { invested * annualRate }
    }
    private var instruments: [InstrumentInfo] {
        [InstrumentInfo(name: "Treasury Bills",  icon: "building.columns.fill", color: Color(hex: "#30D158"), pct: pTBills,  annualRate: EFInstrumentRate.treasuryBills,  holding: currentSaved),
         InstrumentInfo(name: "Saving Account",  icon: "banknote.fill",         color: Color(hex: "#007AFF"), pct: pSavings, annualRate: EFInstrumentRate.savingsAccount, holding: currentSaved),
         InstrumentInfo(name: "Sweep-in FD",     icon: "arrow.2.squarepath",    color: Color(hex: "#FF9F0A"), pct: pSweepFD, annualRate: EFInstrumentRate.sweepInFD,      holding: currentSaved),
        ].filter { $0.invested > 0 }
    }

    // MARK: Body
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerView
            goalSummaryRow
            Divider().padding(.horizontal, -20)
            lineGraphSection
            Divider().padding(.horizontal, -20)
            contributionSliderSection
            Divider().padding(.horizontal, -20)
            allocationRow
            if showManage && hasAllocation {
                allocationBreakdownTable.transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 14, x: 0, y: 5)
        .animation(.spring(response: 0.36, dampingFraction: 0.80), value: showManage)
        .animation(.spring(response: 0.28, dampingFraction: 0.75), value: monthlyContribution)
        .onAppear(perform: syncFromProfile)
        .navigationDestination(isPresented: $showEditSheet){
            ManageAllocationSheet(currentHolding: currentSaved, pTBills: $pTBills, pSavings: $pSavings, pSweepFD: $pSweepFD, onSave: saveAllocation)
                .environment(appState)
        }
        .sheet(isPresented: $showRecommendSheet) {
            AllocationRecommendationSheet(
                currentHolding: currentSaved,
                riskTolerance: profile?.basicDetails.riskTolerance ?? .medium,
                pTBills: $pTBills, pSavings: $pSavings, pSweepFD: $pSweepFD,
                onAccept: { saveAllocation(); showRecommendSheet = false },
                onCustomize: { showRecommendSheet = false; DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showEditSheet = true } }
            )
            .environment(appState)
        }
    }

    // MARK: Header
    private var headerView: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(AppTheme.vibrantCyan.opacity(0.14)).frame(width: 38, height: 38)
                Image(systemName: "shield.lefthalf.filled").font(.system(size: 16, weight: .bold)).foregroundStyle(AppTheme.vibrantCyan)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Emergency Fund").font(.system(size: 17, weight: .bold, design: .rounded))
                Text(statusSubtitle).font(.system(size: 12, design: .rounded)).foregroundStyle(.secondary).contentTransition(.numericText())
            }
            Spacer()
        }
    }
    private var statusSubtitle: String {
        if !hasData          { return "Complete assessment to set goal" }
        if goalMet           { return "Goal reached" }
        if currentSaved == 0 { return "Not started yet" }
        return "\(Int(progressRatio * 100))% of 6-month goal"
    }

    // MARK: Goal Summary Row
    private var goalSummaryRow: some View {
        HStack(spacing: 0) {
            statPill(label: "Target",    value: hasData ? emergencyFundTarget.toCurrency(compact: true) : "—", color: AppTheme.auraIndigo)
            Spacer()
            statPill(label: "Saved",     value: currentSaved.toCurrency(compact: true), color: AppTheme.auraGreen)
            Spacer()
            statPill(label: "Remaining", value: hasData ? remainingNeeded.toCurrency(compact: true) : "—",
                     color: remainingNeeded > 0 ? Color(hex: "#FF9F0A") : AppTheme.auraGreen)
        }
        .padding(.vertical, 4)
    }
    private func statPill(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(color).contentTransition(.numericText())
            Text(label).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
        }
    }

    // MARK: Line Graph Section
    private var lineGraphSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Savings Projection").font(.system(size: 14, weight: .semibold, design: .rounded))
                Spacer()
                if monthsToGoal > 0 {
                    Label(completionDate, systemImage: "flag.checkered")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.auraIndigo)
                }
            }
            EFLineGraphView(points: graphPoints, target: emergencyFundTarget, currentSaved: currentSaved, accentColor: AppTheme.auraIndigo)
                .frame(height: 170)
            HStack(spacing: 16) {
                legendDot(color: AppTheme.auraIndigo,   label: "Projected")
                legendDot(color: Color(hex: "#30D158"), label: "Target")
                if currentSaved > 0 { legendDot(color: Color(hex: "#FF9F0A"), label: "Current") }
            }
        }
    }
    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 5) { Circle().fill(color).frame(width: 7, height: 7); Text(label).font(.system(size: 11, design: .rounded)).foregroundStyle(.secondary) }
    }

    // MARK: Monthly Contribution Slider
    private var contributionSliderSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Monthly Contribution").font(.system(size: 15, weight: .medium))
                    Text("Drag to project your goal timeline").font(.system(size: 11, design: .rounded)).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(monthlyContribution > 0 ? monthlyContribution.toCurrency(compact: true) : "₹0")
                        .font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.auraIndigo).contentTransition(.numericText(countsDown: false))
                    Text("/ month").font(.system(size: 11, design: .rounded)).foregroundStyle(.secondary)
                }
            }
            VStack(spacing: 6) {
                Slider(value: $monthlyContribution, in: hasData ? sliderMin...max(sliderMax, sliderMin + 1) : 500...50000, step: 500)
                    .tint(AppTheme.auraIndigo)
                HStack {
                    Text(sliderMin.toCurrency(compact: true)).font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                    Spacer()
                    if monthlySurplus > 0 {
                        Text("Surplus: \(monthlySurplus.toCurrency(compact: true))/mo").font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(sliderMax.toCurrency(compact: true)).font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                }
            }

            // Result chip
            if monthlyContribution > 0 { timelineChip }
            else if !hasData {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle").font(.system(size: 13)).foregroundStyle(.secondary)
                    Text("Complete your financial assessment to unlock personalised projections").font(.system(size: 12, design: .rounded)).foregroundStyle(.secondary)
                }
                .padding(12).background(Color.secondary.opacity(0.07)).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    private var timelineChip: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill((goalMet ? AppTheme.auraGreen : AppTheme.auraIndigo).opacity(0.12)).frame(width: 36, height: 36)
                Image(systemName: goalMet ? "checkmark.seal.fill" : "calendar.badge.clock")
                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(goalMet ? AppTheme.auraGreen : AppTheme.auraIndigo)
            }
            if goalMet {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Goal Already Achieved!").font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.auraGreen)
                    Text("Consider growing to a 12-month fund.").font(.system(size: 11, design: .rounded)).foregroundStyle(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Achieve goal in **\(monthsToGoal) month\(monthsToGoal == 1 ? "" : "s")**").font(.system(size: 13, weight: .semibold, design: .rounded))
                    Text("By \(completionDate) · Remaining \(remainingNeeded.toCurrency(compact: true))").font(.system(size: 11, design: .rounded)).foregroundStyle(.secondary).contentTransition(.numericText())
                }
            }
            Spacer()
        }
        .padding(12)
        .background((goalMet ? AppTheme.auraGreen : AppTheme.auraIndigo).opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: Allocation Row
    private var allocationRow: some View {
        HStack {
            Text("Allocation").font(.system(size: 15, weight: .medium))
            Spacer()
            if currentSaved == 0 {
                Text("No Allocation").font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(.secondary).padding(.horizontal, 14).padding(.vertical, 7).background(Color.secondary.opacity(0.10)).clipShape(Capsule())
            } else {
                HStack(spacing: 8) {
                    if hasAllocation && showManage {
                        Button { showEditSheet = true } label: { Image(systemName: "pencil.circle.fill").font(.system(size: 22)).foregroundStyle(AppTheme.auraIndigo.opacity(0.8)) }.buttonStyle(PlainButtonStyle())
                    }
                    Button {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                            if hasAllocation { showManage.toggle() } else { showRecommendSheet = true }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(hasAllocation ? (showManage ? "Done" : "Manage") : "Allocate").font(.system(size: 13, weight: .semibold, design: .rounded))
//                            if !(hasAllocation && showManage) { Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold)) }
                        }
                        .foregroundStyle(.white).padding(.horizontal, 14).padding(.vertical, 7).background(AppTheme.auraIndigo).clipShape(Capsule())
                    }.buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    // MARK: Allocation Breakdown
    private var allocationBreakdownTable: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Funds").frame(maxWidth: .infinity, alignment: .leading)
                Text("Invested").frame(width: 76, alignment: .trailing)
                Text("Returns").frame(width: 64, alignment: .trailing)
            }
            .font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(.secondary)
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Color.secondary.opacity(0.06)).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            if instruments.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3").font(.system(size: 22)).foregroundStyle(.secondary)
                    Text("Tap the pencil to set allocation percentages").font(.system(size: 13, design: .rounded)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }.frame(maxWidth: .infinity).padding(.vertical, 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(instruments) { row in
                        instrumentTableRow(row)
                        if row.id != instruments.last?.id { Divider().padding(.leading, 14) }
                    }
                }
                .background(Color.secondary.opacity(0.04)).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                let tI = instruments.reduce(0) { $0 + $1.invested }
                let tR = instruments.reduce(0) { $0 + $1.annualReturn }
                HStack {
                    Text("Total").font(.system(size: 13, weight: .bold, design: .rounded)).frame(maxWidth: .infinity, alignment: .leading)
                    Text(tI.toCurrency(compact: true)).font(.system(size: 13, weight: .bold, design: .rounded)).frame(width: 76, alignment: .trailing).contentTransition(.numericText())
                    Text("+\(tR.toCurrency(compact: true))").font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.auraGreen).frame(width: 64, alignment: .trailing).contentTransition(.numericText())
                }
                .padding(.horizontal, 14).padding(.vertical, 10).background(AppTheme.auraIndigo.opacity(0.06)).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }
    private func instrumentTableRow(_ row: InstrumentInfo) -> some View {
        HStack(spacing: 10) {
            ZStack { Circle().fill(row.color.opacity(0.12)).frame(width: 28, height: 28); Image(systemName: row.icon).font(.system(size: 11, weight: .semibold)).foregroundStyle(row.color) }
            Text(row.name).font(.system(size: 13, weight: .medium, design: .rounded)).frame(maxWidth: .infinity, alignment: .leading).lineLimit(1)
            Text(row.invested.toCurrency(compact: true)).font(.system(size: 13, weight: .semibold, design: .rounded)).frame(width: 76, alignment: .trailing).contentTransition(.numericText())
            Text("+\(row.annualReturn.toCurrency(compact: true))").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(AppTheme.auraGreen).frame(width: 64, alignment: .trailing).contentTransition(.numericText())
        }.padding(.horizontal, 14).padding(.vertical, 11)
    }

    // MARK: Helpers
    private func syncFromProfile() {
        if let a = profile?.emergencyFundAllocation { pTBills = a.treasuryBills; pSavings = a.savingsAccount; pSweepFD = a.sweepInFD }
        // Smart default: 30% of surplus, snapped to nearest ₹500
        if monthlyContribution == 0 && hasData {
            let suggested = (monthlySurplus * 0.30 / 500).rounded() * 500
            monthlyContribution = min(max(sliderMin, suggested), sliderMax)
        }
    }
    private func saveAllocation() {
        guard var p = appState.currentProfile else { return }
        p.emergencyFundAllocation = AstraEmergencyFundAllocation(treasuryBills: pTBills, commercialPapers: 0, savingsAccount: pSavings, sweepInFD: pSweepFD, isAllocatedByUser: true)
        appState.currentProfile = p
    }
}

// MARK: - Manage Allocation Sheet
struct ManageAllocationSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppStateManager.self) var appState

    let currentHolding: Double
    @Binding var pTBills: Double
    @Binding var pSavings: Double
    @Binding var pSweepFD: Double
    var onSave: () -> Void

    private var total: Double { pTBills + pSavings + pSweepFD }

    private var tBillsBinding: Binding<Double> { Binding(get: { pTBills }, set: { pTBills = $0; rebalance(changed: $0, a: $pSavings, b: $pSweepFD) }) }
    private var savingsBinding: Binding<Double> { Binding(get: { pSavings }, set: { pSavings = $0; rebalance(changed: $0, a: $pTBills, b: $pSweepFD) }) }
    private var sweepFDBinding: Binding<Double> { Binding(get: { pSweepFD }, set: { pSweepFD = $0; rebalance(changed: $0, a: $pTBills, b: $pSavings) }) }

    private func rebalance(changed: Double, a: Binding<Double>, b: Binding<Double>) {
        let rem = max(0, 100 - changed)
        let sum = a.wrappedValue + b.wrappedValue
        if sum > 0 { let na = (rem * (a.wrappedValue / sum) / 5).rounded() * 5; a.wrappedValue = max(0, min(rem, na)); b.wrappedValue = max(0, rem - a.wrappedValue) }
        else { let h = (rem / 2 / 5).rounded() * 5; a.wrappedValue = h; b.wrappedValue = rem - h }
    }

    private var blendedReturn: Double { (pTBills/100 * EFInstrumentRate.treasuryBills) + (pSavings/100 * EFInstrumentRate.savingsAccount) + (pSweepFD/100 * EFInstrumentRate.sweepInFD) }
    private var totalAnnualEarnings: Double { currentHolding * blendedReturn }
    private func estReturn(pct: Double, rate: Double) -> String { "Est. return: \(( currentHolding * pct/100 * rate).toCurrency(compact: true))/yr" }

    var body: some View {
        NavigationStack {
            Form {
                Section("Summary") {
                    VStack(alignment: .leading, spacing: 8) {
                        lv("Total Holding", value: currentHolding.toCurrency())
                        lv("Allocated",     value: String(format: "%.0f%%", total),           vc: AppTheme.auraGreen)
                        lv("Unallocated",   value: String(format: "%.0f%%", max(0,100-total)), vc: .secondary)
                    }.padding(.vertical, 4)
                }
                Section { sr("Treasury Bills", sub: String(format: "~%.1f%% p.a. · T+2 liquidity",   EFInstrumentRate.treasuryBills*100),  eR: estReturn(pct: pTBills,  rate: EFInstrumentRate.treasuryBills),  ic: "building.columns.fill", cl: Color(hex: "#30D158"), v: tBillsBinding)
                    sr("Saving Account", sub: String(format: "~%.1f%% p.a. · Instant access",  EFInstrumentRate.savingsAccount*100), eR: estReturn(pct: pSavings, rate: EFInstrumentRate.savingsAccount), ic: "banknote.fill",         cl: Color(hex: "#007AFF"), v: savingsBinding)
                    sr("Sweep-in FD",    sub: String(format: "~%.1f%% p.a. · Next-day access", EFInstrumentRate.sweepInFD*100),      eR: estReturn(pct: pSweepFD, rate: EFInstrumentRate.sweepInFD),      ic: "arrow.2.squarepath",    cl: Color(hex: "#FF9F0A"), v: sweepFDBinding)
                } header: { Text("Instruments") } footer: { Text("Total always stays at 100%.") }

                if currentHolding > 0 {
                    Section("Projected Annual Returns") {
                        pr("Treasury Bills", pct: pTBills,  rate: EFInstrumentRate.treasuryBills,  cl: Color(hex: "#30D158"))
                        pr("Saving Account", pct: pSavings, rate: EFInstrumentRate.savingsAccount, cl: Color(hex: "#007AFF"))
                        pr("Sweep-in FD",    pct: pSweepFD, rate: EFInstrumentRate.sweepInFD,      cl: Color(hex: "#FF9F0A"))
                        Divider()
                        HStack {
                            VStack(alignment: .leading, spacing: 3) { Text("Blended Return").font(.system(size: 13)).foregroundStyle(.secondary); Text(String(format: "~%.2f%% p.a.", blendedReturn*100)).font(.system(size: 17, weight: .bold)).foregroundStyle(AppTheme.auraIndigo).contentTransition(.numericText()) }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 3) { Text("Est. Annual Earnings").font(.system(size: 13)).foregroundStyle(.secondary); Text("+\(totalAnnualEarnings.toCurrency(compact: true))").font(.system(size: 17, weight: .bold)).foregroundStyle(Color(hex: "#30D158")).contentTransition(.numericText()) }
                        }.padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Manage Allocation").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { onSave(); dismiss() }.fontWeight(.semibold) }
            }
        }
    }

    private func lv(_ l: String, value: String, vc: Color = .primary) -> some View {
        HStack { Text(l).foregroundStyle(.secondary); Spacer(); Text(value).fontWeight(.semibold).foregroundStyle(vc) }.font(.subheadline)
    }
    private func sr(_ title: String, sub: String, eR: String, ic: String, cl: Color, v: Binding<Double>) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                ZStack { Circle().fill(cl.opacity(0.14)).frame(width: 32, height: 32); Image(systemName: ic).font(.system(size: 13, weight: .semibold)).foregroundStyle(cl) }
                VStack(alignment: .leading, spacing: 2) { Text(title).font(.system(size: 14, weight: .semibold)); Text(sub).font(.system(size: 11)).foregroundStyle(.secondary); Text(eR).font(.system(size: 11, weight: .medium)).foregroundStyle(cl.opacity(0.85)) }
                Spacer()
                Text(String(format: "%.0f%%", v.wrappedValue)).font(.system(size: 15, weight: .bold, design: .monospaced)).foregroundStyle(cl).frame(width: 44, alignment: .trailing)
            }
            Slider(value: v, in: 0...100, step: 5).tint(cl)
            let amt = currentHolding * (v.wrappedValue / 100)
            if amt > 0 { HStack { Spacer(); Text("= \(amt.toCurrency(compact: true)) invested").font(.system(size: 11)).foregroundStyle(.secondary).contentTransition(.numericText()) } }
        }.padding(.vertical, 4)
    }
    private func pr(_ name: String, pct: Double, rate: Double, cl: Color) -> some View {
        let invested = currentHolding * (pct / 100)
        return HStack {
            Circle().fill(cl).frame(width: 8, height: 8); Text(name).font(.system(size: 13, weight: .medium)); Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if invested > 0 { Text(invested.toCurrency(compact: true)).font(.system(size: 13, weight: .semibold)).contentTransition(.numericText()) } else { Text("—").font(.system(size: 13)).foregroundStyle(.secondary) }
                Text("+\((invested * rate).toCurrency(compact: true))/yr").font(.system(size: 11, weight: .medium)).foregroundStyle(Color(hex: "#30D158")).contentTransition(.numericText())
            }
        }.padding(.vertical, 2)
    }
}

// MARK: - Instrument Info Sheet (private)
private struct InstrumentInfoSheet: View {
    let info: InstrumentInfoContent
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(info.headline).font(.system(size: 15, design: .rounded)).foregroundStyle(.secondary).padding(.horizontal, 20).padding(.top, 8)
                    Text(info.detail).font(.system(size: 15, design: .rounded)).lineSpacing(4).padding(.horizontal, 20)
                    VStack(spacing: 12) {
                        chip(icon: "percent",   label: info.rateNote,      color: Color(hex: "#30D158"))
                        chip(icon: "bolt.fill", label: info.liquidityNote, color: Color(hex: "#007AFF"))
                    }.padding(.horizontal, 20)
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "building.columns").font(.system(size: 13)).foregroundStyle(.secondary).padding(.top, 1)
                        Text("Rates are indicative based on RBI benchmark data and may vary. Always verify current rates with your bank or broker before investing.").font(.system(size: 12, design: .rounded)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }.padding(14).background(Color(.systemFill)).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous)).padding(.horizontal, 20)
                    Spacer(minLength: 32)
                }
            }
            .navigationTitle(info.name).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() }.fontWeight(.semibold) } }
        }
    }
    private func chip(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 10) {
            ZStack { Circle().fill(color.opacity(0.12)).frame(width: 32, height: 32); Image(systemName: icon).font(.system(size: 13, weight: .semibold)).foregroundStyle(color) }
            Text(label).font(.system(size: 13, design: .rounded)).fixedSize(horizontal: false, vertical: true); Spacer()
        }.padding(12).background(color.opacity(0.07)).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Instrument Info Content Model (private)
private struct InstrumentInfoContent: Identifiable {
    var id: String { name }
    let name, headline, detail, rateNote, liquidityNote: String
    static let treasuryBills = InstrumentInfoContent(name: "Treasury Bills (T-Bills)", headline: "Government-backed short-term debt instrument",
        detail: "Treasury Bills are issued by the Reserve Bank of India on behalf of the Government of India. They are zero-coupon securities — bought at a discount and redeemed at face value at maturity.",
        rateNote: "Yield: ~6.9% p.a. (91-day T-Bill, as per RBI auctions)", liquidityNote: "Liquidity: T+2 — proceeds take 2 working days to settle")
    static let savingsAccount = InstrumentInfoContent(name: "Savings Account", headline: "Everyday bank deposit with instant access",
        detail: "A savings account held with a scheduled bank offers the highest liquidity. It is insured up to ₹5 lakh per depositor per bank by DICGC.",
        rateNote: "Interest: ~3.5% p.a. (average across major banks, per RBI data)", liquidityNote: "Liquidity: Instant — available 24/7 through digital channels")
    static let sweepInFD = InstrumentInfoContent(name: "Sweep-in Fixed Deposit", headline: "FD linked to your savings account for auto-sweep",
        detail: "A sweep-in FD automatically transfers excess balance from your savings account into a fixed deposit, earning a higher FD rate.",
        rateNote: "Interest: ~5.2% p.a. (7-day sweep-in average, SBI/HDFC/ICICI)", liquidityNote: "Liquidity: Next-day — broken FD funds credited by next working day")
}

// MARK: - Allocation Recommendation Sheet
struct AllocationRecommendationSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppStateManager.self) var appState

    let currentHolding: Double
    let riskTolerance: AstraRiskTolerance
    @Binding var pTBills: Double; @Binding var pSavings: Double; @Binding var pSweepFD: Double
    var onAccept: () -> Void; var onCustomize: () -> Void

    @State private var activeInfo: InstrumentInfoContent? = nil
    @State private var expandedHowTo: String? = nil
    @State private var activeGuide: HowToInvestGuide? = nil

    private var rec: (t: Double, s: Double, f: Double) { switch riskTolerance { case .low: (20,50,30); case .medium: (35,35,30); case .high: (50,25,25) } }
    private var riskLabel: String { switch riskTolerance { case .low: "Conservative"; case .medium: "Balanced"; case .high: "Growth-oriented" } }
    private var riskColor: Color  { switch riskTolerance { case .low: Color(hex: "#30D158"); case .medium: Color(hex: "#007AFF"); case .high: Color(hex: "#FF9F0A") } }
    private var riskRationale: String { switch riskTolerance {
        case .low:    return "Your profile suggests you prefer safety and instant access."
        case .medium: return "A balanced split gives good liquidity with slightly better returns."
        case .high:   return "You can tolerate lower immediate liquidity for better returns via T-Bills."
    }}
    private var blendedReturn: Double { (rec.t/100*EFInstrumentRate.treasuryBills)+(rec.s/100*EFInstrumentRate.savingsAccount)+(rec.f/100*EFInstrumentRate.sweepInFD) }
    private var annualReturn: Double { currentHolding * blendedReturn }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    profileBadge; rationaleView
                    instrumentsSection
                    returnSummary; actionButtons
                }.padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 32)
            }
            .navigationTitle("Recommended Plan").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
        .sheet(item: $activeGuide) { HowToInvestFullGuideSheet(guide: $0) }
    }

    private var profileBadge: some View {
        HStack(spacing: 12) {
            ZStack { Circle().fill(riskColor.opacity(0.15)).frame(width: 44, height: 44); Image(systemName: riskTolerance == .low ? "tortoise.fill" : riskTolerance == .medium ? "gauge.medium" : "hare.fill").font(.system(size: 18, weight: .semibold)).foregroundStyle(riskColor) }
            VStack(alignment: .leading, spacing: 3) { Text(riskLabel + " Profile").font(.system(size: 16, weight: .bold, design: .rounded)); Text("Based on your financial assessment").font(.system(size: 12, design: .rounded)).foregroundStyle(.secondary) }
            Spacer()
            Text(riskTolerance.rawValue).font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(riskColor).padding(.horizontal, 10).padding(.vertical, 5).background(riskColor.opacity(0.12)).clipShape(Capsule())
        }.padding(16).background(Color.secondary.opacity(0.06)).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var rationaleView: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill").font(.system(size: 13)).foregroundStyle(Color(hex: "#FF9F0A")).padding(.top, 1)
            Text(riskRationale).font(.system(size: 13, design: .rounded)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }.padding(14).background(Color(hex: "#FF9F0A").opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var instrumentsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Suggested Allocation").font(.system(size: 15, weight: .semibold, design: .rounded))
            instrRow(name: "Treasury Bills", icon: "building.columns.fill", color: Color(hex: "#30D158"), pct: rec.t, rate: EFInstrumentRate.treasuryBills,  liq: "T+2 access",     info: .treasuryBills, guide: .treasuryBills)
            instrRow(name: "Saving Account", icon: "banknote.fill",         color: Color(hex: "#007AFF"), pct: rec.s, rate: EFInstrumentRate.savingsAccount, liq: "Instant access", info: .savingsAccount, guide: .savingsAccount)
            instrRow(name: "Sweep-in FD",    icon: "arrow.2.squarepath",    color: Color(hex: "#FF9F0A"), pct: rec.f, rate: EFInstrumentRate.sweepInFD,      liq: "Next-day",       info: .sweepInFD, guide: .sweepInFD)
        }
        .sheet(item: $activeInfo) { InstrumentInfoSheet(info: $0).presentationDetents([.medium]).presentationDragIndicator(.visible) }
    }

    private func instrRow(name: String, icon: String, color: Color, pct: Double, rate: Double, liq: String, info: InstrumentInfoContent, guide: HowToInvestGuide) -> some View {
        let invested = currentHolding * (pct / 100)
        let isExp    = expandedHowTo == name
        return VStack(spacing: 10) {
            HStack(spacing: 12) {
                ZStack { Circle().fill(color.opacity(0.14)).frame(width: 36, height: 36); Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundStyle(color) }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) { Text(name).font(.system(size: 14, weight: .semibold, design: .rounded)); Button { activeInfo = info } label: { Image(systemName: "info.circle").font(.system(size: 14)).foregroundStyle(color.opacity(0.75)) }.buttonStyle(PlainButtonStyle()) }
                    Text(String(format: "%.1f%% p.a. · %@", rate*100, liq)).font(.system(size: 11, design: .rounded)).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.0f%%", pct)).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(color)
                    if invested > 0 { Text(invested.toCurrency(compact: true)).font(.system(size: 11, design: .rounded)).foregroundStyle(.secondary) }
                }
            }
            ProgressView(value: pct/100).progressViewStyle(.linear).tint(color)
            if invested * rate > 0 { HStack { Spacer(); Text("Est. +\((invested*rate).toCurrency(compact: true)) / year").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(color.opacity(0.85)) } }
            Button { withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { expandedHowTo = isExp ? nil : name } } label: {
                HStack(spacing: 4) { Text("How to Invest").font(.system(size: 12, weight: .semibold, design: .rounded)); Image(systemName: isExp ? "chevron.up" : "chevron.right").font(.system(size: 9, weight: .bold)) }.foregroundStyle(color)
            }.buttonStyle(PlainButtonStyle()).frame(maxWidth: .infinity, alignment: .leading)
            if isExp {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(guide.compactSteps.enumerated()), id: \.offset) { i, s in
                        HStack(alignment: .top, spacing: 8) { Text("\(i+1)").font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(.white).frame(width: 18, height: 18).background(color.opacity(0.8)).clipShape(Circle()); Text(s).font(.system(size: 12, design: .rounded)).fixedSize(horizontal: false, vertical: true) }
                    }
                    HStack(alignment: .top, spacing: 6) { Image(systemName: "info.circle.fill").font(.system(size: 11)).foregroundStyle(.secondary).padding(.top, 1); Text(guide.taxNote).font(.system(size: 11, design: .rounded)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true) }
                        .padding(10).background(Color(.systemFill)).clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    Button { activeGuide = guide } label: { HStack(spacing: 4) { Image(systemName: "book.fill").font(.system(size: 11)); Text("View Full Guide").font(.system(size: 12, weight: .semibold, design: .rounded)) }.foregroundStyle(.white).padding(.horizontal, 14).padding(.vertical, 8).background(color).clipShape(Capsule()) }.buttonStyle(PlainButtonStyle())
                }.padding(12).background(color.opacity(0.05)).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous)).transition(.opacity.combined(with: .move(edge: .top)))
            }
        }.padding(14).background(color.opacity(0.05)).clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var returnSummary: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) { Text("Blended Annual Return").font(.system(size: 13, design: .rounded)).foregroundStyle(.secondary); Text(String(format: "~%.2f%% p.a.", blendedReturn*100)).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(riskColor) }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) { Text("Est. Annual Earnings").font(.system(size: 13, design: .rounded)).foregroundStyle(.secondary); Text("+\(annualReturn.toCurrency(compact: true))").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(Color(hex: "#30D158")) }
        }.padding(16).background(Color.secondary.opacity(0.06)).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button { pTBills = rec.t; pSavings = rec.s; pSweepFD = rec.f; onAccept() } label: { Text("Apply This Plan").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 16).background(riskColor).clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous)) }.buttonStyle(PlainButtonStyle())
            Button { pTBills = rec.t; pSavings = rec.s; pSweepFD = rec.f; onCustomize() } label: { Text("Customize Manually").font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundStyle(riskColor).frame(maxWidth: .infinity).padding(.vertical, 14).background(riskColor.opacity(0.10)).clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous)) }.buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - How to Invest Full Guide Sheet
private struct HowToInvestFullGuideSheet: View {
    let guide: HowToInvestGuide
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 12) {
                        ZStack { Circle().fill(guide.color.opacity(0.14)).frame(width: 44, height: 44); Image(systemName: guide.icon).font(.system(size: 18, weight: .semibold)).foregroundStyle(guide.color) }
                        VStack(alignment: .leading, spacing: 3) { Text("How to Invest in").font(.system(size: 13, design: .rounded)).foregroundStyle(.secondary); Text(guide.instrumentName).font(.system(size: 18, weight: .bold, design: .rounded)) }
                    }.padding(.horizontal, 20).padding(.top, 8)
                    ForEach(Array(guide.detailedSteps.enumerated()), id: \.offset) { i, step in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(i+1)").font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(.white).frame(width: 26, height: 26).background(guide.color).clipShape(Circle())
                                VStack(alignment: .leading, spacing: 4) { Text(step.title).font(.system(size: 15, weight: .semibold, design: .rounded)); Text(step.detail).font(.system(size: 14, design: .rounded)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true).lineSpacing(3) }
                            }
                        }.padding(.horizontal, 20)
                        if i < guide.detailedSteps.count-1 { HStack { Rectangle().fill(guide.color.opacity(0.2)).frame(width: 2, height: 12).padding(.leading, 32); Spacer() } }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) { Image(systemName: "building.columns").font(.system(size: 13, weight: .semibold)).foregroundStyle(guide.color); Text("Tax & Regulatory Note").font(.system(size: 14, weight: .semibold, design: .rounded)) }
                        Text(guide.taxNote).font(.system(size: 13, design: .rounded)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true).lineSpacing(3)
                    }.padding(16).background(guide.color.opacity(0.06)).clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous)).padding(.horizontal, 20)
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 12)).foregroundStyle(.secondary).padding(.top, 1)
                        Text("Rates are indicative based on RBI benchmark data and may vary.").font(.system(size: 12, design: .rounded)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }.padding(14).background(Color(.systemFill)).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous)).padding(.horizontal, 20)
                    Spacer(minLength: 32)
                }
            }
            .navigationTitle("Investment Guide").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() }.fontWeight(.semibold) } }
        }
    }
}

// MARK: - Preview
#Preview {
    ScrollView { VStack(spacing: 16) { EmergencyFundSectionView().environment(AppStateManager.withSampleData()) }.padding() }
}
