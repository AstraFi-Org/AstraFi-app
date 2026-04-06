import SwiftUI
import Foundation
import PhotosUI

private extension Color {
    static let trackFill      = Color(UIColor.systemFill)
    static let pillBackground = Color(UIColor.secondarySystemFill)
    static let barTrack       = Color(UIColor.tertiarySystemFill)
}

struct FinancialHealthReportView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppStateManager.self) var appState
    var data: CompleteAssessmentData?

    private var profile: AstraUserProfile? { appState.currentProfile }
    private var userName: String { profile?.basicDetails.name ?? data?.name ?? "Akash" }

    @State private var spendingSheet  = false
    @State private var riskSheet      = false
    @State private var insuranceSheet = false
    @State private var vitalsDetail   = false
    @State private var liabilityDetail = false
    @State private var animatedScore: Double = 0
    @State private var vitalsPeriod: VitalsPeriod = .monthly

    enum VitalsPeriod: String, CaseIterable { case monthly = "Monthly"; case yearly = "Yearly" }

    private var score: Double {
        let values = radarValues.map { $0.1 }
        let avg = values.reduce(0.0, +) / Double(values.count)
        return min(100, avg * 100)
    }

    private var savingRatio: Double {
        let income   = Double(profile?.basicDetails.monthlyIncomeAfterTax ?? Double(data?.incomeAfterTax ?? "") ?? 0)
        let expenses = Double(profile?.basicDetails.monthlyExpenses       ?? Double(data?.expenditure ?? "") ?? 0)
        guard income > 0 else { return 0 }
        return max(0, min(1.0, (income - expenses) / income))
    }

    private var incomeValue: String {
        let val: Double = Double(profile?.basicDetails.monthlyIncomeAfterTax ?? 0) > 0
            ? profile!.basicDetails.monthlyIncomeAfterTax
            : Double(data?.incomeAfterTax ?? "") ?? Double(data?.income ?? "") ?? 0
        return fmtDecimals(val)
    }

    private var expensesValue: String {
        let val: Double = Double(profile?.basicDetails.monthlyExpenses ?? 0) > 0
            ? profile!.basicDetails.monthlyExpenses
            : Double(data?.expenditure ?? "") ?? 0
        return fmtDecimals(val)
    }

    private var displayedExpenses: String {
        if let cf = profile?.cashflowData, cf.total > 0 { return fmtDecimals(cf.total) }
        return expensesValue
    }

    private var radarValues: [(String, Double, Double)] {[
        ("Income Stability",   profile?.basicDetails.incomeType == .fixed ? 0.95 : 0.65, 1.0),
        ("Saving Discipline",  min(1.0, savingRatio / 0.3), 0.7), 
        ("Risk Protection",    (profile?.insurances.count ?? 0) > 0 ? (profile!.insurances.count >= 2 ? 0.9 : 0.6) : 0.2, 0.5),
        ("Investment Balance", (profile?.investments.count ?? 0) > 0 ? (profile!.investments.count >= 3 ? 0.85 : 0.5) : 0.1, 0.5),
        ("Expense Control",    1.0 - (spendingRatio > 0.7 ? 0.7 : spendingRatio), 0.6), 
    ]}

    private var spendingRatio: Double {
        let expenses = Double(profile?.basicDetails.monthlyExpenses ?? 0)
        let income = Double(profile?.basicDetails.monthlyIncomeAfterTax ?? 1)
        return expenses / (income > 0 ? income : 1)
    }

    private var investCount: Int { profile?.investments.count ?? data?.investmentEntries.count ?? 0 }
    private var loanCount: Int   { profile?.loans.count ?? 0 }
    private var insCount: Int    { profile?.insurances.count ?? 0 }

    private func fmtDecimals(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal; f.groupingSeparator = ","
        f.minimumFractionDigits = 2; f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: v)) ?? "\(v)"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                _ReportHeader(name: userName, score: animatedScore)
                    .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 16)

                _SectionTitle("Financial Health Overview")
                _RadarChart(values: radarValues)
                    .frame(height: 240)
                    .padding(.horizontal, 20).padding(.bottom, 8)

                _ParameterSection(
                    savingRatio: savingRatio,
                    invCount: investCount,
                    loanCount: loanCount,
                    insCount: insCount,
                    onTap: { type in
                        switch type {
                        case .vitals: vitalsDetail = true
                        case .investment: riskSheet = true
                        case .liabilities: liabilityDetail = true
                        case .insurance: insuranceSheet = true
                        }
                    }
                )

                _SectionTitle("Financial Vitals")
                _VitalsCard(
                    period: $vitalsPeriod,
                    income: incomeValue,
                    expenses: displayedExpenses,
                    cashflow: appState.currentProfile?.cashflowData ?? CashflowEntry()
                )
                .padding(.horizontal, 20).padding(.bottom, 8)
                .onTapGesture { vitalsDetail = true }

                _BlueLink("Want to see where you spend the most?") { spendingSheet = true }
                    .padding(.horizontal, 20).padding(.bottom, 20)

                _SectionTitle("Investment Analysis")
                _InvestmentStatsCard(total: investCount, active: investCount, atRisk: 0)
                    .padding(.horizontal, 20).padding(.bottom, 12)
                    .onTapGesture { riskSheet = true }

                _AreaSparkline()
                    .frame(height: 120)
                    .padding(.horizontal, 20).padding(.bottom, 8)

                HStack(spacing: 8) {
                    _Chip("Market Fluctuation", color: .purple)
                    _Chip("Risk Imbalance",     color: .orange)
                }.padding(26)

                _BlueLink("Would you like help reducing this risk?") { riskSheet = true }
                    .padding(.horizontal, 20).padding(.bottom, 20)

                _SectionTitle("Insurance Analysis")
                _InsuranceAnalysisCard(
                    adultDependents: profile?.basicDetails.adultDependents ?? data?.adultDependents ?? 1,
                    hasHealth: profile?.basicDetails.activeInvestment ?? (data?.insuranceEntries.contains { $0.currentType == .health } ?? false),
                    hasLife: insCount > 0 || (data?.insuranceEntries.contains { $0.currentType == .life } ?? false)
                )
                .padding(.horizontal, 20).padding(.bottom, 8)
                .onTapGesture { insuranceSheet = true }

                _BlueLink("Want help choosing the right insurance coverage for your family?") {
                    insuranceSheet = true
                }
                .padding(.horizontal, 20).padding(.bottom, 24)

                _ReportFooterCTA(data: data)
                    .padding(.horizontal, 20).padding(.bottom, 40)
            }
        }
        .background(AppTheme.appBackground(for: colorScheme).ignoresSafeArea())
        .navigationTitle("AstraFi Health Report")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeOut(duration: 1.4)) { animatedScore = score }
        }
        .sheet(isPresented: $vitalsDetail) {
            _VitalsDetailSheet(income: incomeValue, expenses: displayedExpenses, ratio: savingRatio)
        }
        .sheet(isPresented: $spendingSheet) {
            _CashflowInputSheet(cashflow: Binding(
                get: { profile?.cashflowData ?? CashflowEntry() },
                set: { appState.updateCashflow($0) }
            ))
        }
        .sheet(isPresented: $riskSheet) {
            _RiskSheet(investCount: investCount)
        }
        .sheet(isPresented: $insuranceSheet) {
            _InsuranceAdviceSheet(
                adultDependents: profile?.basicDetails.adultDependents ?? data?.adultDependents ?? 1
            )
        }
        .sheet(isPresented: $liabilityDetail) {
            _LiabilityDetailSheet(loanCount: loanCount)
        }
    }
}

private struct _ParameterSection: View {
    let savingRatio: Double
    let invCount: Int
    let loanCount: Int
    let insCount: Int
    let onTap: (ParamType) -> Void

    enum ParamType { case vitals, investment, liabilities, insurance }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            _SectionTitle("4 Parameters of Financial Health")
            Text("Below are the financial health parameters that require frequent monitoring")
                .font(.caption).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20).padding(.bottom, 12)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                _ParameterCard(
                    title: "Financial Vitals",
                    description: "You save \(savingRatio.isFinite ? "\(Int(savingRatio * 100))" : "0")% of your income",
                    status: savingRatio > 0.2 ? .fine : .concern
                ).onTapGesture { onTap(.vitals) }

                _ParameterCard(
                    title: "Investment",
                    description: "You have \(invCount) active investments",
                    status: invCount > 0 ? .fine : .concern
                ).onTapGesture { onTap(.investment) }

                _ParameterCard(
                    title: "Liabilities",
                    description: "You have \(loanCount) active loans",
                    status: loanCount == 0 ? .fine : .concern
                ).onTapGesture { onTap(.liabilities) }

                _ParameterCard(
                    title: "Insurance",
                    description: "You have \(insCount) active policies",
                    status: insCount > 0 ? .fine : .concern
                ).onTapGesture { onTap(.insurance) }
            }
            .padding(.horizontal, 20).padding(.bottom, 20)
        }
    }
}

private struct _RiskSheet: View {
    let investCount: Int
    var body: some View {
        _InsightSheet(
            icon: "exclamationmark.triangle.fill", color: .orange,
            title: "Reduce Your Investment Risk",
            items: investCount == 0
                ? [("No Investments", "0%", 0.0)]
                : [("Mutual Funds", "100%", 1.0)],
            advice: investCount < 2
                ? "You have limited diversification. Consider adding Low-risk Debt or Gold to your portfolio."
                : "Your portfolio is taking shape. Regularly rebalance between equity and debt based on market conditions."
        )
    }
}

private struct _CashflowInputSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var cashflow: CashflowEntry
    @State private var draft: CashflowEntry = CashflowEntry()
    @State private var photoItem: PhotosPickerItem? = nil
    @State private var uploadedFileName: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    _CashflowUploadSection(photoItem: $photoItem, fileName: $uploadedFileName)
                        .padding(.horizontal, 16).padding(.top, 16)

                    OrDividerLabel(text: "or enter manually")
                        .padding(.horizontal, 24).padding(.vertical, 14)

                    _CashflowManualEntry(draft: $draft)
                        .padding(.horizontal, 16)

                    _CashflowSubmitButton(hasValues: draft.total > 0) {
                        cashflow = draft
                        dismiss()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20).padding(.bottom, 48)
                }
            }
            .background(AppTheme.appBackground(for: .light).ignoresSafeArea())
            .navigationTitle("Where You Spend the Most")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.blue)
                }
            }
            .onAppear {
                draft = cashflow
            }
        }
    }
}

private struct _CashflowUploadSection: View {
    @Binding var photoItem: PhotosPickerItem?
    @Binding var fileName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "building.columns.fill")
                    .font(.subheadline).foregroundStyle(.blue)
                    .frame(width: 36, height: 36)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Upload Bank Statement")
                        .font(.subheadline).fontWeight(.semibold)
                    Text("We'll auto-extract your monthly cashflow")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }

            PhotosPicker(selection: $photoItem, matching: .any(of: [.images])) {
                _UploadZone(hasFile: fileName != nil, label: fileName)
            }
            .onChange(of: photoItem) { _, newItem in
                if newItem != nil {
                    fileName = "statement_\(Int.random(in: 1000...9999)).pdf"
                }
            }

            if let name = fileName {
                HStack(spacing: 8) {
                    Image(systemName: "doc.fill").foregroundStyle(.blue)
                    Text(name).font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        withAnimation { fileName = nil; photoItem = nil }
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
    }
}

private struct _UploadZone: View {
    let hasFile: Bool
    let label: String?
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.blue.opacity(0.4),
                              style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.blue.opacity(0.04)))
                .frame(height: 76)
            VStack(spacing: 6) {
                Image(systemName: hasFile ? "checkmark.circle.fill" : "arrow.up.doc.fill")
                    .font(.title3).foregroundStyle(.blue)
                Text(hasFile ? (label ?? "File selected") : "Tap to upload PDF or CSV")
                    .font(.subheadline).foregroundStyle(.blue)
            }
        }
    }
}

private struct _CashflowManualEntry: View {
    @Binding var draft: CashflowEntry

    typealias CF = CashflowEntry

    private let rowData: [(String, String, WritableKeyPath<CF, Double>, Color)] = [
        ("house.fill",           "House Rent / EMI",      \CF.rent,            .indigo),
        ("basket.fill",          "Groceries",              \CF.groceries,       .green),
        ("bolt.fill",            "Utilities & Bills",      \CF.utilities,       .yellow),
        ("fork.knife",           "Dining & Delivery",      \CF.dining,          .orange),
        ("car.fill",             "Transport",              \CF.transport,       .blue),
        ("cart.fill",            "Shopping",               \CF.shopping,        .cyan),
        ("popcorn.fill",         "Entertainment",          \CF.entertainment,   .pink),
        ("ellipsis.circle.fill", "Other / Misc",           \CF.misc,            .gray),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "list.bullet.clipboard.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
                Text("Monthly Cashflow Breakdown")
                    .font(.subheadline).fontWeight(.semibold)
            }
            .padding(.bottom, 16)

            ForEach(Array(rowData.enumerated()), id: \.offset) { idx, row in
                _CashflowRow(
                    icon: row.0,
                    label: row.1,
                    color: row.3,
                    value: Binding(
                        get: { draft[keyPath: row.2] },
                        set: { draft[keyPath: row.2] = $0 }
                    )
                )
                if idx < rowData.count - 1 {
                    Divider().padding(.leading, 42)
                }
            }

            if draft.total > 0 {
                _CashflowTotalPreview(draft: draft)
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
    }
}

private struct _CashflowRow: View {
    let icon: String
    let label: String
    let color: Color
    @Binding var value: Double

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption).foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(label)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 3) {
                Text("₹").font(.subheadline).foregroundStyle(.secondary)
                TextField("0", value: $value, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 88)
                    .font(.subheadline).fontWeight(.medium)
                    .padding(.vertical, 8).padding(.horizontal, 10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 9))
            }
        }
        .padding(.vertical, 10)
    }
}

private struct _CashflowTotalPreview: View {
    let draft: CashflowEntry

    private func fmtCompact(_ v: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal
        f.groupingSeparator = ","; f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "0"
    }

    var body: some View {
        VStack(spacing: 12) {
            Divider().padding(.vertical, 8)
            HStack {
                Text("Estimated Total Spending").font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                Text("₹\(fmtCompact(draft.total))")
                    .font(.headline).fontWeight(.bold).foregroundStyle(.blue)
            }
        }
        .padding(.top, 4)
    }
}

private struct _BreakdownPreviewRow: View {
    let name: String
    let amount: Double
    let total: Double

    private func fmt(_ v: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal
        f.groupingSeparator = ","; f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: Int(v))) ?? "\(Int(v))"
    }

    var body: some View {
        HStack {
            Text(name).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text("₹\(fmt(amount))").font(.caption).fontWeight(.semibold).foregroundStyle(.primary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.tertiarySystemFill)).frame(height: 5)
                    Capsule()
                        .fill(LinearGradient(
                            colors: [.blue,
                                     .blue],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * (total > 0 ? amount / total : 0), height: 5)
                }
            }
            .frame(width: 60, height: 5)
        }
    }
}

private struct _CashflowSubmitButton: View {
    let hasValues: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                Text(hasValues ? "Calculate & Update Report" : "Save & Continue")
            }
            .font(.headline).fontWeight(.semibold).foregroundColor(.white)
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(LinearGradient(
                colors: [.blue,
                         .blue],
                startPoint: .leading, endPoint: .trailing
            ))
            .clipShape(Capsule())
        }
    }
}

private struct OrDividerLabel: View {
    let text: String
    var body: some View {
        HStack(spacing: 12) {
            Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 1)
            Text(text)
                .font(.footnote).fontWeight(.medium).foregroundStyle(.secondary).fixedSize()
            Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 1)
        }
    }
}

private struct _ReportHeader: View {
    let name: String
    let score: Double

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 0) {
                    Text("AstraFi").font(.title2).fontWeight(.black).foregroundStyle(Color.primary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("Financial Health").font(.caption).foregroundStyle(.secondary)
                        Text("Report").font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 4)
                Text("Dear \(name),").font(.subheadline).fontWeight(.semibold)
                Text("Congratulations, you have successfully completed health assessment.")
                    .font(.caption).foregroundStyle(.secondary).lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            _ScoreGauge(score: score).frame(width: 80, height: 80)
        }
        .padding(18)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
    }
}

private struct _ScoreGauge: View {
    let score: Double
    private var scoreColor: Color {
        score >= 75 ? .blue : score >= 50 ? .orange : .red
    }
    var body: some View {
        ZStack {
            Circle().trim(from: 0.1, to: 0.9)
                .stroke(Color.trackFill, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(90))
            Circle().trim(from: 0.1, to: 0.1 + (score / 100) * 0.8)
                .stroke(
                    LinearGradient(colors: [scoreColor.opacity(0.7), scoreColor],
                                   startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(90))
                .animation(.easeOut(duration: 1.4), value: score)
            VStack(spacing: 0) {
                Text("\(Int(score))").font(.title3).fontWeight(.black).foregroundStyle(scoreColor)
                Text("score").font(.system(size: 9)).foregroundStyle(.secondary)
            }
        }
    }
}

private struct _RadarChart: View {
    let values: [(String, Double, Double)]
    @Environment(\.colorScheme) private var colorScheme
    private var dotFill: Color { colorScheme == .dark ? Color(UIColor.systemBackground) : .white }

    var body: some View {
        Canvas { ctx, size in
            let center     = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius     = min(size.width, size.height) * 0.36
            let count      = values.count
            let step       = (2 * Double.pi) / Double(count)
            let startAngle = -Double.pi / 2

            func point(_ i: Int, _ r: Double) -> CGPoint {
                let a = startAngle + Double(i) * step
                return CGPoint(x: center.x + radius * r * Darwin.cos(a),
                               y: center.y + radius * r * Darwin.sin(a))
            }
            for ring in stride(from: 0.2, through: 1.0, by: 0.2) {
                var p = Path()
                for i in 0..<count { i == 0 ? p.move(to: point(i, ring)) : p.addLine(to: point(i, ring)) }
                p.closeSubpath()
                ctx.stroke(p, with: .color(.gray.opacity(0.15)), lineWidth: 0.8)
            }
            for i in 0..<count {
                var s = Path(); s.move(to: center); s.addLine(to: point(i, 1.0))
                ctx.stroke(s, with: .color(.gray.opacity(0.2)), lineWidth: 0.8)
            }
            var bp = Path()
            for i in 0..<count { i == 0 ? bp.move(to: point(i, values[i].2)) : bp.addLine(to: point(i, values[i].2)) }
            bp.closeSubpath()
            ctx.fill(bp, with: .color(.blue.opacity(0.08)))
            ctx.stroke(bp, with: .color(.blue.opacity(0.35)), lineWidth: 1.2)
            var ap = Path()
            for i in 0..<count { i == 0 ? ap.move(to: point(i, values[i].1)) : ap.addLine(to: point(i, values[i].1)) }
            ap.closeSubpath()
            ctx.fill(ap, with: .color(.blue.opacity(0.15)))
            ctx.stroke(ap, with: .color(.blue.opacity(0.85)), lineWidth: 2)
            for i in 0..<count {
                let pt  = point(i, values[i].1)
                let dot = Path(ellipseIn: CGRect(x: pt.x - 3, y: pt.y - 3, width: 6, height: 6))
                ctx.fill(dot, with: .color(dotFill))
                ctx.stroke(dot, with: .color(.blue), lineWidth: 1.5)
            }
        }
        .overlay(
            GeometryReader { geo in
                let s      = geo.size
                let center = CGPoint(x: s.width / 2, y: s.height / 2)
                let radius = min(s.width, s.height) * 0.36
                let count  = values.count
                let step   = (2 * Double.pi) / Double(count)
                let start  = -Double.pi / 2
                ForEach(0..<count, id: \.self) { i in
                    let angle = start + Double(i) * step
                    let lr    = radius * 1.28
                    VStack(spacing: 1) {
                        Text(String(format: "%.1f", values[i].1 * 10))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.blue)
                        Text(String(format: "%.1f", values[i].2 * 10))
                            .font(.system(size: 8)).foregroundStyle(.secondary)
                        Text(values[i].0)
                            .font(.system(size: 8, weight: .medium)).foregroundStyle(.primary)
                            .multilineTextAlignment(.center).lineLimit(2).frame(width: 70)
                    }
                    .position(x: center.x + lr * cos(angle), y: center.y + lr * sin(angle))
                }
            }
        )
        .padding()
    }
}

private enum _ParamStatus { case fine, concern }

private struct _ParameterCard: View {
    let title: String; let description: String; let status: _ParamStatus
    private var statusLabel: String { status == .fine ? "Everything is Fine" : "Concern" }
    private var statusColor: Color  { status == .fine ? .green : .orange }
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline).bold()
            Text(description).font(.caption).foregroundStyle(.secondary)
            Spacer(minLength: 4)
            Text(statusLabel).font(.caption).fontWeight(.semibold).foregroundStyle(statusColor)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: AppTheme.adaptiveShadow, radius: 4, x: 0, y: 2)
    }
}

private struct _VitalsCard: View {
    @Binding var period: FinancialHealthReportView.VitalsPeriod
    let income: String
    let expenses: String
    let cashflow: CashflowEntry?

    private let segmentColors: [Color] = [
        .indigo,
        .teal,
        .red,
        .green,
        .yellow,
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            _VitalsHeader(period: $period)
            Text(expenses).font(.system(size: 32)).bold().foregroundStyle(.primary)

            if let cf = cashflow, cf.total > 0 {
                _VitalsSegmentedContent(cf: cf, segmentColors: segmentColors)
            } else {
                _VitalsDefaultContent(income: income)
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.vertical, 4)
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
    }
}

private struct _VitalsHeader: View {
    @Binding var period: FinancialHealthReportView.VitalsPeriod
    var body: some View {
        HStack {
            Text("Total \(period == .monthly ? "Expenses" : "Yearly Expenses")")
                .font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Picker("", selection: $period) {
                ForEach(FinancialHealthReportView.VitalsPeriod.allCases, id: \.self) {
                    Text($0.rawValue)
                }
            }
            .pickerStyle(.menu)
            .tint(.blue)
            .scaleEffect(0.9)
        }
    }
}

private struct _VitalsSegmentedContent: View {
    let cf: CashflowEntry
    let segmentColors: [Color]

    private func fmtCompact(_ v: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal
        f.groupingSeparator = ","; f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: Int(v))) ?? "\(Int(v))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            _SegmentedBar(breakdown: cf.breakdown, total: cf.total, colors: segmentColors)
                .frame(height: 28)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(Array(cf.breakdown.enumerated()), id: \.offset) { idx, item in
                    _VitalsLegendItem(
                        label: item.0,
                        amount: fmtCompact(item.1),
                        color: segmentColors[idx % segmentColors.count]
                    )
                }
            }
        }
    }
}

private struct _VitalsLegendItem: View {
    let label: String
    let amount: String
    let color: Color
    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.caption).fontWeight(.semibold).foregroundStyle(color)
                Text("₹\(amount)").font(.subheadline).fontWeight(.bold).foregroundStyle(.primary)
            }
            Spacer()
        }
    }
}

private struct _VitalsDefaultContent: View {
    let income: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            HStack {
                Text("Total Income").font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                Text("Monthly")
                    .font(.caption).foregroundStyle(.secondary)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.pillBackground).clipShape(Capsule())
            }
            Text(income).font(.system(size: 28)).bold().foregroundStyle(.primary)
        }
    }
}

private struct _SegmentedBar: View {
    let breakdown: [(String, Double)]
    let total: Double
    let colors: [Color]

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(Array(breakdown.enumerated()), id: \.offset) { idx, item in
                    let ratio = total > 0 ? item.1 / total : 0
                    _StripedSegment(color: colors[idx % colors.count])
                        .frame(width: max(2, geo.size.width * ratio))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
            }
        }
    }
}

private struct _StripedSegment: View {
    let color: Color
    var body: some View {
        Canvas { ctx, size in
            var x: CGFloat = 0
            while x < size.width {
                ctx.fill(Path(CGRect(x: x, y: 0, width: 3, height: size.height)),
                         with: .color(color.opacity(0.85)))
                x += 5
            }
        }
        .background(color.opacity(0.3))
    }
}

private struct _InvestmentStatsCard: View {
    let total: Int; let active: Int; let atRisk: Int
    var body: some View {
        let stats: [(String, String, Color)] = [
            ("Total Investment",  "\(total)",  .primary),
            ("Active Investment", "\(active)", .primary),
            ("Closed Investment", "0",         .primary),
            ("Funds at Risk",     "\(atRisk)", .red),
        ]
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 1) {
            ForEach(Array(stats.enumerated()), id: \.offset) { idx, stat in
                VStack(alignment: .leading, spacing: 8) {
                    Text(stat.0).font(.caption).foregroundStyle(.secondary)
                    Text(stat.1).font(.system(size: 30).bold()).foregroundStyle(stat.2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16).background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.vertical, 5)
            }
        }
        .padding(.vertical)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 6, x: 0, y: 2)
    }
}

private struct _AreaSparkline: View {
    private let dataPoints: [Double] = [
        60, 75, 55, 80, 65, 90, 50, 70, 45, 85, 60, 75,
        55, 65, 78, 50, 68, 82, 55, 70, 48, 75, 62, 80
    ]
    private let months = ["Mar", "Apr", "May", "Jun", "Jul", "Aug"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overall Performance").font(.subheadline).fontWeight(.semibold).padding(.horizontal, 4)
            Canvas { ctx, size in
                let h = size.height - 24; let w = size.width
                let maxV = dataPoints.max() ?? 1; let minV = dataPoints.min() ?? 0
                let range = maxV - minV; let step = w / Double(dataPoints.count - 1)
                func y(_ v: Double) -> Double { h - ((v - minV) / range) * h }
                var area = Path(); area.move(to: CGPoint(x: 0, y: h))
                for (i, v) in dataPoints.enumerated() {
                    let x = Double(i) * step
                    if i == 0 { area.addLine(to: CGPoint(x: x, y: y(v))) }
                    else {
                        let px = Double(i - 1) * step
                        area.addCurve(to: CGPoint(x: x, y: y(v)),
                                      control1: CGPoint(x: px + step * 0.4, y: y(dataPoints[i-1])),
                                      control2: CGPoint(x: x - step * 0.4, y: y(v)))
                    }
                }
                area.addLine(to: CGPoint(x: w, y: h)); area.closeSubpath()
                ctx.fill(area, with: .linearGradient(
                    Gradient(colors: [Color.purple.opacity(0.35), Color.purple.opacity(0.05)]),
                    startPoint: CGPoint(x: w/2, y: 0), endPoint: CGPoint(x: w/2, y: h)))
                var line = Path()
                for (i, v) in dataPoints.enumerated() {
                    let x = Double(i) * step
                    if i == 0 { line.move(to: CGPoint(x: x, y: y(v))) }
                    else {
                        let px = Double(i-1) * step
                        line.addCurve(to: CGPoint(x: x, y: y(v)),
                                      control1: CGPoint(x: px + step * 0.4, y: y(dataPoints[i-1])),
                                      control2: CGPoint(x: x - step * 0.4, y: y(v)))
                    }
                }
                ctx.stroke(line, with: .color(.purple), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
            .frame(height: 90).background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            HStack {
                ForEach(months, id: \.self) { m in
                    Text(m).font(.caption2).foregroundStyle(.secondary)
                    if m != months.last { Spacer() }
                }
            }.padding(.horizontal, 4)
        }
        .padding(16).background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 6, x: 0, y: 2)
    }
}

private struct _InsuranceAnalysisCard: View {
    let adultDependents: Int; let hasHealth: Bool; let hasLife: Bool
    private var coveredCount: Int { hasLife ? max(1, adultDependents - 1) : 0 }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !hasHealth {
                _AnalysisRow(icon: "cross.case.fill", color: .orange,
                             text: "Your children do not have health insurance.")
            }
            _AnalysisRow(icon: "person.2.fill", color: .blue,
                         text: "Out of \(adultDependents) adult dependent family members, only \(coveredCount) currently have life insurance coverage.")
        }
        .padding(18).background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.vertical)
        .shadow(color: AppTheme.adaptiveShadow, radius: 6, x: 0, y: 2)
    }
}

private struct _AnalysisRow: View {
    let icon: String; let color: Color; let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).font(.subheadline).foregroundStyle(color).frame(width: 22)
            Text(text).font(.subheadline).foregroundStyle(.primary).lineSpacing(3)
        }
    }
}

private struct _BlueLink: View {
    let text: String; let action: () -> Void
    init(_ text: String, action: @escaping () -> Void) { self.text = text; self.action = action }
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(text).font(.subheadline).fontWeight(.medium)
                    .foregroundStyle(.blue)
                    .multilineTextAlignment(.leading)
                Image(systemName: "chevron.right").font(.caption).fontWeight(.semibold)
                    .foregroundStyle(.blue.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct _ReportFooterCTA: View {
    @Environment(AppStateManager.self) var appState
    var data: CompleteAssessmentData?

    var body: some View {
        VStack(spacing: 16) {
            Text("We've analysed your report and summarised key insights. Your dashboard is ready.")
            Button {
                if let data = data {
                    appState.updateProfile(from: data)
                    appState.isAssessmentSkipped = false
                }
                appState.showDashboard = true
            } label: {
                Text("Go to Dashboard")
                    .font(.headline).fontWeight(.semibold).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 17)
                    .background(LinearGradient(
                        colors: [.blue,
                                 .blue],
                        startPoint: .leading, endPoint: .trailing))
                    .clipShape(Capsule())
            }
        }
    }
}

private struct _InsightSheet: View {
    @Environment(\.dismiss) private var dismiss
    let icon: String; let color: Color; let title: String
    let items: [(String, String, Double)]; let advice: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 12) {
                        Image(systemName: icon).font(.title2).foregroundStyle(color)
                            .frame(width: 52, height: 52).background(color.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        Text(title).font(.title3).fontWeight(.bold)
                    }.padding(.top, 4)
                    VStack(spacing: 14) {
                        ForEach(items, id: \.0) { item in
                            _InsightRow(label: item.0, value: item.1, ratio: item.2, color: color)
                        }
                    }
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lightbulb.fill").foregroundStyle(.yellow)
                        Text(advice).font(.subheadline).foregroundStyle(.secondary).lineSpacing(3)
                    }
                    .padding(14).background(Color.yellow.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal, 20).padding(.bottom, 32)
            }
            .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}

private struct _InsightRow: View {
    let label: String; let value: String; let ratio: Double; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label).font(.subheadline)
                Spacer()
                Text(value).font(.subheadline).fontWeight(.semibold)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.barTrack).frame(height: 8)
                    Capsule()
                        .fill(LinearGradient(colors: [color.opacity(0.7), color],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * ratio, height: 8)
                }
            }.frame(height: 8)
        }
    }
}

private struct _InsuranceAdviceSheet: View {
    @Environment(\.dismiss) private var dismiss
    let adultDependents: Int
    @State private var myAge: String = ""
    private let diseases = ["None", "Diabetes", "Hypertension", "Heart Condition", "Thyroid", "Other"]
    @State private var myDisease: String = "None"

    @State private var depAges: [String] = []
    @State private var depDiseases: [String] = []

    private let coverTypes: [(String, String, String, Color)] = [
        ("shield.fill", "Term Life Insurance",
         "Cover your dependents with 10–15x annual income. Ideal for breadwinners.",
         .blue),
        ("cross.case.fill", "Family Health Insurance",
         "A family floater of ₹10–20L covers hospitalisation for the whole family.", .blue),
        ("waveform.path.ecg", "Critical Illness Rider",
         "Covers 36+ critical illnesses with a lump-sum payout on diagnosis.", .orange),
        ("person.badge.shield.checkmark.fill", "Child Plan",
         "Secures your child's education milestones even in your absence.", .purple),
    ]
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Based on your profile with \(adultDependents) adult dependent\(adultDependents == 1 ? "" : "s"), here's what we recommend:")
                        .font(.subheadline).foregroundStyle(.secondary).lineSpacing(4)

                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "person.text.rectangle.fill").foregroundColor(.blue)
                            Text("Health Credentials").font(.headline)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Details").font(.caption).fontWeight(.bold).foregroundColor(.secondary)
                            HStack {
                                TextField("Your Age", text: $myAge).keyboardType(.numberPad)
                                    .padding(12).background(Color.secondary.opacity(0.1)).cornerRadius(10)
                                Spacer()
                                Picker("Disease", selection: $myDisease) {
                                    ForEach(diseases, id: \.self) { Text($0) }
                                }.pickerStyle(.menu)
                            }
                        }

                        if adultDependents > 0 {
                            Divider()
                            Text("Dependents Details").font(.caption).fontWeight(.bold).foregroundColor(.secondary)
                            ForEach(0..<adultDependents, id: \.self) { i in
                                HStack {
                                    Text("Dep \(i+1)").font(.caption).frame(width: 40)
                                    TextField("Age", text: Binding(
                                        get: { depAges.indices.contains(i) ? depAges[i] : "" },
                                        set: { if depAges.indices.contains(i) { depAges[i] = $0 } else { depAges.append($0) } }
                                    )).keyboardType(.numberPad).padding(8).background(Color.secondary.opacity(0.1)).cornerRadius(8)

                                    Picker("Disease", selection: Binding(
                                        get: { depDiseases.indices.contains(i) ? depDiseases[i] : "None" },
                                        set: { if depDiseases.indices.contains(i) { depDiseases[i] = $0 } else { depDiseases.append($0) } }
                                    )) {
                                        ForEach(diseases, id: \.self) { Text($0) }
                                    }.pickerStyle(.menu).scaleEffect(0.9)
                                }
                            }
                        }
                    }
                    .padding(16).background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: AppTheme.adaptiveShadow, radius: 4)

                    Text("Detailed Recommendations")
                        .font(.headline).padding(.top, 8)

                    ForEach(coverTypes, id: \.0) { icon, title, desc, color in
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: icon).font(.title3).foregroundStyle(color)
                                .frame(width: 44, height: 44).background(color.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(title).font(.subheadline).fontWeight(.semibold)
                                Text(desc).font(.caption).foregroundStyle(.secondary).lineSpacing(3)
                            }
                        }
                        .padding(14).background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: AppTheme.adaptiveShadow, radius: 6, x: 0, y: 2)
                    }
                    Button { dismiss() } label: {
                        Text("Explore Insurance Plans")
                            .font(.headline).fontWeight(.semibold).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(.blue).clipShape(Capsule())
                    }.padding(.top, 8)
                }
                .padding(.horizontal, 20).padding(.vertical, 8).padding(.bottom, 32)
            }
            .navigationTitle("Insurance Recommendations").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .onAppear {
                if depAges.count < adultDependents {
                    depAges = Array(repeating: "", count: adultDependents)
                    depDiseases = Array(repeating: "None", count: adultDependents)
                }
            }
        }
    }
}

private struct _VitalsDetailSheet: View {
    let income: String; let expenses: String; let ratio: Double
    var body: some View {
        _InsightSheet(
            icon: "heart.text.square.fill", color: .indigo,
            title: "Financial Vitals Analysis",
            items: [
                ("Monthly Income", "₹\(income)", 1.0),
                ("Monthly Expenses", "₹\(expenses)", expensesRatio),
                ("Savings Margin", "\(Int(ratio * 100))%", ratio)
            ],
            advice: ratio < 0.2 
                ? "Why is my score low? Your savings rate is below the 20% safety benchmark. How to fix? Try reducing 'Discretionary' spending (Dining/Shopping) for 3 months to build your emergency buffer first." 
                : "Astra Insight: You are saving over 20% of your income. This is excellent! You can now afford to take 'Calculated Risks' in Equity to beat inflation and achieve goals 3–5 years earlier."
        )
    }
    private var expensesRatio: Double {

        let inc = Double(income.replacingOccurrences(of: ",", with: "")) ?? 1
        let exp = Double(expenses.replacingOccurrences(of: ",", with: "")) ?? 0
        return min(1.0, exp / (inc > 0 ? inc : 1))
    }
}

private struct _LiabilityDetailSheet: View {
    let loanCount: Int
    var body: some View {
        _InsightSheet(
            icon: "creditcard.fill", color: .purple,
            title: "Liability & Debt Health",
            items: [
                ("Active Loans", "\(loanCount)", loanCount > 0 ? 0.6 : 0.0),
                ("Credit Utilization", loanCount > 0 ? "Moderate" : "Low", loanCount > 0 ? 0.4 : 0.1)
            ],
            advice: loanCount == 0 
                ? "Good News: Zero debt means you have maximum 'Financial Leverage'. You should explore Plan 3 (Leveraged Investing) where you can borrow at 10% and earn 15%—effectively using the bank's money to build your wealth."
                : "Astra Insight: You have active liabilities. To improve your health score, use our Plan 2 (Pre-payment) simulator. Paying just 5% extra on your principal every month can save you lakhs in interest and clear your debt years earlier."
        )
    }
}

private struct _SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).font(.title3).bold()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20).padding(.top, 20)
    }
}

private struct _Chip: View {
    let text: String; let color: Color
    init(_ text: String, color: Color) { self.text = text; self.color = color }
    var body: some View {
        Text(text).font(.caption).fontWeight(.medium).foregroundStyle(color)
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(color.opacity(0.1)).clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        FinancialHealthReportView(data: {
            let d = CompleteAssessmentData()
            d.name = "Akash"
            d.income = "134890"
            d.expenditure = "51000"
            d.adultDependents = 4
            let dummyLife = AssessmentInsuranceEntry(details: .life(AssessmentInsuranceEntry.LifeDetails()))
            d.insuranceEntries.append(dummyLife)
            return d
        }())
    }
    .environment(AppStateManager())
}
