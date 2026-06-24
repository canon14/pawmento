import SwiftUI

struct SpeciesSelectorView: View {
    @Binding var selectedSpecies: Species?
    @State private var otherText: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                SpeciesPill(icon: "🐶", label: "Dog", isSelected: selectedSpecies == .dog) {
                    selectedSpecies = .dog
                }
                SpeciesPill(icon: "🐱", label: "Cat", isSelected: selectedSpecies == .cat) {
                    selectedSpecies = .cat
                }
                SpeciesPill(icon: "🐰", label: "Rabbit", isSelected: selectedSpecies == .rabbit) {
                    selectedSpecies = .rabbit
                }
                
                let isOther = selectedSpecies != nil && selectedSpecies != .dog && selectedSpecies != .cat && selectedSpecies != .rabbit
                SpeciesPill(icon: "···", label: "Other", isSelected: isOther) {
                    if case .other = selectedSpecies { return }
                    selectedSpecies = .other(otherText)
                }
            }
            
            if let species = selectedSpecies {
                if case .other(_) = species {
                    FormTextField(placeholder: "e.g. Hamster, Turtle, Parrot...", text: Binding(
                        get: {
                            if case .other(let text) = selectedSpecies { return text }
                            return ""
                        },
                        set: {
                            selectedSpecies = .other($0)
                            otherText = $0
                        }
                    ))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }
}

struct SpeciesPill: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(icon).font(.headlineMD)
                Text(label).font(.labelMD)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                isSelected ? 
                LinearGradient(colors: [Color.primary, Color.primary.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing) 
                : LinearGradient(colors: [Color.surface0, Color.surface0], startPoint: .top, endPoint: .bottom)
            )
            .foregroundColor(isSelected ? .white : .primaryText)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Color.primary.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: isSelected ? Color.primary.opacity(0.3) : Color.black.opacity(0.02), radius: isSelected ? 8 : 4, x: 0, y: isSelected ? 4 : 2)
        }
        .buttonStyle(SquishyCardStyle())
    }
}
