import SwiftUI
import Charts

struct GoalDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    var appState: AppStateManager

    let goalID: UUID

    private var goal: AstraGoal? {
        appState.currentProfile?.goals.first(where: { $0.id == goalID })
    }

    private var goalName: String {
        goal?.goalName ?? "Goal Details"
    }

    private var targetAmount: Double {
        goal?.targetAmount ?? 0
    }

    private var currentAmount: Double {
        goal?.currentAmount ?? 0
    }

    private var remainingAmount: Double {
        max(targetAmount - currentAmount, 0)
    }

    private var completionPercentage: Double {
        if targetAmount > 0 {
            return min(currentAmount / targetAmount, 1.0)
        }
        return 0.0
    }

    private var timeLeftBinding: String {
        guard let endDate = goal?.targetDate else { return "N/A" }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: Date(), to: endDate)
        let y = max(components.year ?? 0, 0)
        let m = max(components.month ?? 0, 0)

        if y == 0 && m == 0 {
            return "Due"
        }
        return "\(y)Y \(m)M"
    }

    private var calendar: Calendar { Calendar.current }
    private var df: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }

    private var firstDate: Date {
        let linked = goal.map { appState.investments(for: $0.id) } ?? []
        return linked.map { $0.startDate }.min() ?? Date()
    }

    private var progressData: [ProgressDataPoint] {
        let components = calendar.dateComponents([.month], from: firstDate, to: Date())
        let monthsPassed = max(1, components.month ?? 0)

        var points: [ProgressDataPoint] = []
        let step = currentAmount / Double(max(1, monthsPassed))

        for i in (0...monthsPassed).reversed() {
            if let date = calendar.date(byAdding: .month, value: -i, to: Date()) {
                let monthName = shortDF.string(from: date)
                let amount = Double(monthsPassed - i) * step
                points.append(ProgressDataPoint(month: monthName, amount: amount))
            }
        }

        if points.count < 2 {
            let prevDate = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            points.insert(ProgressDataPoint(month: shortDF.string(from: prevDate), amount: 0), at: 0)
        }

        return points
    }

    private var dynamicSIPData: [SIPBarPoint] {
        let linked = goal.map { appState.investments(for: $0.id) } ?? []
        guard !linked.isEmpty else {

            return (1...6).map { i in SIPBarPoint(month: "M\(i)", amount: 0) }
        }

        var data: [SIPBarPoint] = []
        let components = calendar.dateComponents([.month], from: firstDate, to: Date())
        let monthsPassed = max(5, components.month ?? 0) 

        let sipBase = linked.filter { $0.mode == .sip }.reduce(0.0) { $0 + $1.investmentAmount }

        for i in (0...monthsPassed).reversed() {
            if let date = calendar.date(byAdding: .month, value: -i, to: Date()) {

                let monthName = shortDF.string(from: date)

                var amount = sipBase

                if i > 0 && i % 4 == 0 { amount *= 1.2 } 

                data.append(SIPBarPoint(month: monthName, amount: amount))
            }
        }

        return data.suffix(12)
    }

    private var shortDF: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f
    }

    private var sipBaseAmount: Double {
        let linked = goal.map { appState.investments(for: $0.id) } ?? []
        return linked.filter { $0.mode == .sip }.reduce(0.0) { $0 + $1.investmentAmount }
    }

    private var linkedFundName: String {
        let linked = goal.map { appState.investments(for: $0.id) } ?? []
        if linked.isEmpty { return "" }
        if linked.count == 1 { return linked[0].investmentName }
        return "\(linked.count) Funds Attached"
    }

    private let gradient: [Color] = [.orange, .red]

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroCard
                progressChartCard
                sipContributionCard
                detailInfoCard
            }
            .padding()
            .padding(.bottom, 30)
        }
        .navigationTitle(goalName)
        .navigationBarTitleDisplayMode(.large)
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
            if let goal = goal {
                EditGoalView(goal: goal)
            }
        }
        .alert("Delete Goal", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let g = goal {
                    appState.deleteGoal(g)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to remove this goal?")
        }
        .background(AppTheme.appBackground(for: colorScheme))
    }

    private var heroCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: gradient[0].opacity(0.4), radius: 16, x: 0, y: 8)

            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Target Amount")
                            .font(.subheadline).foregroundColor(.white.opacity(0.8))
                        Text(targetAmount.toCurrency())
                            .font(.system(size: 32, weight: .bold)).foregroundColor(.white)
                        Text(linkedFundName)
                            .font(.caption).foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.25), lineWidth: 8)
                            .frame(width: 70, height: 70)
                        Circle()
                            .trim(from: 0, to: CGFloat(completionPercentage))
                            .stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 70, height: 70)
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 0) {
                            Text("\(Int(completionPercentage * 100))%").font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                            Text("done").font(.system(size: 9)).foregroundColor(.white.opacity(0.8))
                        }
                    }
                }

                Divider().background(Color.white.opacity(0.3))

                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Collected").font(.caption).foregroundColor(.white.opacity(0.75))
                        Text(currentAmount.toCurrency()).font(.subheadline).fontWeight(.bold).foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Rectangle().fill(Color.white.opacity(0.3)).frame(width: 1, height: 34)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Remaining").font(.caption).foregroundColor(.white.opacity(0.75))
                        Text(remainingAmount.toCurrency()).font(.subheadline).fontWeight(.bold).foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 16)

                    Rectangle().fill(Color.white.opacity(0.3)).frame(width: 1, height: 34)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Time Left").font(.caption).foregroundColor(.white.opacity(0.75))
                        Text(timeLeftBinding).font(.subheadline).fontWeight(.bold).foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 16)
                }
            }
            .padding(20)
        }
    }

    private var progressChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Collection Progress").font(.headline).fontWeight(.semibold)
                Spacer()
                Text("2024")
                    .font(.caption).foregroundColor(.secondary)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(8)
            }

            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .trailing, spacing: 0) {
                    Text(targetAmount.toCurrency()).font(.caption2).foregroundColor(.secondary)
                    Spacer()
                    Text((targetAmount * 0.6).toCurrency()).font(.caption2).foregroundColor(.secondary)
                    Spacer()
                    Text((targetAmount * 0.3).toCurrency()).font(.caption2).foregroundColor(.secondary)
                    Spacer()
                    Text("0").font(.caption2).foregroundColor(.secondary)
                }
                .frame(width: 44, height: 150)

                Chart(progressData) { dp in
                    LineMark(x: .value("Month", dp.month), y: .value("Amount", dp.amount))
                        .foregroundStyle(LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing))
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .symbol(Circle().strokeBorder(lineWidth: 2))
                        .symbolSize(30)
                    AreaMark(x: .value("Month", dp.month), y: .value("Amount", dp.amount))
                        .foregroundStyle(LinearGradient(
                            colors: [gradient[0].opacity(0.25), gradient[0].opacity(0.03)],
                            startPoint: .top, endPoint: .bottom))
                }
                .frame(height: 150)
                .chartYScale(domain: 0...(max(targetAmount, 1000)))
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel().font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }

            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2).fill(gradient[0]).frame(width: 20, height: 3)
                Text("Collected Amount").font(.caption2).foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right").font(.caption2).foregroundColor(.green)
                    Text("Almost there! \(remainingAmount.toCurrency()) to go").font(.caption2).foregroundColor(.green).fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
    }

    private var sipContributionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Monthly SIP Contributions").font(.headline).fontWeight(.semibold)
                Spacer()
                HStack(spacing: 4) {
                    Circle().fill(gradient[0]).frame(width: 8, height: 8)
                    Text("\(sipBaseAmount.toCurrency()) base").font(.caption2).foregroundColor(.secondary)
                }
            }

            Chart(dynamicSIPData) { item in
                BarMark(x: .value("Month", item.month), y: .value("Amount", item.amount))
                    .foregroundStyle(
                        item.amount > sipBaseAmount
                            ? LinearGradient(colors: gradient, startPoint: .bottom, endPoint: .top)
                            : LinearGradient(colors: [gradient[0].opacity(0.4), gradient[0].opacity(0.4)], startPoint: .bottom, endPoint: .top)
                    )
                    .cornerRadius(4)
            }
            .frame(height: 120)
            .chartYScale(domain: 0...(max(sipBaseAmount * 1.5, 1000)))
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel().font(.caption2).foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2).fill(gradient[0]).frame(width: 14, height: 10)
                    Text("Extra top-up").font(.caption2).foregroundColor(.secondary)
                }
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2).fill(gradient[0].opacity(0.4)).frame(width: 14, height: 10)
                    Text("Regular SIP").font(.caption2).foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
    }

    private var detailInfoCard: some View {
        let linked = goal.map { appState.investments(for: $0.id) } ?? []
        let fundNames = linked.isEmpty ? "None Linked" : linked.map { $0.investmentName }.joined(separator: ", ")
        let totalSipAmount = linked.filter { $0.mode == .sip }.reduce(0.0) { $0 + $1.investmentAmount }

        return VStack(spacing: 14) {
            DetailInfoRow(label: "Goal Name",     value: goalName)
            Divider()
            DetailInfoRow(label: linked.count > 1 ? "Funds Attached" : "Primary Fund",  value: fundNames)
            Divider()
            DetailInfoRow(label: "Monthly SIP",   value: totalSipAmount.toCurrency())
            Divider()
            DetailInfoRow(label: "Started On",    value: df.string(from: firstDate))
            Divider()
            DetailInfoRow(label: "Last Invested", value: df.string(from: calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()))
            Divider()
            DetailInfoRow(label: "Next Due Date", value: df.string(from: Date()))
            Divider()
            HStack {
                Text("Status").font(.subheadline).foregroundColor(.secondary)
                Spacer()
                Text(currentAmount >= targetAmount ? "Achieved" : "In Progress")
                    .font(.subheadline).fontWeight(.medium)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
    }
}

#Preview {
    let sampleState = AppStateManager.withSampleData()
    let goalID = sampleState.currentProfile?.goals.first?.id ?? UUID()
    NavigationStack {
        GoalDetailView(appState: sampleState, goalID: goalID)
    }
}
