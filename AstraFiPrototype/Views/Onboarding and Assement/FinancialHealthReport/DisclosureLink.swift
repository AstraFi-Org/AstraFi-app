//
//  DisclosureLink.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI

struct DisclosureLink: View {
    let text: String; let action: () -> Void
    init(_ text: String, action: @escaping () -> Void) { self.text = text; self.action = action }
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill").font(.caption).foregroundStyle(Color(hex: "#FF9F0A"))
                Text(text).font(.subheadline).fontWeight(.medium).foregroundStyle(Color(hex: "#007AFF"))
                    .multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).fontWeight(.semibold)
                    .foregroundStyle(Color(hex: "#007AFF").opacity(0.6))
            }
        }
    }
}
