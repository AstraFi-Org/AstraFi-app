//
//  SwiftUIView.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 20/04/26.
//

import SwiftUI

struct SnapshotCard: View {
    struct Item {
        let icon: String
        let color: Color
        let label: String
        let value: String
    }

    let title: String
    let items: [Item]
    var caption: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.auraGold)
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }

            VStack(spacing: 12) {
                ForEach(items.indices, id: \.self) { i in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(items[i].color.opacity(0.12))
                                .frame(width: 32, height: 32)
                            Image(systemName: items[i].icon)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(items[i].color)
                        }
                        Text(items[i].label)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(items[i].value)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                    }
                    if i < items.count - 1 {
                        Divider().opacity(0.5)
                    }
                }
            }

            if let caption {
                Text(caption)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding(18)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.auraGold.opacity(0.25), lineWidth: 1)
        )
    }
}
