import Foundation
import UserNotifications
import Combine
import Supabase

@MainActor
class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    @Published var isAuthorized: Bool = false
    
    /// Identifier prefix for all PawMento notifications
    private static let identifierPrefix = "" // All reminder IDs are UUIDs — we track them
    
    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        Task { await refreshAuthorizationStatus() }
        registerCategories()
        
        // Fix R3/R7: Observe timezone changes → resync all notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTimezoneChange),
            name: .NSSystemTimeZoneDidChange,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc nonisolated private func handleTimezoneChange() {
        Task { @MainActor in
            // Re-sync all notifications with the updated timezone
            let enabledReminders = ReminderStore.shared.reminders.filter { $0.isEnabled }
            await syncNotifications(enabledReminders: enabledReminders)
        }
    }
    
    // MARK: - Authorization (Fix R6)
    
    /// Re-reads the actual notification settings from the OS.
    /// Treats both .authorized AND .provisional as usable.
    private func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let status = settings.authorizationStatus
        isAuthorized = (status == .authorized || status == .provisional)
    }
    
    func checkAuthorization() {
        Task { await refreshAuthorizationStatus() }
    }
    
    /// Requests notification authorization. Re-reads actual settings afterward
    /// (the `granted` bool can lag behind actual OS state).
    func requestAuthorization() async -> Bool {
        do {
            // Fix R6: Also request .provisional for quiet notifications
            let _ = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound, .provisional]
            )
            // Fix R6: Re-read actual settings instead of trusting the `granted` bool
            await refreshAuthorizationStatus()
            return isAuthorized
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }
    
    private func registerCategories() {
        // "Log It" action for the notification
        let logAction = UNNotificationAction(
            identifier: "LOG_ACTION",
            title: "Log It Now",
            options: .foreground
        )
        
        let category = UNNotificationCategory(
            identifier: "REMINDER_CATEGORY",
            actions: [logAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    // MARK: - Notification Scheduling (Fix R3, R4, R7)
    
    enum ScheduleContext {
        case userInitiated
        case sync
    }
    
    /// Priority ordering for the 64-notification limit (Fix R4).
    /// Medication and health reminders are scheduled first.
    private func notificationPriority(for reminder: Reminder) -> Int {
        switch LogCategory.fromStoredValue(reminder.categoryId) {
        case .med: return 0      // Highest — medication
        case .symptom: return 1  // Health monitoring
        case .vetVisit: return 2      // Vet appointments
        case .meal: return 3     // Feeding
        default: return 4        // Everything else
        }
    }
    
    func scheduleReminder(_ reminder: Reminder, context: ScheduleContext = .userInitiated) async {
        // Fix R6: Always re-check settings freshly (not stale isAuthorized)
        await refreshAuthorizationStatus()
        
        if !isAuthorized {
            let granted = await requestAuthorization()
            if !granted { return }
        }
        
        // Fix R7: Reject .once reminders in the past
        if reminder.isPastOnceFireTime {
            if context == .userInitiated {
                ToastManager.shared.show("This reminder's time has already passed. Choose a future time.", duration: 4.0)
            }
            return
        }
        
        // Fix R4: Check the 64-notification cap with priority policy
        let pendingRequests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        if pendingRequests.count >= 60 {
            let myPriority = notificationPriority(for: reminder)
            // Only drop if this reminder is lower priority than what's already scheduled
            if myPriority >= 3 {
                if context == .userInitiated {
                    ToastManager.shared.show("Notification limit reached. Lower-priority reminders won't schedule.", duration: 4.0)
                }
                return
            }
            // High-priority: log a warning but still try to schedule
            print("Warning: Near iOS 64 pending notification limit (\(pendingRequests.count)). Scheduling high-priority reminder.")
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Time for \(reminder.title)!"
        content.body = "Tap to log this event for your pet."
        content.sound = .default
        content.categoryIdentifier = "REMINDER_CATEGORY"
        
        // Pass context data so we know what to log when tapped (canonical category for LogCategory lookup)
        let canonicalCategoryId = LogCategory.canonicalStoredValue(from: reminder.categoryId) ?? reminder.categoryId
        content.userInfo = [
            "petId": reminder.petId.uuidString,
            "categoryId": canonicalCategoryId,
            "reminderId": reminder.id.uuidString,
            "reminderTitle": reminder.title
        ]
        
        let calendar = Calendar.current
        let trigger: UNNotificationTrigger
        
        switch reminder.frequency {
        case .once:
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.time)
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
        case .daily:
            let components = calendar.dateComponents([.hour, .minute], from: reminder.time)
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
        case .weekly:
            // Fix R7: Weekday derived from reminder.time — single source of truth confirmed
            let components = calendar.dateComponents([.weekday, .hour, .minute], from: reminder.time)
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        }
        
        let request = UNNotificationRequest(identifier: reminder.id.uuidString, content: content, trigger: trigger)
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Error scheduling reminder: \(error)")
        }
    }
    
    func removeReminder(_ reminder: Reminder) {
        let center = UNUserNotificationCenter.current()
        let identifier = [reminder.id.uuidString]
        center.removePendingNotificationRequests(withIdentifiers: identifier)
        center.removeDeliveredNotifications(withIdentifiers: identifier)
    }
    
    // MARK: - Notification Reconciliation (Fix R3)
    
    /// Removes ALL pending PawMento notifications, then reschedules from the given
    /// enabled-reminder list. Called after loadReminders(), fetchReminders(), and
    /// on timezone change.
    func syncNotifications(enabledReminders: [Reminder]) async {
        let center = UNUserNotificationCenter.current()
        
        // 1. Get current PawMento notification identifiers
        let pendingRequests = await center.pendingNotificationRequests()
        let pawmentoIds = pendingRequests
            .filter { $0.content.categoryIdentifier == "REMINDER_CATEGORY" }
            .map { $0.identifier }
        
        // 2. Remove all PawMento pending notifications
        center.removePendingNotificationRequests(withIdentifiers: pawmentoIds)
        
        // 3. Reschedule from the reconciled enabled-reminder list
        // Fix R4: Sort by priority — medication/health first
        let sorted = enabledReminders.sorted { notificationPriority(for: $0) < notificationPriority(for: $1) }
        
        for reminder in sorted {
            await scheduleReminder(reminder, context: .sync)
        }
    }
    
    /// Cancels all PawMento notifications (for logout/reset — Fix R8).
    func cancelAllPawMentoNotifications() async {
        let center = UNUserNotificationCenter.current()
        let pendingRequests = await center.pendingNotificationRequests()
        let pawmentoIds = pendingRequests
            .filter { $0.content.categoryIdentifier == "REMINDER_CATEGORY" }
            .map { $0.identifier }
        
        center.removePendingNotificationRequests(withIdentifiers: pawmentoIds)
        
        // Also clear delivered
        let deliveredNotifications = await center.deliveredNotifications()
        let deliveredIds = deliveredNotifications
            .filter { $0.request.content.categoryIdentifier == "REMINDER_CATEGORY" }
            .map { $0.request.identifier }
        center.removeDeliveredNotifications(withIdentifiers: deliveredIds)
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // When app is in foreground
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }
    
    // When user taps a notification or its actions (Fix R5)
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        
        if response.actionIdentifier == "LOG_ACTION" || response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            guard let petIdStr = userInfo["petId"] as? String,
                  let petId = UUID(uuidString: petIdStr),
                  let categoryId = userInfo["categoryId"] as? String,
                  let reminderIdStr = userInfo["reminderId"] as? String else {
                return
            }
            
            // Fix R5: If category mapping fails, do NOT silently log as .other
            guard let logCategory = LogCategory.fromStoredValue(categoryId) else {
                print("Error: Unknown category '\(categoryId)' from notification — skipping log creation")
                let errorContent = UNMutableNotificationContent()
                errorContent.title = "Reminder Category Error"
                errorContent.body = "Could not log '\(categoryId)' — please log manually in the app."
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: errorContent, trigger: nil)
                try? await center.add(request)
                return
            }
            
            // Fix R5: Use the notification's fire date as the log timestamp, not insert time.
            // This preserves temporal accuracy if the user taps hours later.
            let fireDate = response.notification.date
            
            // Idempotency key — reminderId + occurrence date (truncated to minute)
            let sourceKey = Self.reminderLogSourceKey(reminderId: reminderIdStr, fireDate: fireDate)
            let reminderTitle = userInfo["reminderTitle"] as? String ?? logCategory.rawValue
            let displayNote = "Logged from reminder: \(reminderTitle)"
            
            Task { @MainActor in
                guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else {
                    return
                }
                
                let existingLogs: [LogDTO] = (try? await SupabaseManager.shared.client
                    .from("logs")
                    .select()
                    .eq("source_key", value: sourceKey)
                    .execute()
                    .value) ?? []
                
                if !existingLogs.isEmpty {
                    print("Duplicate notification tap detected for \(sourceKey) — skipping")
                    return
                }
                
                let newLog = LogEntry(
                    id: UUID(),
                    petId: petId,
                    category: logCategory,
                    note: displayNote,
                    sourceKey: sourceKey,
                    createdAt: Date(),
                    recordedAt: fireDate
                )
                
                do {
                    try await LogStore.shared.saveLog(newLog, userId: userId)
                } catch {
                    print("Error saving log from notification: \(error)")
                    let errorContent = UNMutableNotificationContent()
                    errorContent.title = "Failed to Save Log"
                    errorContent.body = "We couldn't save your \(categoryId) log. Please log manually."
                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: errorContent, trigger: nil)
                    try? await center.add(request)
                }
            }
        }
    }
    
    /// Stable idempotency key for a single reminder occurrence (minute precision).
    nonisolated static func reminderLogSourceKey(reminderId: String, fireDate: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        return "reminder:\(reminderId)_\(components.year ?? 0)_\(components.month ?? 0)_\(components.day ?? 0)_\(components.hour ?? 0)_\(components.minute ?? 0)"
    }
}
