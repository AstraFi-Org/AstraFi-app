import SwiftUI
import Charts

private struct InvestmentHistoryChartPoint: Identifiable {
    let index: Int
    let date: String
    let value: Double

    var id: Int { index }
}

private struct InvestmentTransactionChartPoint: Identifiable {
    let id: UUID
    let index: Int
    let value: Double
}

private enum InvestmentFundChartRange: String, CaseIterable, Identifiable {
    case oneMonth = "1M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    case threeYears = "3Y"
    case fiveYears = "5Y"
    case max = "Max"
    case sip = "SIP"

    var id: String { rawValue }

    func startDate(for investment: AstraInvestment?) -> Date? {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .oneMonth:
            return calendar.date(byAdding: .month, value: -1, to: now)
        case .sixMonths:
            return calendar.date(byAdding: .month, value: -6, to: now)
        case .oneYear:
            return calendar.date(byAdding: .year, value: -1, to: now)
        case .threeYears:
            return calendar.date(byAdding: .year, value: -3, to: now)
        case .fiveYears:
            return calendar.date(byAdding: .year, value: -5, to: now)
        case .max:
            return Date(timeIntervalSince1970: 0)
        case .sip:
            return investment?.startDate
        }
    }
}

struct InvestmentDetailView: View {
    @Environment(AppStateManager.self) var appState
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    let investmentID: UUID

    init(investmentID: UUID) {
        self.investmentID = investmentID
    }

    private var inv: AstraInvestment? {
        appState.currentProfile?.investments.first(where: { $0.id == investmentID })
    }

    private var gain: Double {
        inv?.currentGain ?? 0
    }

    private var actualCurrentValue: Double {
        inv?.currentValue ?? 0
    }

    private var profitPct: Double {
        guard let amt = inv?.totalInvestedAmount, amt > 0 else { return 0 }
        return (gain / amt) * 100
    }

    private func formatPercentage(_ val: Double) -> String {
        if val == 0 { return "0.0%" }

        if abs(val) < 0.1 {
            return String(format: "%.2f%%", val)
        }
        return String(format: "%.1f%%", val)
    }
    private var df: DateFormatter  { let f = DateFormatter(); f.dateStyle = .medium; return f }

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var history: [MFHistoryPoint] = []
    @State private var isLoadingHistory = false
    @State private var selectedFundRange: InvestmentFundChartRange = .sip

    private var sipInstallments: [AstraInvestmentTransaction] {
        inv?.installments.sorted(by: { $0.date > $1.date }) ?? []
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(inv?.investmentName ?? "Investment Detail")
                    .font(.title).fontWeight(.bold)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .padding(.top)

                headerCard
                valueChart
                detailsSection
                fundAnalysisSection
                if inv?.mode == .sip {
                    sipHistoryCard
                }
            }
            .padding()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button { showingEditSheet = true } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) { showingDeleteAlert = true } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            if let inv = inv {
                EditInvestmentView(investment: inv)
            } else {
                EmptyView()
            }
        }
        .alert("Delete Investment", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let i = inv {
                    appState.deleteInvestment(i)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to remove this investment?")
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .task {
            await loadFundHistory()
        }
        .onChange(of: inv?.schemeCode) { _ in
            Task {
                await loadFundHistory()
            }
        }
        .onChange(of: inv?.startDate) { _ in
            Task {
                await loadFundHistory()
            }
        }
        .onChange(of: selectedFundRange) { _ in
            Task {
                await loadFundHistory()
            }
        }
    }

    @MainActor
    private func loadFundHistory() async {
        let currentInv = inv
        let startDate = selectedFundRange.startDate(for: currentInv)

        if let code = currentInv?.schemeCode {
            isLoadingHistory = true
            history = await MFService.shared.fetchHistoricalGraphData(schemeCode: code, startDate: startDate)
            isLoadingHistory = false
        } else if currentInv?.investmentType == .stocks, let symbol = currentInv?.symbol ?? currentInv?.investmentName {
            isLoadingHistory = true
            history = await StockService.shared.fetchStockChartHistory(symbol: symbol, startDate: startDate ?? currentInv?.startDate ?? Date())
            isLoadingHistory = false
        }
    }

    @ViewBuilder
    private var headerCard: some View {
        if let currentInv = inv {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentInv.investmentType.rawValue)
                            .font(.headline).foregroundColor(.primary)
                        Text(riskLabel)
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatPercentage(abs(profitPct)))
                            .font(.largeTitle).fontWeight(.bold).foregroundColor(profitPct >= 0 ? .green : .red)
                        Text(profitPct >= 0 ? "Profit" : "Loss").font(.caption).foregroundColor(.secondary)
                    }
                }
                Divider()
                HStack {
                    Text("Total Value").font(.headline).foregroundColor(.primary)
                    Spacer()
                    Text(actualCurrentValue > 0 ? actualCurrentValue.toCurrency() : "—")
                        .font(.title3).fontWeight(.bold).foregroundColor(.primary)
                }
                if let lastUpdated = currentInv.lastUpdated {
                    HStack {
                        Text("Last Sync: \(lastUpdated.formatted(date: .abbreviated, time: .shortened))")
                        Spacer()
                        Button {
                            Task {
                                await appState.syncMutualFundNAVs(force: true)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                Text("Refresh").font(.caption2)
                            }.foregroundColor(.blue)
                        }
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                } else {
                    Button {
                        Task {
                            await appState.syncMutualFundNAVs()
                        }
                    } label: {
                        Text("Sync Live Data").font(.caption2).foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .investmentDetailCardStyle(colorScheme: colorScheme)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private var valueChart: some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                if isLoadingHistory {
                    HStack {
                        Spacer()
                        ProgressView().controlSize(.small)
                        Spacer()
                    }
                    .frame(height: 120)
                } else {
                    let chartData = historyChartPoints.isEmpty ? valueChartPlaceholderPoints : historyChartPoints
                    let domain = valueChartDomain(for: chartData)
                    let lineColor: Color = profitPct >= 0 ? .green : .red

                    Chart {
                        ForEach(chartData) { point in
                            AreaMark(
                                x: .value("Point", point.index),
                                yStart: .value("Baseline", domain.lowerBound),
                                yEnd: .value("NAV", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [lineColor.opacity(0.3), lineColor.opacity(0.05)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                            LineMark(
                                x: .value("Point", point.index),
                                y: .value("NAV", point.value)
                            )
                            .foregroundStyle(lineColor)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                        }

                        if let lastPoint = chartData.last {
                            PointMark(
                                x: .value("Point", lastPoint.index),
                                y: .value("NAV", lastPoint.value)
                            )
                            .foregroundStyle(lineColor)
                            .symbolSize(64)
                        }
                    }
                    .chartXScale(domain: 0...(max(chartData.count - 1, 1)))
                    .chartYScale(domain: domain)
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .chartPlotStyle { plotArea in
                        plotArea.background(Color.clear)
                    }
                    .frame(height: 120)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .investmentDetailCardStyle(colorScheme: colorScheme)
    }

    @ViewBuilder
    private var detailsSection: some View {
        VStack(spacing: 0) {
            detailRow(label: "Total Invested", value: inv?.totalInvestedAmount.toCurrency() ?? "—")
            
            if let units = inv?.units {
                detailRow(label: "Total Units Owned", value: String(format: "%.3f", units))
                Divider().padding(.leading)
            }

            if inv?.mode == .sip {
                detailRow(label: "Monthly SIP", value: inv?.investmentAmount.toCurrency() ?? "—")
            }
            Divider().padding(.leading)

            if let pNAV = inv?.purchaseNAV {
                detailRow(label: "Avg. Entry NAV", value: "₹\(String(format: "%.2f", pNAV))")
                Divider().padding(.leading)
            }

            if let lastNAV = inv?.lastNAV {
                detailRow(label: "Current NAV", value: "₹\(String(format: "%.2f", lastNAV))", valueColor: profitPct >= 0 ? .green : .red)
                Divider().padding(.leading)
            }

            detailRow(label: "Absolute Growth", value: formatPercentage(profitPct), valueColor: profitPct >= 0 ? .green : .red)
            Divider().padding(.leading)

            detailRow(label: gain >= 0 ? "Total Profit" : "Total Loss", value: gain >= 0 ? "+" + gain.toCurrency() : gain.toCurrency(), valueColor: gain >= 0 ? .green : .red)
            Divider().padding(.leading)
            detailRow(label: "Investment Mode", value: inv?.mode.rawValue ?? "—")
        }
        .investmentDetailCardStyle(colorScheme: colorScheme)
    }

    @ViewBuilder
    private var fundAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(spacing: 0) {
                dateRow(label: inv?.mode == .sip ? "SIP Start Date" : "Investment Date", date: inv?.startDate)
                Divider().padding(.leading)

                if let startDate = inv?.startDate {
                    let projected = Calendar.current.date(byAdding: .year, value: 5, to: startDate)
                    dateRow(label: "Projected Closing", date: projected)
                } else {
                    dateRow(label: "Projected Closing", date: nil)
                }
            }
            .investmentDetailCardStyle(colorScheme: colorScheme)

            Text("Fund Analysis").font(.title2).fontWeight(.bold).padding(.top, 8)
            fundAnalysisChart
        }
    }

    @ViewBuilder
    private var fundAnalysisChart: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isLoadingHistory {
                HStack { Spacer(); ProgressView(); Spacer() }
                    .frame(height: 220)
            } else if fundAnalysisChartPoints.isEmpty {
                // Placeholder when no data
                VStack(spacing: 8) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("No historical data available")
                        .font(.caption).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                let chartData = fundAnalysisChartPoints
                let vals     = chartData.map(\.value)
                let minVal   = (vals.min() ?? 0) * 0.995
                let maxVal   = (vals.max() ?? 1) * 1.005
                let range    = (maxVal - minVal) > 0 ? (maxVal - minVal) : 1
                let isProfit = (vals.last ?? 0) >= (vals.first ?? 0)
                let lineColor: Color = isProfit ? .green : .red

                // Month tick labels from live history, or from SIP transaction dates when
                // the external graph history is unavailable.
                let monthLabels: [(index: Int, label: String)] = {
                    var result: [(Int, String)] = []
                    let df = DateFormatter(); df.dateFormat = "dd-MM-yyyy"
                    let mf = DateFormatter(); mf.dateFormat = "MMM yy"
                    var lastMonth = -1
                    for pt in chartData {
                        if let d = df.date(from: pt.date) {
                            let m = Calendar.current.component(.month, from: d)
                            if m != lastMonth {
                                result.append((pt.index, mf.string(from: d)))
                                lastMonth = m
                            }
                        }
                    }
                    // Keep max ~6 labels to avoid crowding
                    if result.count > 6 {
                        let step = result.count / 6
                        result = result.enumerated().filter { $0.offset % step == 0 }.map { $0.element }
                    }
                    return result
                }()

                let yTicks: [Double] = [minVal, minVal + range*0.33, minVal + range*0.66, maxVal]
                let transactionPoints = purchaseChartPoints(for: chartData)
                let highlightedPoint: InvestmentHistoryChartPoint? = {
                    if let lastSipIndex = transactionPoints.last?.index,
                       let point = chartData.first(where: { $0.index == lastSipIndex }) {
                        return point
                    }
                    return chartData[safe: max(0, chartData.count / 2)]
                }()

                fundAnalysisStatsHeader(chartData: chartData)
                    .padding(.bottom, 14)

                fundRangeSelector
                    .padding(.bottom, 18)

                Chart {
                    ForEach(chartData) { point in
                        AreaMark(
                            x: .value("Point", point.index),
                            yStart: .value("Baseline", minVal),
                            yEnd: .value("NAV", point.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [lineColor.opacity(0.25), lineColor.opacity(0.03)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        LineMark(
                            x: .value("Point", point.index),
                            y: .value("NAV", point.value)
                        )
                        .foregroundStyle(lineColor)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }

                    if let highlightedPoint {
                        RuleMark(x: .value("Selected Date", highlightedPoint.index))
                            .foregroundStyle(Color.secondary.opacity(0.35))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 4]))

                        PointMark(
                            x: .value("Selected Date", highlightedPoint.index),
                            y: .value("NAV", highlightedPoint.value)
                        )
                        .foregroundStyle(lineColor)
                        .symbol {
                            Circle()
                                .fill(lineColor)
                                .frame(width: 11, height: 11)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(color: lineColor.opacity(0.35), radius: 4)
                        }
                        .annotation(position: .top, alignment: .center) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("₹ \(String(format: "%.2f", highlightedPoint.value))")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primary)
                                Text(displayDateLabel(for: highlightedPoint.date))
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.12), radius: 6, x: 0, y: 2)
                            )
                        }
                    }

                    if let first = chartData.first {
                        PointMark(
                            x: .value("Point", first.index),
                            y: .value("NAV", first.value)
                        )
                        .foregroundStyle(Color.blue)
                        .symbol {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                        }
                    }

                    if let last = chartData.last {
                        PointMark(
                            x: .value("Point", last.index),
                            y: .value("NAV", last.value)
                        )
                        .foregroundStyle(lineColor)
                        .symbol {
                            Circle()
                                .fill(lineColor)
                                .frame(width: 8, height: 8)
                                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                        }
                    }

                    ForEach(transactionPoints) { point in
                        PointMark(
                            x: .value("Point", point.index),
                            y: .value("NAV", point.value)
                        )
                        .foregroundStyle(Color.purple)
                        .symbol {
                            Circle()
                                .fill(Color.purple)
                                .frame(width: 7, height: 7)
                                .overlay(Circle().stroke(Color.white, lineWidth: 1.2))
                                .shadow(color: .purple.opacity(0.4), radius: 2)
                        }
                    }
                }
                .chartXScale(domain: 0...(max(chartData.count - 1, 1)))
                .chartYScale(domain: minVal...maxVal)
                .chartYAxis {
                    AxisMarks(position: .leading, values: yTicks) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                            .foregroundStyle(Color.secondary.opacity(0.10))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: monthLabels.map(\.index)) { value in
                        AxisTick(stroke: StrokeStyle(lineWidth: 1))
                            .foregroundStyle(lineColor)
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                            .foregroundStyle(lineColor.opacity(0.65))
                        AxisValueLabel {
                            if let index = value.as(Int.self),
                               let label = monthLabels.first(where: { $0.index == index })?.label {
                                Text(label)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .frame(height: 300)

                // ── Legend ───────────────────────────────────────────────────
                HStack(spacing: 16) {
                    HStack(spacing: 5) {
                        Circle().fill(Color.blue).frame(width: 7, height: 7)
                        Text("Entry price").font(.system(size: 10)).foregroundColor(.secondary)
                    }
                    HStack(spacing: 5) {
                        Circle().fill(lineColor).frame(width: 7, height: 7)
                        Text("Latest NAV").font(.system(size: 10)).foregroundColor(.secondary)
                    }
                    if !(inv?.installments ?? []).isEmpty {
                        HStack(spacing: 5) {
                            Circle().fill(Color.purple).frame(width: 7, height: 7)
                            Text(inv?.mode == .sip ? "SIP date" : "Purchase").font(.system(size: 10)).foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .investmentDetailCardStyle(colorScheme: colorScheme)
    }

    private func fundAnalysisStatsHeader(chartData: [InvestmentHistoryChartPoint]) -> some View {
        let values = chartData.map(\.value).filter { $0.isFinite && $0 > 0 }
        let high = values.max() ?? 0
        let low = values.min() ?? 0
        let cagr = fundCAGR(for: chartData)
        let cagrColor: Color = cagr >= 0 ? .green : .red

        return HStack(alignment: .top, spacing: 24) {
            fundStatBlock(title: "High", value: "₹\(String(format: "%.2f", high))", color: .primary)
            fundStatBlock(title: "Low", value: "₹\(String(format: "%.2f", low))", color: .primary)
            fundStatBlock(
                title: "CAGR",
                value: "\(cagr >= 0 ? "▲" : "▼") \(String(format: "%.2f", abs(cagr)))%",
                color: cagrColor
            )
            Spacer(minLength: 0)
        }
    }

    private func fundStatBlock(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(minWidth: 76, alignment: .leading)
    }

    private var fundRangeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(InvestmentFundChartRange.allCases) { range in
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                            selectedFundRange = range
                        }
                    } label: {
                        Text(range.rawValue)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(selectedFundRange == range ? .white : .primary)
                            .frame(minWidth: 54, minHeight: 38)
                            .background(
                                Rectangle()
                                    .fill(selectedFundRange == range ? Color.primary.opacity(0.92) : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
            }
        }
    }

    @ViewBuilder
    private var sipHistoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SIP History").font(.title2).fontWeight(.bold)
            
            VStack(spacing: 0) {
                let transactions = sipInstallments
                if transactions.isEmpty {
                    Text("No installments recorded yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(transactions) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.type == .sell ? "Sell Transaction" : "SIP Installment")
                                    .font(.caption)
                                    .foregroundColor(item.type == .sell ? .red : .secondary)
                                Text(item.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Units: \(String(format: "%.3f", item.units))")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("NAV / Rate: ₹\(String(format: "%.2f", item.nav))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("Amount: ₹\(String(format: "%.0f", item.amount))")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                            }
                        }
                        .padding()
                        if item.id != transactions.last?.id {
                            Divider().padding(.leading)
                        }
                    }
                }
            }
            .investmentDetailCardStyle(colorScheme: colorScheme)
        }
    }

    private func detailRow(label: String, value: String, valueColor: Color = .primary) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundColor(.primary)
            Spacer()
            Text(value).font(.subheadline).fontWeight(.semibold).foregroundColor(valueColor)
        }
        .padding()
    }

    private func dateRow(label: String, date: Date?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(label).font(.subheadline).foregroundColor(.primary)
                Spacer()
            }.padding()
            HStack {
                Spacer()
                Text(date != nil ? df.string(from: date!) : "—")
                    .font(.subheadline).fontWeight(.medium).foregroundColor(.primary)
            }
            .padding(.horizontal).padding(.bottom)
        }
    }

    private var riskLabel: String {
        switch inv?.investmentType {
        case .mutualFund:     return "Mutual Fund  •  Moderate Risk"
        case .stocks:         return "Equity  •  High Risk"
        case .goldETF:        return "Commodity  •  Low Risk"
        case .physicalGold:   return "Commodity  •  Low Risk"
        case .deposits:       return "Fixed Income  •  Low Risk"
        case .cryptocurrency: return "Crypto  •  Very High Risk"
        case .realEstate:     return "Real Estate  •  Low Risk"
        case .bonds:          return "Bonds  •  Low Risk"
        case .ppf:            return "PPF  •  Low Risk"
        case .nps:            return "NPS  •  Moderate Risk"
        case .cashSavings:    return "Cash Savings  •  Low Risk"
        case .emergencyFund:  return "Emergency Fund  •  Low Risk"
        case .other, .none:   return "Investment"
        }
    }

    private var historyChartPoints: [InvestmentHistoryChartPoint] {
        history.enumerated().compactMap { index, point in
            guard let value = Double(point.nav) else { return nil }
            return InvestmentHistoryChartPoint(index: index, date: point.date, value: value)
        }
    }

    private var fundAnalysisChartPoints: [InvestmentHistoryChartPoint] {
        let liveHistory = historyChartPoints.filter { $0.value.isFinite && $0.value > 0 }
        if !liveHistory.isEmpty {
            return liveHistory
        }

        return sipHistoryChartPoints
    }

    private var sipHistoryChartPoints: [InvestmentHistoryChartPoint] {
        guard let currentInv = inv else { return [] }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"

        var points = currentInv.installments
            .filter { $0.nav.isFinite && $0.nav > 0 }
            .sorted { $0.date < $1.date }
            .map { transaction in
                (date: transaction.date, value: transaction.nav)
            }

        if let currentNAV = currentInv.lastNAV, currentNAV.isFinite, currentNAV > 0 {
            let latestDate = currentInv.lastUpdated ?? Date()
            if points.isEmpty || points.last?.date != latestDate || points.last?.value != currentNAV {
                points.append((date: latestDate, value: currentNAV))
            }
        }

        return points.enumerated().map { index, point in
            InvestmentHistoryChartPoint(
                index: index,
                date: dateFormatter.string(from: point.date),
                value: point.value
            )
        }
    }

    private var valueChartPlaceholderPoints: [InvestmentHistoryChartPoint] {
        [
            InvestmentHistoryChartPoint(index: 0, date: "", value: 0.35),
            InvestmentHistoryChartPoint(index: 1, date: "", value: 0.45),
            InvestmentHistoryChartPoint(index: 2, date: "", value: 0.60),
            InvestmentHistoryChartPoint(index: 3, date: "", value: 0.75),
            InvestmentHistoryChartPoint(index: 4, date: "", value: 0.90)
        ]
    }

    private func valueChartDomain(for points: [InvestmentHistoryChartPoint]) -> ClosedRange<Double> {
        let vals = points.map(\.value)
        let minVal = vals.min() ?? 0
        let maxVal = vals.max() ?? 1
        let range = (maxVal - minVal) > 0 ? (maxVal - minVal) : 1
        let padding = range * 0.2142857143
        return (minVal - padding)...(maxVal + padding)
    }

    private func parsedDate(from chartDate: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter.date(from: chartDate)
    }

    private func displayDateLabel(for chartDate: String) -> String {
        guard let date = parsedDate(from: chartDate) else { return chartDate }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    private func fundCAGR(for points: [InvestmentHistoryChartPoint]) -> Double {
        guard let first = points.first,
              let last = points.last,
              first.value.isFinite,
              last.value.isFinite,
              first.value > 0,
              last.value > 0,
              let firstDate = parsedDate(from: first.date),
              let lastDate = parsedDate(from: last.date) else {
            return 0
        }

        let days = max(lastDate.timeIntervalSince(firstDate) / 86_400, 1)
        let years = days / 365.0
        return (pow(last.value / first.value, 1.0 / years) - 1.0) * 100
    }

    private func purchaseChartPoints(for chartData: [InvestmentHistoryChartPoint]) -> [InvestmentTransactionChartPoint] {
        let txList = inv?.installments ?? []
        guard chartData.count > 1, !txList.isEmpty else { return [] }

        if historyChartPoints.isEmpty {
            return txList
                .filter { $0.nav.isFinite && $0.nav > 0 }
                .sorted { $0.date < $1.date }
                .enumerated()
                .compactMap { index, tx in
                    guard chartData.indices.contains(index) else { return nil }
                    return InvestmentTransactionChartPoint(id: tx.id, index: index, value: tx.nav)
                }
        }

        let df = DateFormatter()
        df.dateFormat = "dd-MM-yyyy"

        return txList.compactMap { tx in
            let txDateStr = df.string(from: tx.date)
            let exactIndex = history.firstIndex { $0.date == txDateStr }
            let fallbackIndex: Int? = exactIndex == nil ? history.firstIndex { point in
                guard let hDate = df.date(from: point.date) else { return false }
                return hDate >= tx.date
            } : nil
            guard let hIndex = exactIndex ?? fallbackIndex,
                  history.indices.contains(hIndex),
                  let nav = Double(history[hIndex].nav) else { return nil }

            return InvestmentTransactionChartPoint(id: tx.id, index: hIndex, value: nav)
        }
    }

}

private extension View {
    func investmentDetailCardStyle(colorScheme: ColorScheme) -> some View {
        background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.04), lineWidth: 1)
        }
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.05), radius: 10, x: 0, y: 3)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    let sampleState = AppStateManager.withSampleData()
    let sampleID = sampleState.currentProfile?.investments.first?.id ?? UUID()
    return NavigationStack {
        InvestmentDetailView(investmentID: sampleID)
            .environment(sampleState)
    }
}
