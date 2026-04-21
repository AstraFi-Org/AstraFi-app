//
//  HeroCard.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI

struct HeroCard: View {
    let name: String
    let score: Double
    let radarValues: [(String, Double, Double)]

    private var scoreColor: Color {
        score >= 75 ? Color(hex: "#30D158") : score >= 50 ? Color(hex: "#FF9F0A") : Color(hex: "#FF453A")
    }
    private var scoreLabel: String {
        score >= 80 ? "Excellent" : score >= 65 ? "Good" : score >= 45 ? "Fair" : "Needs Work"
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.text.square.fill")
                            .foregroundStyle(Color(hex: "#007AFF")).font(.system(size: 15))
                        Text("AstraFi Report")
                            .font(.subheadline).fontWeight(.semibold).foregroundStyle(.secondary)
                    }
                    Text("Hi, \(name)").font(.title2).bold()
                    Text("Your financial health assessment is complete.")
                        .font(.subheadline).foregroundStyle(.secondary).lineSpacing(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    Circle().trim(from: 0.1, to: 0.9)
                        .stroke(Color(UIColor.systemFill), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .rotationEffect(.degrees(90))
                    Circle().trim(from: 0.1, to: 0.1 + (score / 100) * 0.8)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .rotationEffect(.degrees(90))
                        .animation(.easeOut(duration: 1.4), value: score)
                    VStack(spacing: 1) {
                        Text("\(Int(score))").font(.title3).fontWeight(.black).foregroundStyle(scoreColor)
                        Text(scoreLabel).font(.system(size: 9, weight: .semibold)).foregroundStyle(.secondary)
                    }
                }
                .frame(width: 76, height: 76)
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("5-Parameter Overview").font(.headline)
                RadarChart(values: radarValues).frame(height: 230)
            }
        }
        .padding(22)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow, radius: 14, x: 0, y: 6)
    }
}

