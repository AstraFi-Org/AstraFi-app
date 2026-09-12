import SwiftUI

struct InsuranceListView: View {
    @Environment(AppStateManager.self) var appState
    @Environment(\.dismiss) var dismiss
    @State private var showingAddPolicy = false

    private var profile: AstraUserProfile? { appState.currentProfile }
    private var insurances: [AstraInsurance] { profile?.insurances ?? [] }
    private var analyses: [(AstraInsurance, InsuranceAnalysisResult)] {
        guard let profile else { return [] }
        return insurances.map { ($0, InsuranceAnalysisEngine.analyze(policy: $0, profile: profile)) }
    }
    private var totalPremium: Double { insurances.reduce(0) { $0 + $1.annualPremium } }
    private var totalLifeCover: Double { insurances.filter { [.life, .termLifeInsurance, .ulip].contains($0.insuranceType) }.reduce(0) { $0 + $1.sumAssured } }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.auraInterCardSpacing) {
                dashboard
                if insurances.isEmpty { emptyState } else {
                    if let action = analyses.flatMap({ $0.1.topIssues }).sorted(by: { $0.priority.rawValue < $1.priority.rawValue }).first { actionCard(action) }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("YOUR POLICIES").font(.caption.weight(.bold)).foregroundStyle(.secondary).padding(.leading, 4)
                        ForEach(analyses, id: \.0.id) { policy, analysis in
                            NavigationLink { InsuranceDetailView(insurance: policy) } label: { policyRow(policy, analysis) }.buttonStyle(.plain)
                        }
                    }
                }
            }.padding().padding(.bottom, 30)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Insurance").navigationBarTitleDisplayMode(.large).navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showingAddPolicy) { AddInsuranceView() }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { Button { dismiss() } label: { Image(systemName: "chevron.left").fontWeight(.bold) } }
            ToolbarItem(placement: .navigationBarTrailing) { Button { showingAddPolicy = true } label: { Image(systemName: "plus").fontWeight(.bold) } }
        }
    }

    private var dashboard: some View {
        let scored = analyses.compactMap { $0.1.insuranceHealthScore }
        let score = scored.isEmpty ? nil : scored.reduce(0, +) / scored.count
        return VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("INSURANCE HEALTH").font(.caption.weight(.bold)).foregroundStyle(.white.opacity(0.74))
                    Text(score.map { "\($0)/100" } ?? "Review needed").font(.system(size: 30, weight: .bold)).foregroundStyle(.white)
                    Text(score.map(healthLabel) ?? "Verify policy information").font(.subheadline).foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                Image(systemName: "shield.lefthalf.filled").font(.system(size: 32)).foregroundStyle(.white.opacity(0.9))
            }
            Divider().overlay(.white.opacity(0.25))
            HStack { metric("Life cover", totalLifeCover.toCurrency()); Spacer(); metric("Annual premium", totalPremium.toCurrency()) }
        }.padding(20).background(AppTheme.accentGradient).clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous)).shadow(color: AppTheme.accentShadow, radius: 14, x: 0, y: 7)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "shield.slash").font(.system(size: 34)).foregroundStyle(.secondary)
            Text("No policies added").font(.headline)
            Text("Add a policy to see protection, premium, and review insights.").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }.frame(maxWidth: .infinity).padding(36).auraCardStyle(radius: 20)
    }

    private func policyRow(_ policy: AstraInsurance, _ analysis: InsuranceAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) { Text(policy.provider).font(.headline); Text(policyKind(policy)).font(.subheadline).foregroundStyle(.secondary) }
                Spacer(); statusPill(analysis.insuranceHealthStatus.rawValue, color: statusColor(analysis.insuranceHealthStatus))
            }
            HStack { metric("Cover", policy.sumAssured.toCurrency(), dark: true); Spacer(); metric("Premium / year", policy.annualPremium.toCurrency(), dark: true); Spacer(); statusPill(policy.status.rawValue, color: policy.status == .active ? AppTheme.auraGreen : AppTheme.vibrantRed) }
            if let issue = analysis.topIssues.first { Label(issue.title, systemImage: issue.priority == .critical ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill").font(.caption.weight(.semibold)).foregroundStyle(statusColor(analysis.insuranceHealthStatus)) }
        }.padding(18).auraCardStyle(radius: 18)
    }

    private func actionCard(_ action: InsuranceAction) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ATTENTION REQUIRED").font(.caption.weight(.bold)).foregroundStyle(.secondary)
            Label(action.title, systemImage: action.priority == .critical ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill").font(.headline).foregroundStyle(action.priority == .critical ? AppTheme.vibrantRed : AppTheme.vibrantOrange)
            Text(action.detail).font(.subheadline).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(18).auraCardStyle(radius: 18)
    }

    private func metric(_ label: String, _ value: String, dark: Bool = false) -> some View { VStack(alignment: .leading, spacing: 3) { Text(label).font(.caption).foregroundStyle(dark ? Color.secondary : Color.white.opacity(0.72)); Text(value).font(.subheadline.weight(.bold)).foregroundStyle(dark ? Color.primary : Color.white) } }
    private func healthLabel(_ score: Int) -> String { score < 40 ? "Critical" : score < 60 ? "Needs Attention" : score < 75 ? "Review Recommended" : score < 90 ? "Good" : "Strong" }
    private func policyKind(_ policy: AstraInsurance) -> String { policy.lifeDetails?.lifeInsuranceType.map { "\(policy.insuranceType.rawValue) / \($0)" } ?? "\(policy.insuranceType.rawValue) Insurance" }
    private func statusColor(_ status: InsuranceHealthStatus) -> Color { switch status { case .critical, .verificationRequired: AppTheme.vibrantRed; case .needsAttention, .reviewRecommended: AppTheme.vibrantOrange; case .good, .strong: AppTheme.auraGreen } }
    private func statusPill(_ text: String, color: Color) -> some View { Text(text).font(.caption2.weight(.bold)).foregroundStyle(color).padding(.horizontal, 8).padding(.vertical, 5).background(color.opacity(0.13)).clipShape(Capsule()) }
}

#Preview { NavigationStack { InsuranceListView().environment(AppStateManager.withSampleData()) } }
