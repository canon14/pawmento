import SwiftUI

struct FormTextField: View {
    let placeholder: String
    @Binding var text: String
    var isError: Bool = false
    
    var body: some View {
        TextField(placeholder, text: $text)
            .font(.bodyMD)
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Color.surface0)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isError ? Color.error : Color.primary.opacity(0.05), lineWidth: isError ? 2 : 1)
            )
            .foregroundColor(.primaryText)
    }
}
