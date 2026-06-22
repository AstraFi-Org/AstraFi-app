import SwiftUI

struct NotificationItem: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let message: String
    let date: Date
    let isUnread: Bool
    let category: String
}

struct NotificationsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    private var notifications: [NotificationItem] {
        let now = Date()
        let cal = Calendar.current
        return [
            NotificationItem(
                icon: "exclamationmark.triangle.fill",
                iconColor: .red,
                title: "Home Goal Delay Risk",
                message: "Market dip has reduced your projected home corpus. Consider a 10% SIP increment.",
                date: cal.date(byAdding: .hour, value: -2, to: now) ?? now,
                isUnread: true,
                category: "Critical Alerts"
            ),
            NotificationItem(
                icon: "calendar.badge.clock",
                iconColor: .orange,
                title: "HDFC Index Fund SIP",
                message: "Your monthly SIP of ₹5,000 will be auto-debited tomorrow.",
                date: cal.date(byAdding: .hour, value: -5, to: now) ?? now,
                isUnread: true,
                category: "Upcoming Payments"
            ),
            NotificationItem(
                icon: "checkmark.circle.fill",
                iconColor: .green,
                title: "ICICI Bluechip SIP Success",
                message: "₹2,500 successfully invested. Units will reflect in 2 days.",
                date: cal.date(byAdding: .day, value: -1, to: now) ?? now,
                isUnread: false,
                category: "Upcoming Payments"
            ),
            NotificationItem(
                icon: "chart.line.uptrend.xyaxis",
                iconColor: .blue,
                title: "Portfolio Rebalancing",
                message: "Your equity exposure is now 72%. Rebalancing to 65% is recommended.",
                date: cal.date(byAdding: .day, value: -1, to: now) ?? now,
                isUnread: false,
                category: "Market Insights"
            ),
            NotificationItem(
                icon: "lightbulb.fill",
                iconColor: .yellow,
                title: "New IPO Alert",
                message: "Avana Electrosystems IPO opens next week. Check the analysis.",
                date: cal.date(byAdding: .day, value: -2, to: now) ?? now,
                isUnread: false,
                category: "Market Insights"
            )
        ]
    }

    private var groupedNotifications: [(String, [NotificationItem])] {
        let cal = Calendar.current
        var groups: [String: [NotificationItem]] = [:]

        for item in notifications {
            let label: String
            if cal.isDateInToday(item.date) {
                label = "Today"
            } else if cal.isDateInYesterday(item.date) {
                label = "Yesterday"
            } else {
                label = "Earlier"
            }
            groups[label, default: []].append(item)
        }

        let order = ["Today", "Yesterday", "Earlier"]
        return order.compactMap { label in
            guard let items = groups[label], !items.isEmpty else { return nil }
            return (label, items.sorted { $0.date > $1.date })
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(groupedNotifications, id: \.0) { groupName, items in
                    VStack(alignment: .leading, spacing: 14) {
                        Text(groupName)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)

                        VStack(spacing: 12) {
                            ForEach(items) { item in
                                NotificationCard(item: item)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.appBackground(for: colorScheme))
    }
}

struct NotificationCard: View {
    let item: NotificationItem
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(item.iconColor.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: item.icon)
                    .foregroundColor(item.iconColor)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center) {
                    Text(item.category)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(item.iconColor.opacity(0.1))
                        .foregroundColor(item.iconColor)
                        .cornerRadius(6)
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        if item.isUnread {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                        }
                        Text(timeAgo(item.date))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(item.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 4)
    }

    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NavigationStack {
        NotificationsView()
    }
}
