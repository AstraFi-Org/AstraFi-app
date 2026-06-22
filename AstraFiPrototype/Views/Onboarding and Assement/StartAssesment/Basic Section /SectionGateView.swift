//
//  SectionGateView.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 22/04/26.
//

import SwiftUI

struct SectionGateView: View {
    @Environment(\.dismiss) private var dismiss
    let progress: Int
    let icon: String
    let iconColor: Color
    let question: String
    let detail: String
    let yesLabel: String
    let noLabel: String
    let onYes: () -> Void
    let onNo: () -> Void

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 28) {
                // Progress
                AssessmentProgressBar(progress: Double(progress) / 6.0)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 80, height: 80)
                    Image(systemName: icon)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(iconColor)
                }

                // Question
                VStack(spacing: 10) {
                    Text(question)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                    Text(detail)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                // Choices
                VStack(spacing: 12) {
                    GateChoiceCard(
                        icon: "plus.circle.fill",
                        color: iconColor,
                        title: yesLabel,
                        subtitle: "Takes about 1–2 minutes",
                        isRecommended: true,
                        action: onYes
                    )
                    GateChoiceCard(
                        icon: "arrow.right.circle",
                        color: .secondary,
                        title: noLabel,
                        subtitle: "You can add this later from your profile",
                        isRecommended: false,
                        action: onNo
                    )
                }
                .padding(.horizontal, 20)

                Spacer()
            }
        }
        .navigationTitle("Financial Assessment")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SectionGateView(
            progress: 3,
            icon: "building.columns.fill",
            iconColor: .blue,
            question: "Do you have any investments?",
            detail: "Adding your investments helps us understand your wealth growth and illustrate better strategies.",
            yesLabel: "Yes, add investments",
            noLabel: "Skip for now",
            onYes: {},
            onNo: {}
        )
    }
}
