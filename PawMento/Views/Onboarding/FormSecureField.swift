import SwiftUI

struct FormSecureField: View {
    let placeholder: String
    @Binding var text: String
    var isError: Bool = false
    
    @State private var isVisible: Bool = false
    
    var body: some View {
        HStack {
            if isVisible {
                TextField(placeholder, text: $text)
                    .font(.bodyMD)
                    .foregroundColor(.primaryText)
            } else {
                SecureField(placeholder, text: $text)
                    .font(.bodyMD)
                    .foregroundColor(.primaryText)
            }
            
            Button(action: {
                isVisible.toggle()
            }) {
                Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.tertiaryText)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isError ? Color.warmCoral : Color.warmSand, lineWidth: isError ? 2 : 1)
        )
    }
}
