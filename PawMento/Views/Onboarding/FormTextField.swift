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
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isError ? Color.error : Color.warmSand, lineWidth: isError ? 2 : 1)
            )
            .foregroundColor(.primaryText)
    }
}
