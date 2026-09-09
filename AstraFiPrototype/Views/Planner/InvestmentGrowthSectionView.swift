import SwiftUI
import Charts

// MARK: - Investment Growth Section

struct InvestmentGrowthSectionView: View {
    @Environment(AppStateManager.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    @Binding var selectedInvestmentIDs: Set<UUID>

    @State private var selectedTimeframe: InvestmentGrowthTimeframe = .oneWeek
    @State private var growthResult: GrowthLoadResult = .unavailable
    @State private var isLoading = false
    @State private var showSelectionSheet = false
    @State private var selectedChartIndex: Int?
    @State private var loadTask: Task<Void, Never>?

    private var investments: [AstraInvestment] {
        appState.currentProfile?.investments ?? []
    }

    private var selectedInvestments: [AstraInvestment] {
        investments.filter { selectedInvestmentIDs.contains($0.id) }
    }

    private var isCombinedMode: Bool { selectedInvestments.count > 1 }

    private var combinedCurrentValue: Double {
        selectedInvestments.reduce(0) { $0 + $1.currentValue.safeFinite }
    }

    private var combinedInvested: Double {
        selectedInvestments.reduce(0) { $0 + $1.totalInvestedAmount.safeFinite }
    }

    private var combinedProfit: Double {
        selectedInvestments.reduce(0) { $0 + $1.currentGain.safeFinite }
    }

    private var combinedReturnPct: Double? {
        guard combinedInvested > 0 else { return nil }
        return (combinedProfit / combinedInvested) * 100
    }

    private var allChartPoints: [GrowthChartPoint] {
        growthResult.actualPoints + growthResult.projectedPoints
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerSection

            if investments.isEmpty {
                emptyInvestmentsState
            } else if selectedInvestments.isEmpty {
                noSelectionState
            } else {
                selectionSummary
                performanceSummary
                timeframeSelector
                chartSection
                historicalInsightSection
                projectionSection

                if isCombinedMode, !growthResult.individualReturns.isEmpty {
                    individualBreakdownSection
                }
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 14, x: 0, y: 5)
        .sheet(isPresented: $showSelectionSheet) {
            InvestmentGrowthSelectionSheet(
                investments: investments,
                selectedIDs: $selectedInvestmentIDs
            )
        }
        .onAppear { scheduleLoad() }
        .onChange(of: selectedInvestmentIDs) { _, _ in scheduleLoad() }
        .onChange(of: selectedTimeframe) { _, _ in scheduleLoad() }
        .onChange(of: investments.count) { _, _ in scheduleLoad() }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(isCombinedMode ? "Combined Investment Growth" : "Investment Growth")
                .font(.system(size: 17, weight: .bold, design: .rounded))
            Text("Track how your selected investments are performing over time.")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    private var selectionSummary: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Selected")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                if selectedInvestments.count == 1, let name = selectedInvestments.first?.investmentName {
                    Text(name)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .lineLimit(2)
                } else {
                    Text("\(selectedInvestments.count) Investments")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
            }
            Spacer()
            Button("Select Investments") { showSelectionSheet = true }
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.auraIndigo)
        }
    }

    // MARK: - Performance Summary

    private var performanceSummary: some View {
        let columns = [
            summaryMetric(
                title: isCombinedMode ? "Combined Current Value" : "Current Value",
                value: combinedCurrentValue.toCurrency()
            ),
            summaryMetric(
                title: isCombinedMode ? "Total Invested" : "Invested Amount",
                value: combinedInvested > 0 ? combinedInvested.toCurrency() : "—"
            ),
            summaryMetric(
                title: isCombinedMode ? "Total Profit" : "Profit",
                value: profitLabel(combinedProfit),
                color: combinedProfit >= 0 ? AppTheme.auraGreen : Color(hex: "#FF453A")
            ),
            summaryMetric(
                title: isCombinedMode ? "Portfolio Return" : "Return",
                value: combinedReturnPct.map { formatSignedPercent($0) } ?? "—",
                color: (combinedReturnPct ?? 0) >= 0 ? AppTheme.auraGreen : Color(hex: "#FF453A")
            ),
            summaryMetric(
                title: "Period Change",
                value: growthResult.periodChangePct.map { formatSignedPercent($0) } ?? "—",
                color: (growthResult.periodChangePct ?? 0) >= 0 ? AppTheme.auraGreen : Color(hex: "#FF453A")
            )
        ]

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                column
            }
        }
    }

    private func summaryMetric(title: String, value: String, color: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Timeframe

    private var timeframeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(InvestmentGrowthTimeframe.allCases) { range in
                    let isAvailable = growthResult.availableTimeframes.contains(range) || isLoading
                    Button {
                        guard isAvailable else { return }
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            selectedTimeframe = range
                        }
                    } label: {
                        Text(range.rawValue)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(selectedTimeframe == range ? .white : (isAvailable ? .primary : .secondary))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                selectedTimeframe == range
                                    ? AppTheme.auraIndigo
                                    : Color(uiColor: .secondarySystemFill).opacity(isAvailable ? 1 : 0.45)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(!isAvailable && !isLoading)
                }
            }
        }
    }

    // MARK: - Chart

    @ViewBuilder
    private var chartSection: some View {
        if isLoading {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .frame(height: 180)
        } else if growthResult.isUnavailable {
            unavailableChartState(message: "Historical performance unavailable.")
        } else if growthResult.actualPoints.isEmpty {
            unavailableChartState(message: "Historical performance unavailable.")
        } else {
            VStack(alignment: .leading, spacing: 10) {
                if growthResult.hasLimitedData {
                    Label("Showing available historical data.", systemImage: "info.circle")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                if let selected = selectedChartPoint {
                    chartSelectionCallout(for: selected)
                }

                growthChart
                    .frame(height: 190)

                HStack(spacing: 16) {
                    legendItem(color: AppTheme.auraIndigo, label: "Actual", dashed: false)
                    if !growthResult.projectedPoints.isEmpty {
                        legendItem(color: AppTheme.auraIndigo.opacity(0.45), label: "Projected", dashed: true)
                    }
                }
            }
        }
    }

    private var growthChart: some View {
        let actual = growthResult.actualPoints
        let projected = growthResult.projectedPoints
        let domain = chartDomain(for: actual + projected)
        let lineColor: Color = (growthResult.periodChangePct ?? 0) >= 0 ? AppTheme.auraGreen : Color(hex: "#FF453A")

        return Chart {
            ForEach(actual) { point in
                AreaMark(
                    x: .value("Index", point.index),
                    yStart: .value("Baseline", domain.lowerBound),
                    yEnd: .value("Value", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [lineColor.opacity(0.18), lineColor.opacity(0.03)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Index", point.index),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(lineColor)
                .lineStyle(StrokeStyle(lineWidth: 2.2, lineJoin: .round))
            }

            if let lastActual = actual.last, !projected.isEmpty {
                ForEach([lastActual] + projected) { point in
                    LineMark(
                        x: .value("Index", point.index),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(AppTheme.auraIndigo.opacity(0.45))
                    .lineStyle(
                        StrokeStyle(
                            lineWidth: 1.8,
                            lineJoin: .round,
                            dash: [6, 4]
                        )
                    )
                }
            }

            if let selected = selectedChartPoint {
                RuleMark(x: .value("Selected", selected.index))
                    .foregroundStyle(Color.secondary.opacity(0.35))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                PointMark(x: .value("Selected", selected.index), y: .value("Value", selected.value))
                    .foregroundStyle(lineColor)
                    .symbolSize(70)
            }
        }
        .chartXScale(domain: chartXDomain)
        .chartYScale(domain: domain)
        .chartXAxis {
            AxisMarks(values: xAxisTicks) { value in
                AxisValueLabel {
                    if let index = value.as(Int.self),
                       let point = allChartPoints.first(where: { $0.index == index }) {
                        Text(shortDateLabel(point.date))
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartYAxis(.hidden)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                updateSelectedIndex(at: value.location, proxy: proxy, geometry: geometry)
                            }
                            .onEnded { _ in
                                // Keep selection visible after touch.
                            }
                    )
            }
        }
    }

    private var selectedChartPoint: GrowthChartPoint? {
        guard let index = selectedChartIndex else { return nil }
        return allChartPoints.first(where: { $0.index == index })
    }

    private var chartXDomain: ClosedRange<Int> {
        let maxIndex = allChartPoints.map(\.index).max() ?? 1
        return 0...max(maxIndex, 1)
    }

    private var xAxisTicks: [Int] {
        let points = growthResult.actualPoints
        guard points.count > 1 else { return [0] }
        if points.count <= 5 { return points.map(\.index) }
        let step = max(1, points.count / 4)
        return stride(from: 0, to: points.count, by: step).map { points[$0].index }
    }

    private func chartSelectionCallout(for point: GrowthChartPoint) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(relativeDateLabel(point.date))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
            Text(point.value.toCurrency())
                .font(.system(size: 16, weight: .bold, design: .rounded))
            if let change = point.changeFromPrevious, let pct = point.changePctFromPrevious {
                Text("\(change >= 0 ? "+" : "")\(change.toCurrency()) · \(formatSignedPercent(pct))")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(change >= 0 ? AppTheme.auraGreen : Color(hex: "#FF453A"))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.auraIndigo.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Historical Insight

    @ViewBuilder
    private var historicalInsightSection: some View {
        if !growthResult.snapshots.isEmpty, !growthResult.isUnavailable {
            VStack(spacing: 0) {
                ForEach(growthResult.snapshots) { snapshot in
                    HStack {
                        Text(snapshot.label)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                        Spacer()
                        if snapshot.label.contains("Change"), let pct = snapshot.value {
                            Text(formatSignedPercent(pct))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(pct >= 0 ? AppTheme.auraGreen : Color(hex: "#FF453A"))
                        } else if let value = snapshot.value {
                            Text(value.toCurrency())
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        } else {
                            Text("—")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 10)
                    if snapshot.id != growthResult.snapshots.last?.id {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, 14)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: - Projection

    @ViewBuilder
    private var projectionSection: some View {
        if growthResult.isUnavailable || growthResult.actualPoints.count < 3 {
            EmptyView()
        } else if let estimate = growthResult.projection, estimate.isAvailable {
            VStack(alignment: .leading, spacing: 10) {
                Text("Estimated Range")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Text("Estimated based on recent trend. Not a guaranteed return.")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.secondary)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text(estimate.currentValue.toCurrency())
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Projected Range")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text("\(estimate.low.toCurrency()) – \(estimate.high.toCurrency())")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.auraIndigo.opacity(0.85))
                    }
                }
                .padding(14)
                .background(AppTheme.auraIndigo.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        } else {
            Text("Not enough historical data to generate a projection.")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
        }
    }

    // MARK: - Combined Breakdown

    private var individualBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Individual Contribution")
                .font(.system(size: 14, weight: .semibold, design: .rounded))

            ForEach(growthResult.individualReturns) { item in
                HStack {
                    Text(item.name)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .lineLimit(1)
                    Spacer()
                    if let pct = item.periodReturnPct {
                        Text(formatSignedPercent(pct))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(pct >= 0 ? AppTheme.auraGreen : Color(hex: "#FF453A"))
                    } else {
                        Text("—")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Empty States

    private var emptyInvestmentsState: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("No investments available yet.")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
            Text("Add an investment to start tracking growth.")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var noSelectionState: some View {
        VStack(spacing: 12) {
            Text("No investment selected.")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
            Text("Choose one or more investments to track their growth.")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Select Investments") { showSelectionSheet = true }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.auraIndigo)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private func unavailableChartState(message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 28))
                .foregroundStyle(.secondary.opacity(0.5))
            Text(message)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
    }

    // MARK: - Helpers

    private func scheduleLoad() {
        loadTask?.cancel()
        loadTask = Task {
            await loadGrowthData()
        }
    }

    @MainActor
    private func loadGrowthData() async {
        guard !selectedInvestments.isEmpty else {
            growthResult = .unavailable
            isLoading = false
            return
        }

        isLoading = true
        let result = await InvestmentGrowthEngine.shared.loadGrowthData(
            investments: selectedInvestments,
            timeframe: selectedTimeframe
        )

        guard !Task.isCancelled else { return }

        growthResult = result
        if !result.availableTimeframes.contains(selectedTimeframe),
           let first = result.availableTimeframes.first {
            selectedTimeframe = first
        }
        selectedChartIndex = result.actualPoints.last?.index
        isLoading = false
    }

    private func chartDomain(for points: [GrowthChartPoint]) -> ClosedRange<Double> {
        let values = points.map(\.value).filter { $0.isFinite && $0 > 0 }
        guard let minVal = values.min(), let maxVal = values.max() else {
            return 0...1
        }
        let range = max(maxVal - minVal, maxVal * 0.05)
        let padding = range * 0.12
        return (minVal - padding)...(maxVal + padding)
    }

    private func updateSelectedIndex(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        guard let plotFrame = proxy.plotFrame else { return }
        let origin = geometry[plotFrame].origin
        let xPosition = location.x - origin.x
        if let index: Int = proxy.value(atX: xPosition) {
            let nearest = allChartPoints.min(by: {
                abs($0.index - index) < abs($1.index - index)
            })
            selectedChartIndex = nearest?.index
        }
    }

    private func legendItem(color: Color, label: String, dashed: Bool) -> some View {
        HStack(spacing: 5) {
            if dashed {
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(color)
                            .frame(width: 4, height: 2)
                    }
                }
            } else {
                Circle().fill(color).frame(width: 7, height: 7)
            }
            Text(label)
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    private func profitLabel(_ profit: Double) -> String {
        guard combinedInvested > 0 else { return "—" }
        let prefix = profit >= 0 ? "+" : ""
        return prefix + profit.toCurrency()
    }

    private func formatSignedPercent(_ value: Double) -> String {
        let prefix = value >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", prefix, value)
    }

    private func shortDateLabel(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }

    private func relativeDateLabel(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Selection Sheet

private struct InvestmentGrowthSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss

    let investments: [AstraInvestment]
    @Binding var selectedIDs: Set<UUID>

    var body: some View {
        NavigationStack {
            List {
                ForEach(investments) { investment in
                    Button {
                        toggle(investment.id)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: selectedIDs.contains(investment.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedIDs.contains(investment.id) ? AppTheme.auraIndigo : .secondary)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(investment.investmentName)
                                    .foregroundStyle(.primary)
                                Text(investment.investmentType.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text(investment.currentValue.toCurrency(compact: true))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Select Investments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func toggle(_ id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }
}

#Preview {
    ScrollView {
        InvestmentGrowthSectionView(selectedInvestmentIDs: .constant([]))
            .padding()
            .environment(AppStateManager.withSampleData())
    }
}
