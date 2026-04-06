import SwiftUI

struct HeaderView: View {
    @Environment(\.colorScheme) var colorScheme
    let monthlyIncome: Int
    let monthlyExpense: Int
    let savingRate: Int
    let insightText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Financial Vitals")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    VitalMetricItem(
                        title: "Monthly Income",
                        value: "₹\(monthlyIncome)",
                        color: .cyan
                    )

                    VitalMetricItem(
                        title: "Monthly Expense",
                        value: "₹\(monthlyExpense)",
                        color: .orange
                    )

                    VitalMetricItem(
                        title: "Saving Rate",
                        value: "\(savingRate)%",
                        color: .mint
                    )
                }

                HStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.green)
                        .font(.subheadline)
                    Text(insightText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(colorScheme == .dark ? 0.15 : 0.08))
                .cornerRadius(12)
            }
            .padding(20)
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.06), radius: 12, x: 0, y: 4)
        }
    }
}

struct VitalMetricItem: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HeaderView(
        monthlyIncome: 75000,
        monthlyExpense: 40000,
        savingRate: 47,
        insightText: "Your Saving rate improved by 3% compared to last month"
    )
    .padding()
}
