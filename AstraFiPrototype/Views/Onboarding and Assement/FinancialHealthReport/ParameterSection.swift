//
//  ParameterSection.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI

// MARK: - Parameter Section
struct ParameterSection: View {
    let summaries: [AssessmentParameterSummary]
    let onTap: (AssessmentParameter) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ReportSectionTitle("5 Parameters")
            Text("Tap any parameter to explore details and recommendations.")
                .font(.subheadline).foregroundStyle(.secondary)
                .padding(.horizontal, 20).padding(.bottom, 14)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(summaries) { summary in
                    ParameterCard(summary: summary).onTapGesture { onTap(summary.parameter) }
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 24)
        }
    }
}
