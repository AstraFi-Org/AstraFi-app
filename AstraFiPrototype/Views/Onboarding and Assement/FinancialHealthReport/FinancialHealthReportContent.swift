import SwiftUI

struct FinancialHealthReportContent: View {
    let report: FinancialHealthReportModel
    let userName: String
    var animatedScore: Double
    var onSelectParameter: (AssessmentParameter) -> Void
    var onAction: (FinancialHealthActionDestination) -> Void
    var onDecisionCenter: () -> Void

    var onImproveHealth: (() -> Void)? = nil

    private var identifiedAreasCount: Int {
        if !report.priorities.isEmpty {
            return report.priorities.count
        }
        if !report.insights.activeConcerns.isEmpty {
            return report.insights.activeConcerns.count
        }
        return 3
    }

    var body: some View {
        VStack(spacing: 0) {
            Group {
                HeroCard(
                    name: userName,
                    score: animatedScore,
                    radarValues: report.radarValues,
                    insights: report.insights,
                    parameters: report.parameters,
                    statusTitle: report.statusTitle,
                    scoreChange: report.scoreChange
                )
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)

                FinancialHealthPlannerConnectionCard(
                    score: report.overallScoreInt,
                    identifiedAreasCount: identifiedAreasCount,
                    onImproveHealth: {
                        onImproveHealth?()
                    }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                if let change = report.scoreChange, let previous = report.previousScore {
                    scoreChangeCard(change: change, previous: previous)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }

                ScoreDriversSection(parameters: report.parameters, onTap: onSelectParameter)

                if !report.priorities.isEmpty {
                    TopFinancialPrioritiesSection(items: report.priorities, onAction: onAction)
                }
            }

            Group {
                ForEach(orderedParameters) { result in
                    ReportSectionTitle(result.parameter.title)
                    ParameterHealthCard(result: result) {
                        onAction(result.actionDestination)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 6)
                    .onTapGesture { onSelectParameter(result.parameter) }
                }

                if !report.whatIfScenarios.isEmpty {
                    WhatIfScoreSection(currentScore: report.overallScoreInt, scenarios: report.whatIfScenarios)
                }

                if !report.goals.isEmpty {
                    GoalReadinessSection(goals: report.goals) {
                        onAction(.goals)
                    }
                }

                if report.journey.count >= 2 {
                    FinancialJourneySection(points: report.journey, gain: report.journeyGain)
                }

                if !report.nextSteps.isEmpty {
                    nextStepsSection
                }

                Button(action: onDecisionCenter) {
                    Label("Explore My Financial Decisions", systemImage: "arrow.triangle.branch")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .foregroundStyle(.white)
                        .background(AppTheme.auraIndigo, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)
            }
        }
    }

    private var orderedParameters: [FinancialHealthParameterResult] {
        let order: [AssessmentParameter] = [.vitals, .liabilities, .emergencyFund, .investment, .insurance]
        return order.compactMap { report.result(for: $0) }
    }

    private func scoreChangeCard(change: Int, previous: Int) -> some View {
        HStack {
            Image(systemName: change >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                .foregroundStyle(change >= 0 ? Color(hex: "#30D158") : Color(hex: "#FF453A"))
            VStack(alignment: .leading, spacing: 2) {
                Text("Since previous assessment")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(change >= 0 ? "+" : "")\(change) points from \(previous)")
                    .font(.subheadline.weight(.semibold))
            }
            Spacer()
        }
        .padding(14)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var nextStepsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            ReportSectionTitle("Next Steps")
            VStack(alignment: .leading, spacing: 12) {
                ForEach(report.nextSteps) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Text(String(format: "%02d", item.rank))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.auraIndigo)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.subheadline.weight(.semibold))
                            Text(item.reason)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(16)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 20)
        }
    }
}

struct ScoreDriversSection: View {
    let parameters: [FinancialHealthParameterResult]
    let onTap: (AssessmentParameter) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ReportSectionTitle("What's driving your score?")
            Text("Each parameter is scored out of 10 and weighted into your overall score.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .padding(.bottom, 14)

            VStack(spacing: 10) {
                ForEach(parameters) { result in
                    Button { onTap(result.parameter) } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: FinancialHealthUIStyle.icon(for: result.parameter))
                                .foregroundStyle(FinancialHealthUIStyle.accent(for: result.parameter))
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(result.parameter.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Text(result.displayScore)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(FinancialHealthUIStyle.parameterColor(result.status))
                                }
                                Text(result.statusTitle)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(FinancialHealthUIStyle.parameterColor(result.status))
                                Text(result.oneLineReason)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(14)
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }
}

struct TopFinancialPrioritiesSection: View {
    let items: [FinancialHealthPriorityItem]
    let onAction: (FinancialHealthActionDestination) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ReportSectionTitle("Your Top Financial Priorities")
            Text("Ranked by impact, urgency, and the size of the gap — not only the lowest score.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .padding(.bottom, 14)

            VStack(spacing: 12) {
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(String(format: "%02d", item.rank))
                                .font(.title3.weight(.bold))
                                .foregroundStyle(AppTheme.auraIndigo)
                            Text(item.title.uppercased())
                                .font(.headline)
                        }
                        HStack {
                            metric("Current", item.currentValue)
                            Spacer()
                            metric("Target", item.targetValue)
                        }
                        labeled("Why", item.reason)
                        labeled("Impact", item.impact)
                        Button {
                            onAction(item.destination)
                        } label: {
                            Text(item.actionTitle)
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .foregroundStyle(.white)
                                .background(AppTheme.auraIndigo, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: AppTheme.adaptiveShadow, radius: 6, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.subheadline.weight(.semibold))
        }
    }

    private func labeled(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Text(text).font(.subheadline)
        }
    }
}

struct WhatIfScoreSection: View {
    let currentScore: Int
    let scenarios: [FinancialHealthWhatIfScenario]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ReportSectionTitle("What could improve your score?")
            Text("Estimated based on AstraFi's scoring model. These are not guaranteed financial outcomes.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .padding(.bottom, 14)

            VStack(spacing: 10) {
                ForEach(scenarios) { scenario in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(scenario.title)
                            .font(.subheadline.weight(.semibold))
                        Text(scenario.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack {
                            Text("Current \(scenario.currentScore) / 100")
                            Spacer()
                            Text("Estimated \(scenario.estimatedScore) / 100")
                                .foregroundStyle(AppTheme.auraIndigo)
                            if scenario.delta != 0 {
                                Text("\(scenario.delta > 0 ? "+" : "")\(scenario.delta)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(scenario.delta > 0 ? Color(hex: "#30D158") : Color(hex: "#FF453A"))
                            }
                        }
                        .font(.caption.weight(.semibold))
                    }
                    .padding(14)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }
}

struct GoalReadinessSection: View {
    let goals: [FinancialHealthGoalReadiness]
    var onPlan: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ReportSectionTitle("Goal Readiness")
            VStack(spacing: 10) {
                ForEach(goals) { goal in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(goal.name).font(.headline)
                            Spacer()
                            Text(goal.status)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(goal.status == "On Track" || goal.status == "Complete" ? Color(hex: "#30D158") : Color(hex: "#FF9F0A"))
                        }
                        Text("\(goal.currentAmount.toCurrency(compact: true)) of \(goal.targetAmount.toCurrency(compact: true))")
                            .font(.subheadline)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color(UIColor.tertiarySystemFill)).frame(height: 7)
                                Capsule()
                                    .fill(AppTheme.auraIndigo)
                                    .frame(width: max(8, geo.size.width * goal.progress), height: 7)
                            }
                        }
                        .frame(height: 7)
                        HStack {
                            Text("\(goal.monthlyContribution.toCurrency(compact: true))/month")
                            Spacer()
                            Text(goal.projectedCompletion)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                Button(action: onPlan) {
                    Text("Plan Goal")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .foregroundStyle(.white)
                        .background(AppTheme.auraIndigo, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }
}

struct FinancialJourneySection: View {
    let points: [FinancialHealthJourneyPoint]
    let gain: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ReportSectionTitle("Financial Health History")
            VStack(alignment: .leading, spacing: 14) {
                gainBanner

                historyList

                Text("Tracking month-over-month score progress helps you stay consistent and build long-term wealth.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }

    @ViewBuilder
    private var gainBanner: some View {
        if let gain, gain != 0 {
            let isPositive = gain >= 0
            let statusText = isPositive ? "improved" : "changed"
            let gainPoints = abs(gain)
            let tintColor = isPositive ? Color(hex: "#30D158") : Color(hex: "#FF453A")
            let iconName = isPositive ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill"

            HStack(spacing: 10) {
                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(tintColor)
                
                Text("Your financial health \(statusText) by \(gainPoints) points.")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tintColor.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var historyList: some View {
        VStack(spacing: 8) {
            ForEach(0..<points.count, id: \.self) { index in
                FinancialJourneyRow(index: index, point: points[index])
            }
        }
    }
}

struct FinancialJourneyRow: View {
    let index: Int
    let point: FinancialHealthJourneyPoint

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index + 1)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(.tertiary)
                .frame(width: 18)

            Text(point.label)
                .font(.subheadline.weight(.medium))

            Spacer()

            Text("\(point.score)")
                .font(.system(.subheadline, design: .monospaced).weight(.bold))
                .foregroundStyle(FinancialHealthUIStyle.scoreColor(point.score))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
