import Foundation
import UserNotifications
import Combine
import Supabase

@MainActor
class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    @Published var isAuthorized: Bool = false
    
    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorization()
        registerCategories()
    }
    
    func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = (settings.authorizationStatus == .authorized)
            }
        }
    }
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            self.isAuthorized = granted
            return granted
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
            options: .foreground // Opens the app briefly or runs in background if supported, we'll use foreground for now to be safe and update UI
        )
        
        let category = UNNotificationCategory(
            identifier: "REMINDER_CATEGORY",
            actions: [logAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    func scheduleReminder(_ reminder: Reminder) async {
        if !isAuthorized {
            let granted = await requestAuthorization()
            if !granted { return }
        }
        
        let pendingRequests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        if pendingRequests.count >= 60 {
            print("Warning: Exceeding iOS 64 pending notification limit.")
            await MainActor.run {
                ToastManager.shared.show("Notification limit reached. Some reminders won't schedule.", duration: 4.0)
            }
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Time for \(reminder.title)!"
        content.body = "Tap to log this event for your pet."
        content.sound = .default
        content.categoryIdentifier = "REMINDER_CATEGORY"
        
        // Pass context data so we know what to log when tapped
        content.userInfo = [
            "petId": reminder.petId.uuidString,
            "categoryId": reminder.categoryId,
            "reminderId": reminder.id.uuidString
        ]
        
        let calendar = Calendar.current
        var trigger: UNNotificationTrigger
        
        // STRATEGY: Timezone Handling
        // .daily and .weekly use UNCalendarNotificationTrigger with hour/minute components.
        // Without an explicit `.timeZone` on DateComponents, it defaults to the device's current timezone.
        // A 9:00 AM reminder will always fire at 9:00 AM local time, even if the user travels.
        // Optional hook: observe `.NSSystemTimeZoneDidChange` in the app shell to force a reschedule
        // of all reminders if we ever need to recalculate them relative to a fixed timezone.
        
        switch reminder.frequency {
        case .once:
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.time)
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
        case .daily:
            let components = calendar.dateComponents([.hour, .minute], from: reminder.time)
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
        case .weekly:
            let components = calendar.dateComponents([.weekday, .hour, .minute], from: reminder.time)
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        }
        
        let request = UNNotificationRequest(identifier: reminder.id.uuidString, content: content, trigger: trigger)
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Scheduled reminder: \(reminder.title) at \(reminder.time)")
        } catch {
            print("Error scheduling reminder: \(error)")
        }
    }
    
    func removeReminder(_ reminder: Reminder) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminder.id.uuidString])
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // When app is in foreground
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }
    
    // When user taps a notification or its actions
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        
        if response.actionIdentifier == "LOG_ACTION" || response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            // They tapped "Log It" or just tapped the notification itself
            guard let petIdStr = userInfo["petId"] as? String,
                  let petId = UUID(uuidString: petIdStr),
                  let categoryId = userInfo["categoryId"] as? String else {
                return
            }
            
            // Reconstruct the category (in a real app, we might need value etc.)
            let logCategory = LogCategory(rawValue: categoryId) ?? .other
            
            Task { @MainActor in
                guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else {
                    return
                }
                
                let newLog = LogEntry(
                    id: UUID(),
                    petId: petId,
                    category: logCategory,
                    note: "Logged from Reminder"
                )
                
                do {
                    let dto = newLog.toDTO(userId: userId)
                    try await SupabaseManager.shared.client
                        .from("logs")
                        .insert(dto)
                        .execute()
                    print("Successfully logged \(categoryId) from background notification!")
                } catch {
                    print("Error saving log from notification: \(error)")
                    let errorContent = UNMutableNotificationContent()
                    errorContent.title = "Failed to Save Log"
                    errorContent.body = "We couldn't save your \(categoryId) log. Please make sure you are online."
                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: errorContent, trigger: nil)
                    try? await UNUserNotificationCenter.current().add(request)
                }
            }
        }
    }
}
