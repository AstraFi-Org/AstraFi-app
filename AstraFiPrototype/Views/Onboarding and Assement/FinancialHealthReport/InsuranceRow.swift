//
//  InsuranceRow.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI
struct InsuranceRow: View {
    let icon: String; let color: Color; let text: String; let covered: Bool
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).font(.subheadline).foregroundStyle(color)
                .frame(width: 30, height: 30).background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            Text(text).font(.subheadline).foregroundStyle(.primary).lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Image(systemName: covered ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(covered ? Color(hex: "#30D158") : Color(hex: "#FF453A")).font(.body)
        }
        .padding(12).background(color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
