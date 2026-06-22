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
                Text(label).font(.labelLarge)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(isSelected ? Color.primary : Color.surface0)
            .foregroundColor(isSelected ? .white : .primaryText)
            .cornerRadius(AppRadius.input)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.warmSand, lineWidth: 1)
            )
            .scaleEffect(isSelected ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.08), value: isSelected)
        }
    }
}
