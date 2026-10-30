import SwiftUI

struct FixedIncomeLadderInputView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(AppStateManager.self) private var appState

    @State private var totalCapital: Double = 1_000_000
    @State private var desiredLiquidityReserve: Double = 100_000
    @State private var inflationAssumptionPct: Double = 6.0
    @State private var entries: [FixedIncomeEntry] = FixedIncomeLadderInput.defaultLadder()
    @State private var navigateToResult: Bool = false
    @State private var editingEntry: FixedIncomeEntry? = nil
    @State private var showingEditSheet: Bool = false

    init() {}

    private var totalAllocated: Double {
        entries.reduce(0.0) { $0 + $1.allocatedAmount }
    }

    private var unallocatedCapital: Double {
        totalCapital - totalAllocated
    }

    private var currentInput: FixedIncomeLadderInput {
        FixedIncomeLadderInput(
            totalCapitalAvailable: totalCapital,
            desiredLiquidityReserve: desiredLiquidityReserve,
            ladderEntries: entries,
            inflationAssumptionPct: inflationAssumptionPct,
            scenarioKind: .base
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header card
                headerCard

                // Capital allocation summary card
                capitalSummaryCard

                // Ladder tranches list
                ladderEntriesSection

                // Advanced assumptions
                assumptionsSection

                // Run simulation CTA
                simulateButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(AppTheme.appBackground(for: colorScheme))
        .navigationTitle("Fixed-Income Ladder")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToResult) {
            FixedIncomeLadderResultView(input: currentInput)
        }
        .sheet(item: $editingEntry) { entry in
            FixedIncomeEntryEditorSheet(entry: entry) { updated in
                if let idx = entries.firstIndex(where: { $0.id == updated.id }) {
                    entries[idx] = updated
                }
            }
        }
        .onAppear {
            seedFromProfile()
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "stairs")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppTheme.auraIndigo)
                Text("Ladder Strategy Builder")
                    .font(.auraHeader(size: 20))
            }

            Text("Stagger bond, deposit, and T-bill maturities across 1–5+ years to lock in yields, optimize liquidity, and minimize reinvestment risk.")
                .font(.auraCaption())
                .foregroundStyle(.secondary)
        }
        .auraCardStyle(radius: 20)
    }

    private var capitalSummaryCard: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Total Capital Available")
                    .font(.auraHeader(size: 16))
                Spacer()
                Text(totalCapital.toCurrency())
                    .font(.auraDigital(size: 18))
                    .foregroundStyle(AppTheme.auraIndigo)
            }

            SimulatorInputField(
                title: "Adjust Capital Pool",
                value: $totalCapital,
                step: 100_000,
                range: 50_000...50_000_000
            )

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Allocated")
                        .font(.auraCaption())
                        .foregroundStyle(.secondary)
                    Text(totalAllocated.toCurrency())
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(totalAllocated > totalCapital ? AppTheme.vibrantRed : .primary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Unallocated Cash")
                        .font(.auraCaption())
                        .foregroundStyle(.secondary)
                    Text(unallocatedCapital.toCurrency())
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(unallocatedCapital >= 0 ? AppTheme.auraGreen : AppTheme.vibrantRed)
                }
            }

            if totalAllocated > totalCapital {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(AppTheme.vibrantRed)
                    Text("Allocations exceed available capital by \((totalAllocated - totalCapital).toCurrency()).")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.vibrantRed)
                }
            }
        }
        .auraCardStyle(radius: 20)
    }

    private var ladderEntriesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SimulatorSectionHeader(
                    title: "Ladder Tranches (\(entries.count))",
                    subtitle: "Tap a tranche to configure tenure, coupon, and reinvestment",
                    icon: "list.bullet.rectangle.fill"
                )
                Spacer()
                Button {
                    let newTranche = FixedIncomeEntry(
                        instrumentName: "New Tranche \(entries.count + 1)",
                        instrumentType: .bankFD,
                        allocatedAmount: 150_000,
                        startYearOffset: 0,
                        tenureYears: entries.count + 1,
                        annualInterestRatePct: 7.20
                    )
                    entries.append(newTranche)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(AppTheme.auraIndigo)
                }
            }

            VStack(spacing: 10) {
                ForEach(entries) { entry in
                    TrancheRowView(entry: entry) {
                        editingEntry = entry
                    } onDelete: {
                        entries.removeAll { $0.id == entry.id }
                    } onDuplicate: {
                        var dup = entry
                        dup.id = UUID()
                        dup.instrumentName += " (Copy)"
                        entries.append(dup)
                    }
                }
            }
        }
        .auraCardStyle(radius: 20)
    }

    private var assumptionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SimulatorSectionHeader(
                title: "Planning & Liquidity Reserves",
                subtitle: "Safety cushions and expense inflation",
                icon: "shield.checkerboard"
            )

            SimulatorInputField(
                title: "Minimum Liquidity Reserve",
                value: $desiredLiquidityReserve,
                step: 25_000,
                range: 0...5_000_000
            )

            HStack {
                Text("Inflation Assumption")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Text("\(String(format: "%.1f", inflationAssumptionPct))%")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            Slider(value: $inflationAssumptionPct, in: 2.0...12.0, step: 0.5)
                .tint(AppTheme.auraIndigo)
        }
        .auraCardStyle(radius: 20)
    }

    private var simulateButton: some View {
        Button {
            navigateToResult = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 20))
                Text("Run Ladder Simulation")
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.accentGradient)
            .clipShape(Capsule())
            .shadow(color: AppTheme.auraIndigo.opacity(0.35), radius: 12, x: 0, y: 6)
        }
        .disabled(entries.isEmpty)
        .padding(.top, 8)
    }

    private func seedFromProfile() {
        guard let p = appState.currentProfile else { return }
        let totalInvestments = p.investments.reduce(0.0) { $0 + $1.investmentAmount }
        let cash = p.basicDetails.emergencyFundAmount
        let candidatePool = max(cash, totalInvestments * 0.4)
        if candidatePool >= 200_000 {
            totalCapital = (candidatePool / 100_000).rounded() * 100_000
        }
        if p.basicDetails.monthlyExpenses > 0 {
            desiredLiquidityReserve = max(50_000, p.basicDetails.monthlyExpenses * 2)
        }
    }
}

// MARK: - Tranche Row View
private struct TrancheRowView: View {
    let entry: FixedIncomeEntry
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.auraIndigo.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Text("\(entry.tenureYears)Y")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.auraIndigo)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.instrumentName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.primary)
                    Text("\(entry.instrumentType.shortName) • \(String(format: "%.2f", entry.annualInterestRatePct))% p.a. • \(entry.payoutFrequency.rawValue)")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text(entry.allocatedAmount.toCurrency(compact: true))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text(entry.reinvestmentAction == .reinvestLadder ? "Reinvest" : "Cash Out")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(entry.reinvestmentAction == .reinvestLadder ? AppTheme.auraGreen : .orange)
                }

                Menu {
                    Button(action: onEdit) {
                        Label("Edit Tranche", systemImage: "pencil")
                    }
                    Button(action: onDuplicate) {
                        Label("Duplicate", systemImage: "plus.square.on.square")
                    }
                    Button(role: .destructive, action: onDelete) {
                        Label("Remove", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(8)
                }
            }
            .padding(12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Tranche Editor Sheet
struct FixedIncomeEntryEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var entry: FixedIncomeEntry
    let onSave: (FixedIncomeEntry) -> Void

    init(entry: FixedIncomeEntry, onSave: @escaping (FixedIncomeEntry) -> Void) {
        self._entry = State(initialValue: entry)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Tranche Profile") {
                    TextField("Tranche Name", text: $entry.instrumentName)

                    Picker("Instrument Type", selection: $entry.instrumentType) {
                        ForEach(FixedIncomeInstrumentType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .onChange(of: entry.instrumentType) { _, newType in
                        entry.annualInterestRatePct = newType.defaultRatePct
                        entry.payoutFrequency = newType.defaultFrequency
                    }

                    HStack {
                        Text("Tenure (Years)")
                        Spacer()
                        Stepper("\(entry.tenureYears) Years", value: $entry.tenureYears, in: 1...20)
                    }

                    SimulatorInputField(
                        title: "Allocated Capital",
                        value: $entry.allocatedAmount,
                        step: 50_000,
                        range: 10_000...50_000_000
                    )
                }

                Section("Yield & Payout Terms") {
                    HStack {
                        Text("Annual Rate / YTM")
                        Spacer()
                        TextField("Rate", value: $entry.annualInterestRatePct, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("%")
                    }

                    Picker("Coupon / Payout Frequency", selection: $entry.payoutFrequency) {
                        ForEach(FixedIncomePayoutFrequency.allCases) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }

                    HStack {
                        Text("Tax Rate Assumption")
                        Spacer()
                        TextField("Tax", value: $entry.taxRatePct, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("%")
                    }
                }

                Section("Maturity Action") {
                    Picker("When Tranche Matures", selection: $entry.reinvestmentAction) {
                        ForEach(FixedIncomeReinvestmentAction.allCases) { act in
                            Text(act.rawValue).tag(act)
                        }
                    }

                    if entry.reinvestmentAction == .reinvestLadder {
                        HStack {
                            Text("Assumed Reinvestment Rate")
                            Spacer()
                            TextField("Rate", value: $entry.reinvestmentRatePct, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                            Text("%")
                        }
                    }

                    SimulatorInputField(
                        title: "Planned Withdrawal at Maturity",
                        value: $entry.plannedWithdrawalAtMaturity,
                        step: 25_000,
                        range: 0...10_000_000
                    )
                }
            }
            .navigationTitle("Configure Tranche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(entry)
                        dismiss()
                    }
                }
            }
        }
    }
}
