//
//  InsuranceCard.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI

struct ReportInsuranceCard: View {
    let adultDependents: Int; let hasHealth: Bool; let hasLife: Bool
    private var coveredCount: Int { hasLife ? max(1, adultDependents - 1) : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Coverage Summary").font(.headline)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).fontWeight(.semibold).foregroundStyle(.tertiary)
            }
            InsuranceRow(icon: "cross.case.fill",
                         color: hasHealth ? Color(hex: "#30D158") : Color(hex: "#FF453A"),
                         text: hasHealth ? "Health insurance is in place." : "Your family does not have health insurance coverage.",
                         covered: hasHealth)
            InsuranceRow(icon: "person.2.fill", color: Color(hex: "#007AFF"),
                         text: "Out of \(adultDependents) adult dependent\(adultDependents == 1 ? "" : "s"), \(coveredCount) \(coveredCount == 1 ? "has" : "have") life insurance.",
                         covered: coveredCount >= adultDependents)
        }
        .padding(18).background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
    }
}
