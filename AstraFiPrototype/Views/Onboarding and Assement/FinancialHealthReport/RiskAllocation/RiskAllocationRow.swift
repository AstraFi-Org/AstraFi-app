//
//  RiskAllocationRow.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI

struct RiskAllocationRow: View {
    let label: String; let amount: Double; let total: Double; let color: Color
    private var ratio: Double { total > 0 ? amount / total : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(color).frame(width: 8, height: 8)
                    Text(label).font(.subheadline)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(Int(ratio * 100))%").font(.subheadline).bold().foregroundStyle(color)
                    Text(amount.toCurrency(compact: true)).font(.caption).foregroundStyle(.secondary)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(UIColor.tertiarySystemFill)).frame(height: 6)
                    Capsule().fill(color).frame(width: max(6, geo.size.width * ratio), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 6)
    }
}
