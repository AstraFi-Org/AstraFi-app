import SwiftUI
import Foundation
import PhotosUI

// MARK: - Main View
struct FinancialHealthReportView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppStateManager.self) var appState
    var data: CompleteAssessmentData?

    private var profile: AstraUserProfile? { appState.currentProfile }
    private var userName: String { profile?.basicDetails.name ?? data?.name ?? "User" }

    @State private var spendingSheet   = false
    @State private var riskSheet       = false
    @State private var insuranceSheet  = false
    @State private var vitalsDetail    = false
    @State private var liabilityDetail = false
    @State private var emergencyDetail = false
    @State private var showingAddGoal  = false
    @State private var animatedScore: Double = 0
    @State private var vitalsPeriod: VitalsPeriod = .monthly

    enum VitalsPeriod: String, CaseIterable { case monthly = "Monthly"; case yearly = "Yearly" }

    private var insights: FinancialAssessmentInsights {
        FinancialAssessmentInsights.build(profile: profile, data: data)
    }

    private var score: Double {
        let values = insights.radarValues.map { $0.1 }
        let avg = values.reduce(0.0, +) / Double(values.count)
        return min(100, avg * 100)
    }

    private var savingRatio: Double { insights.savingsRate }
    private var status: String { score >= 80 ? "Excellent" : score >= 70 ? "Good" : "Needs Work" }

    private func periodValue(_ monthly: Double) -> Double {
        vitalsPeriod == .yearly ? monthly * 12 : monthly
    }

    private var incomeValue: String      { fmtDecimals(periodValue(insights.monthlyIncome)) }
    private var grossIncomeValue: String { fmtDecimals(periodValue(insights.grossMonthlyIncome)) }

    private var displayedExpenses: String {
        let total = profile?.cashflowData?.total ?? 0
        let base  = total > 0 ? total : insights.monthlyExpenses
        return fmtDecimals(periodValue(base))
    }

    private var investCount: Int { insights.investmentCount }
    private var loanCount: Int   { insights.loanCount }
    private var insCount: Int    { insights.insuranceCount }

    private func fmtDecimals(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal; f.groupingSeparator = ","
        f.minimumFractionDigits = 2; f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: v)) ?? "\(v)"
    }

    // MARK: - Body Sections

    private var heroSection: some View {
        Group {
            HeroCard(name: userName, score: animatedScore, radarValues: insights.radarValues)
                .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 24)

            ParameterSection(summaries: insights.parameterSummaries) { param in
                switch param {
                case .vitals:        vitalsDetail    = true
                case .investment:    riskSheet       = true
                case .liabilities:   liabilityDetail = true
                case .insurance:     insuranceSheet  = true
                case .emergencyFund: emergencyDetail = true
                }
            }
        }
    }

    private var vitalsSection: some View {
        Group {
            ReportSectionTitle("Financial Vitals")
            VitalsCard(period: $vitalsPeriod, income: incomeValue,
                       expenses: displayedExpenses,
                       cashflow: appState.currentProfile?.cashflowData)
            .padding(.horizontal, 20).padding(.bottom, 6)
            .contentShape(Rectangle())
            DisclosureLink("Where do you spend the most?") { spendingSheet = true }
                .padding(.horizontal, 20).padding(.bottom, 24)
        }
    }

    private var investmentSection: some View {
        Group {
            ReportSectionTitle("Investment Analysis")
            InvestmentStatsGrid(total: investCount,
                                atRisk: insights.investmentBreakdown.highRiskCount)
            .padding(.horizontal, 20).padding(.bottom, 10)
//            .contentShape(Rectangle()).onTapGesture { riskSheet = true }

            DisclosureLink("How can I reduce investment risk?") { riskSheet = true }
                .padding(.horizontal, 20).padding(.bottom, 24)
        }
    }

    private var emergencyFundSection: some View {
        Group {
            ReportSectionTitle("Emergency Fund")
            EmergencyFundCard(currentAmount: insights.emergencyFundAmount,
                              targetAmount: insights.emergencyFundTarget,
                              lowRiskLiquid: insights.investmentBreakdown.lowRiskLiquidAmount,
                              statusMessage: insights.emergencyStatusMessage)
            .padding(.horizontal, 20).padding(.bottom, 6)
            .contentShape(Rectangle())
            DisclosureLink("How to improve emergency-fund liquidity?") { emergencyDetail = true }
                .padding(.horizontal, 20).padding(.bottom, 24)
        }
    }

    private var insuranceSection: some View {
        Group {
            ReportSectionTitle("Insurance Coverage")
            ReportInsuranceCard(
                adultDependents: profile?.basicDetails.adultDependents ?? Int(data?.numberOfDependents ?? "") ?? 1,
                hasHealth: profile?.insurances.contains(where: { $0.insuranceType == .health })
                    ?? (data?.insuranceEntries.contains { $0.currentType == .health } ?? false),
                hasLife: profile?.insurances.contains(where: { [.life, .termLifeInsurance, .ulip].contains($0.insuranceType) })
                    ?? (data?.insuranceEntries.contains { [.life, .term, .ulip].contains($0.currentType) } ?? false)
            )
            .padding(.horizontal, 20).padding(.bottom, 6)
            .contentShape(Rectangle())

            DisclosureLink("Help me choose the right insurance") { insuranceSheet = true }
                .padding(.horizontal, 20).padding(.bottom, 28)
        }
    }

    private var footerSection: some View {
        ReportFooterCTA(data: data, score: Int(score), status: status,
                        insights: insights.activeConcerns.map { $0.title },
                        assessmentInsights: insights)
            .padding(.horizontal, 20).padding(.bottom, 48)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                vitalsSection
                investmentSection
                emergencyFundSection
                insuranceSection
                footerSection
            }
        }
        .background(AppTheme.appBackground(for: colorScheme).ignoresSafeArea())
        .navigationTitle("Health Report")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { withAnimation(.easeOut(duration: 1.4)) { animatedScore = score } }
        .sheet(isPresented: $vitalsDetail) {
            VitalsDetailSheet(income: insights.monthlyIncome,
                              expenses: insights.monthlyExpenses,
                              savings: insights.monthlySavings,
                              ratio: savingRatio,
                              concerns: insights.activeConcerns.filter { $0.parameter == .vitals })
        }
        .sheet(isPresented: $spendingSheet) {
            CashflowInputSheet(cashflow: Binding(
                get: { profile?.cashflowData ?? CashflowEntry() },
                set: { appState.updateCashflow($0) }
            ))
        }
        .sheet(isPresented: $riskSheet) {
            RiskSheet(insights: insights,
                      concerns: insights.activeConcerns.filter { $0.parameter == .investment })
        }
        .sheet(isPresented: $insuranceSheet) {
            InsuranceAdviceSheet(
                adultDependents: profile?.basicDetails.adultDependents ?? Int(data?.numberOfDependents ?? "") ?? 1,
                concerns: insights.activeConcerns.filter { $0.parameter == .insurance }
            )
        }
        .sheet(isPresented: $liabilityDetail) {
            LiabilityDetailSheet(insights: insights,
                                 concerns: insights.activeConcerns.filter { $0.parameter == .liabilities })
        }
        .sheet(isPresented: $emergencyDetail) {
            EmergencyFundInsightSheet(insights: insights)
        }
        .sheet(isPresented: $showingAddGoal) { AddGoalView() }
    }
}




// MARK: - Preview
#Preview {
    NavigationStack {
        let dummyData: CompleteAssessmentData = {
            let d = CompleteAssessmentData()
            d.name = "Akash"; d.income = "134890"
            d.expenditure = "51000"; d.numberOfDependents = "4"
            d.insuranceEntries.append(AssessmentInsuranceEntry(details: .life(AssessmentInsuranceEntry.LifeDetails())))
            return d
        }()
        FinancialHealthReportView(data: dummyData)
    }
    .environment(AppStateManager.withSampleData())
}
