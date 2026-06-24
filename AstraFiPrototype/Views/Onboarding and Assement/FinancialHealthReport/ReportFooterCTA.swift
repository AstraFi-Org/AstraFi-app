//
//  ReportFooterCTA.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI

struct ReportFooterCTA: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppStateManager.self) var appState
    var data: CompleteAssessmentData?
    var score: Int; var status: String; var insights: [String]
    var assessmentInsights: FinancialAssessmentInsights?

    @State private var showAuthModal = false
    @State private var showSaveAlert = false

    var body: some View {
        VStack(spacing: 16) {
            Button {
                if appState.isGuest {
                    if let data = data, let assessmentInsights = assessmentInsights {
                        appState.pendingGuestAssessment = AppStateManager.PendingGuestAssessment(
                            data: data,
                            score: score,
                            status: status,
                            insights: insights,
                            assessmentInsights: assessmentInsights
                        )
                    }
                    showSaveAlert = true
                } else {
                    if let data = data {
                        appState.saveAssessmentToHistory(score: score, status: status, insights: insights, assessmentInsights: assessmentInsights)
                        appState.updateProfile(from: data)
                        appState.isAssessmentSkipped = false
                    }
                    appState.showDashboard = true
                    dismiss()
                }
            } label: {
                HStack(spacing: 8) {
                    Text(appState.isGuest ? "Save Report" : "Save")
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(brandGradient)
                .clipShape(Capsule())
            }
        }
        .sheet(isPresented: $showAuthModal) {
            NavigationStack {
                AuthenticationFlowView()
            }
        }
        .alert("Save Report", isPresented: $showSaveAlert) {
            Button("Sign In") {
                showAuthModal = true
            }
            Button("Cancel", role: .cancel) {
                appState.pendingGuestAssessment = nil
            }
        } message: {
            Text("To save your personalized financial health report and access it later, you must create an account or sign in.")
        }
        .onChange(of: appState.showDashboard) { _, newValue in
            if newValue {
                showAuthModal = false
            }
        }
    }
}
