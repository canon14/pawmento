import SwiftUI

struct CreateReminderSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var petStore: PetStore
    
    var existingReminder: Reminder? = nil
    
    @State private var title: String = ""
    @State private var selectedCategory: LogCategory = .meal
    @State private var time: Date = Date()
    @State private var frequency: ReminderFrequency = .daily
    @State private var isSaving = false
    
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
                        Task { await saveReminder() }
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
        }
        .onAppear {
            if let reminder = existingReminder {
                title = reminder.title
                if let cat = LogCategory.fromStoredValue(reminder.categoryId) {
                    selectedCategory = cat
                }
                time = reminder.time
                frequency = reminder.frequency
            }
        }
    }
    
    private func saveReminder() async {
        guard let petId = petStore.activePet?.id else { return }
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        
        do {
            if var reminder = existingReminder {
                reminder.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
                reminder.categoryId = selectedCategory.rawValue
                reminder.time = time
                reminder.frequency = frequency
                try await ReminderStore.shared.updateReminder(reminder)
            } else {
                let newReminder = Reminder(
                    petId: petId,
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    time: time,
                    frequency: frequency,
                    categoryId: selectedCategory.rawValue
                )
                try await ReminderStore.shared.addReminder(newReminder)
            }
            dismiss()
        } catch {
            ToastManager.shared.show("Failed to save reminder. Check your connection.", duration: 4.0)
        }
    }
}
