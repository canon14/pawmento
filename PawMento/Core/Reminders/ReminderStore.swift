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
    
    func loadReminders() {
        guard let data = UserDefaults.standard.data(forKey: remindersKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([Reminder].self, from: data)
            self.reminders = decoded
        } catch {
            print("Failed to decode reminders: \(error)")
        }
    }
    
    func fetchReminders() async {
        do {
            let dtos: [ReminderDTO] = try await SupabaseManager.shared.client
                .from("reminders")
                .select()
                .execute()
                .value
            
            self.reminders = dtos.map { $0.toReminder() }
            saveReminders() // Update local cache
        } catch {
            print("Failed to fetch reminders from server: \(error)")
        }
    }
    
    func saveReminders() {
        do {
            let encoded = try JSONEncoder().encode(reminders)
            UserDefaults.standard.set(encoded, forKey: remindersKey)
        } catch {
            print("Failed to encode reminders: \(error)")
        }
    }
    
    func addReminder(_ reminder: Reminder) {
        reminders.append(reminder)
        saveReminders()
        Task {
            do {
                try await SupabaseManager.shared.client
                    .from("reminders")
                    .insert(reminder.toDTO())
                    .execute()
            } catch {
                print("Failed to sync new reminder to server: \(error)")
            }
            await NotificationManager.shared.scheduleReminder(reminder)
        }
    }
    
    func deleteReminder(_ reminder: Reminder) {
        reminders.removeAll { $0.id == reminder.id }
        saveReminders()
        NotificationManager.shared.removeReminder(reminder)
        
        Task {
            do {
                try await SupabaseManager.shared.client
                    .from("reminders")
                    .delete()
                    .eq("id", value: reminder.id.uuidString)
                    .execute()
            } catch {
                print("Failed to delete reminder from server: \(error)")
            }
        }
    }
    
    func updateReminder(_ reminder: Reminder) {
        if let idx = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[idx] = reminder
            saveReminders()
            Task {
                do {
                    try await SupabaseManager.shared.client
                        .from("reminders")
                        .update(reminder.toDTO())
                        .eq("id", value: reminder.id.uuidString)
                        .execute()
                } catch {
                    print("Failed to update reminder on server: \(error)")
                }
                await NotificationManager.shared.scheduleReminder(reminder)
            }
        }
    }
    
    func toggleReminder(_ reminder: Reminder) {
        var updated = reminder
        updated.isEnabled.toggle()
        updateReminder(updated)
        
        if updated.isEnabled {
            Task {
                await NotificationManager.shared.scheduleReminder(updated)
            }
        } else {
            NotificationManager.shared.removeReminder(updated)
        }
    }
    
    func reminders(for petId: UUID) -> [Reminder] {
        return reminders.filter { $0.petId == petId }.sorted { $0.nextOccurrence < $1.nextOccurrence }
    }
    
    func reset() {
        reminders = []
    }
}
