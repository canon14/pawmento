import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct AddFirstPetScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var petStore: PetStore
    @EnvironmentObject var authManager: AuthManager
    var onComplete: () -> Void
    
    // Form State
    @State private var petImage: UIImage? = nil
    @State private var name: String = ""
    @State private var selectedSpecies: Species? = nil
    @State private var breed: String = ""
    @State private var birthday: DateComponents? = nil
    @State private var weight: String = ""
    @State private var isKg: Bool = false
    
    @State private var isSubmitting: Bool = false
    @State private var showError: Bool = false
    
    @State private var breedSuggestions: [String] = []
    @State private var isShowingBreedSuggestions = false
    
    var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && selectedSpecies != nil
    }
    
    var ctaText: String {
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Add your pet →"
        }
        return "Add \(name) →"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .font(.bodyMD)
                .foregroundColor(.tertiaryText)
                
                Spacer()
                
                if canSubmit {
                    Button("Done") {
                        submitForm()
                    }
                    .font(.labelLarge)
                    .foregroundColor(.warmTan)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)
            
            // Grabber
            Capsule()
                .fill(Color.warmSand)
                .frame(width: 36, height: 4)
                .padding(.bottom, 16)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    
                    // Photo Well
                    HStack {
                        Spacer()
                        PetPhotoWellView(selectedImage: $petImage)
                        Spacer()
                    }
                    .padding(.bottom, 24)
                    
                    // Form Fields
                    Group {
                        // Name
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Pet's name")
                                .font(.labelSemibold)
                                .foregroundColor(.primaryText)
                            FormTextField(placeholder: "e.g. Buddy", text: $name, isError: showError && name.isEmpty)
                            if showError && name.isEmpty {
                                Text("Give your pet a name first")
                                    .font(.custom("PlusJakartaSans-Regular", size: 12))
                                    .foregroundColor(.warmCoral)
                                    .padding(.leading, 4)
                            }
                        }
                        .padding(.bottom, 24)
                        
                        // Species
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Species")
                                .font(.labelSemibold)
                                .foregroundColor(.primaryText)
                            SpeciesSelectorView(selectedSpecies: $selectedSpecies)
                            if showError && selectedSpecies == nil {
                                Text("Select a species to continue")
                                    .font(.custom("PlusJakartaSans-Regular", size: 12))
                                    .foregroundColor(.warmCoral)
                                    .padding(.leading, 4)
                            }
                        }
                        .padding(.bottom, 24)
                        
                        // Breed
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 4) {
                                Text("Breed")
                                    .font(.labelSemibold)
                                    .foregroundColor(.primaryText)
                                Text("(optional)")
                                    .font(.labelRegular)
                                    .foregroundColor(.secondaryText)
                            }
                            FormTextField(placeholder: "e.g. Golden Retriever", text: $breed)
                                .onChange(of: breed) { newValue in
                                    if let species = selectedSpecies {
                                        breedSuggestions = BreedStore.shared.suggestBreeds(for: species, query: newValue)
                                        isShowingBreedSuggestions = !breedSuggestions.isEmpty && !breedSuggestions.contains(newValue)
                                    } else {
                                        isShowingBreedSuggestions = false
                                    }
                                }
                                .onChange(of: selectedSpecies) { _ in
                                    breed = ""
                                    isShowingBreedSuggestions = false
                                }
                            
                            if isShowingBreedSuggestions {
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(breedSuggestions, id: \.self) { suggestion in
                                        Button(action: {
                                            breed = suggestion
                                            isShowingBreedSuggestions = false
                                            hideKeyboard()
                                        }) {
                                            Text(suggestion)
                                                .font(.bodyMD)
                                                .foregroundColor(.primaryText)
                                                .padding(.horizontal, 16)
                                                .frame(height: 44)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        if suggestion != breedSuggestions.last {
                                            Divider().padding(.horizontal, 16)
                                        }
                                    }
                                }
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.warmSand, lineWidth: 1)
                                )
                                .padding(.top, 4)
                            }
                            
                            Text("You can always add this later")
                                .font(.custom("PlusJakartaSans-Regular", size: 12))
                                .foregroundColor(.tertiaryText)
                        }
                        .padding(.bottom, 24)
                        
                        // Birthday
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 4) {
                                Text("Birthday")
                                    .font(.labelSemibold)
                                    .foregroundColor(.primaryText)
                                Text("(optional)")
                                    .font(.labelRegular)
                                    .foregroundColor(.secondaryText)
                            }
                            BirthdayPickerField(selectedDateComponents: $birthday)
                        }
                        .padding(.bottom, 24)
                        
                        // Weight
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 4) {
                                Text("Weight")
                                    .font(.labelSemibold)
                                    .foregroundColor(.primaryText)
                                Text("(optional)")
                                    .font(.labelRegular)
                                    .foregroundColor(.secondaryText)
                            }
                            WeightFieldView(weightText: $weight, isKg: $isKg)
                        }
                        .padding(.bottom, 32)
                    }
                }
                .padding(.horizontal, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                hideKeyboard()
            }
            
            // Primary CTA
            Button(action: submitForm) {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.trailing, 8)
                        Text("Adding \(name)…")
                    } else {
                        Text(ctaText)
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!canSubmit || isSubmitting)
            .padding(.horizontal, AppSpacing.gutter)
            .padding(.bottom, AppSpacing.gutter)
        }
        .background(Color.warmCream.ignoresSafeArea())
    }
    
    private func submitForm() {
        guard canSubmit, let species = selectedSpecies else {
            showError = true
            return
        }
        
        isSubmitting = true
        
        let newPet = Pet(
            name: name,
            species: species,
            breed: breed.isEmpty ? nil : breed,
            birthday: birthday,
            weightKg: Double(weight), // basic parse for MVP
            photoImage: petImage
        )
        
        Task {
            guard let ownerId = await authManager.getCurrentUserId() else {
                print("Cannot add pet: No authenticated user.")
                await MainActor.run {
                    showError = true
                    isSubmitting = false
                }
                return
            }
            
            await petStore.addPet(newPet, ownerId: ownerId)
            
            await MainActor.run {
                isSubmitting = false
                dismiss()
                onComplete()
            }
        }
    }
}

#Preview {
    AddFirstPetScreen(onComplete: {})
}
