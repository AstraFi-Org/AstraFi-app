import SwiftUI

struct EnhancedPaymentRow: View {
    let title: String
    let subtitle: String
    let amount: String
    let iconColor: Color
    let isDueSoon: Bool
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Premium Icon Container
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: "creditcard.fill")
                    .foregroundColor(iconColor)
                    .font(.system(size: 20, weight: .semibold))
            }
            
            // Core Text Details
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isDueSoon ? .orange : .secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Amount and Indicator
            HStack(spacing: 12) {
                VStack(alignment: .trailing, spacing: 6) {
                    Text("₹\(amount)")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(.primary)
                    
                    if isDueSoon {
                        Text("DUE SOON")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .clipShape(Capsule())
                    }
                }
                
                // Navigable Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.secondary.opacity(0.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.6), radius: 10, x: 0, y: 4)
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
    .background(Color(UIColor.systemGroupedBackground))
}
