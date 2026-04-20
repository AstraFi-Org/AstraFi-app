//
//  AssesmentProgressBar.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 20/04/26.
//

import SwiftUI

// MARK: - Continuous Progress Bar
struct AssessmentProgressBar: View {
    let progress: Double // 0.0 to 1.0
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.secondary.opacity(0.12))
                    .frame(height: 6)
                
                // Active fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.auraIndigo, AppTheme.auraIndigo.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(12, geo.size.width * progress), height: 6)
                    .shadow(color: AppTheme.auraIndigo.opacity(0.3), radius: 4, x: 0, y: 2)
            }
        }
        .frame(height: 6)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
    }
}

#Preview {
    VStack(spacing: 20) {
        AssessmentProgressBar(progress: 0.2) 
    }
    .padding()
}
