import SwiftUI
import Charts

struct TrackerMoneyFlowSection: View {
    let moneyFlowData: [MoneyFlowData]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Money Flow")
                .font(.system(size: 22, weight: .bold))

            NavigationLink(destination: SpendingInsightsView()) {
                VStack(spacing: 0) {
                    if moneyFlowData.isEmpty {
                        TrackerEmptyState(icon: "chart.bar.fill", message: "No money flow data available yet.")
                    } else {
                        MoneyFlowChart(data: moneyFlowData)
                            .frame(height: 250)
                            .padding(.top, 16)
                            .padding(.horizontal, 16)

                        HStack(spacing: 16) {
                            TrackerLegendItem(color: .red, label: "Expenses")
                            TrackerLegendItem(color: .blue, label: "Savings")
                            TrackerLegendItem(color: .green, label: "Emergency")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                }
                .background(AppTheme.cardBackground)
                .cornerRadius(16)
                .shadow(color: AppTheme.adaptiveShadow, radius: 6, x: 0, y: 3)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct MoneyFlowChart: View {
    let data: [MoneyFlowData]
    @State private var animated: Bool = false

    struct ChartData: Identifiable {
        let id = UUID()
        let month: String
        let category: String
        let value: Double
    }

    var chartData: [ChartData] {
        var result: [ChartData] = []
        for item in data {
            result.append(ChartData(month: item.month, category: "Expenses", value: item.expenses))
            result.append(ChartData(month: item.month, category: "Savings", value: item.savings))
            result.append(ChartData(month: item.month, category: "Emergency", value: item.emergencyFund))
        }
        return result
    }

    var body: some View {
        Chart(chartData) { item in
            BarMark(
                x: .value("Month", item.month),
                y: .value("Amount", animated ? item.value : 0)
            )
            .foregroundStyle(by: .value("Category", item.category))
            .cornerRadius(4)
        }
        .chartForegroundStyleScale([
            "Expenses": Color.red.gradient,
            "Savings": Color.blue.gradient,
            "Emergency": Color.green.gradient
        ])
        .chartLegend(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .foregroundStyle(Color.gray.opacity(0.3))
                if let amount = value.as(Double.self) {
                    AxisValueLabel {
                        Text(amount.toCurrency())
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                if let month = value.as(String.self) {
                    AxisValueLabel {
                        Text(month)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                animated = true
            }
        }
    }
}

struct TrackerLegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    TrackerMoneyFlowSection(moneyFlowData: [
        MoneyFlowData(month: "Jan", savings: 15000, emergencyFund: 5000, expenses: 30000),
        MoneyFlowData(month: "Feb", savings: 18000, emergencyFund: 5000, expenses: 28000),
        MoneyFlowData(month: "Mar", savings: 12000, emergencyFund: 5000, expenses: 35000)
    ])
    .padding()
}
