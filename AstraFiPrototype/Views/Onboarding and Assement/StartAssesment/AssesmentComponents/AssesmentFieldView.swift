//
//  AssesmentField.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 20/04/26.
//

import Foundation
import SwiftUI
// MARK: - Shared Assessment Field
struct AssessmentField: View {
    let icon: String
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.auraIndigo.opacity(0.10))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.auraIndigo)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                TextField(placeholder, text: $text)
                    .keyboardType(keyboard)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 6, x: 0, y: 2)
    }
}
#Preview {
    AssessmentField(
        icon: "person.crop.circle",
        label: "Name",
        placeholder: "Akash Kashyap",
        text: .constant(""),
        keyboard: .emailAddress
    )
}
