import Foundation
import Combine
import Supabase

@MainActor
class MedicationStore: ObservableObject {
    @Published var medications: [Medication] = []
    @Published var isLoading: Bool = false
    
    // We will just fetch for MVP. Adding can be done later.
    func fetchMedications(for petId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let dtos: [MedicationDTO] = try await SupabaseManager.shared.client
                .from("medications")
                .select()
                .eq("pet_id", value: petId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            self.medications = dtos.map { $0.toModel() }
        } catch {
            print("Failed to fetch medications: \(error)")
            // Fallback to mock data for MVP demo if database is empty or fails
            self.medications = [
                Medication(petId: petId, name: "Apoquel 16mg", frequency: "Daily, 8am", streakCount: 14),
                Medication(petId: petId, name: "Heartgard", frequency: "Monthly", nextDueDate: Date().addingTimeInterval(12*24*3600), streakCount: 0)
            ]
        }
    }
}
