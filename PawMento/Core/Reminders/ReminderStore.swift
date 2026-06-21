import Foundation
import SwiftUI
import Combine
import Supabase

@MainActor
class ReminderStore: ObservableObject {
    static let shared = ReminderStore()
    
    @Published var reminders: [Reminder] = []
    
    private let remindersKey = "pawmento_saved_reminders"
    
    private init() {
        loadReminders()
    }
    
    // MARK: - Local Cache (UserDefaults)
    
    func loadReminders() {
        guard let data = UserDefaults.standard.data(forKey: remindersKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([Reminder].self, from: data)
            self.reminders = decoded
        } catch {
            print("Failed to decode reminders: \(error)")
        }
        
        // Fix R3: Reconcile OS notifications with loaded reminders
        Task {
            await NotificationManager.shared.syncNotifications(
                enabledReminders: reminders.filter { $0.isEnabled }
            )
        }
    }
    
    // Fix R2: Server is the source of truth (online-only app).
    // Fetch replaces local cache entirely — no offline pending state needed.
    func fetchReminders() async {
        do {
            let dtos: [ReminderDTO] = try await SupabaseManager.shared.client
                .from("reminders")
                .select()
                .execute()
                .value
            
            self.reminders = dtos.map { $0.toReminder() }
            saveToCache()
            
            // Fix R3: Reconcile OS notifications after fetch
            await NotificationManager.shared.syncNotifications(
                enabledReminders: reminders.filter { $0.isEnabled }
            )
        } catch {
            print("Failed to fetch reminders from server: \(error)")
        }
    }
    
    private func saveToCache() {
        do {
            let encoded = try JSONEncoder().encode(reminders)
            UserDefaults.standard.set(encoded, forKey: remindersKey)
        } catch {
            print("Failed to encode reminders: \(error)")
        }
    }
    
    // MARK: - Server-First Writes (Fix R1)
    // All writes go to the server FIRST. Only on success do we mutate local state
    // and schedule/cancel OS notifications. No ghost reminders, no zombies.
    
    func addReminder(_ reminder: Reminder) async throws {
        // 1. Server first
        try await SupabaseManager.shared.client
            .from("reminders")
            .insert(reminder.toDTO())
            .execute()
        
        // 2. Local state (only on server success)
        reminders.append(reminder)
        saveToCache()
        
        // 3. Schedule OS notification
        if reminder.isEnabled {
            await NotificationManager.shared.scheduleReminder(reminder)
        }
    }
    
    func deleteReminder(_ reminder: Reminder) async throws {
        // 1. Server first
        try await SupabaseManager.shared.client
            .from("reminders")
            .delete()
            .eq("id", value: reminder.id.uuidString)
            .execute()
        
        // 2. Local state (only on server success — no zombie resurrection)
        reminders.removeAll { $0.id == reminder.id }
        saveToCache()
        
        // 3. Cancel OS notification
        NotificationManager.shared.removeReminder(reminder)
    }
    
    func updateReminder(_ reminder: Reminder) async throws {
        // 1. Server first
        try await SupabaseManager.shared.client
            .from("reminders")
            .update(reminder.toDTO())
            .eq("id", value: reminder.id.uuidString)
            .execute()
        
        // 2. Local state (only on server success)
        if let idx = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[idx] = reminder
            saveToCache()
        }
        
        // 3. Update OS notification
        if reminder.isEnabled {
            await NotificationManager.shared.scheduleReminder(reminder)
        } else {
            NotificationManager.shared.removeReminder(reminder)
        }
    }
    
    func toggleReminder(_ reminder: Reminder) async throws {
        var updated = reminder
        updated.isEnabled.toggle()
        try await updateReminder(updated)
    }
    
    func reminders(for petId: UUID) -> [Reminder] {
        return reminders.filter { $0.petId == petId }.sorted { $0.nextOccurrence < $1.nextOccurrence }
    }
    
    // Fix R8: Reset clears everything — UserDefaults key AND OS notifications.
    // Prevents cross-account leakage after logout.
    func reset() {
        reminders = []
        UserDefaults.standard.removeObject(forKey: remindersKey)
        Task {
            await NotificationManager.shared.cancelAllPawMentoNotifications()
        }
    }
}
