import SwiftUI

struct EnhancedPaymentRow: View {
    let title: String; let subtitle: String; let amount: String; let iconColor: Color; let isDueSoon: Bool
    var body: some View {
        HStack(spacing: 14) {
            ZStack { RoundedRectangle(cornerRadius: 12).fill(iconColor.opacity(0.15)).frame(width: 50, height: 50); Image(systemName: "arrow.up.right").font(.title3).foregroundColor(iconColor) }
            VStack(alignment: .leading, spacing: 4) { Text(title).font(.subheadline).fontWeight(.semibold).foregroundColor(.primary); Text(subtitle).font(.caption).foregroundColor(isDueSoon ? .orange : .secondary) }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("₹\(amount)").font(.headline).fontWeight(.bold).foregroundColor(.primary)
                if isDueSoon { Text("Due Soon").font(.caption2).foregroundColor(.orange).padding(.horizontal, 8).padding(.vertical, 2).background(Color.orange.opacity(0.15)).cornerRadius(6) }
            }
        }
        .padding(16).background(AppTheme.cardBackground).cornerRadius(16).shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    VStack(spacing: 12) {
        EnhancedPaymentRow(
            title: "Home Loan EMI",
            subtitle: "Due in 3 days",
            amount: "45,000",
            iconColor: .blue,
            isDueSoon: true
        )
        EnhancedPaymentRow(
            title: "SIP - Axis Bluechip",
            subtitle: "Due in 12 days",
            amount: "10,000",
            iconColor: .green,
            isDueSoon: false
        )
    }
    .padding()
}
