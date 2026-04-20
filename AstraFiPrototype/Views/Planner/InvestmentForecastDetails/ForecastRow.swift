//
//  ForecastRow.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 20/04/26.
//

import SwiftUI


struct ForecastRow: View {
    let icon: String
    let label: String
    let value: String
    let iconColor: Color

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .tint(iconColor)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
        }
    }
}
