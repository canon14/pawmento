import Foundation
import Combine
import Supabase

enum MedicationStoreError: LocalizedError {
    case validationFailed(String)
    case alreadyLoggedToday
    
    var errorDescription: String? {
        switch self {
        case .validationFailed(let message):
            return message
        case .alreadyLoggedToday:
            return "This dose was already logged today."
        }
    }
}

@MainActor
class MedicationStore: ObservableObject {
    @Published var medications: [Medication] = []
    @Published var isLoading: Bool = false
    @Published var fetchError: String? = nil
    
    private var activePetId: UUID?
    
    func fetchMedications(for petId: UUID) async {
        isLoading = true
        fetchError = nil
        activePetId = petId
        defer { isLoading = false }
        
        do {
            let dtos: [MedicationDTO] = try await SupabaseManager.shared.client
                .from("medications")
                .select()
                .eq("pet_id", value: petId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            self.medications = dtos.map { normalizeLoggedToday($0.toModel()) }
        } catch {
            print("Failed to fetch medications: \(error)")
            fetchError = "Unable to load medications. Please check your connection and try again."
        }
    }
    
    // MARK: - Server-First Writes (mirrors ReminderStore)
    
    func addMedication(_ medication: Medication) async throws {
        try validate(medication)
        
        try await SupabaseManager.shared.client
            .from("medications")
            .insert(medication.toDTO())
            .execute()
        
        medications.insert(medication, at: 0)
    }
    
    func updateMedication(_ medication: Medication) async throws {
        try validate(medication)
        
        try await SupabaseManager.shared.client
            .from("medications")
            .update(medication.toDTO())
            .eq("id", value: medication.id.uuidString)
            .execute()
        
        if let index = medications.firstIndex(where: { $0.id == medication.id }) {
            medications[index] = medication
        }
    }
    
    func deleteMedication(_ medication: Medication) async throws {
        try await SupabaseManager.shared.client
            .from("medications")
            .delete()
            .eq("id", value: medication.id.uuidString)
            .execute()
        
        medications.removeAll { $0.id == medication.id }
    }
    
    func logDoseTaken(_ medication: Medication) async throws {
        var updated = medication
        
        if updated.loggedToday {
            throw MedicationStoreError.alreadyLoggedToday
        }
        
        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        
        if let due = updated.nextDueDate {
            let dueDay = calendar.startOfDay(for: due)
            let daysLate = calendar.dateComponents([.day], from: dueDay, to: startOfToday).day ?? 0
            updated.streakCount = daysLate > 1 ? 1 : updated.streakCount + 1
        } else {
            updated.streakCount = max(1, updated.streakCount + 1)
        }
        
        updated.loggedToday = true
        updated.nextDueDate = Medication.nextDueDate(
            after: now,
            frequency: updated.frequency,
            previousDue: updated.nextDueDate ?? now
        )
        
        try await updateMedication(updated)
    }
    
    // MARK: - Helpers
    
    private func validate(_ medication: Medication) throws {
        let trimmedName = medication.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw MedicationStoreError.validationFailed("Medication name is required.")
        }
        guard trimmedName.count <= 120 else {
            throw MedicationStoreError.validationFailed("Medication name must be 120 characters or fewer.")
        }
        if let dose = medication.dose {
            let trimmedDose = dose.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmedDose.count <= 80 else {
                throw MedicationStoreError.validationFailed("Dose must be 80 characters or fewer.")
            }
        }
        guard !medication.frequency.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MedicationStoreError.validationFailed("Frequency is required.")
        }
    }
    
    /// Clears stale `loggedToday` when the current dosing period has elapsed.
    private func normalizeLoggedToday(_ medication: Medication) -> Medication {
        guard medication.loggedToday, let nextDue = medication.nextDueDate, nextDue <= Date() else {
            return medication
        }
        var normalized = medication
        normalized.loggedToday = false
        return normalized
    }
    
    func reset() {
        medications = []
        isLoading = false
        fetchError = nil
        activePetId = nil
    }
}
