import SwiftUI

/// A consistent overline-style section header used throughout the app.
/// Replaces ad-hoc Text(...).font(.bodyXS).kerning(1.2) and "─── TITLE ───" patterns.
struct SectionHeader: View {
    let title: String
    var trailing: AnyView? = nil
    var style: Style = .default
    
    enum Style {
        case `default`     // Simple overline label
        case withRule      // Decorative thin rule on each side
    }
    
    var body: some View {
        switch style {
        case .default:
            HStack {
                Text(title.uppercased())
                    .font(.labelXS)
                    .foregroundColor(.ink600)
                    .kerning(1.0)
                
                Spacer()
                
                if let trailing = trailing {
                    trailing
                }
            }
            
        case .withRule:
            HStack(spacing: 12) {
                ruleView
                
                Text(title.uppercased())
                    .font(.labelXS)
                    .foregroundColor(.ink600)
                    .kerning(1.0)
                    .lineLimit(1)
                    .fixedSize()
                
                ruleView
            }
        }
    }
    
    private var ruleView: some View {
        Rectangle()
            .fill(Color.ink300.opacity(0.4))
            .frame(height: 1)
    }
}

// Convenience initializers
extension SectionHeader {
    init(_ title: String, style: Style = .default) {
        self.title = title
        self.style = style
    }
    
    init(_ title: String, style: Style = .default, @ViewBuilder trailing: () -> some View) {
        self.title = title
        self.style = style
        self.trailing = AnyView(trailing())
    }
}

#Preview {
    VStack(spacing: 24) {
        SectionHeader("Up Next")
        SectionHeader("This Week's Headline", style: .withRule)
        SectionHeader("Today") {
            Button("See all") {  }
                .font(.labelMD)
                .foregroundColor(.primary)
        }
    }
    .padding()
}
