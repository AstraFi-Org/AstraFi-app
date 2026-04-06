import SwiftUI

struct EnhancedTipCard: View {
    let category: String; let title: String; let time: String; let icon: String; let accentColor: Color
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack { RoundedRectangle(cornerRadius: 12).fill(accentColor.opacity(0.15)).frame(width: 50, height: 50); Image(systemName: icon).font(.title3).foregroundColor(accentColor) }
            VStack(alignment: .leading, spacing: 6) {
                HStack { Text(category).font(.caption).fontWeight(.semibold).foregroundColor(accentColor).padding(.horizontal, 10).padding(.vertical, 4).background(accentColor.opacity(0.15)).cornerRadius(8); Spacer(); Text(time).font(.caption2).foregroundColor(.secondary) }
                Text(title).font(.subheadline).fontWeight(.medium).foregroundColor(.primary).fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16).background(AppTheme.cardBackground).cornerRadius(16).shadow(color: accentColor.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    VStack(spacing: 12) {
        EnhancedTipCard(
            category: "Tax Saving",
            title: "Maximize 80C benefits before March 31st to save up to ₹46,800 in taxes.",
            time: "2 days left",
            icon: "leaf.fill",
            accentColor: .green
        )
        EnhancedTipCard(
            category: "Investment",
            title: "Consider diversifying with Gold ETFs as market volatility increases.",
            time: "New",
            icon: "star.fill",
            accentColor: .orange
        )
    }
    .padding()
}
