import SwiftUI

struct SeveritySliderView: View {
    @Binding var severity: Int
    
    private let labels = ["Mild", "Mild-Moderate", "Moderate", "Concerning", "Severe"]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(AppStrings.QuickLog.severity)
                    .font(.labelSemibold)
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Text(labels[severity - 1])
                    .font(.labelSemibold)
                    .foregroundColor(colorForSeverity(severity))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(colorForSeverity(severity).opacity(0.15))
                    .clipShape(Capsule())
            }
            
            Slider(value: Binding(
                get: { Double(severity) },
                set: {
                    let newValue = Int($0)
                    if newValue != severity {
                        severity = newValue
                        let generator = UISelectionFeedbackGenerator()
                        generator.selectionChanged()
                        TelemetryEngine.shared.track(event: .quick_log_severity_changed, properties: ["value": newValue])
                    }
                }
            ), in: 1...5, step: 1)
            .accentColor(colorForSeverity(severity))
        }
        .padding(.vertical, 8)
        .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
    }
    
    private func colorForSeverity(_ val: Int) -> Color {
        switch val {
        case 1: return Color.primary
        case 2, 3: return Color.primary
        case 4, 5: return Color.error
        default: return Color.primary
        }
    }
}
