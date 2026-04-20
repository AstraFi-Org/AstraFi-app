//
//  AssesmentProgressHeader.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 20/04/26.
//

import SwiftUI

// MARK: - Assessment Progress Header
struct AssessmentProgressHeader: View {
    let progress: Double   // 0.0 to 1.0
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AssessmentProgressBar(progress: progress)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }
}

#Preview {
    AssessmentProgressHeader(
        progress: 0.6,
        title: "Your Risk Profile",
        subtitle: "Answer a few questions to personalize your portfolio"
    )
    .padding()
}
