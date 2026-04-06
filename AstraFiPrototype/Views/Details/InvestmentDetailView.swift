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
        guard let amt = inv?.investmentAmount, amt > 0 else { return 0 }
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
            }
        }
        .onChange(of: inv) { oldInv, newInv in

            if oldInv?.startDate != newInv?.startDate || oldInv?.schemeCode != newInv?.schemeCode {
                Task {
                    if let code = newInv?.schemeCode {
                        isLoadingHistory = true
                        history = await MFService.shared.fetchHistoricalGraphData(schemeCode: code, startDate: newInv?.startDate)
                        isLoadingHistory = false
                    }
                }
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(inv?.investmentType.rawValue ?? "Mutual Fund")
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
            if let lastUpdated = inv?.lastUpdated {
                HStack {
                    Text("Last Sync: \(lastUpdated.formatted(date: .abbreviated, time: .shortened))")
                    Spacer()
                    Button {
                        Task { await appState.syncMutualFundNAVs(force: true) }
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
                    Task { await appState.syncMutualFundNAVs() }
                } label: {
                    Text("Sync Live Data").font(.caption2).foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 8, x: 0, y: 2)
    }

    private var valueChart: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geo in
                let w = geo.size.width
                let h: CGFloat = 120
                if isLoadingHistory {
                    HStack {
                        Spacer()
                        ProgressView().controlSize(.small)
                        Spacer()
                    }
                    .frame(height: 120)
                } else if !history.isEmpty {
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
            .frame(height: 120).padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 8, x: 0, y: 2)
    }

    private var detailsSection: some View {
        VStack(spacing: 0) {
            detailRow(label: "Invested Amount", value: inv?.investmentAmount.toCurrency() ?? "—")
            Divider().padding(.leading)

            if let pNAV = inv?.purchaseNAV {
                detailRow(label: "Avg. Purchase NAV", value: "₹\(String(format: "%.2f", pNAV))")
                Divider().padding(.leading)
            }

            if let units = inv?.units {
                detailRow(label: "Units", value: String(format: "%.3f", units))
                Divider().padding(.leading)
            }

            if let lastNAV = inv?.lastNAV {
                detailRow(label: "Current NAV", value: "₹\(String(format: "%.2f", lastNAV))", valueColor: profitPct >= 0 ? .green : .red)
                Divider().padding(.leading)
            }

            detailRow(label: gain >= 0 ? "Current Gain" : "Current Loss", value: gain >= 0 ? "+" + gain.toCurrency() : gain.toCurrency(), valueColor: gain >= 0 ? .green : .red)
            Divider().padding(.leading)
            detailRow(label: "Investment Mode", value: inv?.mode.rawValue ?? "—")
        }
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 8, x: 0, y: 2)
    }

    private var fundAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            VStack(spacing: 0) {
                dateRow(label: "Investment Date", date: inv?.startDate)
                Divider().padding(.leading)

                let projected = inv.flatMap { Calendar.current.date(byAdding: .year, value: 5, to: $0.startDate) }
                dateRow(label: "Projected Closing", date: projected)
            }
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 8, x: 0, y: 2)

            Text("Fund Analysis").font(.title2).fontWeight(.bold).padding(.top, 8)
            fundAnalysisChart
        }
    }

    private var fundAnalysisChart: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geo in
                let chartWidth = geo.size.width - 60
                let chartHeight: CGFloat = 180

                ZStack(alignment: .bottomLeading) {

                    Path { p in
                        p.move(to: CGPoint(x: 40, y: 0))
                        p.addLine(to: CGPoint(x: 40, y: chartHeight))
                    }.stroke(Color.gray.opacity(0.3), lineWidth: 1)

                    VStack(spacing: 0) {
                        if let lastNAV = inv?.lastNAV {
                            Text("Latest").font(.system(size: 8, weight: .bold)).foregroundColor(.green)
                            Text("₹\(String(format: "%.2f", lastNAV))").font(.caption2).foregroundColor(.secondary)
                            Spacer()
                            if let pNAV = inv?.purchaseNAV {
                                Text("Entry").font(.system(size: 8, weight: .bold)).foregroundColor(.blue)
                                Text("₹\(String(format: "%.2f", pNAV))").font(.caption2).foregroundColor(.secondary)
                            }
                        } else {
                            Text(actualCurrentValue.toCurrency()).font(.caption2).foregroundColor(.secondary)
                            Spacer()
                            Text((inv?.investmentAmount ?? 0).toCurrency()).font(.caption2).foregroundColor(.secondary)
                        }
                    }
                    .frame(width: 80, height: chartHeight, alignment: .leading)

                    Group {
                        if !history.isEmpty {
                            let vals = history.compactMap { Double($0.nav) }
                            let minVal = vals.min() ?? 0
                            let maxVal = vals.max() ?? 1
                            let range = (maxVal - minVal) > 0 ? (maxVal - minVal) : 1

                            ZStack(alignment: .bottomLeading) {

                                Path { p in
                                    p.move(to: CGPoint(x: 40, y: chartHeight))
                                    for (i, val) in vals.enumerated() {
                                        let x = 40 + (chartWidth * CGFloat(i) / CGFloat(vals.count - 1))
                                        let normalizedVal = (val - minVal) / range
                                        let y = chartHeight * (1.0 - (normalizedVal * 0.7 + 0.15))
                                        p.addLine(to: CGPoint(x: x, y: y))
                                    }
                                    p.addLine(to: CGPoint(x: 40 + chartWidth, y: chartHeight))
                                    p.closeSubpath()
                                }
                                .fill(LinearGradient(colors: [(profitPct >= 0 ? Color.green : Color.red).opacity(0.2), (profitPct >= 0 ? Color.green : Color.red).opacity(0.02)], startPoint: .top, endPoint: .bottom))

                                Path { p in
                                    for (i, val) in vals.enumerated() {
                                        let x = 40 + (chartWidth * CGFloat(i) / CGFloat(vals.count - 1))
                                        let normalizedVal = (val - minVal) / range
                                        let y = chartHeight * (1.0 - (normalizedVal * 0.7 + 0.15))
                                        if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                                        else { p.addLine(to: CGPoint(x: x, y: y)) }
                                    }
                                }
                                .stroke(profitPct >= 0 ? Color.green : Color.red, lineWidth: 2)

                                if let last = vals.last {
                                    let x = 40 + chartWidth
                                    let normalizedVal = (last - minVal) / range
                                    let y = chartHeight * (1.0 - (normalizedVal * 0.7 + 0.15))

                                    Text("₹\(String(format: "%.2f", last))")
                                        .font(.system(size: 8, weight: .bold))
                                        .padding(.horizontal, 4).padding(.vertical, 2)
                                        .background((profitPct >= 0 ? Color.green : Color.red).opacity(0.2))
                                        .cornerRadius(4)
                                        .position(x: x, y: y - 12)
                                }

                                let df = DateFormatter()
                                let yearDf = DateFormatter()
                                let _ = df.dateFormat = "dd-MM-yyyy"
                                let _ = yearDf.dateFormat = "yyyy"

                                HStack {
                                    if let firstStr = history.first?.date, let firstDate = df.date(from: firstStr) {
                                        Text(yearDf.string(from: firstDate)).font(.system(size: 8))
                                    }
                                    Spacer()
                                    if let lastStr = history.last?.date, let lastDate = df.date(from: lastStr) {
                                        Text(yearDf.string(from: lastDate)).font(.system(size: 8))
                                    }
                                }
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 40)
                                .offset(y: 12)
                            }
                        } else if isLoadingHistory {
                            ProgressView().position(x: geo.size.width/2, y: chartHeight/2)
                        } else {

                            Path { p in
                                let pts: [(CGFloat, CGFloat)] = [(0,0.55),(chartWidth*0.15,0.65),(chartWidth*0.35,0.45),(chartWidth,0.45)]
                                p.move(to: CGPoint(x: 40, y: chartHeight))
                                for (_, pt) in pts.enumerated() {
                                    p.addLine(to: CGPoint(x: pt.0 + 40, y: chartHeight * pt.1))
                                }
                                p.addLine(to: CGPoint(x: chartWidth + 40, y: chartHeight))
                                p.closeSubpath()
                            }
                            .fill(Color.green.opacity(0.1))
                        }
                    }

                    if let pNAV = inv?.purchaseNAV, history.count > 1 {
                        let vals = history.compactMap { Double($0.nav) }
                        let minV = vals.min() ?? 0
                        let maxV = vals.max() ?? 1
                        let rng = (maxV - minV) > 0 ? (maxV - minV) : 1

                        let ratio = (pNAV - minV) / rng
                        let y = chartHeight * (1.0 - (CGFloat(ratio) * 0.7 + 0.15))

                        if y > 0 && y < chartHeight {
                            Path { p in
                                p.move(to: CGPoint(x: 40, y: y))
                                p.addLine(to: CGPoint(x: geo.size.width, y: y))
                            }
                            .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 2]))
                        }
                    }
                }
            }
            .frame(height: 220)
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 8, x: 0, y: 2)
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
}

#Preview {
    let sampleState = AppStateManager.withSampleData()
    let sampleID = sampleState.currentProfile?.investments.first?.id ?? UUID()
    return NavigationStack {
        InvestmentDetailView(investmentID: sampleID)
            .environment(sampleState)
    }
}
