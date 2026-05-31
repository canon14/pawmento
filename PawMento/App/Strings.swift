import Foundation

struct AppStrings {
    struct QuickLog {
        static let title = String(localized: "Quick Log", comment: "Header title for the quick log sheet")
        static let cancel = String(localized: "Cancel", comment: "Cancel button text")
        static let tapToDescribe = String(localized: "Tap to describe...", comment: "Placeholder for the note field")
        static let whatHappened = String(localized: "What happened?", comment: "Label above category selection")
        static let more = String(localized: "More", comment: "Button to show more categories")
        static let severity = String(localized: "Severity", comment: "Label for the severity slider")
        static let save = String(localized: "Save", comment: "Primary save button text")
        static let moreDetails = String(localized: "More details ↗", comment: "Link to full detail view")
        static let restoreUnsavedLog = String(localized: "Restore unsaved log?", comment: "Prompt to restore a draft")
        static let restore = String(localized: "Restore", comment: "Button to restore draft")
        static let discard = String(localized: "Discard", comment: "Button to discard draft")
        static let undo = String(localized: "Undo", comment: "Undo action in toast")
        
        static func loggedFor(_ petName: String) -> String {
            // In a real localized strings dict this would use string formatting: "Logged for %@"
            String(localized: "Logged for \(petName)", comment: "Success toast message")
        }
        
        static func subtitleJustNow(_ petName: String) -> String {
            String(localized: "\(petName) · just now", comment: "Subtitle showing pet name and time")
        }
    }
}
