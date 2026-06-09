import SwiftUI

struct EnhancedPaymentRow: View {
    let title: String; let subtitle: String; let amount: String; let iconColor: Color; let isDueSoon: Bool
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 54, height: 54)
                Image(systemName: "creditcard.fill")
                    .foregroundColor(iconColor)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.auraHeader(size: 16)).foregroundColor(AppTheme.auraIndigo)
                Text(subtitle).font(.auraCaption()).foregroundColor(isDueSoon ? .orange : .secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("₹\(amount)").font(.auraDigital(size: 20)).foregroundColor(AppTheme.auraIndigo)
                if isDueSoon {
                    Text("Due Soon").font(.system(size: 10, weight: .bold)).foregroundColor(.orange).padding(.horizontal, 8).padding(.vertical, 4).background(Color.orange.opacity(0.1)).cornerRadius(8)
                }
            }
        }
        .auraCardStyle(radius: 20)
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
            title: "SIP Axis Bluechip",
            subtitle: "Due in 12 days",
            amount: "10,000",
            iconColor: .green,
            isDueSoon: false
        )
    }
    .padding()
}
