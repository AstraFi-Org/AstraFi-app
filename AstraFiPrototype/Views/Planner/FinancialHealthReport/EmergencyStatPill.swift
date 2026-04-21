//
//  EmergencyStatPill.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI

struct EmergencyStatPill: View {
    let label: String; let value: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.subheadline).bold().foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(10)
        .background(color.opacity(0.07)).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
