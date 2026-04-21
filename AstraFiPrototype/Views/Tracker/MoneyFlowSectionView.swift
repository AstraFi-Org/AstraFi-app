import SwiftUI
import Charts

struct TrackerMoneyFlowSection: View {
    @Environment(AppStateManager.self) var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingDetailSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Cash In & Out").font(.auraHeader(size: 22))
                Spacer()
                Button {
                    showingDetailSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(AppTheme.auraIndigo)
                }
            }

            VStack(spacing: 20) {
                if let profile = appState.currentProfile {
                    AuraMoneyFlowChart(profile: profile)
                        .frame(height: 300)
                } else {
                    TrackerEmptyState(icon: "chart.bar.fill", message: "No data available yet.")
                }
            }
            .auraCardStyle(radius: 34)
            .onTapGesture {
                showingDetailSheet = true
            }
        }
        .sheet(isPresented: $showingDetailSheet) {
            MoneyFlowSourceSheet()
        }
    }
}

struct AuraMoneyFlowChart: View {
    let profile: AstraUserProfile
    
    @State private var selectedMonth: String? = nil
    @State private var rawSelectedDate: Date? = nil // For newer ChartSelection versions
    
    struct ChartDataEntry: Identifiable, Equatable {
        let id = UUID()
        let month: String // Readable: "Jan"
        let dateKey: String // Sortable: "2024-01"
        let category: String
        let amount: Double
        let isIncome: Bool
    }
    
    var chartData: [ChartDataEntry] {
        var data: [ChartDataEntry] = []
        let snapshots = profile.monthlyCashflowSnapshots
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        
        if snapshots.isEmpty {
            // New User Fallback: Show current month only based on basic details
            let date = Date()
            let calendar = Calendar.current
            let monthLabel = months[calendar.component(.month, from: date)-1]
            let dateKey = String(format: "%d-%02d", calendar.component(.year, from: date), calendar.component(.month, from: date))
            
            // Show as unclassified if no specific sources
            data.append(ChartDataEntry(month: monthLabel, dateKey: dateKey, category: "Total Income", amount: profile.basicDetails.monthlyIncome, isIncome: true))
            data.append(ChartDataEntry(month: monthLabel, dateKey: dateKey, category: "Total Expenses", amount: -profile.basicDetails.monthlyExpenses, isIncome: false))
        } else {
            // Sort keys to ensure chronological order
            let sortedKeys = snapshots.keys.sorted()
            for key in sortedKeys {
                if let snapshot = snapshots[key] {
                    let parts = key.split(separator: "-")
                    let mIdx = Int(parts[1]) ?? 1
                    let monthLabel = months[mIdx-1]
                    
                    if snapshot.incomeSources.isEmpty && snapshot.expenseSources.isEmpty {
                        // Unclassified Month
                        data.append(ChartDataEntry(month: monthLabel, dateKey: key, category: "Total Income", amount: snapshot.totalIncome, isIncome: true))
                        data.append(ChartDataEntry(month: monthLabel, dateKey: key, category: "Total Expenses", amount: -snapshot.totalExpenses, isIncome: false))
                    } else {
                        for item in snapshot.incomeSources {
                            data.append(ChartDataEntry(month: monthLabel, dateKey: key, category: item.name, amount: item.amount, isIncome: true))
                        }
                        for item in snapshot.expenseSources {
                            data.append(ChartDataEntry(month: monthLabel, dateKey: key, category: item.name, amount: -item.amount, isIncome: false))
                        }
                    }
                }
            }
        }
        return data
    }

    private func color(for category: String, isIncome: Bool) -> Color {
        let cat = category.lowercased()
        if isIncome {
            if cat.contains("job") { return Color(hex: "#FF9F0A") }
            if cat.contains("tution") || cat.contains("tuition") { return Color(hex: "#32ADE6") }
            if cat.contains("rent") { return Color(hex: "#30D158") }
            return AppTheme.auraGreen
        } else {
            if cat.contains("house") || cat.contains("household") { return Color(hex: "#FF453A") }
            if cat.contains("entertainment") { return Color(hex: "#FF8080") }
            if cat.contains("transport") { return Color(hex: "#FFB3BA") }
            return AppTheme.auraIndigo.opacity(0.6)
        }
    }

    private var growthInfo: (percentage: Double, isIncrease: Bool)? {
        let sortedDates = Array(Set(chartData.map { $0.dateKey })).sorted()
        guard sortedDates.count >= 2 else { return nil }
        
        let last = sortedDates[sortedDates.count - 1]
        let prev = sortedDates[sortedDates.count - 2]
        
        let lastInc = chartData.filter { $0.dateKey == last && $0.isIncome }.map { $0.amount }.reduce(0, +)
        let prevInc = chartData.filter { $0.dateKey == prev && $0.isIncome }.map { $0.amount }.reduce(0, +)
        
        guard prevInc > 0 else { return nil }
        let diff = lastInc - prevInc
        return (percentage: (abs(diff) / prevInc) * 100, isIncrease: diff >= 0)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Growth Indicator
            if let growth = growthInfo {
                HStack(spacing: 4) {
                    Image(systemName: growth.isIncrease ? "arrow.up.right" : "arrow.down.right")
                    Text("\(Int(growth.percentage))% monthly growth in income")
                }
                .font(.auraCaption(size: 11, weight: .semibold))
                .foregroundColor(growth.isIncrease ? .green : .orange)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Circle().fill(.white).opacity(0.05).frame(width: 0, height: 0)) // Spacer behavior
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Chart {
                ForEach(chartData) { item in
                    BarMark(
                        x: .value("Month", item.month),
                        y: .value("Amount", item.amount)
                    )
                    .foregroundStyle(color(for: item.category, isIncome: item.isIncome))
                    .opacity(selectedMonth == nil || selectedMonth == item.month ? 1.0 : 0.4)
                    .cornerRadius(2)
                    .annotation(position: .overlay, alignment: .center) {
                        // Only show labels if the segment is large enough
                        if abs(item.amount) > 1500 {
                            VStack(spacing: 0) {
                                Text("\(Int(abs(item.amount)))")
                                    .font(.system(size: 10, weight: .bold))
                                Text(item.category)
                                    .font(.system(size: 7, weight: .medium))
                                    .lineLimit(1)
                            }
                            .foregroundColor(.black.opacity(0.8))
                            .padding(.horizontal, 2)
                        }
                    }
                }
                
                RuleMark(y: .value("Baseline", 0))
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .foregroundStyle(.white.opacity(0.8))
                
                // Totals Annotations (only for non-selected or matching selection)
                ForEach(Array(Set(chartData.map { $0.month })), id: \.self) { month in
                    let monthEntries = chartData.filter { $0.month == month }
                    let totalInc = monthEntries.filter { $0.isIncome }.map { $0.amount }.reduce(0, +)
                    let totalExp = monthEntries.filter { !$0.isIncome }.map { $0.amount }.reduce(0, +)
                    
                    if totalInc > 0 {
                        BarMark(x: .value("Month", month), y: .value("Amount", 0))
                        .annotation(position: .top) {
                            if selectedMonth == month || selectedMonth == nil {
                                Text("\(Int(totalInc))")
                                    .font(.auraCaption(size: 8, weight: .bold))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    if totalExp < 0 {
                        BarMark(x: .value("Month", month), y: .value("Amount", 0))
                        .annotation(position: .bottom) {
                            if selectedMonth == month || selectedMonth == nil {
                                Text("\(Int(abs(totalExp)))")
                                    .font(.auraCaption(size: 8, weight: .bold))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                if let selectedMonth {
                    RuleMark(x: .value("Selected", selectedMonth))
                        .foregroundStyle(.white.opacity(0.1))
                        .offset(y: 0)
                        .zIndex(-1)
                }
            }
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: chartData.count > 6 ? 6 : chartData.count)
            .chartXSelection(value: $selectedMonth)
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel().font(.auraCaption(size: 10))
                }
            }
            .chartYAxis(.hidden)
            .chartPlotStyle { plotContent in
                plotContent.background(Color.clear)
            }
            .frame(height: 240)
            
            // Selection Detail Tooltip (Custom)
            if let selectedMonth {
                let monthEntries = chartData.filter { $0.month == selectedMonth }
                let totalInc = monthEntries.filter { $0.isIncome }.map { $0.amount }.reduce(0, +)
                let totalExp = monthEntries.filter { !$0.isIncome }.map { $0.amount }.reduce(0, +)
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedMonth).font(.auraCaption(weight: .bold))
                        Text("Net: ₹\(Int(totalInc + totalExp))").font(.auraCaption(size: 10)).foregroundColor(.secondary)
                    }
                    Spacer()
                    Button { self.selectedMonth = nil } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.05)))
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                HStack(spacing: 16) {
                    _LegendItem(label: "Income", color: AppTheme.auraGreen)
                    _LegendItem(label: "Expenses", color: Color(hex: "#FF453A"))
                }
                .transition(.opacity)
            }
        }
    }
}

struct _LegendItem: View {
    let label: String
    let color: Color
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.auraCaption()).foregroundColor(.secondary)
        }
    }
}

struct MoneyFlowSourceSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppStateManager.self) var appState
    
    @State private var incomeSources: [CashflowEntry.DetailedItem] = []
    @State private var expenseSources: [CashflowEntry.DetailedItem] = []
    
    @State private var newIncomeName = ""
    @State private var newIncomeAmount = ""
    @State private var newExpenseName = ""
    @State private var newExpenseAmount = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Income Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Income Sources")
                                .font(.headline).foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                            
                            VStack(spacing: 0) {
                                ForEach($incomeSources) { $source in
                                    _SourceRow(name: $source.name, amount: $source.amount)
                                    Divider()
                                }
                                
                                _AddSourceRow(name: $newIncomeName, amount: $newIncomeAmount) {
                                    if let amt = Double(newIncomeAmount), !newIncomeName.isEmpty {
                                        incomeSources.append(.init(name: newIncomeName, amount: amt))
                                        newIncomeName = ""; newIncomeAmount = ""
                                    }
                                }
                            }
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(16)
                        }
                        
                        // Expense Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Expense Sources")
                                .font(.headline).foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                            
                            VStack(spacing: 0) {
                                ForEach($expenseSources) { $source in
                                    _SourceRow(name: $source.name, amount: $source.amount)
                                    Divider()
                                }
                                
                                _AddSourceRow(name: $newExpenseName, amount: $newExpenseAmount) {
                                    if let amt = Double(newExpenseAmount), !newExpenseName.isEmpty {
                                        expenseSources.append(.init(name: newExpenseName, amount: amt))
                                        newExpenseName = ""; newExpenseAmount = ""
                                    }
                                }
                            }
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(16)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Update Money Flow")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveData()
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                loadData()
            }
        }
    }
    
    private func loadData() {
        if let cf = appState.currentProfile?.cashflowData {
            incomeSources = cf.incomeSources
            expenseSources = cf.expenseSources
        }
        
        // Add predefined if empty
        if incomeSources.isEmpty {
            incomeSources = [
                .init(name: "Job", amount: 0),
                .init(name: "Rent from tenants", amount: 0)
            ]
        }
        if expenseSources.isEmpty {
            expenseSources = [
                .init(name: "Daily Household", amount: 0),
                .init(name: "Entertainment", amount: 0),
                .init(name: "Transport", amount: 0)
            ]
        }
    }
    
    private func saveData() {
        var cf = appState.currentProfile?.cashflowData ?? CashflowEntry()
        cf.incomeSources = incomeSources.filter { $0.amount > 0 }
        cf.expenseSources = expenseSources.filter { $0.amount > 0 }
        appState.updateCashflow(cf)
        
        // Save current snapshot for history
        if var profile = appState.currentProfile {
            let df = DateFormatter(); df.dateFormat = "yyyy-MM"
            let key = df.string(from: Date())
            profile.monthlyCashflowSnapshots[key] = cf
            appState.currentProfile = profile
        }
    }
}

struct _SourceRow: View {
    @Binding var name: String
    @Binding var amount: Double
    
    var body: some View {
        HStack {
            TextField("Name", text: $name)
                .font(.body)
            Spacer()
            HStack(spacing: 4) {
                Text("₹")
                TextField("0", value: $amount, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
            }
            .font(.body.weight(.semibold))
        }
        .padding()
    }
}

struct _AddSourceRow: View {
    @Binding var name: String
    @Binding var amount: String
    let onAdd: () -> Void
    
    var body: some View {
        HStack {
            TextField("Source Name", text: $name)
                .font(.body).foregroundColor(.secondary)
            TextField("Amount", text: $amount)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
        }
        .padding()
    }
}



