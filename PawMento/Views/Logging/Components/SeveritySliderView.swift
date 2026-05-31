import SwiftUI

struct SeveritySliderView: View {
    @Binding var severity: Int
    
    private let labels = ["Mild", "Mild-Moderate", "Moderate", "Concerning", "Severe"]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Severity")
                    .font(.labelSemibold)
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Text(labels[severity - 1])
                    .font(.labelMD)
                    .foregroundColor(colorForSeverity(severity))
            }
            
            Slider(value: Binding(
                get: { Double(severity) },
                set: {
                    let newValue = Int($0)
                    if newValue != severity {
                        severity = newValue
                        let generator = UISelectionFeedbackGenerator()
                        generator.selectionChanged()
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
        case 1: return Color.sage
        case 2, 3: return Color.warmTan
        case 4, 5: return Color.warmCoral
        default: return Color.warmTan
        }
    }
}
