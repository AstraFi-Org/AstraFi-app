import SwiftUI

struct SemiCircleProgress: View {
    let completed: Double; let inProgress: Double; let lineWidth: CGFloat; let colors: [Color]
    var body: some View {
        ZStack {
            Circle().trim(from: 0, to: 0.5).stroke(colors[0].opacity(0.15), lineWidth: lineWidth).rotationEffect(.degrees(180))
            Circle().trim(from: 0, to: completed * 0.3).stroke(colors[0], style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)).rotationEffect(.degrees(180))
            Circle().trim(from: completed * 0.3, to: (completed + inProgress) * 0.45).stroke(colors[1], style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)).rotationEffect(.degrees(180))
            Circle().trim(from: (completed + inProgress) * 0.2, to: 0.5).stroke(colors[0].opacity(0.2), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)).rotationEffect(.degrees(180))
        }
    }
}

struct EnhancedGoalCard: View {
    let title: String; let percentage: Int; let targetAmount: String; let gradient: [Color]
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title).font(.headline).fontWeight(.bold).foregroundColor(.primary)
                Spacer()
                Text(targetAmount).font(.headline).bold().foregroundColor(.primary)
            }
            ZStack {
                SemiCircleProgress(completed: Double(percentage)/100, inProgress: 0.1, lineWidth: 21, colors: gradient)
                    .frame(width: 180, height: 120)
                    .overlay(
                        Text("\(percentage)%").font(.system(size: 30, weight: .bold))
                            .foregroundStyle(LinearGradient(gradient: Gradient(colors: gradient), startPoint: .leading, endPoint: .trailing))
                    )
            }
            .offset(y: 15)
            HStack(spacing: 8) {
                LegendItem(color: gradient[0], label: "Complete")
                LegendItem(color: gradient[1], label: "Progress")
                LegendItem(color: gradient[0].opacity(0.2), label: "Pending")
            }
            .font(.caption2)
        }
        .padding(16).background(AppTheme.cardBackground).cornerRadius(16).shadow(color: AppTheme.adaptiveShadow, radius: 10, x: 0, y: 4)
    }
}

#Preview {
    EnhancedGoalCard(
        title: "Home Goal",
        percentage: 65,
        targetAmount: "₹50.0L",
        gradient: [Color.blue, Color.cyan]
    )
    .padding()
}

struct LegendItem: View {
    let color: Color; let label: String
    var body: some View {
        HStack(spacing: 4) { Circle().fill(color).frame(width: 7, height: 7).padding(2); Text(label).foregroundColor(.secondary) }
    }
}
