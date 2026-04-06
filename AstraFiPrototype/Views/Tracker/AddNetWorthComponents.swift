import SwiftUI

struct StyledAssetRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    @Binding var value: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
            }
            Text(label)
                .font(.system(size: 15))
            Spacer()
            HStack(spacing: 4) {
                Text("₹")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                TextField("0", text: $value)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 90)
                    .font(.system(size: 15, weight: .medium))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct NWInfoBadge: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(width: 20)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}
