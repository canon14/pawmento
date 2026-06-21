import Foundation
import Supabase

struct Signal {
    let id: UUID
    let category: LogCategory
    let note: String?
    let severity: Int?
    let timestamp: Date
}

class SignalLoader {
    static func load(petId: UUID, window: TimeRange) async throws -> [Signal] {
        let now = Date()
        let startDate: Date
        
        switch window {
        case .days7: startDate = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        case .days30: startDate = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        case .days90: startDate = Calendar.current.date(byAdding: .day, value: -90, to: now)!
        case .months6: startDate = Calendar.current.date(byAdding: .month, value: -6, to: now)!
        case .year1: startDate = Calendar.current.date(byAdding: .year, value: -1, to: now)!
        case .all: startDate = Date.distantPast
        }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateString = formatter.string(from: startDate)
        
        let dtos: [LogDTO] = try await SupabaseManager.shared.client
            .from("logs")
            .select()
            .eq("pet_id", value: petId.uuidString)
            .gte("timestamp", value: dateString)
            .order("timestamp", ascending: true)
            .execute()
            .value
        
        return dtos.map { dto in
            let category = LogCategory(rawValue: dto.log_type) ?? .other
            return Signal(id: dto.id, category: category, note: dto.description, severity: dto.severity, timestamp: dto.timestamp)
        }
    }
}
