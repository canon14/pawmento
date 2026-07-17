import SwiftUI

struct MedicationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var petStore: PetStore
    @EnvironmentObject private var medicationStore: MedicationStore
    
    var existingMedication: Medication? = nil
    
    @State private var name: String = ""
    @State private var dose: String = ""
    @State private var selectedForm: MedicationForm = .pill
    @State private var selectedFrequency: MedicationFrequency = .daily
    @State private var nextDueDate: Date = Date()
    @State private var hasNextDueDate: Bool = true
    @State private var isSaving = false
    @State private var showDeleteConfirm = false
    
    private var isEditing: Bool { existingMedication != nil }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Medication Details")) {
                    TextField("Name (e.g. Apoquel)", text: $name)
                    
                    TextField("Dose (e.g. 16mg)", text: $dose)
                    
                    Picker("Form", selection: $selectedForm) {
                        ForEach(MedicationForm.allCases, id: \.self) { form in
                            Text(form.displayName).tag(form)
                        }
                    }
                }
                
                Section(header: Text("Schedule")) {
                    Picker("Frequency", selection: $selectedFrequency) {
                        ForEach(MedicationFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.displayName).tag(frequency)
                        }
                    }
                    
                    if selectedFrequency != .asNeeded {
                        Toggle("Set next due date", isOn: $hasNextDueDate)
                        
                        if hasNextDueDate {
                            DatePicker(
                                "Next due",
                                selection: $nextDueDate,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                        }
                    }
                }
                
                if isEditing {
                    Section {
                        Button("Delete Medication", role: .destructive) {
                            showDeleteConfirm = true
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Medication" : "Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.onSurfaceVariant)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task { await saveMedication() }
                    }
                    .font(.headlineMD)
                    .fontWeight(.semibold)
                    .foregroundColor(canSave ? .primary : .outline)
                    .disabled(!canSave || isSaving)
                }
            }
            .confirmationDialog(
                "Delete this medication?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    Task { await deleteMedication() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone.")
            }
        }
        .onAppear(perform: populateFromExisting)
    }
    
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func populateFromExisting() {
        guard let medication = existingMedication else { return }
        name = medication.name
        dose = medication.dose ?? ""
        if let form = medication.form, let parsed = MedicationForm(rawValue: form) {
            selectedForm = parsed
        }
        selectedFrequency = medication.medicationFrequency
        if let due = medication.nextDueDate {
            nextDueDate = due
            hasNextDueDate = true
        } else {
            hasNextDueDate = false
        }
    }
    
    private func buildMedication(petId: UUID) -> Medication {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDose = dose.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedDose = trimmedDose.isEmpty ? nil : trimmedDose
        let resolvedNextDue: Date? = {
            if selectedFrequency == .asNeeded { return nil }
            return hasNextDueDate ? nextDueDate : nil
        }()
        
        if var existing = existingMedication {
            existing.name = trimmedName
            existing.dose = resolvedDose
            existing.form = selectedForm.rawValue
            existing.frequency = selectedFrequency.rawValue
            existing.nextDueDate = resolvedNextDue
            return existing
        }
        
        return Medication(
            petId: petId,
            name: trimmedName,
            dose: resolvedDose,
            form: selectedForm.rawValue,
            frequency: selectedFrequency.rawValue,
            nextDueDate: resolvedNextDue
        )
    }
    
    private func saveMedication() async {
        guard let petId = petStore.activePet?.id else { return }
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        
        let medication = buildMedication(petId: petId)
        
        do {
            if isEditing {
                try await medicationStore.updateMedication(medication)
                ToastManager.shared.show("Medication updated")
            } else {
                try await medicationStore.addMedication(medication)
                ToastManager.shared.show("Medication added")
            }
            dismiss()
        } catch let error as MedicationStoreError {
            ToastManager.shared.show(error.localizedDescription, duration: 4.0)
        } catch {
            ToastManager.shared.show("Failed to save medication. Check your connection.", duration: 4.0)
        }
    }
    
    private func deleteMedication() async {
        guard let medication = existingMedication else { return }
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        
        do {
            try await medicationStore.deleteMedication(medication)
            ToastManager.shared.show("Medication deleted")
            dismiss()
        } catch {
            ToastManager.shared.show("Failed to delete medication. Check your connection.", duration: 4.0)
        }
    }
}
