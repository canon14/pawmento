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
    @State private var errorMessage: String = ""
    
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
                .disabled(isSubmitting)
                
                Spacer()
                
                if canSubmit {
                    Button("Done") {
                        submitForm()
                    }
                    .font(.labelMD)
                    .foregroundColor(.primary)
                    .disabled(isSubmitting)
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
                                .font(.labelSM)
                                .foregroundColor(.primaryText)
                            FormTextField(placeholder: "e.g. Max", text: $name, isError: showError && name.isEmpty)
                            if showError && name.isEmpty {
                                Text("Give your pet a name first")
                                    .font(.caption)
                                    .foregroundColor(.error)
                                    .padding(.leading, 4)
                            }
                        }
                        .padding(.bottom, 24)
                        
                        // Species
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Species")
                                .font(.labelSM)
                                .foregroundColor(.primaryText)
                            SpeciesSelectorView(selectedSpecies: $selectedSpecies)
                            if showError && selectedSpecies == nil {
                                Text("Select a species to continue")
                                    .font(.caption)
                                    .foregroundColor(.error)
                                    .padding(.leading, 4)
                            }
                        }
                        .padding(.bottom, 24)
                        
                        // Breed
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 4) {
                                Text("Breed")
                                    .font(.labelSM)
                                    .foregroundColor(.primaryText)
                                Text("(optional)")
                                    .font(.bodyXS)
                                    .foregroundColor(.secondaryText)
                            }
                            FormTextField(placeholder: "e.g. Golden Retriever", text: $breed)
                                .task(id: breed) {
                                    guard let species = selectedSpecies else { return }
                                    guard !breed.isEmpty else {
                                        isShowingBreedSuggestions = false
                                        return
                                    }
                                    
                                    try? await Task.sleep(nanoseconds: 300_000_000)
                                    guard !Task.isCancelled else { return }
                                    
                                    let suggestions = BreedStore.shared.suggestBreeds(for: species, query: breed)
                                    await MainActor.run {
                                        self.breedSuggestions = suggestions
                                        self.isShowingBreedSuggestions = !suggestions.isEmpty && !suggestions.contains(breed)
                                    }
                                }
                                .onChange(of: selectedSpecies) { _, _ in
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
                                .background(Color.surfaceContainerLow)
                                .cornerRadius(AppRadius.input)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.warmSand, lineWidth: 1)
                                )
                                .padding(.top, 4)
                            }
                            
                            Text("You can always add this later")
                                .font(.caption)
                                .foregroundColor(.tertiaryText)
                        }
                        .padding(.bottom, 24)
                        
                        // Birthday
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 4) {
                                Text("Birthday")
                                    .font(.labelSM)
                                    .foregroundColor(.primaryText)
                                Text("(optional)")
                                    .font(.bodyXS)
                                    .foregroundColor(.secondaryText)
                            }
                            BirthdayPickerField(selectedDateComponents: $birthday)
                        }
                        .padding(.bottom, 24)
                        
                        // Weight
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 4) {
                                Text("Weight")
                                    .font(.labelSM)
                                    .foregroundColor(.primaryText)
                                Text("(optional)")
                                    .font(.bodyXS)
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
                isShowingBreedSuggestions = false
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
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func submitForm() {
        guard canSubmit, let species = selectedSpecies else { return }
        
        var finalWeightKg: Double? = nil
        let trimmedWeight = weight.trimmingCharacters(in: .whitespaces)
        
        if !trimmedWeight.isEmpty {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.locale = Locale.current
            
            if let num = formatter.number(from: trimmedWeight) {
                let w = num.doubleValue
                if w <= 0 || w > 1000 {
                    errorMessage = "Please enter a valid weight (between 0 and 1000)."
                    showError = true
                    return
                }
                finalWeightKg = isKg ? w : (w * 0.453592)
            } else {
                errorMessage = "Please enter a valid number for weight."
                showError = true
                return
            }
        }
        
        isSubmitting = true
        
        let newPet = Pet(
            name: name,
            species: species,
            breed: breed.isEmpty ? nil : breed,
            birthday: birthday,
            weightKg: finalWeightKg,
            photoImage: petImage
        )
        
        Task {
            guard let ownerId = await authManager.getCurrentUserId() else {
                TelemetryEngine.shared.track(event: .error_occurred, properties: ["message": "Cannot add pet: No authenticated user"])
                await MainActor.run {
                    errorMessage = "Your session expired. Please sign out and sign back in to save changes."
                    showError = true
                    isSubmitting = false
                }
                return
            }
            
            do {
                try await petStore.addPet(newPet, ownerId: ownerId)
                await MainActor.run {
                    isSubmitting = false
                    dismiss()
                    onComplete()
                }
            } catch {
                TelemetryEngine.shared.track(event: .error_occurred, properties: ["message": "Failed to add pet: \(error.localizedDescription)"])
                await MainActor.run {
                    errorMessage = "Failed to save pet: \(error.localizedDescription). Please try again."
                    showError = true
                    isSubmitting = false
                }
            }
        }
    }
}

#Preview {
    AddFirstPetScreen(onComplete: {})
}
