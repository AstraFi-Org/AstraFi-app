//
//  StructFooterButton.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 20/04/26.
//

import SwiftUI

// MARK: - Assessment Footer Button
struct AssessmentFooterButton: View {
    let label: String
    let enabled: Bool
    var isLast: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(label)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(enabled ? AppTheme.auraIndigo : Color.secondary.opacity(0.3))
            .clipShape(Capsule())
        }
        .disabled(!enabled)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemGroupedBackground))
        .animation(.easeInOut(duration: 0.2), value: enabled)
    }
}

#Preview {
    AssessmentFooterButton(
        label: "Continue",
        enabled: true,
        isLast: false,
        action: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
