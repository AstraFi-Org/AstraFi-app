//
//  ReportFooterCTA.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI

struct ReportFooterCTA: View {
    @Environment(AppStateManager.self) var appState
    var data: CompleteAssessmentData?
    var score: Int; var status: String; var insights: [String]
    var assessmentInsights: FinancialAssessmentInsights?

    var body: some View {
        VStack(spacing: 16) {
            Button {
                if let data = data {
                    appState.saveAssessmentToHistory(score: score, status: status, insights: insights, assessmentInsights: assessmentInsights)
                    appState.updateProfile(from: data)
                    appState.isAssessmentSkipped = false
                }
                appState.showDashboard = true
            } label: {
                HStack(spacing: 8) {
                    Text("Save");
                }.font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(brandGradient)
                    .clipShape(Capsule())
//                .font(.headline).bold().foregroundColor(.white)
//                .frame(maxWidth: .infinity).padding(.vertical, 17)
//                .background(LinearGradient(colors: [Color(hex: "#007AFF"), Color(hex: "#5E5CE6")],
//                                           startPoint: .leading, endPoint: .trailing))
//                .clipShape(Capsule())
//                .shadow(color: Color(hex: "#007AFF").opacity(0.3), radius: 10, x: 0, y: 5)
            }
        }
    }
}
