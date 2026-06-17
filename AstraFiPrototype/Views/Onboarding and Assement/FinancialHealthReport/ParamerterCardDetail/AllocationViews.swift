//
//  AllocationViews.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI

struct AllocationInputRow: View {
    let icon: String; let color: Color; let label: String
    @Binding var value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.subheadline).foregroundStyle(color)
                .frame(width: 28, height: 28).background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 7))
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.subheadline)
                TextField("₹ Amount", text: $value).keyboardType(.numberPad)
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AllocationBarRow: View {
    let label: String; let amount: Double; let total: Double; let color: Color
    private var ratio: Double { total > 0 ? amount / total : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(color).frame(width: 8, height: 8)
                    Text(label).font(.subheadline)
                }
                Spacer()
                Text("\((ratio * 100).safeInt)% · \(amount.toCurrency(compact: true))")
                    .font(.caption).bold().foregroundStyle(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(UIColor.tertiarySystemFill)).frame(height: 6)
                    Capsule().fill(color).frame(width: max(6, geo.size.width * ratio), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 4)
    }
}
