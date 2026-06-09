//
//  ConcernCard.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI

struct ConcernCard: View {
    let concern: AssessmentConcern

    private var isCritical: Bool { concern.status == .concern }
    private var accentColor: Color { isCritical ? Color(hex: "#FF453A") : Color(hex: "#FF9F0A") }
    private var iconName: String {
        switch concern.parameter {
        case .vitals:        return "heart.text.square.fill"
        case .investment:    return "chart.line.downtrend.xyaxis"
        case .emergencyFund: return "exclamationmark.shield.fill"
        case .insurance:     return "cross.case.fill"
        case .liabilities:   return "creditcard.trianglebadge.exclamationmark"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: iconName).font(.title3).foregroundStyle(accentColor)
                    .frame(width: 44, height: 44).background(accentColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(concern.parameter.title).font(.caption).bold()
                            .foregroundStyle(accentColor).textCase(.uppercase)
                        Spacer()
                        Text(isCritical ? "Action Needed" : "Watch").font(.caption).bold()
                            .foregroundStyle(accentColor).padding(.horizontal, 8).padding(.vertical, 4)
                            .background(accentColor.opacity(0.12)).clipShape(Capsule())
                    }
                    Text(concern.title).font(.headline)
                }
            }
            Text(concern.summary).font(.subheadline).foregroundStyle(.secondary).lineSpacing(3)
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb.fill").font(.caption).foregroundStyle(Color(hex: "#FF9F0A")).padding(.top, 1)
                Text(concern.recommendation).font(.subheadline).fontWeight(.medium).lineSpacing(3)
            }
            .padding(12).background(Color(hex: "#FF9F0A").opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(16).background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(accentColor.opacity(0.2), lineWidth: 1))
        .shadow(color: AppTheme.adaptiveShadow, radius: 6, x: 0, y: 2)
    }
}
