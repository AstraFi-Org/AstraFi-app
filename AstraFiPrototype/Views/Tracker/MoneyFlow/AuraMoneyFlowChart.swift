import SwiftUI
import Charts

// MARK: - Chart View
struct AuraMoneyFlowChart: View {
    let profile: AstraUserProfile
    @State private var selectedMonth: String? = nil

    // Palette
    private let incomeGreen  = Color(hex: "#30D158")
    private let expenseRed   = Color(hex: "#FF453A")
    private let incomeSoft   = Color(hex: "#30D158").opacity(0.75)
    private let expenseSoft  = Color(hex: "#FF6B6B").opacity(0.75)

    // MARK: Data model
    struct ChartEntry: Identifiable, Equatable {
        var id: String { "\(dateKey)-\(category)" }
        let month: String
        let dateKey: String
        let category: String
        let amount: Double      // positive = income, negative = expense
        let isIncome: Bool
    }

    var chartData: [ChartEntry] {
        let months = ["Jan","Feb","Mar","Apr","May","Jun",
                      "Jul","Aug","Sep","Oct","Nov","Dec"]
        var data: [ChartEntry] = []
        let snapshots = profile.monthlyCashflowSnapshots

        if snapshots.isEmpty {
            let cal  = Calendar.current
            let now  = Date()
            let mIdx = cal.component(.month, from: now) - 1
            let key  = String(format: "%d-%02d",
                              cal.component(.year, from: now),
                              mIdx + 1)
            data.append(.init(month: months[mIdx], dateKey: key,
                              category: "Total Income",
                              amount: profile.basicDetails.monthlyIncome.safeFinite,
                              isIncome: true))
            data.append(.init(month: months[mIdx], dateKey: key,
                              category: "Total Expenses",
                              amount: -profile.basicDetails.monthlyExpenses.safeFinite,
                              isIncome: false))
        } else {
            for key in snapshots.keys.sorted() {
                guard let snap = snapshots[key] else { continue }
                let parts = key.split(separator: "-")
                let mIdx: Int
                if parts.count >= 2, let parsedM = Int(parts[1]) {
                    mIdx = max(0, min(11, parsedM - 1))
                } else {
                    mIdx = 0
                }
                let lbl = months[mIdx]

                if snap.incomeSources.isEmpty && snap.expenseSources.isEmpty {
                    data.append(.init(month: lbl, dateKey: key,
                                      category: "Income",
                                      amount: snap.totalIncome.safeFinite, isIncome: true))
                    data.append(.init(month: lbl, dateKey: key,
                                      category: "Expenses",
                                      amount: -snap.totalExpenses.safeFinite, isIncome: false))
                } else {
                    for item in snap.incomeSources {
                        data.append(.init(month: lbl, dateKey: key,
                                          category: item.name,
                                          amount: item.amount.safeFinite, isIncome: true))
                    }
                    for item in snap.expenseSources {
                        data.append(.init(month: lbl, dateKey: key,
                                          category: item.name,
                                          amount: -item.amount.safeFinite, isIncome: false))
                    }
                }
            }
        }
        return data.filter { $0.amount.isFinite }
    }

    // MARK: Helpers
    private func barColor(for entry: ChartEntry) -> Color {
        entry.isIncome ? incomeGreen : expenseRed
    }

    private var uniqueMonths: [String] {
        // preserve insertion order
        var seen = Set<String>()
        return chartData.compactMap { seen.insert($0.month).inserted ? $0.month : nil }
    }

    private func totalIncome(_ month: String) -> Double {
        chartData.filter { $0.month == month && $0.isIncome }.map { $0.amount.safeFinite }.reduce(0, +)
    }
    private func totalExpense(_ month: String) -> Double {
        abs(chartData.filter { $0.month == month && !$0.isIncome }.map { $0.amount.safeFinite }.reduce(0, +))
    }
    private func netSaving(_ month: String) -> Double {
        totalIncome(month) - totalExpense(month)
    }

    // Month-over-month income growth
    private var growthInfo: (pct: Double, up: Bool)? {
        let sorted = Array(Set(chartData.map { $0.dateKey })).sorted()
        guard sorted.count >= 2 else { return nil }
        let last = sorted[sorted.count - 1]
        let prev = sorted[sorted.count - 2]
        let lastI = chartData.filter { $0.dateKey == last && $0.isIncome }.map { $0.amount.safeFinite }.reduce(0, +)
        let prevI = chartData.filter { $0.dateKey == prev && $0.isIncome }.map { $0.amount.safeFinite }.reduce(0, +)
        guard prevI > 0 else { return nil }
        let diff = lastI - prevI
        return (pct: ((abs(diff) / prevI) * 100).safeFinite, up: diff >= 0)
    }

    // MARK: Body
    var body: some View {
        VStack(spacing: 0) {
            // ── Chart
            Chart {
                ForEach(chartData) { entry in
                    BarMark(
                        x: .value("Month", entry.month),
                        y: .value("Amount", entry.amount)
                    )
                    .foregroundStyle(barColor(for: entry))
                    .opacity(selectedMonth == nil || selectedMonth == entry.month ? 1 : 0.35)
                    .cornerRadius(4)
                }

                // Zero baseline
                RuleMark(y: .value("Zero", 0))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    .foregroundStyle(Color.black)

                // Selection highlight
                if let sel = selectedMonth {
                    RuleMark(x: .value("Sel", sel))
                        .foregroundStyle(Color.secondary.opacity(0.12))
                        .lineStyle(StrokeStyle(lineWidth: 24))
                        .zIndex(-1)
                }
            }
            .chartXSelection(value: $selectedMonth)
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: max(1, min(uniqueMonths.count, 6)))
            .chartXAxis {
                AxisMarks { val in
                    AxisValueLabel()
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.secondary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading,
                          values: .automatic(desiredCount: 4)) { val in
                    AxisGridLine()
                        .foregroundStyle(Color.secondary.opacity(0.12))
                    AxisValueLabel {
                        if let v = val.as(Double.self), v != 0 {
                            Text(v.toCurrency(compact: true))
                                .font(.system(size: 10))
                                .foregroundStyle(Color.secondary)
                        }
                    }
                }
            }
            .chartPlotStyle { plot in
                plot.background(Color.clear)
            }
            .frame(height: 220)
            .padding(.horizontal, 12)
            .padding(.top, 16)

            // ── Bottom: tooltip or legend
            Group {
                if let sel = selectedMonth {
                    selectionTooltip(for: sel)
                } else {
                    legendStrip
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 20)
            .animation(.easeInOut(duration: 0.2), value: selectedMonth)
            
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.auraIndigo)
                Text("Click on any Month to see income and expense of that month")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
        
    }

    private var legendStrip: some View {
        HStack(spacing: 20) {
            legendDot(color: incomeGreen, label: "Income")
            legendDot(color: expenseRed,  label: "Expenses")
            if let g = growthInfo {
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: g.up ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                    Text(String(format: "%.0f%% vs last month", g.pct))
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(g.up ? incomeGreen : expenseRed)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background((g.up ? incomeGreen : expenseRed).opacity(0.1))
                .clipShape(Capsule())
            }
        }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.secondary)
        }
    }

    private func selectionTooltip(for month: String) -> some View {
        let inc = totalIncome(month)
        let exp = totalExpense(month)
        let net = netSaving(month)

        return HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                Text(month)
                    .font(.system(size: 13, weight: .bold))
                Text("Net saved: \(net >= 0 ? "+" : "")\(shortAmount(net))")
                    .font(.system(size: 11))
                    .foregroundStyle(net >= 0 ? incomeGreen : expenseRed)
            }
            Spacer()
            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text(shortAmount(inc))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(incomeGreen)
                    Text("In")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                VStack(spacing: 2) {
                    Text(shortAmount(exp))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(expenseRed)
                    Text("Out")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            Button {
                withAnimation { selectedMonth = nil }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.secondary.opacity(0.5))
            }
            .padding(.leading, 12)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }

    private func shortAmount(_ v: Double) -> String {
        guard v.isFinite else { return "₹0" }
        let a = abs(v)
        let s = v < 0 ? "-" : ""
        if a >= 1_00_00_000 { return "\(s)₹\(String(format: "%.1f", a/1_00_00_000))Cr" }
        if a >= 1_00_000     { return "\(s)₹\(String(format: "%.1f", a/1_00_000))L"   }
        if a >= 1_000        { return "\(s)₹\(String(format: "%.0f", a/1_000))K"      }
        return "\(s)₹\(a.safeInt)"
    }
}
