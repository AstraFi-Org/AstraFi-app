import SwiftUI
import Charts

extension AstraLoanType {
    var displayIcon: String {
        switch self {
        case .homeLoan:       return "house.fill"
        case .carLoan:        return "car.fill"
        case .educationLoan:  return "graduationcap.fill"
        case .businessLoan:   return "briefcase.fill"
        case .personalLoan:   return "person.fill"
        case .creditCard:     return "creditcard.fill"
        case .other:          return "banknote.fill"
        }
    }

    var displayColor: Color {
        switch self {
        case .homeLoan:       return .blue
        case .carLoan:        return .green
        case .educationLoan:  return .purple
        case .businessLoan:   return .orange
        case .personalLoan:   return .pink
        case .creditCard:     return .cyan
        case .other:          return .secondary
        }
    }
}

struct LoanTrackerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppStateManager.self) var appState
    @Environment(\.colorScheme) private var colorScheme

    private var loans: [AstraLoan] { appState.currentProfile?.loans ?? [] }
    private var totalLoanAmount: Double { loans.reduce(0) { $0 + $1.loanAmount } }
    private var totalPaid: Double       { loans.reduce(0) { $0 + $1.estimatedPaidAmount } }
    private var totalRemaining: Double  { totalLoanAmount - totalPaid }

    @State private var showingAddLoan = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                HStack(spacing: 0) {
                    SummaryCell(label: "Total Debt", amount: totalLoanAmount, color: .primary)
                    Divider().frame(height: 48)
                    SummaryCell(label: "Remaining",  amount: totalRemaining,  color: .primary)
                }
                .padding(.vertical, 16)
                .background(AppTheme.cardBackground)
                .cornerRadius(16)
                .shadow(color: AppTheme.adaptiveShadow, radius: 8)

                if let first = loans.first {
                    NextEMIBanner(loan: first)
                }

                if loans.isEmpty {
                    EmptyLoansView()
                } else {    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Active Loans")
                            .font(.system(size: 20, weight: .bold))
                            .padding(.horizontal, 4)

                        VStack(spacing: 14) {
                            ForEach(loans) { loan in
                                NavigationLink(destination: LoanDetailView(loanID: loan.id)) {
                                    LoanDetailCard(loan: loan)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
            .padding(.top, 8)
        }
        .background(AppTheme.appBackground(for: colorScheme).ignoresSafeArea())
        .navigationTitle("Loan Tracker")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingAddLoan = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showingAddLoan) {
            AddLoanView()
        }
    }
}

private struct EmptyLoansView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
            Text("No loans added yet")
                .font(.system(size: 17, weight: .semibold))
            Text("Add your loans during onboarding to track them here.")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
    }
}

struct SummaryCell: View {
    let label: String
    let amount: Double
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            Text(amount.toCurrency())
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

struct NextEMIBanner: View {
    let loan: AstraLoan

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(loan.loanType.displayColor.opacity(0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: loan.loanType.displayIcon)
                    .font(.system(size: 22))
                    .foregroundColor(loan.loanType.displayColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(loan.calculatedEMI.toCurrency())
                    .font(.system(size: 22, weight: .bold))
                HStack(spacing: 4) {
                    Text("Next EMI")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(loan.loanType.displayColor)
                    Text("· \(loan.displayName)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                Text(loan.displayLender)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f%%", loan.interestRate))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(loan.loanType.displayColor)
                Text(loan.interestType.rawValue)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: loan.loanType.displayColor.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}

struct LoanDetailCard: View {
    let loan: AstraLoan
    @Environment(\.colorScheme) private var colorScheme

    private var progress:  Double { loan.estimatedPaidAmount / max(loan.loanAmount, 1) }
    private var remaining: Double { loan.loanAmount - loan.estimatedPaidAmount }
    private var color: Color { loan.loanType.displayColor }

    var body: some View {
        VStack(spacing: 14) {

            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(color.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: loan.loanType.displayIcon)
                            .font(.system(size: 18))
                            .foregroundColor(color)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(loan.displayName)
                            .font(.system(size: 17, weight: .semibold))
                        Text(loan.displayLender)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 6) {
                HStack {
                    Text("Repayment Progress")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.0f%%", progress * 100))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(color)
                }
                ProgressView(value: min(max(0, progress), 1))
                    .progressViewStyle(.linear)
                    .tint(color)
            }

            HStack(spacing: 10) {
                AmountBox(label: "Principal",  value: loan.loanAmount.toCurrency(),          color: color)
                AmountBox(label: "Paid",       value: loan.estimatedPaidAmount.toCurrency(), color: color)
                AmountBox(label: "Remaining",  value: remaining.toCurrency(),                color: color)
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: color.opacity(0.10), radius: 6, x: 0, y: 3)
    }
}

struct AmountBox: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .cornerRadius(10)
    }
}

struct LoanDetailView: View {
    let loanID: UUID

    init(loanID: UUID) {
        self.loanID = loanID
    }
    @Environment(AppStateManager.self) var appState
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    private var loan: AstraLoan? {
        appState.currentProfile?.loans.first(where: { $0.id == loanID })
    }

    private var color: Color      { loan?.loanType.displayColor ?? .blue }
    private var paid: Double      { loan?.estimatedPaidAmount ?? 0 }
    private var remaining: Double { (loan?.loanAmount ?? 0) - paid }
    private var progress: Double  { paid / max(loan?.loanAmount ?? 1, 1) }

    private var monthsLeft: Int {
        max(0, (loan?.loanTenureMonths ?? 0) - loan!.installmentsPaid)
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter(); f.dateStyle = .medium; return f
    }

    var body: some View {
        Group {
            if let loan = loan {
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 20) {
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(color.opacity(0.12))
                                        .frame(width: 72, height: 72)
                                    Image(systemName: loan.loanType.displayIcon)
                                        .font(.system(size: 32))
                                        .foregroundColor(color)
                                }
                                Text(loan.displayName)
                                    .font(.system(size: 22, weight: .bold))
                                Text(loan.displayLender)
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                            }

                            VStack(spacing: 8) {
                                HStack {
                                    Text("Repayment Progress")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(String(format: "%.1f%%", progress * 100))
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(color)
                                }
                                ProgressView(value: min(max(0, progress), 1))
                                    .progressViewStyle(.linear)
                                    .tint(color)
                            }

                            HStack(spacing: 10) {
                                AmountBox(label: "Total Principal", value: loan.loanAmount.toCurrency(), color: color)
                                AmountBox(label: "Paid Approx",    value: paid.toCurrency(),             color: color)
                                AmountBox(label: "Remaining",      value: remaining.toCurrency(),        color: color)
                            }
                        }
                        .padding(20)
                        .background(AppTheme.cardBackground)
                        .cornerRadius(20)
                        .shadow(color: color.opacity(0.12), radius: 10, x: 0, y: 4)

                        LoanAmortizationChartCard(loan: loan, color: color)

                        LoanInfoSection(title: "EMI & Interest") {
                            LoanInfoRow(label: "Monthly EMI",    value: loan.calculatedEMI.toCurrency())
                            LoanInfoRow(label: "Interest Rate",  value: String(format: "%.2f%% (\(loan.interestType.rawValue))", loan.interestRate))
                            LoanInfoRow(label: "Compounding",    value: loan.compoundingFrequency.rawValue)
                            LoanInfoRow(label: "EMI Frequency",  value: loan.emiFrequency.rawValue)
                            LoanInfoRow(label: "Rate Type",      value: loan.isFloatingRate ? "Floating" : "Fixed")
                        }

                        LoanInfoSection(title: "Tenure & Tracking") {
                            LoanInfoRow(label: "Total Tenure",   value: loan.tenureDisplay)
                            LoanInfoRow(label: "EMIs Paid",      value: "\(loan.installmentsPaid) Months")
                            LoanInfoRow(label: "EMIs Remaining", value: "\(monthsLeft) Months", highlight: color)
                            LoanInfoRow(label: "Start Date",     value: dateFormatter.string(from: loan.loanStartDate))
                            if let firstEmi = loan.firstEMIDate {
                                LoanInfoRow(label: "First EMI Date", value: dateFormatter.string(from: firstEmi))
                            }
                        }

                        LoanInfoSection(title: "Charges & Fees") {
                            LoanInfoRow(label: "Processing Fee", value: loan.processingFee.toCurrency())
                            LoanInfoRow(label: "Insurance Cost", value: loan.insurancePremium.toCurrency())
                            LoanInfoRow(label: "Late Penalty",   value: loan.latePaymentPenalty.toCurrency())
                            LoanInfoRow(label: "Other Charges",  value: loan.otherCharges.toCurrency())

                            let totalHidden = loan.processingFee + loan.insurancePremium + loan.otherCharges
                            LoanInfoRow(label: "Total Overhead", value: totalHidden.toCurrency(), highlight: .red)
                        }

                        if loan.moratoriumMonths > 0 || loan.trackTaxBenefits {
                            LoanInfoSection(title: "Advanced Details") {
                                if loan.moratoriumMonths > 0 {
                                    LoanInfoRow(label: "Moratorium", value: "\(loan.moratoriumMonths) Months")
                                    LoanInfoRow(label: "Moratorium Int.", value: loan.interestAccrualDuringMoratorium ? "Accruing" : "Waived")
                                }
                                if loan.trackTaxBenefits {
                                    LoanInfoRow(label: "Tax Benefit", value: "Tracked (80C / Sec 24)")
                                }
                            }
                        }

                        AmortizationCard(loan: loan, color: color)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                    .padding(.top, 8)
                }
                .background(AppTheme.appBackground(for: colorScheme))
                .navigationTitle(loan.displayName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button { showingEditSheet = true } label: { Label("Edit", systemImage: "pencil") }
                            Button(role: .destructive) { showingDeleteAlert = true } label: { Label("Delete", systemImage: "trash") }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .fontWeight(.semibold)
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .sheet(isPresented: $showingEditSheet) {
                    EditLoanView(loan: loan)
                }
                .alert("Delete Loan", isPresented: $showingDeleteAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        appState.deleteLoan(loan)
                        dismiss()
                    }
                } message: {
                    Text("Are you sure you want to remove this loan?")
                }
            } else {
                Text("Loan not found")
                    .navigationTitle("Detail")
            }
        }
    }

    @ViewBuilder
    private var pageBackground: some View {
        if colorScheme == .dark {
            AppTheme.cardBackground
        } else {
            LinearGradient(
                gradient: Gradient(colors: [
                    .blue.opacity(0.05),
                    .purple.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct LoanInfoSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
            VStack(spacing: 0) { content }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
        }
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppTheme.adaptiveShadow, radius: 6)
    }
}

struct LoanInfoRow: View {
    let label: String
    let value: String
    var highlight: Color? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                Spacer()
                Text(value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(highlight ?? .primary)
            }
            .padding(.vertical, 12)
            Divider()
        }
    }
}

struct AmortizationCard: View {
    let loan: AstraLoan
    let color: Color
    @Environment(\.colorScheme) private var colorScheme

    private struct ARow: Identifiable {
        let id: Int
        let principal: Double
        let interest: Double
        let balance: Double
    }

    private var rows: [ARow] {
        let r = (loan.interestRate / 100) / 12
        let emi = loan.calculatedEMI
        var balance = loan.loanAmount
        var result: [ARow] = []
        let count = min(loan.loanTenureMonths, 6)
        guard count > 0 else { return [] }
        for m in 1...count {
            let interestPart  = balance * r
            let principalPart = emi - interestPart
            balance = max(0, balance - principalPart)
            result.append(ARow(id: m, principal: principalPart, interest: interestPart, balance: balance))
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Amortization (first 6 months)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

            HStack {
                Text("Mo").frame(width: 28, alignment: .leading)
                Text("Principal").frame(maxWidth: .infinity, alignment: .trailing)
                Text("Interest").frame(maxWidth: .infinity, alignment: .trailing)
                Text("Balance").frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.secondary)
            .padding(.horizontal, 16)
            .padding(.bottom, 6)

            Divider().padding(.horizontal, 16)

            ForEach(rows) { row in
                HStack {
                    Text("\(row.id)").frame(width: 28, alignment: .leading)
                    Text(row.principal.toCurrency()).frame(maxWidth: .infinity, alignment: .trailing)
                    Text(row.interest.toCurrency())
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    Text(row.balance.toCurrency()).frame(maxWidth: .infinity, alignment: .trailing)
                }
                .font(.system(size: 13))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                Divider().padding(.horizontal, 16)
            }

            Spacer().frame(height: 8)
        }
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.06), radius: 6)
    }
}

// MARK: - EMI Breakdown Stacked Bar Chart

private struct StackedBarEntry: Identifiable {
    let id = UUID()
    let label: String
    let year: Int
    let type: String
    let amount: Double
}

struct LoanAmortizationChartCard: View {
    let loan: AstraLoan
    let color: Color
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedYearLabel: String? = nil

    // ── Use loan.calculatedEMI so the schedule matches the rest of the app
    private var schedule: [LoanCalculationEngine.AmortizationRow] {
        let emi = loan.calculatedEMI
        guard emi > 0, loan.loanTenureMonths > 0 else { return [] }
        return LoanCalculationEngine.generateAmortizationSchedule(
            principal: loan.loanAmount,
            annualRate: loan.interestRate,
            months: loan.loanTenureMonths,
            emi: emi
        )
    }

    // ── Aggregate monthly rows into yearly buckets
    private var stackedEntries: [StackedBarEntry] {
        let rows = schedule
        guard !rows.isEmpty else { return [] }
        let totalYears = (loan.loanTenureMonths + 11) / 12
        var entries: [StackedBarEntry] = []

        for yr in 1...totalYears {
            let lo = (yr - 1) * 12 + 1
            let hi = min(yr * 12, loan.loanTenureMonths)
            var p = 0.0, i = 0.0
            for row in rows where row.month >= lo && row.month <= hi {
                p += row.principalPaid
                i += row.interest
            }
            let label = "Y\(yr)"
            // Interest at bottom, principal on top
            entries.append(StackedBarEntry(label: label, year: yr, type: "Interest", amount: i))
            entries.append(StackedBarEntry(label: label, year: yr, type: "Principal", amount: p))
        }
        return entries
    }

    private var currentYear: Int {
        loan.installmentsPaid > 0 ? ((loan.installmentsPaid - 1) / 12) + 1 : 0
    }

    private var totalInterest: Double {
        schedule.reduce(0) { $0 + $1.interest }
    }

    private var totalPayable: Double {
        loan.loanAmount + totalInterest
    }

    private var interestPercentage: Double {
        guard loan.loanAmount > 0 else { return 0 }
        return (totalInterest / loan.loanAmount) * 100
    }

    /// Cumulative principal and interest paid so far based on installmentsPaid
    private var paidBreakdown: (principal: Double, interest: Double) {
        let rows = schedule
        let limit = loan.installmentsPaid
        var p = 0.0
        var i = 0.0
        for row in rows where row.month <= limit {
            p += row.principalPaid
            i += row.interest
        }
        return (p, i)
    }

    /// Interest share for the first year (used in the default insight text)
    private var firstYearInterestShare: Int {
        let rows = schedule
        guard !rows.isEmpty else { return 0 }
        let hi = min(12, loan.loanTenureMonths)
        var p = 0.0, i = 0.0
        for row in rows where row.month >= 1 && row.month <= hi {
            p += row.principalPaid
            i += row.interest
        }
        let total = p + i
        guard total > 0 else { return 0 }
        return Int(round((i / total) * 100))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ── Header
            VStack(alignment: .leading, spacing: 4) {
                Text("EMI Breakdown")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
                Text("Each bar shows how your annual payments split between principal & interest")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            // ── Stacked bar chart
            if !stackedEntries.isEmpty {
                Chart {
                    ForEach(stackedEntries) { entry in
                        BarMark(
                            x: .value("Year", entry.label),
                            y: .value("Amount", entry.amount)
                        )
                        .foregroundStyle(by: .value("Type", entry.type))
                        .cornerRadius(3)
                    }

                    // Interactive RuleMark showing only when a specific bar is tapped/selected
                    if let selected = selectedYearLabel {
                        let yearNum = Int(selected.replacingOccurrences(of: "Y", with: "")) ?? 1
                        RuleMark(x: .value("Selected", selected))
                            .foregroundStyle(Color.orange.opacity(0.8))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                            .annotation(position: .top, alignment: .center) {
                                Text("Year \(yearNum)")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6).padding(.vertical, 3)
                                    .background(Color.orange)
                                    .cornerRadius(4)
                            }
                    }
                }
                .chartForegroundStyleScale([
                    "Principal": AppTheme.auraGreen,
                    "Interest": Color(hex: "#FF6B6B")
                ])
                .chartLegend(.visible)
                .chartLegend(position: .bottom, spacing: 12)
                .chartXSelection(value: $selectedYearLabel)
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(v.toCurrency(compact: true))
                                    .font(.system(size: 9))
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let v = value.as(String.self) {
                                Text(v)
                                    .font(.system(size: 8))
                            }
                        }
                    }
                }
                .frame(height: 220)
            }

            // ── Dynamic Insight Callout
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.vibrantOrange)
                
                Group {
                    if let selected = selectedYearLabel {
                        let yearNum = Int(selected.replacingOccurrences(of: "Y", with: "")) ?? 1
                        let yearEntries = stackedEntries.filter { $0.label == selected }
                        let interest = yearEntries.first(where: { $0.type == "Interest" })?.amount ?? 0
                        let principal = yearEntries.first(where: { $0.type == "Principal" })?.amount ?? 0
                        let total = interest + principal
                        let pct = total > 0 ? Int(round((interest / total) * 100)) : 0
                        Text("Year \(yearNum): **\(principal.toCurrency(compact: true))** principal and **\(interest.toCurrency(compact: true))** interest paid (**\(pct)%** interest share).")
                    } else if loan.installmentsPaid > 0 {
                        Text("You've paid **\(paidBreakdown.principal.toCurrency(compact: true))** principal and **\(paidBreakdown.interest.toCurrency(compact: true))** interest so far (Year \(currentYear) in progress). Tap any bar to inspect.")
                    } else {
                        Text("In Year 1, **\(firstYearInterestShare)%** of your EMI goes to interest. This reduces each year as you pay off more principal. Tap any bar to inspect.")
                    }
                }
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            }
            .padding(12)
            .background(AppTheme.vibrantOrange.opacity(0.08))
            .cornerRadius(12)

            // ── Summary stat tiles
            HStack(spacing: 10) {
                LoanMetricTile(
                    title: "Total Interest",
                    value: totalInterest.toCurrency(compact: true),
                    color: Color(hex: "#FF6B6B")
                )
                LoanMetricTile(
                    title: "Total Payable",
                    value: totalPayable.toCurrency(compact: true),
                    color: AppTheme.auraIndigo
                )
                LoanMetricTile(
                    title: "Interest / Principal",
                    value: String(format: "%.1f%%", interestPercentage),
                    color: AppTheme.vibrantOrange
                )
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppTheme.adaptiveShadow, radius: 8)
    }
}

private struct LoanMetricTile: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.auraCaption(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(value)
                .font(.auraDigital(size: 18))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    let appState = AppStateManager()
    appState.currentProfile = AstraUserProfile(
        signUp: AstraSignUp(signUpName: "Demo", email: "demo@example.com", password: ""),
        basicDetails: AstraBasicDetails(
            name: "Demo", age: 30, gender: .male,
            adultDependents: 0, childDependents: 0,
            incomeType: .fixed,
            monthlyIncome: 100000, monthlyIncomeAfterTax: 80000,
            monthlyExpenses: 50000, emergencyFundAmount: 200000,
            activeInvestment: true
        ),
        assets: AstraAssets(),
        liabilities: AstraLiabilities(),
        investments: [],
        loans: [
            AstraLoan(loanType: .homeLoan, lender: .hdfcBank,
                      loanAmount: 7500000, interestRate: 8.5,
                      loanStartDate: Calendar.current.date(byAdding: .month, value: -5, to: Date())!,
                      loanTenureMonths: 180),
            AstraLoan(loanType: .carLoan, lender: .iciciBank,
                      loanAmount: 900000, interestRate: 9.2,
                      loanStartDate: Calendar.current.date(byAdding: .month, value: -22, to: Date())!,
                      loanTenureMonths: 60),
            AstraLoan(loanType: .educationLoan, lender: .stateBankOfIndia,
                      loanAmount: 500000, interestRate: 7.0,
                      loanStartDate: Calendar.current.date(byAdding: .month, value: -12, to: Date())!,
                      loanTenureMonths: 84)
        ],
        insurances: [],
        goals: []
    )
    return NavigationStack {
        LoanTrackerView()
            .environment(appState)
    }
}
