import SwiftUI

// RBI benchmark rates for short-duration liquid instruments (updated periodically)
// T-Bills: ~6.9-7.1% (91-day, as of 2024 auctions)
// Savings A/C: ~3.5% (major bank average, per RBI data)
// Sweep-in FD: ~5.0-5.5% (average 7-day sweep, SBI/HDFC/ICICI)
enum EFInstrumentRate {
    static let treasuryBills: Double = 0.069   // 91-day T-Bill yield
    static let savingsAccount: Double = 0.035  // Major bank savings rate
    static let sweepInFD: Double = 0.052       // 7-day sweep-in FD average
}

// MARK: - Emergency Fund Section View
struct EmergencyFundSectionView: View {
    @Environment(AppStateManager.self) var appState
    @Environment(\.colorScheme) var colorScheme

    // MARK: Interactive slider state — drives holding & all downstream calculations
    @State private var sliderHolding: Double = 0   // updated live as user drags

    // Allocation percentages
    @State private var pTBills:  Double = 0
    @State private var pSavings: Double = 0
    @State private var pSweepFD: Double = 0

    @State private var showManage:         Bool = false
    @State private var showEditSheet:      Bool = false
    @State private var showRecommendSheet: Bool = false
    @State private var isDragging:         Bool = false

    // MARK: - Profile accessors
    private var profile: AstraUserProfile? { appState.currentProfile }
    private var monthlyIncome: Double      { profile?.basicDetails.monthlyIncome ?? 0 }

    // Targets based on income — zero when income unknown so UI hides goal-dependent UI
    private var target6M:  Double { monthlyIncome * 6  }
    private var target12M: Double { monthlyIncome * 12 }
    private var hasIncomeData: Bool { monthlyIncome > 0 }

    // Slider bounds: always start from 0 so user can build from scratch
    private var sliderMin: Double { 0 }
    // When income unknown, use a reasonable 12L default max so slider is usable
    private var sliderMax: Double { target12M > 0 ? target12M : 1_200_000 }

    private var hasAllocation: Bool {
        profile?.emergencyFundAllocation?.isAllocatedByUser == true
    }

    // MARK: - Live-computed instrument breakdown using sliderHolding
    private struct InstrumentInfo: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let color: Color
        let pct: Double           // 0-100
        let annualRate: Double    // e.g. 0.069
        let holding: Double       // live holding amount

        var invested: Double { holding * (pct / 100) }
        var annualReturn: Double { invested * annualRate }
    }

    private var instruments: [InstrumentInfo] {
        [
            InstrumentInfo(name: "Treasury Bills",  icon: "building.columns.fill", color: Color(hex: "#30D158"), pct: pTBills,  annualRate: EFInstrumentRate.treasuryBills,   holding: sliderHolding),
            InstrumentInfo(name: "Saving Account",  icon: "banknote.fill",         color: Color(hex: "#007AFF"), pct: pSavings, annualRate: EFInstrumentRate.savingsAccount,  holding: sliderHolding),
            InstrumentInfo(name: "Sweep-in FD",     icon: "arrow.2.squarepath",    color: Color(hex: "#FF9F0A"), pct: pSweepFD, annualRate: EFInstrumentRate.sweepInFD,       holding: sliderHolding),
        ].filter { $0.invested > 0 }
    }

    // Months to reach 6M target given a monthly saving amount
    private func monthsToTarget(savingPerMonth: Double) -> Int? {
        guard savingPerMonth > 0, target6M > sliderHolding else { return nil }
        let needed = target6M - sliderHolding
        return Int(ceil(needed / savingPerMonth))
    }

    // Actual monthly surplus from assessment: incomeAfterTax - expenses.
    // Falls back to nil if income not yet entered — hides tip entirely.
    private var monthlySurplus: Double? {
        guard let profile = profile else { return nil }
        let income = profile.basicDetails.monthlyIncomeAfterTax
        let expenses = profile.basicDetails.monthlyExpenses
        guard income > 0 else { return nil }
        let surplus = income - expenses
        // Recommend dedicating surplus to emergency fund until goal is met
        return surplus > 0 ? surplus : nil
    }

    // Portion of surplus suggested for emergency fund:
    // If surplus > 0 and EF not yet at 6M target → recommend 30% of surplus
    // (standard personal-finance rule: 30% savings split toward safety first)
    private var suggestedMonthlySaving: Double? {
        guard let surplus = monthlySurplus else { return nil }
        let suggested = surplus * 0.30
        return suggested > 0 ? suggested : nil
    }

    // Progress toward 6-month target (0…1)
    private var progressRatio: Double {
        target6M > 0 ? min(1.0, sliderHolding / target6M) : 0
    }

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HeaderView
            holdingSliderSection   // ← interactive slider
            Divider().padding(.horizontal, -20)
            allocationRow

            if showManage && hasAllocation {
                allocationBreakdownTable
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            if hasIncomeData && sliderHolding < target6M {
                recommendationTip   // recalculates live — only shown when income known
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 14, x: 0, y: 5)
        .animation(.spring(response: 0.36, dampingFraction: 0.80), value: showManage)
        .animation(.spring(response: 0.28, dampingFraction: 0.75), value: sliderHolding)
        .onAppear(perform: syncFromProfile)
        .sheet(isPresented: $showEditSheet) {
            ManageAllocationSheet(
                currentHolding: sliderHolding,
                pTBills:  $pTBills,
                pSavings: $pSavings,
                pSweepFD: $pSweepFD,
                onSave:   saveAllocation
            )
            .environment(appState)
        }
        .sheet(isPresented: $showRecommendSheet) {
            AllocationRecommendationSheet(
                currentHolding: sliderHolding,
                riskTolerance: profile?.basicDetails.riskTolerance ?? .medium,
                pTBills:  $pTBills,
                pSavings: $pSavings,
                pSweepFD: $pSweepFD,
                onAccept: {
                    saveAllocation()
                    showRecommendSheet = false
                },
                onCustomize: {
                    showRecommendSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showEditSheet = true
                    }
                }
            )
            .environment(appState)
        }
    }

    // MARK: - Header
    private var HeaderView: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(AppTheme.vibrantCyan.opacity(0.14))
                    .frame(width: 38, height: 38)
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.vibrantCyan)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Emergency Fund")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                Text(statusSubtitle)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
            Spacer()
        }
    }

    private var statusSubtitle: String {
        if sliderHolding == 0 && !hasIncomeData { return "Complete assessment to set goal" }
        if sliderHolding == 0 { return "Not started yet" }
        guard hasIncomeData else { return "₹\(Int(sliderHolding).formatted()) saved" }
        if sliderHolding >= target6M { return "Goal reached 🎉" }
        let pct = Int(progressRatio * 100)
        return "\(pct)% of 6-month goal"
    }

    // MARK: - Holding + Interactive Slider
    private var holdingSliderSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Label + live value
            HStack(alignment: .firstTextBaseline) {
                Text("Current Holding")
                    .font(.system(size: 15, weight: .medium))
                VStack(alignment: .trailing, spacing: 2) {
                    Text(sliderHolding.toCurrency(compact: true))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.auraIndigo)
                        .contentTransition(.numericText(countsDown: false))
                    if isDragging {
                        Text(String(format: "%.0f%% of goal", progressRatio * 100))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            // Native SwiftUI Slider — interactive, drives all calculations
            VStack(spacing: 6) {
                Slider(
                    value: $sliderHolding,
                    in: sliderMin...max(sliderMax, 1),
                    step: 1000
                ) { editing in
                    isDragging = editing
                    if !editing {
                        // Persist to profile when user lifts finger
                        persistHolding()
                    }
                }
                .tint(AppTheme.auraIndigo)

                HStack {
                    Text("₹0")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)

                    Spacer()

                    // 6M target marker label
                    if hasIncomeData {
                        Text("6M: \(shortLabel(target6M))")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(sliderHolding >= target6M ? AppTheme.auraGreen : AppTheme.auraIndigo)
                    } else {
                        Text("Complete assessment to see goal")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(shortLabel(sliderMax))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                // Progress bar — Apple-native ProgressView, only shown when income (target) is known
                if hasIncomeData {
                    ProgressView(value: progressRatio)
                        .progressViewStyle(.linear)
                        .tint(progressRatio >= 1 ? AppTheme.auraGreen : AppTheme.auraIndigo)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: progressRatio)
                } // end if hasIncomeData
            }
        }
    }

    // MARK: - Allocation Row
    private var allocationRow: some View {
        HStack {
            Text("Allocation")
                .font(.system(size: 15, weight: .medium))
            Spacer()

            if sliderHolding == 0 {
                Text("No Allocation")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .background(Color.secondary.opacity(0.10))
                    .clipShape(Capsule())
            } else {
                HStack(spacing: 8) {
                    if hasAllocation && showManage {
                        Button { showEditSheet = true } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(AppTheme.auraIndigo.opacity(0.8))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    Button {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                            if hasAllocation {
                                showManage.toggle()
                            } else {
                                showRecommendSheet = true
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(hasAllocation ? (showManage ? "Done" : "Manage") : "Allocate")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                            if !(hasAllocation && showManage) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .bold))
                            }
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(AppTheme.auraIndigo)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    // MARK: - Allocation Breakdown Table (live-updating)
    private var allocationBreakdownTable: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("Funds")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Invested")
                    .frame(width: 76, alignment: .trailing)
                Text("Returns")
                    .frame(width: 64, alignment: .trailing)
            }
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Color.secondary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            if instruments.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 22)).foregroundStyle(.secondary)
                    Text("Tap the pencil to set allocation percentages")
                        .font(.system(size: 13, design: .rounded)).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 20)
            } else {
                // Rows — values update as sliderHolding changes
                VStack(spacing: 0) {
                    ForEach(instruments) { row in
                        instrumentRow(row)
                        if row.id != instruments.last?.id {
                            Divider().padding(.leading, 14)
                        }
                    }
                }
                .background(Color.secondary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                // Totals
                let totalInvested = instruments.reduce(0) { $0 + $1.invested }
                let totalReturns  = instruments.reduce(0) { $0 + $1.annualReturn }
                HStack {
                    Text("Total").font(.system(size: 13, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(totalInvested.toCurrency(compact: true))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .frame(width: 76, alignment: .trailing)
                        .contentTransition(.numericText())
                    Text("+\(totalReturns.toCurrency(compact: true))")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.auraGreen)
                        .frame(width: 64, alignment: .trailing)
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(AppTheme.auraIndigo.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    private func instrumentRow(_ row: InstrumentInfo) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(row.color.opacity(0.12)).frame(width: 28, height: 28)
                Image(systemName: row.icon)
                    .font(.system(size: 11, weight: .semibold)).foregroundStyle(row.color)
            }
            Text(row.name)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .leading).lineLimit(1)
            Text(row.invested.toCurrency(compact: true))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .frame(width: 76, alignment: .trailing)
                .contentTransition(.numericText())
            Text("+\(row.annualReturn.toCurrency(compact: true))")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.auraGreen)
                .frame(width: 64, alignment: .trailing)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
    }

    // MARK: - Recommendation Tip
    // Fully derived from profile: uses actual income-after-tax minus actual expenses
    // (monthlySurplus) and recommends dedicating 30% of that surplus to the EF.
    private var recommendationTip: some View {
        let saving = suggestedMonthlySaving ?? 0
        let months = monthsToTarget(savingPerMonth: saving)
        let surplus = monthlySurplus ?? 0

        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "#FF9F0A"))
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                if let m = months, saving > 0 {
                    Text("Save \(saving.toCurrency(compact: true)) per month")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                    Text("Fund achieved in \(m) month\(m == 1 ? "" : "s")")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                    if surplus > 0 {
                        Text("(30% of your \(surplus.toCurrency(compact: true)) monthly surplus)")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                } else if target6M > 0 && sliderHolding >= target6M {
                    Text("6-month goal achieved! Consider building to 12 months.")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                } else if surplus <= 0 && monthlyIncome > 0 {
                    Text("Expenses exceed income — reduce spending to start building your fund.")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: "#FF453A"))
                }
            }
            Spacer()
        }
        .padding(12)
        .background(Color(hex: "#FF9F0A").opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Helpers
    private func shortLabel(_ value: Double) -> String {
        if value >= 10_00_000 { return String(format: "%.0fL", value / 1_00_000) }
        if value >= 1_000     { return String(format: "%.0fK", value / 1_000) }
        return String(format: "%.0f", value)
    }

    private func syncFromProfile() {
        sliderHolding = profile?.basicDetails.emergencyFundAmount ?? 0
        if let a = profile?.emergencyFundAllocation {
            pTBills  = a.treasuryBills
            pSavings = a.savingsAccount
            pSweepFD = a.sweepInFD
        }
    }

    /// Persist the dragged holding value back to the profile
    private func persistHolding() {
        guard var profile = appState.currentProfile else { return }
        profile.basicDetails.emergencyFundAmount = sliderHolding
        appState.currentProfile = profile
        appState.recalculateFinancials()
    }

    private func saveAllocation() {
        guard var profile = appState.currentProfile else { return }
        profile.emergencyFundAllocation = AstraEmergencyFundAllocation(
            treasuryBills:     pTBills,
            commercialPapers:  0,
            savingsAccount:    pSavings,
            sweepInFD:         pSweepFD,
            isAllocatedByUser: true
        )
        appState.currentProfile = profile
    }
}

// MARK: - Manage Allocation Sheet
struct ManageAllocationSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppStateManager.self) var appState

    let currentHolding: Double
    @Binding var pTBills:  Double
    @Binding var pSavings: Double
    @Binding var pSweepFD: Double
    var onSave: () -> Void

    private var total: Double { pTBills + pSavings + pSweepFD }

    // MARK: - Rebalanced Slider Bindings
    // When one slider changes, the remaining percentage is automatically
    // redistributed among the other two proportionally (based on their current ratio).
    // Falls back to 50/50 if both others are 0. Total always stays at 100%.

    private var tBillsBinding: Binding<Double> {
        Binding(
            get: { pTBills },
            set: { newValue in
                pTBills = newValue
                rebalanceOthers(changed: newValue, otherA: $pSavings, otherB: $pSweepFD)
            }
        )
    }

    private var savingsBinding: Binding<Double> {
        Binding(
            get: { pSavings },
            set: { newValue in
                pSavings = newValue
                rebalanceOthers(changed: newValue, otherA: $pTBills, otherB: $pSweepFD)
            }
        )
    }

    private var sweepFDBinding: Binding<Double> {
        Binding(
            get: { pSweepFD },
            set: { newValue in
                pSweepFD = newValue
                rebalanceOthers(changed: newValue, otherA: $pTBills, otherB: $pSavings)
            }
        )
    }

    // MARK: - Rebalance Logic
    /// rebalanceOthers() → calls distributeRemaining() which splits the leftover
    /// percentage using the ratio of the other two sliders.
    private func rebalanceOthers(changed newValue: Double, otherA: Binding<Double>, otherB: Binding<Double>) {
        let remaining = max(0, 100 - newValue)
        distributeRemaining(remaining, a: otherA, b: otherB)
    }

    /// Distributes `remaining` % between two bindings proportionally.
    /// Falls back to 50/50 if both are currently 0.
    private func distributeRemaining(_ remaining: Double, a: Binding<Double>, b: Binding<Double>) {
        let sumOthers = a.wrappedValue + b.wrappedValue
        if sumOthers > 0 {
            let ratioA = a.wrappedValue / sumOthers
            let newA = (remaining * ratioA / 5).rounded() * 5  // snap to 5% step
            a.wrappedValue = max(0, min(remaining, newA))
            b.wrappedValue = max(0, remaining - a.wrappedValue)
        } else {
            // 50/50 fallback when both others are 0
            let half = (remaining / 2 / 5).rounded() * 5
            a.wrappedValue = half
            b.wrappedValue = remaining - half
        }
    }

    // MARK: - Projected Return Helpers
    private var blendedReturn: Double {
        (pTBills / 100 * EFInstrumentRate.treasuryBills)
        + (pSavings / 100 * EFInstrumentRate.savingsAccount)
        + (pSweepFD / 100 * EFInstrumentRate.sweepInFD)
    }

    private var totalAnnualEarnings: Double { currentHolding * blendedReturn }

    private func estReturnLabel(pct: Double, rate: Double) -> String {
        let r = currentHolding * (pct / 100) * rate
        return "Est. return: \(r.toCurrency(compact: true))/yr"
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                Section("Summary") {
                    VStack(alignment: .leading, spacing: 8) {
                        labelValue("Total Holding", value: currentHolding.toCurrency())
                        labelValue("Allocated", value: String(format: "%.0f%%", total),
                                   valueColor: AppTheme.auraGreen)
                        labelValue("Unallocated", value: String(format: "%.0f%%", max(0, 100 - total)),
                                   valueColor: .secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    sliderRow("Treasury Bills",
                              subtitle: String(format: "~%.1f%% p.a. · T+2 liquidity", EFInstrumentRate.treasuryBills * 100),
                              estReturnText: estReturnLabel(pct: pTBills, rate: EFInstrumentRate.treasuryBills),
                              icon: "building.columns.fill", color: Color(hex: "#30D158"), value: tBillsBinding)
                    sliderRow("Saving Account",
                              subtitle: String(format: "~%.1f%% p.a. · Instant access", EFInstrumentRate.savingsAccount * 100),
                              estReturnText: estReturnLabel(pct: pSavings, rate: EFInstrumentRate.savingsAccount),
                              icon: "banknote.fill", color: Color(hex: "#007AFF"), value: savingsBinding)
                    sliderRow("Sweep-in FD",
                              subtitle: String(format: "~%.1f%% p.a. · Next-day access", EFInstrumentRate.sweepInFD * 100),
                              estReturnText: estReturnLabel(pct: pSweepFD, rate: EFInstrumentRate.sweepInFD),
                              icon: "arrow.2.squarepath", color: Color(hex: "#FF9F0A"), value: sweepFDBinding)
                } header: {
                    Text("Instruments")
                } footer: {
                    Text("Percentages apply to your ₹\(Int(currentHolding).formatted()) holding. Total always stays at 100%.")
                }

                // MARK: Projected Annual Returns
                if currentHolding > 0 {
                    Section("Projected Annual Returns") {
                        projectedRow("Treasury Bills", pct: pTBills, rate: EFInstrumentRate.treasuryBills,
                                     color: Color(hex: "#30D158"))
                        projectedRow("Saving Account", pct: pSavings, rate: EFInstrumentRate.savingsAccount,
                                     color: Color(hex: "#007AFF"))
                        projectedRow("Sweep-in FD", pct: pSweepFD, rate: EFInstrumentRate.sweepInFD,
                                     color: Color(hex: "#FF9F0A"))

                        Divider()

                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Blended Return")
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(.secondary)
                                Text(String(format: "~%.2f%% p.a.", blendedReturn * 100))
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.auraIndigo)
                                    .contentTransition(.numericText())
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 3) {
                                Text("Est. Annual Earnings")
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(.secondary)
                                Text("+\(totalAnnualEarnings.toCurrency(compact: true))")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color(hex: "#30D158"))
                                    .contentTransition(.numericText())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Manage Allocation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(); dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Helpers
    private func labelValue(_ label: String, value: String, valueColor: Color = .primary) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.semibold).foregroundStyle(valueColor)
        }
        .font(.subheadline)
    }

    private func sliderRow(_ title: String, subtitle: String, estReturnText: String, icon: String, color: Color, value: Binding<Double>) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(color.opacity(0.14)).frame(width: 32, height: 32)
                    Image(systemName: icon).font(.system(size: 13, weight: .semibold)).foregroundStyle(color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 14, weight: .semibold))
                    Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
                    Text(estReturnText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(color.opacity(0.85))
                }
                Spacer()
                Text(String(format: "%.0f%%", value.wrappedValue))
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(color).frame(width: 44, alignment: .trailing)
            }
            Slider(value: value, in: 0...100, step: 5).tint(color)
            let amt = currentHolding * (value.wrappedValue / 100)
            if amt > 0 {
                HStack {
                    Spacer()
                    Text("= \(amt.toCurrency(compact: true)) invested")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func projectedRow(_ name: String, pct: Double, rate: Double, color: Color) -> some View {
        let invested = currentHolding * (pct / 100)
        let annualReturn = invested * rate

        return HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(name)
                .font(.system(size: 13, weight: .medium, design: .rounded))
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if invested > 0 {
                    Text(invested.toCurrency(compact: true))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .contentTransition(.numericText())
                } else {
                    Text("—")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Text("+\(annualReturn.toCurrency(compact: true))/yr")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: "#30D158"))
                    .contentTransition(.numericText())
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Instrument Info Sheet (presented via Apple-native .sheet)
private struct InstrumentInfoSheet: View {
    let info: InstrumentInfoContent
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Headline
                    Text(info.headline)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    // Description
                    Text(info.detail)
                        .font(.system(size: 15, design: .rounded))
                        .lineSpacing(4)
                        .padding(.horizontal, 20)

                    // Rate + liquidity info cards
                    VStack(spacing: 12) {
                        infoChip(icon: "percent", label: info.rateNote, color: Color(hex: "#30D158"))
                        infoChip(icon: "bolt.fill", label: info.liquidityNote, color: Color(hex: "#007AFF"))
                    }
                    .padding(.horizontal, 20)

                    // Regulatory note
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "building.columns")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .padding(.top, 1)
                        Text("Rates are indicative based on RBI benchmark data and may vary. Always verify current rates with your bank or broker before investing.")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .background(Color(.systemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 20)

                    Spacer(minLength: 32)
                }
            }
            .navigationTitle(info.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func infoChip(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)
            }
            Text(label)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(12)
        .background(color.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 16) {
            EmergencyFundSectionView()
                .environment(AppStateManager.withSampleData())
        }
        .padding()
    }
}

// MARK: - Instrument Info Model
private struct InstrumentInfoContent: Identifiable {
    var id: String { name }
    let name: String
    let headline: String
    let detail: String
    let rateNote: String
    let liquidityNote: String

    static let treasuryBills = InstrumentInfoContent(
        name: "Treasury Bills (T-Bills)",
        headline: "Government-backed short-term debt instrument",
        detail: "Treasury Bills are issued by the Reserve Bank of India on behalf of the Government of India. They are zero-coupon securities — bought at a discount and redeemed at face value at maturity. Ideal for parking money safely with slightly better returns than a savings account.",
        rateNote: "Yield: ~6.9% p.a. (91-day T-Bill, as per RBI auctions)",
        liquidityNote: "Liquidity: T+2 — proceeds take 2 working days to settle"
    )

    static let savingsAccount = InstrumentInfoContent(
        name: "Savings Account",
        headline: "Everyday bank deposit with instant access",
        detail: "A savings account held with a scheduled bank offers the highest liquidity — you can withdraw funds at any time via UPI, NEFT, or ATM. It is insured up to ₹5 lakh per depositor per bank by DICGC, making it one of the safest options.",
        rateNote: "Interest: ~3.5% p.a. (average across major banks, per RBI data)",
        liquidityNote: "Liquidity: Instant — available 24/7 through digital channels"
    )

    static let sweepInFD = InstrumentInfoContent(
        name: "Sweep-in Fixed Deposit",
        headline: "FD linked to your savings account for auto-sweep",
        detail: "A sweep-in FD automatically transfers excess balance from your savings account into a fixed deposit, earning a higher FD rate. When you withdraw, the FD is broken in reverse chronological order, so your money is always accessible within one business day.",
        rateNote: "Interest: ~5.2% p.a. (7-day sweep-in average, SBI/HDFC/ICICI)",
        liquidityNote: "Liquidity: Next-day — broken FD funds credited by next working day"
    )
}

// MARK: - Allocation Recommendation Sheet
struct AllocationRecommendationSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppStateManager.self) var appState

    let currentHolding: Double
    let riskTolerance: AstraRiskTolerance
    @Binding var pTBills:  Double
    @Binding var pSavings: Double
    @Binding var pSweepFD: Double
    var onAccept:    () -> Void
    var onCustomize: () -> Void

    @State private var activeInfo: InstrumentInfoContent? = nil
    @State private var expandedHowTo: String? = nil          // tracks which card is expanded inline
    @State private var activeGuide: HowToInvestGuide? = nil  // full-screen guide sheet

    // MARK: - Recommended allocations by risk profile
    private var recommendation: (tBills: Double, savings: Double, sweepFD: Double) {
        switch riskTolerance {
        case .low:    return (tBills: 20, savings: 50, sweepFD: 30)
        case .medium: return (tBills: 35, savings: 35, sweepFD: 30)
        case .high:   return (tBills: 50, savings: 25, sweepFD: 25)
        }
    }

    private var riskLabel: String {
        switch riskTolerance {
        case .low:    return "Conservative"
        case .medium: return "Balanced"
        case .high:   return "Growth-oriented"
        }
    }

    private var riskColor: Color {
        switch riskTolerance {
        case .low:    return Color(hex: "#30D158")
        case .medium: return Color(hex: "#007AFF")
        case .high:   return Color(hex: "#FF9F0A")
        }
    }

    private var riskRationale: String {
        switch riskTolerance {
        case .low:
            return "Your profile suggests you prefer safety and instant access. This plan keeps most funds in high-liquidity instruments."
        case .medium:
            return "A balanced split gives you good liquidity while earning a slightly better return through T-Bills and Sweep-in FD."
        case .high:
            return "You can tolerate slightly lower immediate liquidity for better returns. T-Bills yield the most with T+2 access."
        }
    }

    // Expected blended annual return
    private var blendedReturn: Double {
        let r = recommendation
        return (r.tBills / 100 * EFInstrumentRate.treasuryBills)
             + (r.savings / 100 * EFInstrumentRate.savingsAccount)
             + (r.sweepFD / 100 * EFInstrumentRate.sweepInFD)
    }

    private var annualReturnAmount: Double { currentHolding * blendedReturn }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    profileBadge
                    rationale
                    instrumentBreakdown
                    returnSummary
                    actionButtons
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .navigationTitle("Recommended Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .sheet(item: $activeGuide) { guide in
            HowToInvestFullGuideSheet(guide: guide)
        }
    }

    // MARK: - Profile Badge
    private var profileBadge: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(riskColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: riskTolerance == .low ? "tortoise.fill" : riskTolerance == .medium ? "gauge.medium" : "hare.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(riskColor)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(riskLabel + " Profile")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Text("Based on your financial assessment")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(riskTolerance.rawValue)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(riskColor)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(riskColor.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(16)
        .background(Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Rationale
    private var rationale: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "#FF9F0A"))
                .padding(.top, 1)
            Text(riskRationale)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(Color(hex: "#FF9F0A").opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Instrument Breakdown
    private var instrumentBreakdown: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Suggested Allocation")
                .font(.system(size: 15, weight: .semibold, design: .rounded))

            let r = recommendation
            instrumentRow(
                name:       "Treasury Bills",
                icon:       "building.columns.fill",
                color:      Color(hex: "#30D158"),
                pct:        r.tBills,
                rate:       EFInstrumentRate.treasuryBills,
                liquidity:  "T+2 access",
                holding:    currentHolding,
                info:       .treasuryBills,
                guide:      .treasuryBills
            )
            instrumentRow(
                name:       "Saving Account",
                icon:       "banknote.fill",
                color:      Color(hex: "#007AFF"),
                pct:        r.savings,
                rate:       EFInstrumentRate.savingsAccount,
                liquidity:  "Instant access",
                holding:    currentHolding,
                info:       .savingsAccount,
                guide:      .savingsAccount
            )
            instrumentRow(
                name:       "Sweep-in FD",
                icon:       "arrow.2.squarepath",
                color:      Color(hex: "#FF9F0A"),
                pct:        r.sweepFD,
                rate:       EFInstrumentRate.sweepInFD,
                liquidity:  "Next-day access",
                holding:    currentHolding,
                info:       .sweepInFD,
                guide:      .sweepInFD
            )
        }
        // Apple HIG: popover anchored to the ⓘ button via sheet
        .sheet(item: $activeInfo) { item in
            InstrumentInfoSheet(info: item)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private func instrumentRow(
        name: String, icon: String, color: Color,
        pct: Double, rate: Double, liquidity: String, holding: Double,
        info: InstrumentInfoContent, guide: HowToInvestGuide
    ) -> some View {
        let invested = holding * (pct / 100)
        let annualReturn = invested * rate
        let isExpanded = expandedHowTo == name

        return VStack(spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(color.opacity(0.14)).frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(name)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                        // Apple HIG: ⓘ button
                        Button {
                            activeInfo = info
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(color.opacity(0.75))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    Text(String(format: "%.1f%% p.a. · %@", rate * 100, liquidity))
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.0f%%", pct))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                    if invested > 0 {
                        Text(invested.toCurrency(compact: true))
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Apple-native ProgressView
            ProgressView(value: pct / 100)
                .progressViewStyle(.linear)
                .tint(color)
                .animation(.spring(response: 0.5, dampingFraction: 0.75), value: pct)

            // Return label
            if annualReturn > 0 {
                HStack {
                    Spacer()
                    Text("Est. +\(annualReturn.toCurrency(compact: true)) / year")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(color.opacity(0.85))
                }
            }

            // MARK: How to Invest — expandable inline
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    expandedHowTo = isExpanded ? nil : name
                }
            } label: {
                HStack(spacing: 4) {
                    Text("How to Invest")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(color)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(maxWidth: .infinity, alignment: .leading)

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(guide.compactSteps.enumerated()), id: \.offset) { idx, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(idx + 1)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(width: 18, height: 18)
                                .background(color.opacity(0.8))
                                .clipShape(Circle())
                            Text(step)
                                .font(.system(size: 12, design: .rounded))
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    // Tax/regulatory note
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .padding(.top, 1)
                        Text(guide.taxNote)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(10)
                    .background(Color(.systemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    // View Full Guide button
                    Button {
                        activeGuide = guide
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "book.fill")
                                .font(.system(size: 11))
                            Text("View Full Guide")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(color)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(12)
                .background(color.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .background(color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Return Summary
    private var returnSummary: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Blended Annual Return")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(String(format: "~%.2f%% p.a.", blendedReturn * 100))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(riskColor)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Est. Annual Earnings")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
                Text("+\(annualReturnAmount.toCurrency(compact: true))")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#30D158"))
            }
        }
        .padding(16)
        .background(Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                // Apply recommended values to bindings before accepting
                pTBills  = recommendation.tBills
                pSavings = recommendation.savings
                pSweepFD = recommendation.sweepFD
                onAccept()
            } label: {
                Text("Apply This Plan")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(riskColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(PlainButtonStyle())

            Button {
                // Pre-fill bindings with recommendation so user starts from a good baseline
                pTBills  = recommendation.tBills
                pSavings = recommendation.savings
                pSweepFD = recommendation.sweepFD
                onCustomize()
            } label: {
                Text("Customize Manually")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(riskColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(riskColor.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - How to Invest Guide Model


// MARK: - How to Invest Full Guide Sheet
private struct HowToInvestFullGuideSheet: View {
    let guide: HowToInvestGuide
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(guide.color.opacity(0.14)).frame(width: 44, height: 44)
                            Image(systemName: guide.icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(guide.color)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("How to Invest in")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(.secondary)
                            Text(guide.instrumentName)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Step-by-step detailed guide
                    ForEach(Array(guide.detailedSteps.enumerated()), id: \.offset) { idx, step in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(idx + 1)")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(width: 26, height: 26)
                                    .background(guide.color)
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(step.title)
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    Text(step.detail)
                                        .font(.system(size: 14, design: .rounded))
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .lineSpacing(3)
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        if idx < guide.detailedSteps.count - 1 {
                            // Connector line between steps
                            HStack {
                                Rectangle()
                                    .fill(guide.color.opacity(0.2))
                                    .frame(width: 2, height: 12)
                                    .padding(.leading, 32)
                                Spacer()
                            }
                        }
                    }

                    // Tax & Regulatory Note
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "building.columns")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(guide.color)
                            Text("Tax & Regulatory Note")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                        Text(guide.taxNote)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(3)
                    }
                    .padding(16)
                    .background(guide.color.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.horizontal, 20)

                    // Disclaimer
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .padding(.top, 1)
                        Text("Rates are indicative based on RBI benchmark data and may vary. Always verify current rates with your bank or broker before investing.")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .background(Color(.systemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 20)

                    Spacer(minLength: 32)
                }
            }
            .navigationTitle("Investment Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

