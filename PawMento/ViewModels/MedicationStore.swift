import Foundation
import Combine
import Supabase

@MainActor
class MedicationStore: ObservableObject {
    @Published var medications: [Medication] = []
    @Published var isLoading: Bool = false
    // Fix S10: Publish fetch errors instead of injecting fake data
    @Published var fetchError: String? = nil
    
    func fetchMedications(for petId: UUID) async {
        isLoading = true
        fetchError = nil
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
            // Fix S10: PATIENT SAFETY — never show fake/mock medications on error.
            // Preserve existing data if we had a successful fetch before; otherwise empty.
            // Surface the error so the UI can show a retry state.
            fetchError = "Unable to load medications. Please check your connection and try again."
        }
    }
    
    @MainActor
    func reset() {
        medications = []
        isLoading = false
        fetchError = nil
    }
}
