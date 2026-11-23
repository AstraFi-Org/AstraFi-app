import Foundation
import UserNotifications
import SwiftUI

// MARK: - Notification Categories

enum AstraNotificationCategory: String, Codable, CaseIterable {
    case sipReminder = "SIP_REMINDER"
    case emiDue = "EMI_DUE"
    case insuranceRenewal = "INSURANCE_RENEWAL"
    case goalMilestone = "GOAL_MILESTONE"
    case monthlyAssessment = "MONTHLY_ASSESSMENT"
    case financialHealth = "FINANCIAL_HEALTH"

    var displayName: String {
        switch self {
        case .sipReminder: return "SIP Reminder"
        case .emiDue: return "EMI Due"
        case .insuranceRenewal: return "Insurance Renewal"
        case .goalMilestone: return "Goal Progress"
        case .monthlyAssessment: return "Monthly Check-in"
        case .financialHealth: return "Financial Health"
        }
    }

    var iconName: String {
        switch self {
        case .sipReminder: return "calendar.badge.clock"
        case .emiDue: return "indianrupeesign.circle.fill"
        case .insuranceRenewal: return "shield.lefthalf.filled"
        case .goalMilestone: return "flag.fill"
        case .monthlyAssessment: return "chart.bar.doc.horizontal.fill"
        case .financialHealth: return "heart.text.clipboard.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .sipReminder: return .orange
        case .emiDue: return .red
        case .insuranceRenewal: return .purple
        case .goalMilestone: return .green
        case .monthlyAssessment: return .blue
        case .financialHealth: return .teal
        }
    }
}

// MARK: - Persisted Notification Record

struct AstraNotificationRecord: Codable, Identifiable {
    let id: UUID
    let category: AstraNotificationCategory
    let title: String
    let body: String
    let scheduledDate: Date
    var isRead: Bool

    init(category: AstraNotificationCategory, title: String, body: String, scheduledDate: Date) {
        self.id = UUID()
        self.category = category
        self.title = title
        self.body = body
        self.scheduledDate = scheduledDate
        self.isRead = false
    }
}

// MARK: - Notification Manager

@Observable @MainActor
final class AstraNotificationManager: NSObject {
    static let shared = AstraNotificationManager()

    private(set) var deliveredNotifications: [AstraNotificationRecord] = []
    var unreadCount: Int { deliveredNotifications.filter { !$0.isRead }.count }

    private let storageKey = "astra_notification_records"
    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        loadRecords()
        pruneOldRecords()
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            if granted {
                await registerCategories()
            }
            return granted
        } catch {
            print("AstraNotificationManager: permission error — \(error)")
            return false
        }
    }

    func isAuthorized() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    // MARK: - Register Action Categories

    private func registerCategories() async {
        let viewAction = UNNotificationAction(identifier: "VIEW_ACTION", title: "View Details", options: .foreground)
        let categories = AstraNotificationCategory.allCases.map { cat in
            UNNotificationCategory(identifier: cat.rawValue, actions: [viewAction], intentIdentifiers: [])
        }
        center.setNotificationCategories(Set(categories))
    }

    // MARK: - Schedule Notifications from Profile

    func scheduleAllNotifications(for profile: AstraUserProfile, assessmentDue: Bool) {
        // Cancel all previously scheduled AstraFi notifications
        center.removeAllPendingNotificationRequests()
        // Clear delivered records that haven't been seen yet — keep read ones for history
        // We re-schedule fresh each time

        scheduleSIPReminders(investments: profile.investments)
        scheduleEMIReminders(loans: profile.loans)
        scheduleInsuranceRenewals(insurances: profile.insurances)
        scheduleGoalMilestones(goals: profile.goals, investments: profile.investments)

        if assessmentDue {
            scheduleMonthlyAssessmentReminder()
        }
    }

    // MARK: - SIP Reminders

    private func scheduleSIPReminders(investments: [AstraInvestment]) {
        let sipInvestments = investments.filter { $0.mode == .sip && $0.status != .completed && $0.status != .withdrawn }

        for investment in sipInvestments {
            // Schedule a reminder on the same day-of-month as the start date, one day before
            let sipDay = Calendar.current.component(.day, from: investment.startDate)
            let reminderDay = max(1, sipDay - 1)

            let title = "\(investment.investmentName) SIP"
            let formattedAmount = formatCurrency(investment.investmentAmount)
            let body = "Your monthly SIP of \(formattedAmount) will be debited tomorrow."

            scheduleMonthlyNotification(
                id: "sip_\(investment.id.uuidString)",
                category: .sipReminder,
                title: title,
                body: body,
                dayOfMonth: reminderDay,
                hour: 9,
                minute: 0
            )
        }
    }

    // MARK: - EMI Reminders

    private func scheduleEMIReminders(loans: [AstraLoan]) {
        for loan in loans {
            let totalEMIs = loan.loanTenureMonths
            guard loan.installmentsPaid < totalEMIs else { continue }

            // Use firstEMIDate day, or loanStartDate day
            let emiDate = loan.firstEMIDate ?? loan.loanStartDate
            let emiDay = Calendar.current.component(.day, from: emiDate)
            let reminderDay = max(1, emiDay - 2) // 2 days before

            let title = "\(loan.displayName) EMI Due"
            let emiStr = loan.emiAmount.map { formatCurrency($0) } ?? "EMI"
            let body = "\(emiStr) payment due in 2 days. Ensure sufficient balance with \(loan.displayLender)."

            scheduleMonthlyNotification(
                id: "emi_\(loan.id.uuidString)",
                category: .emiDue,
                title: title,
                body: body,
                dayOfMonth: reminderDay,
                hour: 10,
                minute: 0
            )
        }
    }

    // MARK: - Insurance Renewal Reminders

    private func scheduleInsuranceRenewals(insurances: [AstraInsurance]) {
        let calendar = Calendar.current

        for policy in insurances {
            guard let expiry = policy.expiryDate, expiry > Date() else { continue }

            // 30 days before expiry
            if let thirtyDaysBefore = calendar.date(byAdding: .day, value: -30, to: expiry),
               thirtyDaysBefore > Date() {
                let title = "\(policy.provider) \(policy.insuranceType.rawValue) Renewal"
                let body = "Your policy expires in 30 days. Renew early to avoid a coverage lapse."

                scheduleOneTimeNotification(
                    id: "insurance_30d_\(policy.id.uuidString)",
                    category: .insuranceRenewal,
                    title: title,
                    body: body,
                    date: thirtyDaysBefore,
                    hour: 10,
                    minute: 0
                )
            }

            // 7 days before expiry
            if let sevenDaysBefore = calendar.date(byAdding: .day, value: -7, to: expiry),
               sevenDaysBefore > Date() {
                let title = "\(policy.provider) Policy Expiring Soon"
                let body = "Only 7 days left before your \(policy.insuranceType.rawValue.lowercased()) policy expires. Renew now."

                scheduleOneTimeNotification(
                    id: "insurance_7d_\(policy.id.uuidString)",
                    category: .insuranceRenewal,
                    title: title,
                    body: body,
                    date: sevenDaysBefore,
                    hour: 9,
                    minute: 0
                )
            }
        }
    }

    // MARK: - Goal Milestone Notifications

    private func scheduleGoalMilestones(goals: [AstraGoal], investments: [AstraInvestment]) {
        for goal in goals where goal.status == .active {
            let linkedAmount = investments
                .filter { $0.associatedGoalID == goal.id }
                .reduce(0) { $0 + $1.investmentAmount }
            let totalSaved = linkedAmount + goal.manualSavingsContribution
            let progress = goal.targetAmount > 0 ? totalSaved / goal.targetAmount : 0

            // Notify if goal is at risk — less than 50% saved and within 6 months of target
            let calendar = Calendar.current
            if let sixMonthsBefore = calendar.date(byAdding: .month, value: -6, to: goal.targetDate),
               Date() > sixMonthsBefore,
               progress < 0.5 {
                let title = "\(goal.goalName) — On Track?"
                let pct = Int(progress * 100)
                let body = "Only \(pct)% saved towards your goal with less than 6 months left. Consider increasing contributions."

                scheduleOneTimeNotification(
                    id: "goal_risk_\(goal.id.uuidString)",
                    category: .goalMilestone,
                    title: title,
                    body: body,
                    date: Date(),
                    hour: 18,
                    minute: 0
                )
            }
        }
    }

    // MARK: - Monthly Assessment Reminder

    private func scheduleMonthlyAssessmentReminder() {
        // Schedule for the 1st of next month at 9 AM
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: Date())
        components.month = (components.month ?? 1) + 1
        components.day = 1
        components.hour = 9
        components.minute = 0

        let title = "Monthly Financial Check-in"
        let body = "Start of a new month! Review your financial health and update your progress."

        let content = makeContent(category: .monthlyAssessment, title: title, body: body)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "monthly_assessment", content: content, trigger: trigger)

        center.add(request) { error in
            if let error { print("AstraNotificationManager: schedule error — \(error)") }
        }

        // Also persist the record so it shows in the notifications view when delivered
        let record = AstraNotificationRecord(
            category: .monthlyAssessment,
            title: title,
            body: body,
            scheduledDate: calendar.date(from: components) ?? Date()
        )
        addPendingRecord(record)
    }

    // MARK: - Scheduling Helpers

    private func scheduleMonthlyNotification(
        id: String,
        category: AstraNotificationCategory,
        title: String,
        body: String,
        dayOfMonth: Int,
        hour: Int,
        minute: Int
    ) {
        let content = makeContent(category: category, title: title, body: body)

        var dateComponents = DateComponents()
        dateComponents.day = dayOfMonth
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        center.add(request) { error in
            if let error { print("AstraNotificationManager: schedule error — \(error)") }
        }

        // Persist a record for the next occurrence
        let calendar = Calendar.current
        var nextComponents = calendar.dateComponents([.year, .month], from: Date())
        nextComponents.day = dayOfMonth
        nextComponents.hour = hour
        nextComponents.minute = minute
        let nextDate = calendar.date(from: nextComponents) ?? Date()
        // If that date has passed this month, roll to next month
        let scheduledDate: Date
        if nextDate <= Date() {
            scheduledDate = calendar.date(byAdding: .month, value: 1, to: nextDate) ?? nextDate
        } else {
            scheduledDate = nextDate
        }

        let record = AstraNotificationRecord(
            category: category,
            title: title,
            body: body,
            scheduledDate: scheduledDate
        )
        addPendingRecord(record)
    }

    private func scheduleOneTimeNotification(
        id: String,
        category: AstraNotificationCategory,
        title: String,
        body: String,
        date: Date,
        hour: Int,
        minute: Int
    ) {
        let content = makeContent(category: category, title: title, body: body)

        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute

        let fireDate = calendar.date(from: components) ?? date
        guard fireDate > Date() else { return }

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        center.add(request) { error in
            if let error { print("AstraNotificationManager: schedule error — \(error)") }
        }

        let record = AstraNotificationRecord(
            category: category,
            title: title,
            body: body,
            scheduledDate: fireDate
        )
        addPendingRecord(record)
    }

    private func makeContent(category: AstraNotificationCategory, title: String, body: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = category.rawValue
        content.threadIdentifier = category.rawValue
        return content
    }

    // MARK: - Delivery Recording

    /// Records a delivered notification into the persistent store.
    func recordNotificationDelivered(category: AstraNotificationCategory, title: String, body: String, date: Date) {
        let record = AstraNotificationRecord(
            category: category,
            title: title,
            body: body,
            scheduledDate: date
        )
        if !deliveredNotifications.contains(where: {
            $0.title == record.title && $0.category == record.category &&
            Calendar.current.isDate($0.scheduledDate, equalTo: record.scheduledDate, toGranularity: .minute)
        }) {
            deliveredNotifications.append(record)
            saveRecords()
        }
    }

    /// Called when a notification response is received (user tapped it).
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let content = response.notification.request.content
        let categoryStr = content.categoryIdentifier

        if let category = AstraNotificationCategory(rawValue: categoryStr) {
            recordNotificationDelivered(
                category: category,
                title: content.title,
                body: content.body,
                date: response.notification.date
            )
        }
    }

    // MARK: - Read / Clear

    func markAsRead(_ id: UUID) {
        if let idx = deliveredNotifications.firstIndex(where: { $0.id == id }) {
            deliveredNotifications[idx].isRead = true
            saveRecords()
        }
    }

    func markAllAsRead() {
        for idx in deliveredNotifications.indices {
            deliveredNotifications[idx].isRead = true
        }
        saveRecords()
        center.setBadgeCount(0, withCompletionHandler: nil)
    }

    func clearAll() {
        deliveredNotifications.removeAll()
        saveRecords()
        center.setBadgeCount(0, withCompletionHandler: nil)
    }

    // MARK: - Persistence

    private func addPendingRecord(_ record: AstraNotificationRecord) {
        // Don't add duplicates by title + category
        if !deliveredNotifications.contains(where: {
            $0.title == record.title && $0.category == record.category &&
            Calendar.current.isDate($0.scheduledDate, equalTo: record.scheduledDate, toGranularity: .day)
        }) {
            deliveredNotifications.append(record)
            saveRecords()
        }
    }

    private func addDeliveredRecord(_ record: AstraNotificationRecord) {
        if !deliveredNotifications.contains(where: { $0.id == record.id }) {
            deliveredNotifications.append(record)
            saveRecords()
        }
    }

    private func markRecordDelivered(notificationID: String) {
        // We already have the record — nothing extra to do in this model
    }

    private func loadRecords() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let records = try? JSONDecoder().decode([AstraNotificationRecord].self, from: data) else {
            return
        }
        deliveredNotifications = records
    }

    private func saveRecords() {
        guard let data = try? JSONEncoder().encode(deliveredNotifications) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func pruneOldRecords() {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        deliveredNotifications.removeAll { $0.scheduledDate < cutoff }
        saveRecords()
    }

    // MARK: - Format Helper

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "₹\(Int(amount))"
    }

    // MARK: - Filtered & Sorted for Display

    /// Returns delivered notifications that are at or before now, sorted newest first.
    var displayNotifications: [AstraNotificationRecord] {
        deliveredNotifications
            .filter { $0.scheduledDate <= Date() }
            .sorted { $0.scheduledDate > $1.scheduledDate }
    }

    /// Returns upcoming scheduled notifications (future), sorted by soonest.
    var upcomingNotifications: [AstraNotificationRecord] {
        deliveredNotifications
            .filter { $0.scheduledDate > Date() }
            .sorted { $0.scheduledDate < $1.scheduledDate }
    }
}

// MARK: - Notification Delegate

final class AstraNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    // Show notification banner even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        Task { @MainActor in
            let content = notification.request.content
            if let category = AstraNotificationCategory(rawValue: content.categoryIdentifier) {
                AstraNotificationManager.shared.recordNotificationDelivered(
                    category: category,
                    title: content.title,
                    body: content.body,
                    date: notification.date
                )
            }
        }
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            AstraNotificationManager.shared.handleNotificationResponse(response)
        }
        completionHandler()
    }
}
