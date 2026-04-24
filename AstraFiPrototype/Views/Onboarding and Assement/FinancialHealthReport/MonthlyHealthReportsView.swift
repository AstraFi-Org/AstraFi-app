import SwiftUI

struct MonthlyHealthReportsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppStateManager.self) var appState
    @State private var showingAssessment = false

    private var reports: [AstraHealthAssessment] {
        (appState.currentProfile?.monthlyHealthAssessments ?? [])
            .sorted { $0.date > $1.date }
    }

    private var hasCompletedAssessment: Bool {
        appState.currentProfile?.financialHealthReport != nil
    }

    private var groupedByYear: [(String, [AstraHealthAssessment])] {
        let cal = Calendar.current
        var dict: [String: [AstraHealthAssessment]] = [:]
        for r in reports {
            let year = "\(cal.component(.year, from: r.date))"
            dict[year, default: []].append(r)
        }
        return dict.sorted { $0.key > $1.key }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerCard
                if !hasCompletedAssessment || reports.isEmpty {
                    noAssessmentCard
                } else {
                    assessmentHistory
                }
                dataSourceFooter
            }
            .padding()
        }
        .navigationTitle("Health Reports")
        .background(AppTheme.appBackground(for: colorScheme))
        .sheet(isPresented: $showingAssessment) {
            AssessmentPromptView()
        }
        .onAppear {
            addSampleReportsIfNeeded()
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Color.red.opacity(0.12)).frame(width: 48, height: 48)
                    Image(systemName: "heart.text.square.fill")
                        .font(.title2).foregroundColor(.red)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Monthly Health Check").font(.headline)
                    Text("Financial wellness score, updated every month")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            if let latest = reports.first {
                Divider()
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Latest Score").font(.caption).foregroundColor(.secondary)
                        Text("\(latest.score)").font(.system(size: 32, weight: .bold))
                            .foregroundColor(scoreColor(latest.score))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Status").font(.caption).foregroundColor(.secondary)
                        Text(latest.status).font(.subheadline).fontWeight(.semibold)
                            .foregroundColor(scoreColor(latest.score))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("As of").font(.caption).foregroundColor(.secondary)
                        Text(latest.date.formatted(.dateTime.month().year()))
                            .font(.subheadline).fontWeight(.semibold)
                    }
                }
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
    }

    private var noAssessmentCard: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 52)).foregroundColor(.secondary.opacity(0.3))
            VStack(spacing: 8) {
                Text("No Assessment Yet").font(.headline)
                Text("Complete your financial health assessment to start tracking your monthly progress score.")
                    .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
            }
            Button(action: { showingAssessment = true }) {
                Label("Complete Assessment", systemImage: "arrow.right.circle.fill")
                    .font(.headline).padding(.horizontal, 24).padding(.vertical, 12)
                    .background(
                        LinearGradient(colors: [Color(hex: "4F6AFF"), Color(hex: "8A3FFC")],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundColor(.white).cornerRadius(14)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40).padding(.horizontal, 20)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
    }

    private var assessmentHistory: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Assessment History")
                .font(.subheadline).foregroundColor(.secondary)
                .padding(.horizontal, 4)

            ForEach(groupedByYear, id: \.0) { year, yearReports in
                VStack(alignment: .leading, spacing: 0) {
                    Text(year)
                        .font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
                        .padding(.horizontal).padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.07))

                    ForEach(Array(yearReports.enumerated()), id: \.element.id) { idx, report in
                        let prevScore = findPreviousScore(for: report)
                        NavigationLink(destination: HealthReportDetailView(report: report)) {
                            HealthReportRow(report: report, previousScore: prevScore)
                        }
                        .buttonStyle(.plain)
                        if idx < yearReports.count - 1 {
                            Divider().padding(.leading, 72)
                        }
                    }
                }
                .background(AppTheme.cardBackground)
                .cornerRadius(16)
                .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
            }
        }
    }

    private var dataSourceFooter: some View {
        HStack {
            Text("Data Source").font(.subheadline).foregroundColor(.secondary)
            Spacer()
            HStack(spacing: 4) {
                Circle().fill(appState.currentProfile?.isSetuConnected == true ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text(appState.currentProfile?.isSetuConnected == true ? "Connected via Setu" : "Manual Entry")
                    .font(.caption2)
                    .foregroundColor(appState.currentProfile?.isSetuConnected == true ? .green : .orange)
            }
        }
        .padding(.horizontal, 4)
    }

    private func findPreviousScore(for report: AstraHealthAssessment) -> Int? {
        let sorted = reports.sorted { $0.date < $1.date }
        if let idx = sorted.firstIndex(where: { $0.id == report.id }), idx > 0 {
            return sorted[idx - 1].score
        }
        return nil
    }

    private func addSampleReportsIfNeeded() {
        guard let profile = appState.currentProfile, profile.monthlyHealthAssessments.isEmpty,
              profile.financialHealthReport != nil else { return }
        let cal = Calendar.current
        let samples: [(Int, Int, String, [String])] = [
            (0,  696, "Good",        ["High saving ratio", "Proper insurance coverage", "Emergency fund healthy"]),
            (-1, 670, "Good",        ["Increased emergency fund", "High credit card usage"]),
            (-2, 650, "Good",        ["Started new SIP", "Low liquid assets"]),
        ]
        let reports = samples.compactMap { offset, score, status, insights -> AstraHealthAssessment? in
            guard let d = cal.date(byAdding: .month, value: offset, to: Date()) else { return nil }
            return AstraHealthAssessment(date: d, score: score, status: status, keyInsights: insights)
        }
        appState.currentProfile?.monthlyHealthAssessments = reports
    }

    private func scoreColor(_ score: Int) -> Color {
        score >= 800 ? .green : score >= 700 ? .orange : .red
    }
}

struct HealthReportRow: View {
    let report: AstraHealthAssessment
    var previousScore: Int? = nil

    private func scoreColor(_ s: Int) -> Color { s >= 800 ? .green : s >= 700 ? .orange : .red }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(scoreColor(report.score).opacity(0.12)).frame(width: 50, height: 50)
                Text("\(report.score)")
                    .font(.system(size: 15, weight: .bold)).foregroundColor(scoreColor(report.score))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(report.date.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)
                HStack(spacing: 4) {
                    Text(report.status).font(.caption).foregroundColor(scoreColor(report.score))
                    if let prev = previousScore {
                        let diff = report.score - prev
                        if diff != 0 {
                            HStack(spacing: 2) {
                                Image(systemName: diff > 0 ? "arrow.up.right" : "arrow.down.right")
                                Text("\(abs(diff)) pts")
                            }
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(diff > 0 ? .green : .red)
                        }
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption2).foregroundColor(.secondary)
        }
        .padding()
    }
}

struct HealthReportDetailView: View {
    @Environment(AppStateManager.self) var appState
    let report: AstraHealthAssessment
    private func scoreColor(_ s: Int) -> Color { s >= 80 ? .blue : s >= 70 ? .orange : .red }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let insights = report.insights {
                    // Detailed Report from Snapshot
                    HeroCard(
                        name: appState.currentProfile?.basicDetails.name ?? "User",
                        score: Double(report.score),
                        radarValues: insights.radarValues,
                        insights: insights                          // ← added
                    )

                    ParameterSection(summaries: insights.parameterSummaries, onTap: { _ in })

                    ReportSectionTitle("Key Insights")
                    VStack(spacing: 12) {
                        ForEach(Array(report.keyInsights.enumerated()), id: \.offset) { _, insight in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue).font(.body)
                                Text(insight).font(.subheadline)
                                Spacer()
                            }
                            .padding()
                            .background(AppTheme.cardBackground)
                            .cornerRadius(12)
                            .shadow(color: AppTheme.adaptiveShadow, radius: 4, x: 0, y: 2)
                        }
                    }
                } else {
                    // Legacy/Fallback Simple View
                    VStack(spacing: 16) {
                        ZStack {
                            Circle().stroke(scoreColor(report.score).opacity(0.2), lineWidth: 12)
                                .frame(width: 120, height: 120)
                            VStack(spacing: 4) {
                                Text("\(report.score)")
                                    .font(.system(size: 42, weight: .bold))
                                    .foregroundColor(scoreColor(report.score))
                                Text(report.status).font(.caption2)
                                    .foregroundColor(scoreColor(report.score))
                            }
                        }
                        Text(report.date.formatted(.dateTime.month(.wide).year()))
                            .font(.title3).fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity).padding(30)
                    .background(AppTheme.cardBackground).cornerRadius(20)
                    .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)

                    scoreMeaningCard

                    if !report.keyInsights.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Key Insights").font(.headline).padding(.horizontal)
                            ForEach(Array(report.keyInsights.enumerated()), id: \.offset) { _, insight in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue).font(.body)
                                    Text(insight).font(.subheadline)
                                    Spacer()
                                }
                                .padding()
                                .background(AppTheme.cardBackground).cornerRadius(12)
                                .shadow(color: AppTheme.adaptiveShadow, radius: 4, x: 0, y: 2)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(report.date.formatted(.dateTime.month(.wide).year()))
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.appBackground(for: .light))
    }

    private var scoreMeaningCard: some View {
        HStack(spacing: 16) {
            scoreRange(label: "Excellent", range: "800+", color: .green)
            Divider().frame(height: 40)
            scoreRange(label: "Good", range: "700-799", color: .orange)
            Divider().frame(height: 40)
            scoreRange(label: "Needs Work", range: "<700", color: .red)
        }
        .padding()
        .background(Color(uiColor: .systemBackground)).cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func scoreRange(label: String, range: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Circle().fill(color.opacity(0.15)).frame(width: 10, height: 10)
            Text(range).font(.caption2).fontWeight(.bold).foregroundColor(color)
            Text(label).font(.system(size: 10)).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AssessmentPromptView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppStateManager.self) var appState

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.red)

                VStack(spacing: 12) {
                    Text("Financial Health Assessment")
                        .font(.title2).fontWeight(.bold).multilineTextAlignment(.center)
                    Text("Answer a few questions about your income, expenses, savings, and loans. We'll generate your first financial health score.")
                        .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                VStack(spacing: 12) {
                    infoRow(icon: "clock", text: "Takes about 5 minutes")
                    infoRow(icon: "lock.shield", text: "Your data is private and secure")
                    infoRow(icon: "chart.bar.fill", text: "Updated every month automatically")
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground)).cornerRadius(16)
                .padding(.horizontal, 24)

                Button(action: { dismiss() }) {
                    Text("Start Assessment")
                        .font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding()
                        .background(
                            LinearGradient(colors: [Color(hex: "4F6AFF"), Color(hex: "8A3FFC")],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                Spacer()
            }
            .navigationTitle("Get Started")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(.blue).frame(width: 24)
            Text(text).font(.subheadline)
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        MonthlyHealthReportsView()
            .environment(AppStateManager.withSampleData())
    }
}
