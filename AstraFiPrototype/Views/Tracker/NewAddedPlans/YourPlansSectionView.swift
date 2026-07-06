import SwiftUI
import Charts

struct TrackerFollowedPlansSection: View {
    let plans: [InvestmentPlanModel]
    @Environment(TrackerViewModel.self) private var trackerVM

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Followed Plans").font(.auraHeader(size: 22))
                Spacer()
                NavigationLink(destination: FollowedPlansListView(plans: plans)) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.auraIndigo)
                }
            }
            .padding(.horizontal, 8)

            VStack(spacing: 12) {
                ForEach(Array(plans.prefix(3))) { plan in
                    let snapshot = trackerVM.followedPlanSnapshot(for: plan)
                    NavigationLink(destination: FollowedPlanDetailView(snapshot: snapshot)) {
                        FollowedPlanCard(snapshot: snapshot)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct FollowedPlansListView: View {
    let plans: [InvestmentPlanModel]
    @Environment(TrackerViewModel.self) private var trackerVM
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        List {
            ForEach(plans) { plan in
                let snapshot = trackerVM.followedPlanSnapshot(for: plan)
                NavigationLink(destination: FollowedPlanDetailView(snapshot: snapshot)) {
                    FollowedPlanCard(snapshot: snapshot)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            }
            .onDelete { indexSet in
                for index in indexSet {
                    trackerVM.unfollowPlan(planName: plans[index].name)
                }
            }
        }
        .listStyle(.plain)
        .background(AppTheme.appBackground(for: colorScheme))
        .navigationTitle("Followed Plans")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FollowedPlanCard: View {
    let snapshot: FollowedPlanSnapshot

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().stroke(Color.blue.opacity(0.15), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: snapshot.progress)
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(snapshot.progress * 100))%")
                    .font(.auraDigital(size: 13))
                    .foregroundColor(progressColor)
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 6) {
                Text(snapshot.plan.name)
                    .font(.auraHeader(size: 17))
                    .lineLimit(2)
                Text("Following since \(snapshot.dateFollowed)")
                    .font(.auraCaption())
                    .foregroundColor(.secondary)
                Text(snapshot.healthStatus)
                    .font(.auraCaption(size: 12, weight: .semibold))
                    .foregroundColor(progressColor)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(snapshot.currentValue.toCurrency(compact: true))
                    .font(.auraDigital(size: 17))
                Text("Target \(snapshot.targetAmount.toCurrency(compact: true))")
                    .font(.auraCaption(size: 12))
                    .foregroundColor(.secondary)
                Text("\(snapshot.targetYear)")
                    .font(.auraCaption(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.auraIndigo)
            }
        }
        .auraCardStyle(radius: 22)
    }

    private var progressColor: Color {
        switch snapshot.healthStatus {
        case "Ahead of Plan", "On Track": return .green
        case "Slightly Behind": return .orange
        default: return .red
        }
    }
}

struct FollowedPlanDetailView: View {
    let snapshot: FollowedPlanSnapshot
    @Environment(TrackerViewModel.self) private var trackerVM
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingEditSheet = false

    private var liveSnapshot: FollowedPlanSnapshot {
        let currentPlan = trackerVM.followedPlans.first { $0.id == snapshot.plan.id } ?? snapshot.plan
        return trackerVM.followedPlanSnapshot(for: currentPlan)
    }

    var body: some View {
        let item = liveSnapshot
        ScrollView {
            VStack(spacing: 16) {
                followedPlanSummary(item)
                portfolioHealthCard(item)
                expectedVsActualChart(item)
                allocationCard(item)
                linkedInvestmentsCard
                linkedLoansCard
                performanceAnalytics(item)
            }
            .padding(16)
        }
        .background(AppTheme.appBackground(for: colorScheme))
        .navigationTitle(item.plan.targetGoal.isEmpty ? "Followed Plan" : item.plan.targetGoal)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }
                .font(.headline)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            FollowedPlanEditSheet(plan: item.plan)
                .presentationDetents([.large])
        }
    }

    private func followedPlanSummary(_ item: FollowedPlanSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.plan.name).font(.auraHeader(size: 22))
                    Text("Scenario: \(item.scenario) • Risk: \(item.riskProfile)")
                        .font(.auraCaption())
                        .foregroundColor(.secondary)
                }
                Spacer()
                ProgressRing(progress: item.progress, color: statusColor(item.healthStatus))
                    .frame(width: 78, height: 78)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                followedMetric("Target", item.targetAmount.toCurrency(compact: true), .blue)
                followedMetric("Current Portfolio", item.currentValue.toCurrency(compact: true), .green)
                followedMetric("Achieved", "\(String(format: "%.1f", item.progress * 100))%", statusColor(item.healthStatus))
                followedMetric("Remaining", item.remainingAmount.toCurrency(compact: true), .orange)
            }
        }
        .auraCardStyle(radius: 24)
    }

    private func portfolioHealthCard(_ item: FollowedPlanSnapshot) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Portfolio Health").font(.headline)
                Text("Compared with the illustrative path you chose.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(item.healthStatus)
                .font(.caption.weight(.bold))
                .foregroundColor(statusColor(item.healthStatus))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(statusColor(item.healthStatus).opacity(0.12))
                .clipShape(Capsule())
        }
        .auraCardStyle(radius: 20)
    }

    private func expectedVsActualChart(_ item: FollowedPlanSnapshot) -> some View {
        let years = max(1, item.targetYear - Calendar.current.component(.year, from: Date()))

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Expected vs Actual Growth").font(.headline)
                Spacer()
                HStack(spacing: 12) {
                    allocationLegend(color: .blue, text: "Expected")
                    allocationLegend(color: .green, text: "How it is going")
                }
            }
            Chart {
                ForEach(planChartPoints(item, actual: false)) { point in
                    LineMark(
                        x: .value("Years", point.year),
                        y: .value("Value", point.value),
                        series: .value("Series", "Expected")
                    )
                        .foregroundStyle(Color.blue)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    PointMark(x: .value("Years", point.year), y: .value("Value", point.value))
                        .foregroundStyle(Color.blue)
                }
                ForEach(planChartPoints(item, actual: true)) { point in
                    LineMark(
                        x: .value("Years", point.year),
                        y: .value("Value", point.value),
                        series: .value("Series", "How it is going")
                    )
                        .foregroundStyle(Color.green)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    PointMark(x: .value("Years", point.year), y: .value("Value", point.value))
                        .foregroundStyle(Color.green)
                }
            }
            .chartXScale(domain: 0...years)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: min(years + 1, 6))) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let year = value.as(Int.self) {
                            Text(year == 0 ? "Now" : "+\(year)Y")
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(amount.toCurrency(compact: true))
                        }
                    }
                }
            }
            .frame(height: 180)
        }
        .auraCardStyle(radius: 20)
    }

    private func allocationCard(_ item: FollowedPlanSnapshot) -> some View {
        let rows = linkedAllocationRows(for: item)
        let totalLinked = rows.reduce(0.0) { $0 + $1.actualAmount }

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Planned Asset Allocation").font(.headline)
                Spacer()
                if totalLinked > 0 {
                    Text("Linked \(totalLinked.toCurrency(compact: true))")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.green)
                }
            }

            HStack(spacing: 12) {
                allocationLegend(color: .blue, text: "Planned")
                allocationLegend(color: .green, text: "Linked actual")
            }

            if item.allocation.isEmpty {
                Text("Allocation is tracked through linked investments for this strategy.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(rows) { row in
                    allocationRow(row)
                }
            }
        }
        .auraCardStyle(radius: 20)
    }

    private func allocationLegend(color: Color, text: String) -> some View {
        HStack(spacing: 5) {
            Capsule()
                .fill(color)
                .frame(width: 18, height: 5)
            Text(text)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)
        }
    }

    private func allocationRow(_ row: LinkedAllocationRow) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(row.name)
                    .font(.caption)
                    .lineLimit(1)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Plan \(String(format: "%.0f", row.plannedPercent))%")
                        .font(.caption.weight(.bold))
                    if row.actualAmount > 0 {
                        Text("\(String(format: "%.1f", row.actualPercent))% • \(row.actualAmount.toCurrency(compact: true))")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.green)
                    }
                }
            }

            GeometryReader { proxy in
                let width = proxy.size.width
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.16))
                        .frame(height: 6)
                    Capsule()
                        .fill(Color.blue)
                        .frame(width: width * min(max(row.plannedPercent / 100, 0), 1), height: 6)
                    Capsule()
                        .fill(Color.green)
                        .frame(width: width * min(max(row.actualPercent / 100, 0), 1), height: 4)
                }
            }
            .frame(height: 8)

            if !row.linkedInvestmentNames.isEmpty {
                Text(row.linkedInvestmentNames.joined(separator: ", "))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private func linkedAllocationRows(for item: FollowedPlanSnapshot) -> [LinkedAllocationRow] {
        let linkedNames = Set(item.plan.linkedInvestmentNames)
        let linkedInvestments = trackerVM.investments.filter { linkedNames.contains($0.name) }
        let totalLinked = linkedInvestments.reduce(0.0) { $0 + Double($1.amount) }

        var rows = item.allocation.map {
            LinkedAllocationRow(
                allocationID: $0.id,
                name: $0.name,
                plannedPercent: $0.percentage,
                actualAmount: 0,
                actualPercent: 0,
                linkedInvestmentNames: []
            )
        }

        for investment in linkedInvestments {
            guard let rowIndex = matchingAllocationIndex(for: investment, in: item.allocation) else { continue }
            rows[rowIndex].actualAmount += Double(investment.amount)
            rows[rowIndex].linkedInvestmentNames.append(investment.name)
        }

        guard totalLinked > 0 else { return rows }
        return rows.map { row in
            var updated = row
            updated.actualPercent = (row.actualAmount / totalLinked) * 100
            return updated
        }
    }

    private func matchingAllocationIndex(for investment: Investment, in allocations: [AssetAllocation]) -> Int? {
        let investmentText = "\(investment.name) \(investment.category)".lowercased()

        if let index = firstAllocationIndex(in: allocations, matching: ["liquid", "short-term", "short term"], investmentText: investmentText, investmentKeywords: ["liquid", "overnight", "money market", "short term", "short-term"]) {
            return index
        }
        if let index = firstAllocationIndex(in: allocations, matching: ["debt", "bond", "corporate"], investmentText: investmentText, investmentKeywords: ["debt", "bond", "gilt", "fixed income"]) {
            return index
        }
        if let index = firstAllocationIndex(in: allocations, matching: ["small cap", "smallcap"], investmentText: investmentText, investmentKeywords: ["small cap", "smallcap"]) {
            return index
        }
        if let index = firstAllocationIndex(in: allocations, matching: ["large cap", "largecap", "index"], investmentText: investmentText, investmentKeywords: ["large cap", "largecap", "index", "nifty", "sensex"]) {
            return index
        }
        if investmentText.contains("stock") || investmentText.contains("equity") {
            if let bluechip = allocations.firstIndex(where: { $0.name.localizedCaseInsensitiveContains("bluechip") || $0.name.localizedCaseInsensitiveContains("equity") }) {
                return bluechip
            }
            return allocations.firstIndex { $0.riskLevel == .high || $0.riskLevel == .mid }
        }
        if investmentText.contains("mutual fund") {
            return allocations.firstIndex { $0.name.localizedCaseInsensitiveContains("fund") }
        }

        return nil
    }

    private func firstAllocationIndex(
        in allocations: [AssetAllocation],
        matching allocationKeywords: [String],
        investmentText: String,
        investmentKeywords: [String]
    ) -> Int? {
        guard investmentKeywords.contains(where: { investmentText.contains($0) }) else { return nil }
        return allocations.firstIndex { allocation in
            let allocationName = allocation.name.lowercased()
            return allocationKeywords.contains { allocationName.contains($0) }
        }
    }

    private var linkedInvestmentsCard: some View {
        let linkedNames = Set(liveSnapshot.plan.linkedInvestmentNames)
        let linkedInvestments = trackerVM.investments.filter { linkedNames.contains($0.name) }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Linked Investments").font(.headline)
                Spacer()
                Button("Link") { showingEditSheet = true }
                    .font(.caption.weight(.bold))
            }
            if linkedInvestments.isEmpty {
                Text("No investments linked yet. Tap Edit to attach investments to this plan.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(linkedInvestments.prefix(5)) { investment in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(investment.name).font(.caption.weight(.semibold))
                            Text(investment.category).font(.caption2).foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(Double(investment.amount).toCurrency(compact: true))
                            .font(.caption.weight(.bold))
                    }
                }
            }
        }
        .auraCardStyle(radius: 20)
    }

    private var linkedLoansCard: some View {
        let linkedNames = Set(liveSnapshot.plan.linkedLoanNames)
        let linkedLoans = trackerVM.loans.filter { linkedNames.contains($0.name) }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Linked Loans").font(.headline)
                Spacer()
                Button("Link") { showingEditSheet = true }
                    .font(.caption.weight(.bold))
            }
            if linkedLoans.isEmpty {
                Text("No loans linked yet. Tap Edit to attach repayment data to this followed plan.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(linkedLoans.prefix(5)) { loan in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(loan.name).font(.caption.weight(.semibold))
                            Text("\(loan.emisPaid)/\(loan.totalEmis) EMIs paid").font(.caption2).foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(loan.totalAmount)
                            .font(.caption.weight(.bold))
                    }
                }
            }
        }
        .auraCardStyle(radius: 20)
    }

    private func performanceAnalytics(_ item: FollowedPlanSnapshot) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
            followedMetric("Expected CAGR", "\(String(format: "%.1f", item.expectedCAGR))%", .blue)
            followedMetric("Actual CAGR", "\(String(format: "%.1f", trackerVM.portfolioCAGR))%", .green)
            followedMetric("Difference", "\(String(format: "%+.1f", trackerVM.portfolioCAGR - item.expectedCAGR))%", .orange)
            followedMetric("Portfolio Return", "\(String(format: "%+.1f", trackerVM.portfolioReturnPct))%", .purple)
        }
    }

    private func followedMetric(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption).foregroundColor(.secondary)
            Text(value).font(.auraDigital(size: 18)).foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "Ahead of Plan", "On Track": return .green
        case "Slightly Behind": return .orange
        default: return .red
        }
    }

    private func planChartPoints(_ item: FollowedPlanSnapshot, actual: Bool) -> [PlanChartPoint] {
        let years = max(1, item.targetYear - Calendar.current.component(.year, from: Date()))
        let rate = max(0, actual ? trackerVM.portfolioCAGR : item.expectedCAGR) / 100.0
        let startValue: Double

        if actual {
            return [PlanChartPoint(year: 0, value: max(0, item.currentValue))]
        } else if item.plannedCurrentValue > 0 {
            startValue = item.plannedCurrentValue
        } else if item.targetAmount > 0 && rate > 0 {
            startValue = item.targetAmount / pow(1 + rate, Double(years))
        } else {
            startValue = max(0, item.currentValue * 0.95)
        }

        return (0...years).map { offset in
            let value: Double
            if !actual && item.targetAmount > startValue {
                let progress = Double(offset) / Double(years)
                value = startValue + ((item.targetAmount - startValue) * progress)
            } else {
                value = startValue * pow(1 + rate, Double(offset))
            }
            return PlanChartPoint(year: offset, value: value)
        }
    }
}

struct FollowedPlanEditSheet: View {
    let plan: InvestmentPlanModel
    @Environment(TrackerViewModel.self) private var trackerVM
    @Environment(\.dismiss) private var dismiss

    @State private var editedInput: InvestmentPlanInputModel
    @State private var selectedInvestments: Set<String>
    @State private var selectedLoans: Set<String>
    @State private var scenario: String

    init(plan: InvestmentPlanModel) {
        self.plan = plan
        _editedInput = State(initialValue: plan.input)
        _selectedInvestments = State(initialValue: Set(plan.linkedInvestmentNames))
        _selectedLoans = State(initialValue: Set(plan.linkedLoanNames))
        _scenario = State(initialValue: plan.selectedScenario ?? plan.input.followedScenario ?? (plan.name.contains("Loan Stress Test") ? "Moderate" : "Expected"))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Plan Details") {
                    TextField("Target Amount", text: $editedInput.targetAmount)
                        .keyboardType(.decimalPad)
                    TextField("Target Years", text: $editedInput.timePeriod)
                        .keyboardType(.numberPad)
                    TextField("Monthly SIP / Investment", text: $editedInput.amount)
                        .keyboardType(.decimalPad)

                    Picker("Risk Profile", selection: $editedInput.riskType) {
                        Text("Low").tag("Low")
                        Text("Moderate").tag("Moderate")
                        Text("High").tag("High")
                    }

                    Picker("Scenario", selection: $scenario) {
                        Text("Conservative").tag("Conservative")
                        Text("Expected").tag("Expected")
                        Text("Moderate").tag("Moderate")
                        Text("Aggressive").tag("Aggressive")
                    }
                }

                Section("Loan Strategy") {
                    Toggle("Open to Loan", isOn: $editedInput.openToLoan)
                    TextField("Bank Name", text: Binding(
                        get: { editedInput.bankName ?? "" },
                        set: { editedInput.bankName = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Interest Rate", value: Binding(
                        get: { editedInput.interestRate ?? 0 },
                        set: { editedInput.interestRate = $0 > 0 ? $0 : nil }
                    ), format: .number)
                    .keyboardType(.decimalPad)
                }

                Section("Link Investments") {
                    if trackerVM.investments.isEmpty {
                        Text("No investments available. Add or sync investments first.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(trackerVM.investments) { investment in
                            Button {
                                if selectedInvestments.contains(investment.name) {
                                    selectedInvestments.remove(investment.name)
                                } else {
                                    selectedInvestments.insert(investment.name)
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(investment.name)
                                        Text(investment.category)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if selectedInvestments.contains(investment.name) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }

                Section("Link Loans") {
                    if trackerVM.loans.isEmpty {
                        Text("No loans available. Add loans first.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(trackerVM.loans) { loan in
                            Button {
                                if selectedLoans.contains(loan.name) {
                                    selectedLoans.remove(loan.name)
                                } else {
                                    selectedLoans.insert(loan.name)
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(loan.name)
                                        Text("\(loan.emisPaid)/\(loan.totalEmis) EMIs paid")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if selectedLoans.contains(loan.name) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Edit Followed Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        trackerVM.updateFollowedPlan(
                            plan,
                            input: editedInput,
                            scenario: scenario,
                            linkedInvestmentNames: Array(selectedInvestments).sorted(),
                            linkedLoanNames: Array(selectedLoans).sorted()
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PlanChartPoint: Identifiable {
    let id = UUID()
    let year: Int
    let value: Double
}

private struct LinkedAllocationRow: Identifiable {
    let allocationID: UUID
    let name: String
    let plannedPercent: Double
    var actualAmount: Double
    var actualPercent: Double
    var linkedInvestmentNames: [String]

    var id: UUID { allocationID }
}

struct ProgressRing: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.15), lineWidth: 10)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.auraDigital(size: 16))
                .foregroundColor(color)
        }
    }
}

struct TrackerYourPlansSection: View {
    let plans: [InvestmentPlanModel]

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Saved Illustrations").font(.auraHeader(size: 22))
                Spacer()
                NavigationLink(destination: AllPlansListView(plans: plans)) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.auraIndigo)
                }
            }
            .padding(.horizontal, 8)
            VStack(spacing: 12) {
                ForEach(Array(plans.prefix(3))) { plan in
                    PlanNavigationLink(plan: plan)
                }
            }
        }
    }
}

struct PlanNavigationLink: View {
    let plan: InvestmentPlanModel
    @Environment(TrackerViewModel.self) var trackerVM
    @State private var navigateToPlan = false
    
    var body: some View {
        let full = InvestmentPlannerEngine.generateFullPlan(input: plan.input, profile: nil)
        
        Button {
            navigateToPlan = true
        } label: {
            PlanCard(plan: plan)
        }
        .buttonStyle(PlainButtonStyle())
        .navigationDestination(isPresented: $navigateToPlan) {
            if plan.name.contains("Pure Investment") {
                Plan1DetailView(input: plan.input, result: full.plan1, isFromTracker: true)
            } else if plan.name.contains("Loan Strategy") {
                Plan2DetailView(input: plan.input, result: full.plan2 ?? Plan2Result.empty(), isFromTracker: true)
            } else if plan.name.contains("Leveraged Investing") || plan.name.contains("Loan Stress Test") {
                Plan3DetailView(input: plan.input, result: full.plan3 ?? Plan3Result.empty(), isFromTracker: true)
            } else {
                Plan1DetailView(input: plan.input, result: full.plan1, isFromTracker: true)
            }
        }
    }
}

struct AllPlansListView: View {
    let plans: [InvestmentPlanModel]
    @Environment(\.colorScheme) private var colorScheme
    
    @Environment(TrackerViewModel.self) var trackerVM
    
    var body: some View {
        List {
            ForEach(plans) { plan in
                PlanNavigationLink(plan: plan)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let plan = plans[index]
                    trackerVM.unsavePlan(planName: plan.name)
                }
            }
        }
        .listStyle(.plain)
        .background(AppTheme.appBackground(for: colorScheme))
        .navigationTitle("Saved Illustrations")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PlanCard: View {
    let plan: InvestmentPlanModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.name)
                            .font(.auraHeader(size: 17))
                            .multilineTextAlignment(.leading)
                        Text(plan.targetGoal)
                            .font(.auraCaption())
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 6) {
                        let amountStr = plan.input.targetAmount.replacingOccurrences(of: "₹", with: "").replacingOccurrences(of: ",", with: "")
                        let amountVal = Double(amountStr) ?? 0
                        let formattedAmount = amountVal > 0 ? amountVal.toCurrency() : "₹\(plan.input.targetAmount)"
                        Text(formattedAmount)
                            .font(.auraDigital(size: 18))
                            .foregroundColor(AppTheme.auraIndigo)
                    }
                }
                
                VStack(spacing: 8) {
                    HStack {
                        Text("Time Period")
                            .font(.auraCaption())
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(plan.input.timePeriod) Years")
                            .font(.auraDigital(size: 14))
                            .foregroundColor(AppTheme.auraIndigo)
                    }
                }
            }
            
//            Image(systemName: "chevron.right")
//                .font(.system(size: 14, weight: .bold))
//                .foregroundColor(.secondary.opacity(0.5))
        }
        .auraCardStyle(radius: 24)
    }
}

#Preview {
    NavigationStack {
        TrackerYourPlansSection(plans: [
            InvestmentPlanModel(
                name: "Plan 1 - Growth",
                dateSaved: "10 Mar 2024",
                targetGoal: "Retirement",
                input: InvestmentPlanInputModel(
                    investmentType: "Monthly",
                    amount: "25,000",
                    liquidity: "Moderate",
                    riskType: "Moderate",
                    timePeriod: "15",
                    scheduleInvestmentDate: Date(),
                    scheduleSIPDate: Date(),
                    purposeOfInvestment: "Retirement",
                    targetAmount: "₹2.5Cr",
                    savedAmount: "0",
                    hasEmergencyFund: true
                )
            )
        ])
        .padding()
    }
}
