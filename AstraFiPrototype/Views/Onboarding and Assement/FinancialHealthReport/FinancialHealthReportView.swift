import SwiftUI
import Foundation
import PhotosUI

// MARK: - Main View
struct FinancialHealthReportView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppStateManager.self) var appState
    @ObservedObject private var upstoxViewModel = UpstoxViewModel.shared
    var data: CompleteAssessmentData?
    var onSaveComplete: () -> Void = {}

    private var profile: AstraUserProfile? { appState.currentProfile }
    private var userName: String { profile?.basicDetails.name ?? data?.name ?? "User" }

    @State private var animatedScore: Double = 0
    @State private var selectedParameterResult: FinancialHealthParameterResult?
    @State private var selectedActionDestination: FinancialHealthActionDestination?
    @State private var navigateToDecisionCenter = false

    private var reportModel: FinancialHealthReportModel {
        FinancialHealthEngine.evaluate(
            profile: profile,
            data: data,
            history: profile?.monthlyHealthAssessments ?? []
        )
    }

    private var score: Double { reportModel.overallScore }
    private var status: String { reportModel.statusTitle }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                FinancialHealthReportContent(
                    report: reportModel,
                    userName: userName,
                    animatedScore: animatedScore,
                    onSelectParameter: { param in
                        selectedParameterResult = reportModel.result(for: param)
                    },
                    onAction: { destination in
                        selectedActionDestination = destination
                    },
                    onDecisionCenter: {
                        navigateToDecisionCenter = true
                    }
                )

                ReportFooterCTA(
                    data: data,
                    score: score.safeInt,
                    status: status,
                    insights: reportModel.insights.activeConcerns.map { $0.title },
                    assessmentInsights: reportModel.insights,
                    onSaveComplete: onSaveComplete
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
            }
        }
        .background(AppTheme.appBackground(for: colorScheme).ignoresSafeArea())
        .navigationTitle("Financial Health Report")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeOut(duration: 1.4)) {
                animatedScore = score
            }
        }
        .task { await syncUpstoxInvestments() }
        .onChange(of: upstoxViewModel.isConnected) { _, isConnected in
            if isConnected {
                Task { await syncUpstoxInvestments() }
            } else {
                appState.removeUpstoxHoldings()
            }
        }
        .sheet(item: $selectedParameterResult) { result in
            NavigationStack {
                ParameterExplainDetailView(result: result) {
                    let dest = result.actionDestination
                    selectedParameterResult = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        selectedActionDestination = dest
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { selectedParameterResult = nil }
                    }
                }
            }
        }
        .navigationDestination(item: $selectedActionDestination) { destination in
            FinancialHealthActionDestinationView(destination: destination)
        }
        .navigationDestination(isPresented: $navigateToDecisionCenter) {
            FinancialDecisionCenterView()
        }
    }

    private func syncUpstoxInvestments() async {
        guard upstoxViewModel.isConnected else { return }
        let investments = await upstoxViewModel.fetchConnectedInvestments()
        appState.syncUpstoxHoldings(
            investments.equity,
            mutualFunds: investments.mutualFunds,
            mutualFundOrders: investments.mutualFundOrders,
            mutualFundSIPs: investments.mutualFundSIPs
        )
    }
}

// MARK: - Preview
//#Preview {
//    NavigationStack {
//        let dummyData: CompleteAssessmentData = {
//            let d = CompleteAssessmentData()
//            d.name = "Akash"; d.income = "134890"
//            d.expenditure = "51000"; d.numberOfDependents = "4"
//            d.insuranceEntries.append(AssessmentInsuranceEntry(details: .life(AssessmentInsuranceEntry.LifeDetails())))
//            return d
//        }()
//        FinancialHealthReportView(data: dummyData)
//    }
//    .environment(AppStateManager.withSampleData())
//}
