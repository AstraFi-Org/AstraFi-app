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
            HStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill").font(.largeTitle)
                    .foregroundStyle(Color(hex: "#30D158"))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Report complete").font(.headline)
                    Text("Your dashboard is ready with personalised insights.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(16).background(Color(hex: "#30D158").opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Button {
                if let data = data {
                    appState.saveAssessmentToHistory(score: score, status: status, insights: insights, assessmentInsights: assessmentInsights)
                    appState.updateProfile(from: data)
                    appState.isAssessmentSkipped = false
                }
                appState.showDashboard = true
            } label: {
                HStack(spacing: 8) {
                    Text("Go to Dashboard"); Image(systemName: "arrow.right")
                }
                .font(.headline).bold().foregroundColor(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 17)
                .background(LinearGradient(colors: [Color(hex: "#007AFF"), Color(hex: "#5E5CE6")],
                                           startPoint: .leading, endPoint: .trailing))
                .clipShape(Capsule())
                .shadow(color: Color(hex: "#007AFF").opacity(0.3), radius: 10, x: 0, y: 5)
            }
        }
    }
}
