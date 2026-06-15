import SwiftUI

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
            if let code = inv?.schemeCode {
                isLoadingHistory = true
                history = await MFService.shared.fetchHistoricalGraphData(schemeCode: code, startDate: inv?.startDate)
                isLoadingHistory = false
            } else if inv?.investmentType == .stocks, let symbol = inv?.symbol ?? inv?.investmentName {
                isLoadingHistory = true
                history = await StockService.shared.fetchStockChartHistory(symbol: symbol, startDate: inv?.startDate ?? Date())
                isLoadingHistory = false
            }
        }
        .onChange(of: inv?.schemeCode) { _ in
            Task {
                if let code = inv?.schemeCode {
                    isLoadingHistory = true
                    history = await MFService.shared.fetchHistoricalGraphData(schemeCode: code, startDate: inv?.startDate)
                    isLoadingHistory = false
                }
            }
        }
        .onChange(of: inv?.startDate) { _ in
            Task {
                if let code = inv?.schemeCode {
                    isLoadingHistory = true
                    history = await MFService.shared.fetchHistoricalGraphData(schemeCode: code, startDate: inv?.startDate)
                    isLoadingHistory = false
                }
            }
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
            GeometryReader { geo in
                Group {
                    if isLoadingHistory {
                        HStack {
                            Spacer()
                            ProgressView().controlSize(.small)
                            Spacer()
                        }
                        .frame(height: 120)
                    } else if !history.isEmpty {
                        let w = geo.size.width
                        let h: CGFloat = 120
                        let vals = history.compactMap { Double($0.nav) }
                        let minVal = vals.min() ?? 0
                        let maxVal = vals.max() ?? 1
                        let range = (maxVal - minVal) > 0 ? (maxVal - minVal) : 1

                        ZStack(alignment: .bottomLeading) {
                            Path { p in
                                p.move(to: CGPoint(x: 0, y: h))
                                for (i, val) in vals.enumerated() {
                                    let x = (w * CGFloat(i) / CGFloat(vals.count - 1))
                                    let normalizedVal = (val - minVal) / range
                                    let y = h * (1.0 - (normalizedVal * 0.7 + 0.15))
                                    p.addLine(to: CGPoint(x: x, y: y))
                                }
                                p.addLine(to: CGPoint(x: w, y: h)); p.closeSubpath()
                            }
                            .fill(LinearGradient(colors: [(profitPct >= 0 ? Color.green : Color.red).opacity(0.3), (profitPct >= 0 ? Color.green : Color.red).opacity(0.05)], startPoint: .top, endPoint: .bottom))

                            Path { p in
                                for (i, val) in vals.enumerated() {
                                    let x = (w * CGFloat(i) / CGFloat(vals.count - 1))
                                    let normalizedVal = (val - minVal) / range
                                    let y = h * (1.0 - (normalizedVal * 0.7 + 0.15))
                                    if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                                    else { p.addLine(to: CGPoint(x: x, y: y)) }
                                }
                            }
                            .stroke(profitPct >= 0 ? Color.green : Color.red, lineWidth: 2.5)

                            if let lastVal = vals.last {
                                 let x = w
                                 let normalizedVal = (lastVal - minVal) / range
                                 let y = h * (1.0 - (normalizedVal * 0.7 + 0.15))
                                 Circle().fill(profitPct >= 0 ? Color.green : Color.red).frame(width: 8, height: 8).position(x: x, y: y)
                            }
                        }
                    } else {
                        let w = geo.size.width
                        let h: CGFloat = 120
                        ZStack(alignment: .bottomLeading) {
                            Path { p in
                                let pts: [(CGFloat, CGFloat)] = [(0, 0.65),(w*0.25,0.55),(w*0.5,0.40),(w*0.75,0.25),(w,0.10)]
                                p.move(to: CGPoint(x: 0, y: h))
                                p.addLine(to: CGPoint(x: 0, y: h * pts[0].1))
                                for i in 1..<pts.count { p.addLine(to: CGPoint(x: pts[i].0, y: h * pts[i].1)) }
                                p.addLine(to: CGPoint(x: w, y: h)); p.closeSubpath()
                            }
                            .fill(LinearGradient(colors: [(profitPct >= 0 ? Color.green : Color.red).opacity(0.3), (profitPct >= 0 ? Color.green : Color.red).opacity(0.05)], startPoint: .top, endPoint: .bottom))

                            Path { p in
                                let pts: [(CGFloat, CGFloat)] = [(0, 0.65),(w*0.25,0.55),(w*0.5,0.40),(w*0.75,0.25),(w,0.10)]
                                p.move(to: CGPoint(x: pts[0].0, y: h * pts[0].1))
                                for i in 1..<pts.count { p.addLine(to: CGPoint(x: pts[i].0, y: h * pts[i].1)) }
                            }
                            .stroke(profitPct >= 0 ? Color.green : Color.red, lineWidth: 2.5)

                            Circle().fill(profitPct >= 0 ? Color.green : Color.red).frame(width: 8, height: 8).position(x: w, y: h * 0.10)
                        }
                    }
                }
            }
            .frame(height: 120).padding(.horizontal)
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
                dateRow(label: "Investment Date", date: inv?.startDate)
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
            } else if history.isEmpty {
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
                let vals     = history.compactMap { Double($0.nav) }
                let minVal   = (vals.min() ?? 0) * 0.995
                let maxVal   = (vals.max() ?? 1) * 1.005
                let range    = (maxVal - minVal) > 0 ? (maxVal - minVal) : 1
                let isProfit = (vals.last ?? 0) >= (vals.first ?? 0)
                let lineColor: Color = isProfit ? .green : .red

                // Month tick labels from history
                let monthLabels: [(index: Int, label: String)] = {
                    var result: [(Int, String)] = []
                    let df = DateFormatter(); df.dateFormat = "dd-MM-yyyy"
                    let mf = DateFormatter(); mf.dateFormat = "MMM yy"
                    var lastMonth = -1
                    for (i, pt) in history.enumerated() {
                        if let d = df.date(from: pt.date) {
                            let m = Calendar.current.component(.month, from: d)
                            if m != lastMonth {
                                result.append((i, mf.string(from: d)))
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

                GeometryReader { geo in
                    let leftPad:  CGFloat = 54
                    let rightPad: CGFloat = 12
                    let topPad:   CGFloat = 16
                    let botPad:   CGFloat = 28   // space for month labels
                    let w = geo.size.width - leftPad - rightPad
                    let h = geo.size.height - topPad - botPad

                    let xPos: (Int) -> CGFloat = { i in
                        guard vals.count > 1 else { return leftPad }
                        return leftPad + w * CGFloat(i) / CGFloat(vals.count - 1)
                    }
                    let yPos: (Double) -> CGFloat = { val in
                        let ratio = (val - minVal) / range
                        return topPad + h * CGFloat(1.0 - ratio)
                    }

                    ZStack(alignment: .topLeading) {

                        // ── Grid lines + Y-axis labels ───────────────────────
                        let yTicks: [Double] = [minVal, minVal + range*0.33, minVal + range*0.66, maxVal]
                        ForEach(yTicks.indices, id: \.self) { i in
                            let y = yPos(yTicks[i])
                            Path { p in
                                p.move(to:    CGPoint(x: leftPad, y: y))
                                p.addLine(to: CGPoint(x: leftPad + w, y: y))
                            }
                            .stroke(Color.gray.opacity(0.15), style: StrokeStyle(lineWidth: 0.7, dash: [4, 4]))

                            Text("₹\(String(format: "%.0f", yTicks[i]))")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                                .frame(width: leftPad - 4, alignment: .trailing)
                                .position(x: (leftPad - 4) / 2, y: y)
                        }

                        // ── Area fill ────────────────────────────────────────
                        Path { p in
                            guard vals.count > 1 else { return }
                            p.move(to: CGPoint(x: xPos(0), y: topPad + h))
                            for (i, val) in vals.enumerated() {
                                p.addLine(to: CGPoint(x: xPos(i), y: yPos(val)))
                            }
                            p.addLine(to: CGPoint(x: xPos(vals.count - 1), y: topPad + h))
                            p.closeSubpath()
                        }
                        .fill(LinearGradient(
                            colors: [lineColor.opacity(0.25), lineColor.opacity(0.03)],
                            startPoint: .top, endPoint: .bottom))

                        // ── Line stroke ──────────────────────────────────────
                        Path { p in
                            guard vals.count > 1 else { return }
                            for (i, val) in vals.enumerated() {
                                let pt = CGPoint(x: xPos(i), y: yPos(val))
                                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                            }
                        }
                        .stroke(lineColor, lineWidth: 2)

                        // ── Entry dot (first point) ──────────────────────────
                        if let first = vals.first {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                                .position(x: xPos(0), y: yPos(first))

                            // Entry label
                            VStack(spacing: 1) {
                                Text("Entry").font(.system(size: 8, weight: .bold)).foregroundColor(.blue)
                                Text("₹\(String(format: "%.2f", first))").font(.system(size: 8)).foregroundColor(.secondary)
                            }
                            .position(x: xPos(0) + 28, y: yPos(first) - 14)
                        }

                        // ── Latest dot (last point) ──────────────────────────
                        if let last = vals.last {
                            Circle()
                                .fill(lineColor)
                                .frame(width: 8, height: 8)
                                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                                .position(x: xPos(vals.count - 1), y: yPos(last))

                            // Latest label
                            VStack(spacing: 1) {
                                Text("Latest").font(.system(size: 8, weight: .bold)).foregroundColor(lineColor)
                                Text("₹\(String(format: "%.2f", last))").font(.system(size: 8)).foregroundColor(.secondary)
                            }
                            .position(x: xPos(vals.count - 1) - 30, y: yPos(last) - 14)
                        }

                        // ── SIP / purchase dots (purple) ─────────────────────
                        if !sipInstallments.isEmpty || inv?.mode == .lumpsum {
                            let txList = inv?.mode == .sip
                                ? (inv?.installments ?? [])
                                : (inv?.installments ?? [])   // lumpsum has 1 tx
                            ForEach(txList) { tx in
                                if let pos = sipDotPosition(for: tx, chartWidth: w, chartHeight: h,
                                                            xOffset: leftPad, yOffset: topPad) {
                                    // Purple filled circle with white border
                                    Circle()
                                        .fill(Color.purple)
                                        .frame(width: 7, height: 7)
                                        .overlay(Circle().stroke(Color.white, lineWidth: 1.2))
                                        .shadow(color: .purple.opacity(0.4), radius: 2)
                                        .position(x: pos.x, y: pos.y)
                                }
                            }
                        }

                        // ── Month labels on X-axis ───────────────────────────
                        ForEach(monthLabels.indices, id: \.self) { mi in
                            let item = monthLabels[mi]
                            Text(item.label)
                                .font(.system(size: 7.5))
                                .foregroundColor(.secondary)
                                .position(x: xPos(item.index),
                                          y: topPad + h + botPad - 8)
                        }

                        // ── Vertical axis line ───────────────────────────────
                        Path { p in
                            p.move(to:    CGPoint(x: leftPad, y: topPad))
                            p.addLine(to: CGPoint(x: leftPad, y: topPad + h))
                        }
                        .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                    }
                }
                .frame(height: 240)

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
                                Text(item.type == .sell ? "Sell Transaction" : "Buy Transaction")
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
                                Text("At NAV: ₹\(String(format: "%.2f", item.nav))")
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
        case .other, .none:   return "Investment"
        }
    }

    private func sipDotPosition(for tx: AstraInvestmentTransaction, chartWidth: CGFloat, chartHeight: CGFloat,
                                xOffset: CGFloat = 40, yOffset: CGFloat = 0) -> (x: CGFloat, y: CGFloat)? {
        let vals = history.compactMap { Double($0.nav) }
        guard vals.count > 1 else { return nil }
        let minV = (vals.min() ?? 0) * 0.995
        let maxV = (vals.max() ?? 1) * 1.005
        let rng = (maxV - minV) > 0 ? (maxV - minV) : 1

        let df = DateFormatter()
        df.dateFormat = "dd-MM-yyyy"
        let txDateStr = df.string(from: tx.date)

        let exactIndex = history.firstIndex { $0.date == txDateStr }
        let fallbackIndex: Int? = exactIndex == nil ? history.firstIndex { point in
            guard let hDate = df.date(from: point.date) else { return false }
            return hDate >= tx.date
        } : nil
        guard let hIndex = exactIndex ?? fallbackIndex,
              history.indices.contains(hIndex),
              let nav = Double(history[hIndex].nav) else { return nil }

        let x = xOffset + (chartWidth * CGFloat(hIndex) / CGFloat(history.count - 1))
        let ratio = (nav - minV) / rng
        let y = yOffset + chartHeight * CGFloat(1.0 - ratio)
        return (x, y)
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

#Preview {
    let sampleState = AppStateManager.withSampleData()
    let sampleID = sampleState.currentProfile?.investments.first?.id ?? UUID()
    return NavigationStack {
        InvestmentDetailView(investmentID: sampleID)
            .environment(sampleState)
    }
}
