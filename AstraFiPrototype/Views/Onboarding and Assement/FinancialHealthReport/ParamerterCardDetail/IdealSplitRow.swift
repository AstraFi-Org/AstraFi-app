//
//  IdealSplitRow.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI

struct IdealSplitRow: View {
    let label: String; let percent: Int; let color: Color; let reason: String
    var body: some View {
        HStack(spacing: 10) {
            Text("\(percent)%").font(.headline).bold().foregroundStyle(color).frame(width: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.subheadline).bold()
                Text(reason).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

