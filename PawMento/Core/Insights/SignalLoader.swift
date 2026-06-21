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
    // Fix I6: Maximum rows to load per query — prevents memory pressure on large histories
    private static let maxRows = 500
    
    static func load(petId: UUID, window: TimeRange) async throws -> [Signal] {
        let now = Date()
        
        // Fix I6: Build query conditionally — .all omits the date filter entirely
        var query = SupabaseManager.shared.client
            .from("logs")
            .select()
            .eq("pet_id", value: petId.uuidString)
        
        // Fix I6: For .all, skip the .gte filter (don't format Date.distantPast)
        if window != .all {
            let startDate: Date
            switch window {
            case .days7: startDate = Calendar.current.date(byAdding: .day, value: -7, to: now)!
            case .days30: startDate = Calendar.current.date(byAdding: .day, value: -30, to: now)!
            case .days90: startDate = Calendar.current.date(byAdding: .day, value: -90, to: now)!
            case .months6: startDate = Calendar.current.date(byAdding: .month, value: -6, to: now)!
            case .year1: startDate = Calendar.current.date(byAdding: .year, value: -1, to: now)!
            case .all: fatalError("Unreachable")
            }
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let dateString = formatter.string(from: startDate)
            query = query.gte("timestamp", value: dateString)
        }
        
        // Fix I6: Add pagination — cap at maxRows most-recent, ordered by timestamp desc
        let dtos: [LogDTO] = try await query
            .order("timestamp", ascending: false)
            .limit(maxRows)
            .execute()
            .value
        
        // Reverse to restore chronological order for detectors
        return dtos.reversed().map { dto in
            let category = LogCategory(rawValue: dto.log_type) ?? {
                // Fix I10: Log unknown category values in debug to catch typos or new categories
                #if DEBUG
                print("⚠️ SignalLoader: Unknown LogCategory raw value '\(dto.log_type)' — falling back to .other")
                #endif
                return LogCategory.other
            }()
            return Signal(id: dto.id, category: category, note: dto.description, severity: dto.severity, timestamp: dto.timestamp)
        }
    }
}
