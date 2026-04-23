//
//  RadarChart.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 21/04/26.
//

import SwiftUI

// MARK: - Radar Chart
struct RadarChart: View {
    let values: [(String, Double, Double)]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Canvas { ctx, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) * 0.34
            let count  = values.count
            let step   = (2 * Double.pi) / Double(count)
            let start  = -Double.pi / 2

            func pt(_ i: Int, _ r: Double) -> CGPoint {
                let a = start + Double(i) * step
                return CGPoint(x: center.x + radius * r * cos(a), y: center.y + radius * r * sin(a))
            }
            for ring in stride(from: 0.25, through: 1.0, by: 0.25) {
                var p = Path()
                for i in 0..<count { i == 0 ? p.move(to: pt(i, ring)) : p.addLine(to: pt(i, ring)) }
                p.closeSubpath()
                ctx.stroke(p, with: .color(.gray.opacity(ring == 1.0 ? 0.2 : 0.1)), lineWidth: 0.75)
            }
            for i in 0..<count {
                var s = Path(); s.move(to: center); s.addLine(to: pt(i, 1.0))
                ctx.stroke(s, with: .color(.gray.opacity(0.15)), lineWidth: 0.75)
            }
            var bp = Path()
            for i in 0..<count { i == 0 ? bp.move(to: pt(i, values[i].2)) : bp.addLine(to: pt(i, values[i].2)) }
            bp.closeSubpath()
            ctx.fill(bp, with: .color(Color(hex: "#007AFF").opacity(0.06)))
            ctx.stroke(bp, with: .color(Color(hex: "#007AFF").opacity(0.25)), lineWidth: 1)
            var ap = Path()
            for i in 0..<count { i == 0 ? ap.move(to: pt(i, values[i].1)) : ap.addLine(to: pt(i, values[i].1)) }
            ap.closeSubpath()
            ctx.fill(ap, with: .color(Color(hex: "#007AFF").opacity(0.15)))
            ctx.stroke(ap, with: .color(Color(hex: "#007AFF").opacity(0.9)), lineWidth: 2)
            for i in 0..<count {
                let p   = pt(i, values[i].1)
                let dot = Path(ellipseIn: CGRect(x: p.x-3, y: p.y-3, width: 6, height: 6))
                ctx.fill(dot, with: .color(.white))
                ctx.stroke(dot, with: .color(.blue), lineWidth: 1.5)
            }
        }
        .overlay(
            GeometryReader { geo in
                let s = geo.size
                let center = CGPoint(x: s.width / 2, y: s.height / 2)
                let radius = min(s.width, s.height) * 0.34
                let count  = values.count
                let step   = (2 * Double.pi) / Double(count)
                let start  = -Double.pi / 2
                ForEach(0..<count, id: \.self) { i in
                    let angle  = start + Double(i) * step
                    let lr     = radius * 1.30
                    let actual = values[i].1
                    let color: Color = actual >= 0.7 ? Color(hex: "#30D158") : actual >= 0.45 ? Color(hex: "#FF9F0A") : Color(hex: "#FF453A")
                    VStack(spacing: 2) {
                        Text(String(format: "%.0f", actual * 10))
                            .font(.system(size: 10, weight: .bold)).foregroundStyle(color)
                        Text(values[i].0)
                            .font(.system(size: 9, weight: .medium)).foregroundStyle(.primary)
                            .multilineTextAlignment(.center).lineLimit(2).frame(width: 72)
                    }
                    .position(x: center.x + lr * cos(angle), y: center.y + lr * sin(angle))
                }
            }
        )
        .padding(.vertical, 4)
    }
}

