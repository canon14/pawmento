import SwiftUI
import UIKit

enum InsightShareHelper {
    static func shareText(for insight: Insight, petName: String) -> String {
        """
        \(insight.headline)
        
        \(insight.narrative)
        
        — PawMento insight for \(petName)
        """
    }
    
    static func isShareAction(_ title: String) -> Bool {
        let lower = title.lowercased()
        return lower.contains("share") || lower.contains("vet")
    }
}

struct InsightShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var onComplete: (() -> Void)? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
            onComplete?()
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
