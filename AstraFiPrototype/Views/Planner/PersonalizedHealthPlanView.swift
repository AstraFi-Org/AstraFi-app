//
//  PersonalizedHealthPlanView.swift
//  AstraFiPrototype
//
//  Created by AstraFi Agent on 10/09/26.
//

import SwiftUI

struct PersonalizedHealthPlanView: View {
    @Environment(AppStateManager.self) var appState
    @Environment(\.colorScheme) var colorScheme

    @State private var showingAssessmentSheet = false
    @State private var selectedActionDestination: FinancialHealthActionDestination? = nil

    private var profile: AstraUserProfile? { appState.currentProfile }

    private var reportModel: FinancialHealthReportModel {
        FinancialHealthEngine.evaluate(profile: profile, data: nil)
    }

    private var currentScore: Int { reportModel.overallScoreInt }
    private var priorities: [FinancialHealthPriorityItem] { reportModel.priorities }

    private var totalActions: Int { max(priorities.count, 3) }
    private var completedCount: Int { appState.completedPlanActionIDs.count }

    private var estimatedPotentialScore: Int {
        if let maxWhatIf = reportModel.whatIfScenarios.map(\.estimatedScore).max() {
            return max(currentScore, maxWhatIf)
        }
        return min(100, currentScore + (priorities.count * 6) + 10)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            heroHeaderBanner
            scoreProgressCard
            diagnosedActionItems
            reassessmentCTA
        }
        .sheet(isPresented: $showingAssessmentSheet) {
            StartAssesmentView(
                mode: .update,
                prefilledData: appState.currentProfile.map { CompleteAssessmentData.prefilled(from: $0) },
                onSaveComplete: {
                    showingAssessmentSheet = false
                }
            )
        }
        .navigationDestination(item: $selectedActionDestination) { dest in
            FinancialHealthActionDestinationView(destination: dest)
        }
    }

    // MARK: - Hero Header Banner
    private var heroHeaderBanner: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.auraIndigo)
                        Text("PERSONALIZED PLAN")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.auraIndigo)
                    }

                    Text("Your Financial Health Improvement Plan")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.primary)
                }

                Spacer()

                Button {
                    withAnimation {
                        appState.showPersonalizedHealthPlan = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }

            // 6-Stage Lifecycle Flow Header
            VStack(alignment: .leading, spacing: 8) {
                Text("AstraFi Lifecycle Progress")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        stageBadge("1. Assessment", state: .completed)
                        stageArrow
                        stageBadge("2. Diagnosis", state: .completed)
                        stageArrow
                        stageBadge("3. Plan", state: .active)
                        stageArrow
                        stageBadge("4. Action", state: completedCount > 0 ? .completed : .pending)
                        stageArrow
                        stageBadge("5. Tracking", state: completedCount > 0 ? .active : .pending)
                        stageArrow
                        stageBadge("6. Reassessment", state: .pending)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [
                    AppTheme.auraIndigo.opacity(0.12),
                    Color(hex: "#007AFF").opacity(0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.auraIndigo.opacity(0.25), lineWidth: 1.5)
        )
    }

    // MARK: - Score Target & Progress Card
    private var scoreProgressCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Score")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(currentScore)/100")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(FinancialHealthUIStyle.scoreColor(currentScore))
                }

                Spacer()

                Image(systemName: "arrow.forward")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.tertiary)

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Projected Target")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(estimatedPotentialScore)/100")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color(hex: "#30D158"))
                }
            }

            Divider()

            HStack {
                Text("Actions Completed")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(completedCount) of \(totalActions)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.auraIndigo)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.08))
                        .frame(height: 8)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.auraIndigo, Color(hex: "#30D158")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, geo.size.width * (totalActions > 0 ? Double(completedCount) / Double(totalActions) : 0)), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 3)
    }

    // MARK: - Diagnosed Improvement Action Items
    private var diagnosedActionItems: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Diagnosed Action Items")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                Text("\(priorities.count) Priorities")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if priorities.isEmpty {
                fallbackActionItems
            } else {
                ForEach(priorities) { item in
                    planActionRow(for: item)
                }
            }
        }
    }

    // MARK: - Re-assessment CTA Button
    private var reassessmentCTA: some View {
        VStack(alignment: .center, spacing: 10) {
            Button {
                showingAssessmentSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 16, weight: .bold))
                    Text("Re-assess Financial Health")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(AppTheme.auraIndigo)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: AppTheme.auraIndigo.opacity(0.3), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(.plain)

            Text("Take a quick assessment to recalculate your health score after implementing actions.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Individual Plan Action Card
    private func planActionRow(for item: FinancialHealthPriorityItem) -> some View {
        let isDone = appState.completedPlanActionIDs.contains(item.id)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                // Checkmark toggle
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        appState.togglePlanActionCompleted(item.id)
                    }
                } label: {
                    Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(isDone ? Color(hex: "#30D158") : Color.secondary.opacity(0.4))
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(String(format: "%02d", item.rank))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.auraIndigo)
                        Text(item.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(isDone ? .secondary : .primary)
                            .strikethrough(isDone, color: .secondary)

                        Spacer()

                        Text("+6 to +10 pts")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color(hex: "#30D158"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(hex: "#30D158").opacity(0.12))
                            .clipShape(Capsule())
                    }

                    HStack(spacing: 12) {
                        Text("Current: \(item.currentValue)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Target: \(item.targetValue)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.auraIndigo)
                    }

                    Text(item.reason)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            HStack {
                Spacer()
                Button {
                    selectedActionDestination = item.destination
                } label: {
                    HStack(spacing: 4) {
                        Text(item.actionTitle)
                            .font(.caption.weight(.semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .foregroundStyle(.white)
                    .background(AppTheme.auraIndigo)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(isDone ? AppTheme.cardBackground.opacity(0.6) : AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isDone ? Color(hex: "#30D158").opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
        .shadow(color: AppTheme.adaptiveShadow, radius: 6, x: 0, y: 2)
    }

    // MARK: - Fallback Default Action Items
    private var fallbackActionItems: some View {
        let insights = reportModel.insights
        let currentEF = insights.emergencyCoverageRatio > 0
            ? "\(String(format: "%.1f", insights.emergencyCoverageMonths)) mo covered"
            : "0 mo covered"
        let targetEF = insights.emergencyFundTarget > 0
            ? "6 mo (\(insights.emergencyFundTarget.toCurrency()))"
            : "6 months essential expenses"

        let currentSavings = insights.monthlySavings > 0
            ? "\(insights.monthlySavings.toCurrency())/mo"
            : "₹0/mo"
        let targetSavingsVal = insights.monthlyIncome > 0
            ? (insights.monthlyIncome * 0.30).toCurrency()
            : "₹5,000"
        let targetSavings = "\(targetSavingsVal)/mo (30% benchmark)"

        let currentInsurance = (insights.hasHealthInsurance && insights.hasLifeInsurance)
            ? "Fully Covered"
            : (insights.hasHealthInsurance ? "Health active · Term missing" : (insights.hasLifeInsurance ? "Term active · Health missing" : "No active policy"))

        return VStack(spacing: 10) {
            defaultActionCard(
                id: "ef_reserve",
                title: "Build 6-Month Emergency Buffer",
                current: currentEF,
                target: targetEF,
                scoreBoost: "+12 pts",
                destination: .emergencyPlanner,
                buttonText: "Fund Emergency Reserve"
            )

            defaultActionCard(
                id: "sip_boost",
                title: "Start Monthly Investment SIP",
                current: currentSavings,
                target: targetSavings,
                scoreBoost: "+8 pts",
                destination: .investments,
                buttonText: "Set Up SIP"
            )

            defaultActionCard(
                id: "insurance_shield",
                title: "Secure Health & Term Life Insurance",
                current: currentInsurance,
                target: "Health + Term Life Cover",
                scoreBoost: "+10 pts",
                destination: .protection,
                buttonText: "Get Coverage"
            )
        }
    }

    private func defaultActionCard(
        id: String,
        title: String,
        current: String,
        target: String,
        scoreBoost: String,
        destination: FinancialHealthActionDestination,
        buttonText: String
    ) -> some View {
        let isDone = appState.completedPlanActionIDs.contains(id)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Button {
                    withAnimation {
                        appState.togglePlanActionCompleted(id)
                    }
                } label: {
                    Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(isDone ? Color(hex: "#30D158") : Color.secondary.opacity(0.4))
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(isDone ? .secondary : .primary)
                            .strikethrough(isDone, color: .secondary)

                        Spacer()

                        Text(scoreBoost)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color(hex: "#30D158"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(hex: "#30D158").opacity(0.12))
                            .clipShape(Capsule())
                    }

                    HStack(spacing: 10) {
                        Text("Current: \(current)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Target: \(target)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.auraIndigo)
                    }
                }
            }

            HStack {
                Spacer()
                Button {
                    selectedActionDestination = destination
                } label: {
                    Text(buttonText)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .foregroundStyle(.white)
                        .background(AppTheme.auraIndigo)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(isDone ? AppTheme.cardBackground.opacity(0.6) : AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 4, x: 0, y: 2)
    }

    // MARK: - Lifecycle Stage Badge Helpers
    private enum StageState { case completed, active, pending }

    private var stageArrow: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.tertiary)
    }

    private func stageBadge(_ text: String, state: StageState) -> some View {
        HStack(spacing: 4) {
            if state == .completed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(hex: "#30D158"))
            } else if state == .active {
                Circle()
                    .fill(AppTheme.auraIndigo)
                    .frame(width: 6, height: 6)
            }

            Text(text)
                .font(.system(size: 11, weight: state == .active ? .bold : .regular))
                .foregroundStyle(
                    state == .completed ? .primary : (state == .active ? AppTheme.auraIndigo : .secondary)
                )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            state == .active
            ? AppTheme.auraIndigo.opacity(0.14)
            : (state == .completed ? Color.primary.opacity(0.06) : Color.primary.opacity(0.03))
        )
        .clipShape(Capsule())
    }
}

#Preview {
    PersonalizedHealthPlanView()
        .environment(AppStateManager.withSampleData())
        .padding()
}
