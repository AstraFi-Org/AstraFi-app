//
//  FinancialHealthPlannerConnectionCard.swift
//  AstraFiPrototype
//
//  Created by AstraFi Agent on 10/09/26.
//

import SwiftUI

struct FinancialHealthPlannerConnectionCard: View {
    let score: Int
    let identifiedAreasCount: Int
    let onImproveHealth: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: Your score
            HStack(spacing: 8) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.auraIndigo)
                
                Text("Your score: \(score)/100")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.primary)
                
                Spacer()

                Text("Assessment Complete")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.auraIndigo.opacity(0.12))
                    .foregroundStyle(AppTheme.auraIndigo)
                    .clipShape(Capsule())
            }

            Divider()
                .overlay(Color.primary.opacity(0.08))

            // Diagnostic callout
            VStack(alignment: .leading, spacing: 6) {
                Text("Instead of ending there:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.auraIndigo)
                        .padding(.top, 2)
                    
                    Text("\"We've identified \(identifiedAreasCount) areas that can improve your financial health.\"")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.auraIndigo.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            // CTA Button
            Button(action: onImproveHealth) {
                HStack(spacing: 10) {
                    Text("Improve My Financial Health")
                        .font(.system(size: 17, weight: .bold))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#007AFF"), Color(hex: "#5856D6")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color(hex: "#007AFF").opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)

            // Flow Lifecycle Teaser
            VStack(alignment: .leading, spacing: 8) {
                Text("AstraFi Financial Cycle")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        flowBadge("Assessment", active: true, done: true)
                        flowArrow
                        flowBadge("Diagnosis", active: true, done: true)
                        flowArrow
                        flowBadge("Plan", active: true, done: false)
                        flowArrow
                        flowBadge("Action", active: false, done: false)
                        flowArrow
                        flowBadge("Tracking", active: false, done: false)
                        flowArrow
                        flowBadge("Reassessment", active: false, done: false)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(18)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.auraIndigo.opacity(0.2), lineWidth: 1.5)
        )
        .shadow(color: AppTheme.adaptiveShadow, radius: 10, x: 0, y: 4)
    }

    private var flowArrow: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.tertiary)
    }

    private func flowBadge(_ text: String, active: Bool, done: Bool) -> some View {
        HStack(spacing: 3) {
            if done {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(hex: "#30D158"))
            }
            Text(text)
                .font(.system(size: 11, weight: active ? .semibold : .regular))
                .foregroundStyle(active ? (done ? .primary : AppTheme.auraIndigo) : .secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            active
            ? (done ? Color.primary.opacity(0.06) : AppTheme.auraIndigo.opacity(0.12))
            : Color.primary.opacity(0.03)
        )
        .clipShape(Capsule())
    }
}

#Preview {
    FinancialHealthPlannerConnectionCard(
        score: 68,
        identifiedAreasCount: 3,
        onImproveHealth: {}
    )
    .padding()
}
