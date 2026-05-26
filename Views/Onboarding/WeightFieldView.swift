import SwiftUI

struct WeightFieldView: View {
    @Binding var weightText: String
    @Binding var isKg: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            TextField("0.0", text: $weightText)
                .keyboardType(.decimalPad)
                .font(.bodyMD)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .foregroundColor(.primaryText)
            
            Divider()
                .frame(height: 32)
            
            // Toggle
            HStack(spacing: 0) {
                Button(action: { isKg = false }) {
                    Text("lbs")
                        .font(.custom("PlusJakartaSans-Regular", size: 12))
                        .foregroundColor(!isKg ? .primaryText : .outline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(!isKg ? Color.warmSand.opacity(0.3) : Color.clear)
                        .cornerRadius(6)
                }
                
                Button(action: { isKg = true }) {
                    Text("kg")
                        .font(.custom("PlusJakartaSans-Regular", size: 12))
                        .foregroundColor(isKg ? .primaryText : .outline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(isKg ? Color.warmSand.opacity(0.3) : Color.clear)
                        .cornerRadius(6)
                }
            }
            .padding(.horizontal, 8)
        }
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.warmSand, lineWidth: 1)
        )
        
        Text("Used to calculate medication dose reminders")
            .font(.custom("PlusJakartaSans-Regular", size: 12))
            .foregroundColor(.tertiaryText)
            .padding(.top, 2)
    }
}
