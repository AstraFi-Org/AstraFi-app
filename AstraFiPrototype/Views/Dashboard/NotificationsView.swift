import SwiftUI

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppStateManager.self) private var appState
    
    private var notificationManager: AstraNotificationManager {
        AstraNotificationManager.shared
    }

    private var groupedDelivered: [(String, [AstraNotificationRecord])] {
        let cal = Calendar.current
        var groups: [String: [AstraNotificationRecord]] = [:]

        for item in notificationManager.displayNotifications {
            let label: String
            if cal.isDateInToday(item.scheduledDate) {
                label = "Today"
            } else if cal.isDateInYesterday(item.scheduledDate) {
                label = "Yesterday"
            } else {
                label = "Earlier"
            }
            groups[label, default: []].append(item)
        }

        let order = ["Today", "Yesterday", "Earlier"]
        return order.compactMap { label in
            guard let items = groups[label], !items.isEmpty else { return nil }
            return (label, items.sorted { $0.scheduledDate > $1.scheduledDate })
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if notificationManager.deliveredNotifications.isEmpty {
                    emptyStateView
                } else {
                    // Past & Today delivered alerts
                    if !groupedDelivered.isEmpty {
                        ForEach(groupedDelivered, id: \.0) { groupName, items in
                            VStack(alignment: .leading, spacing: 14) {
                                Text(groupName)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 4)

                                VStack(spacing: 12) {
                                    ForEach(items) { item in
                                        NotificationRecordCard(item: item) {
                                            notificationManager.markAsRead(item.id)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Scheduled / Upcoming alerts
                    if !notificationManager.upcomingNotifications.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("Upcoming Scheduled Alerts")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Auto-pushed")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 4)

                            VStack(spacing: 12) {
                                ForEach(notificationManager.upcomingNotifications) { item in
                                    NotificationRecordCard(item: item, isUpcoming: true) {
                                        notificationManager.markAsRead(item.id)
                                    }
                                }
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !notificationManager.deliveredNotifications.isEmpty {
                    Menu {
                        Button {
                            notificationManager.markAllAsRead()
                        } label: {
                            Label("Mark All as Read", systemImage: "checkmark.circle")
                        }
                        
                        Button(role: .destructive) {
                            notificationManager.clearAll()
                        } label: {
                            Label("Clear All", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 16))
                    }
                }
            }
        }
        .onAppear {
            if let profile = appState.currentProfile {
                notificationManager.scheduleAllNotifications(
                    for: profile,
                    assessmentDue: appState.isMonthlyAssessmentDue()
                )
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)
            
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "bell.badge.slash")
                    .font(.system(size: 36))
                    .foregroundColor(.blue)
            }
            
            Text("No Notifications")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("You're all caught up! AstraFi will automatically push notifications for your upcoming SIPs, loan EMIs, insurance renewals, and monthly financial check-ins even when the app is closed.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                if let profile = appState.currentProfile {
                    notificationManager.scheduleAllNotifications(
                        for: profile,
                        assessmentDue: appState.isMonthlyAssessmentDue()
                    )
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh Reminders")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Notification Record Card

struct NotificationRecordCard: View {
    let item: AstraNotificationRecord
    var isUpcoming: Bool = false
    var onTap: () -> Void = {}
    
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(item.category.iconColor.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: item.category.iconName)
                        .foregroundColor(item.category.iconColor)
                        .font(.title3)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center) {
                        Text(item.category.displayName)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(item.category.iconColor.opacity(0.1))
                            .foregroundColor(item.category.iconColor)
                            .cornerRadius(6)

                        Spacer()

                        HStack(spacing: 6) {
                            if !item.isRead && !isUpcoming {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 8, height: 8)
                            }
                            Text(timeAgoOrUpcoming(item.scheduledDate))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    Text(item.title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    Text(item.body)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(16)
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
            .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private func timeAgoOrUpcoming(_ date: Date) -> String {
        let now = Date()
        if date > now {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM, h:mm a"
            return "Due " + formatter.string(from: date)
        } else {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return formatter.localizedString(for: date, relativeTo: now)
        }
    }
}

#Preview {
    NavigationStack {
        NotificationsView()
            .environment(AppStateManager.withSampleData())
    }
}
