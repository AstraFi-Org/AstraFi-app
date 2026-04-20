//
//  GateChoiceCard.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 20/04/26.
//

import SwiftUI

// MARK: - Gate Choice Card
struct GateChoiceCard: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let isRecommended: Bool
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                if !icon.isEmpty {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(color)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                        if isRecommended {
                            Text("Recommended")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.auraGreen)
                                .clipShape(Capsule())
                        }
                    }
                    Text(subtitle)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .background(AppTheme.cardBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: AppTheme.adaptiveShadow, radius: pressed ? 4 : 10, x: 0, y: pressed ? 1 : 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isRecommended ? AppTheme.auraIndigo.opacity(0.4) : Color.primary.opacity(0.06), lineWidth: isRecommended ? 2 : 1)
            )
            .scaleEffect(pressed ? 0.97 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.15), value: pressed)
        ._onButtonGesture(pressing: { pressed = $0 }, perform: {})
    }
}

#Preview("Gate Choice Card") {
    GateChoiceCard(
        icon: "bolt.fill",
        color: .yellow,
        title: "Smart Recommendation",
        subtitle: "Let us pick the best option for you",
        isRecommended: true,
        action: {}
    )
    .padding()
    .background(Color.black.opacity(0.9))
}
