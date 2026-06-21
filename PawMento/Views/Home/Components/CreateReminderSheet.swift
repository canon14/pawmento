import SwiftUI

struct CreateReminderSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var petStore: PetStore
    
    var existingReminder: Reminder? = nil
    
    @State private var title: String = ""
    @State private var selectedCategory: LogCategory = .meal
    @State private var time: Date = Date()
    @State private var frequency: ReminderFrequency = .daily
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Reminder Details")) {
                    TextField("Title (e.g. Heartworm Pill)", text: $title)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(LogCategory.allCases, id: \.self) { category in
                            HStack {
                                Text(category.emoji)
                                Text(category.rawValue.capitalized)
                            }.tag(category)
                        }
                    }
                }
                
                Section(header: Text("Schedule")) {
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                    
                    Picker("Frequency", selection: $frequency) {
                        ForEach(ReminderFrequency.allCases, id: \.self) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                }
            }
            .navigationTitle(existingReminder != nil ? "Edit Reminder" : "New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveReminder()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            if let reminder = existingReminder {
                title = reminder.title
                if let cat = LogCategory(rawValue: reminder.categoryId) {
                    selectedCategory = cat
                }
                time = reminder.time
                frequency = reminder.frequency
            }
        }
    }
    
    private func saveReminder() {
        guard let petId = petStore.activePet?.id else { return }
        
        if var reminder = existingReminder {
            reminder.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            reminder.categoryId = selectedCategory.rawValue
            reminder.time = time
            reminder.frequency = frequency
            Task {
                do {
                    try await ReminderStore.shared.updateReminder(reminder)
                } catch {
                    ToastManager.shared.show("Failed to update reminder. Check your connection.", duration: 4.0)
                }
            }
        } else {
            let newReminder = Reminder(
                petId: petId,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                time: time,
                frequency: frequency,
                categoryId: selectedCategory.rawValue
            )
            Task {
                do {
                    try await ReminderStore.shared.addReminder(newReminder)
                } catch {
                    ToastManager.shared.show("Failed to save reminder. Check your connection.", duration: 4.0)
                }
            }
        }
        
        dismiss()
    }
}
