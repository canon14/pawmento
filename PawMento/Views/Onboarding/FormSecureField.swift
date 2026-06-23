import SwiftUI

struct FormSecureField: View {
    let placeholder: String
    @Binding var text: String
    var isError: Bool = false
    
    @State private var isVisible: Bool = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Group {
                if isVisible {
                    TextField(placeholder, text: $text)
                        .font(.bodyMD)
                        .foregroundColor(.primaryText)
                } else {
                    SecureField(placeholder, text: $text)
                        .font(.bodyMD)
                        .foregroundColor(.primaryText)
                }
            }
            .focused($isFocused)
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isVisible.toggle()
                }
            }) {
                Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 16))
                    .foregroundColor(isFocused ? .primary : .tertiaryText)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.input)
                .fill(isFocused ? Color.surfaceContainerLowest : Color.surfaceContainerLow.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.input)
                .stroke(
                    isError ? Color.error :
                    isFocused ? Color.primary.opacity(0.4) :
                    Color.outlineVariant.opacity(0.4),
                    lineWidth: isError ? 2 : (isFocused ? 1.5 : 1)
                )
        )
        .shadow(
            color: isFocused ? Color.primary.opacity(0.08) : Color.clear,
            radius: 8, x: 0, y: 4
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: isError)
    }
}
