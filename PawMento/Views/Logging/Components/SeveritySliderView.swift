import SwiftUI

struct SeveritySliderView: View {
    @Binding var severity: Int
    
    private let labels = ["Mild", "Mild-Moderate", "Moderate", "Concerning", "Severe"]
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(AppStrings.QuickLog.severity)
                    .font(.labelSM)
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(colorForSeverity(severity))
                        .frame(width: 8, height: 8)
                    Text(labels[severity - 1])
                        .font(.labelSM)
                        .foregroundColor(colorForSeverity(severity))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(colorForSeverity(severity).opacity(0.12))
                .clipShape(Capsule())
                .animation(.easeInOut(duration: 0.2), value: severity)
            }
            
            // Custom segmented severity selector
            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { level in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            severity = level
                        }
                        let generator = UISelectionFeedbackGenerator()
                        generator.selectionChanged()
                        TelemetryEngine.shared.track(event: .quick_log_severity_changed, properties: ["value": level])
                    }) {
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    level <= severity
                                        ? colorForSeverity(level)
                                        : Color.ink300.opacity(0.3)
                                )
                                .frame(height: 28)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(
                                            level == severity
                                                ? colorForSeverity(level).opacity(0.5)
                                                : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                                .shadow(
                                    color: level == severity
                                        ? colorForSeverity(level).opacity(0.25)
                                        : Color.clear,
                                    radius: 4, x: 0, y: 2
                                )
                            
                            Text("\(level)")
                                .font(.system(size: 10, weight: level == severity ? .bold : .medium))
                                .foregroundColor(
                                    level == severity
                                        ? colorForSeverity(level)
                                        : .tertiaryText
                                )
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(labels[level - 1]), severity \(level) of 5")
                    .accessibilityAddTraits(level == severity ? .isSelected : [])
                }
            }
        }
        .padding(.vertical, 8)
        .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
    }
    
    private func colorForSeverity(_ val: Int) -> Color {
        switch val {
        case 1: return Color.primary           // Sage green — mild
        case 2: return Color.sageHue           // Slightly darker sage
        case 3: return Color.warning           // Amber — moderate
        case 4: return Color.coral500          // Coral — concerning
        case 5: return Color.error             // Red — severe
        default: return Color.primary
        }
    }
}
