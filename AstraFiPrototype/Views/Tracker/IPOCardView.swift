import SwiftUI

struct EnhancedIPOCard: View {
    let name: String; let category: String; let status: String; let statusColor: Color; let date: String; let minInvestment: String; let priceRange: String; var leftShare: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) { Text(name).font(.headline).fontWeight(.bold).foregroundColor(.primary); HStack(spacing: 6) { Image(systemName: "building.2.fill").font(.caption).foregroundColor(.secondary); Text(category).font(.caption).foregroundColor(.secondary) } }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) { Text(status).font(.caption).fontWeight(.bold).foregroundColor(statusColor).padding(.horizontal, 12).padding(.vertical, 6).background(statusColor.opacity(0.15)).cornerRadius(10); HStack(spacing: 4) { Image(systemName: "clock.fill").font(.caption2); Text(date) }.font(.caption2).foregroundColor(.secondary) }
            }
            Rectangle().fill(LinearGradient(gradient: Gradient(colors: [statusColor.opacity(0.3), statusColor.opacity(0.1)]), startPoint: .leading, endPoint: .trailing)).frame(height: 1)
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) { Text("Min Investment").font(.caption).foregroundColor(.secondary); Text(minInvestment).font(.subheadline).fontWeight(.bold) }
                Rectangle().fill(Color.gray.opacity(0.2)).frame(width: 1, height: 30)
                VStack(alignment: .leading, spacing: 4) { Text("Price Range").font(.caption).foregroundColor(.secondary); Text(priceRange).font(.subheadline).fontWeight(.bold) }
            }
            if let ls = leftShare { HStack { Image(systemName: "chart.bar.fill").foregroundColor(statusColor); Text("\(ls) remaining").font(.caption).fontWeight(.semibold).foregroundColor(statusColor) }.padding(.horizontal, 12).padding(.vertical, 6).background(statusColor.opacity(0.12)).cornerRadius(8) }
        }
        .padding(18).background(AppTheme.cardBackground).cornerRadius(18).shadow(color: statusColor.opacity(0.12), radius: 12, x: 0, y: 6)
    }
}

#Preview {
    EnhancedIPOCard(
        name: "AstraFi Tech IPO",
        category: "Fintech",
        status: "Open",
        statusColor: .green,
        date: "24-28 Mar",
        minInvestment: "₹14,850",
        priceRange: "₹450 - ₹475",
        leftShare: "45%"
    )
    .padding()
}
