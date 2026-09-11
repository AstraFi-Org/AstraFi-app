//
//  InsuranceCard.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI

struct ReportInsuranceCard: View {
    let adultDependents: Int; let hasHealth: Bool; let hasLife: Bool

    private var lifeInsuranceText: String {
        if hasLife {
            return adultDependents > 0
                ? "Life insurance is active to safeguard your \(adultDependents) dependent\(adultDependents == 1 ? "" : "s")."
                : "Active life insurance policy recorded."
        } else {
            return adultDependents > 0
                ? "You have \(adultDependents) dependent\(adultDependents == 1 ? "" : "s"), but no active term life cover is in place."
                : "No active life insurance policy recorded."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Coverage Summary").font(.headline)
                Spacer()
            }
            InsuranceRow(icon: "cross.case.fill",
                         color: hasHealth ? Color(hex: "#30D158") : Color(hex: "#FF453A"),
                         text: hasHealth ? "Health insurance is in place." : "Your family does not have active health insurance coverage.",
                         covered: hasHealth)
            InsuranceRow(icon: "person.2.fill",
                         color: hasLife ? Color(hex: "#30D158") : (adultDependents > 0 ? Color(hex: "#FF453A") : Color(hex: "#007AFF")),
                         text: lifeInsuranceText,
                         covered: hasLife)
        }
        .padding(18).background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
