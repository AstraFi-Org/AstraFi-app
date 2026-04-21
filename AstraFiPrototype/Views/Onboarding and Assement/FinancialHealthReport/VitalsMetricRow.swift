//
//  VitalsMetricRow.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI

struct VitalsMetricRow: View {
    let label: String
    let value: String
    let barValue: Double
    let barColor: Color
    let icon: String
    let iconColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon).font(.subheadline).foregroundStyle(iconColor)
                Text(label).font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                Text(value).font(.subheadline).bold()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(UIColor.tertiarySystemFill)).frame(height: 6)
                    Capsule().fill(barColor).frame(width: max(6, geo.size.width * barValue), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 6)
    }
}
