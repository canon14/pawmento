import Foundation

enum LogEvent: String {
    case quick_log_opened
    case quick_log_category_selected
    case quick_log_photo_added
    case quick_log_note_typed
    case quick_log_severity_changed
    case quick_log_more_details_tapped
    case quick_log_saved
    case quick_log_cancelled
    case quick_log_undo_tapped
    case error_occurred
}

class TelemetryEngine {
    static let shared = TelemetryEngine()
    
    private init() {}
    
    func track(event: LogEvent, properties: [String: Any]? = nil) {
        print("📊 [Telemetry] \(event.rawValue)")
        if let props = properties {
            print("   ↳ \(props)")
        }
    }
}
