//
//  ParameterCard.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI

struct ParameterCard: View {
    let summary: AssessmentParameterSummary

    private var statusColor: Color {
        switch summary.status {
        case .fine: return Color(hex: "#30D158")
        case .watch: return Color(hex: "#FF9F0A")
        case .concern, .critical: return Color(hex: "#FF453A")
        }
    }
    private var statusLabel: String {
        switch summary.status {
        case .fine: return "On Track"
        case .watch: return "Watch"
        case .concern, .critical: return "Action Needed"
        }
    }
    private var statusIcon: String {
        switch summary.status {
        case .fine: return "checkmark.circle.fill"
        case .watch: return "exclamationmark.circle.fill"
        case .concern, .critical: return "exclamationmark.triangle.fill"
        }
    }
    private var paramIcon: String {
        switch summary.parameter {
        case .vitals: return "heart.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .liabilities: return "creditcard.fill"
        case .insurance: return "shield.fill"
        case .emergencyFund: return "exclamationmark.shield.fill"
        }
    }
    private var paramColor: Color {
        switch summary.parameter {
        case .vitals: return Color(hex: "#FF2D55")
        case .investment: return Color(hex: "#007AFF")
        case .liabilities: return Color(hex: "#BF5AF2")
        case .insurance: return Color(hex: "#30D158")
        case .emergencyFund: return Color(hex: "#FF9F0A")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(paramColor.opacity(0.12)).frame(width: 32, height: 32)
                    Image(systemName: paramIcon)
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(paramColor)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold)).foregroundStyle(.tertiary)
            }
            Text(summary.parameter.title).font(.subheadline).bold()
            Text(summary.description).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            Spacer(minLength: 4)
            HStack(spacing: 4) {
                Image(systemName: statusIcon).font(.caption2)
                Text(statusLabel).font(.caption).fontWeight(.semibold)
            }
            .foregroundStyle(statusColor)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(statusColor.opacity(0.1)).clipShape(Capsule())
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 6, x: 0, y: 2)
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(statusColor.opacity(0.25), lineWidth: 1))
    }
}
