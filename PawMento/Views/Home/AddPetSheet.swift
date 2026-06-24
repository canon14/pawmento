import SwiftUI
import PhotosUI

struct AddPetSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var petStore: PetStore
    @EnvironmentObject var authManager: AuthManager
    
    // Form State
    @State private var name: String = ""
    @State private var selectedSpecies: Species?
    @State private var breed: String = ""
    @State private var breedSuggestions: [String] = []
    @State private var isShowingBreedSuggestions = false
    @State private var birthday: DateComponents?
    @State private var weight: String = ""
    @State private var isKg: Bool = true
    
    // Photo State
    @State private var petImage: UIImage? = nil
    
    // Validation
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isSubmitting = false
    
    var canSubmit: Bool {
        !name.isEmpty && selectedSpecies != nil
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        
                        // Photo Picker
                        CenterContainer {
                            PetPhotoWellView(selectedImage: $petImage)
                        }
                        .padding(.top, 24)
                        
                        // Form Fields
                        VStack(spacing: 24) {
                            
                            // Name
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Pet's Name")
                                    .font(.labelSM)
                                    .foregroundColor(.primaryText)
                                FormTextField(placeholder: "e.g. Max", text: $name)
                            }
                            
                            // Species
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Species")
                                    .font(.labelSM)
                                    .foregroundColor(.primaryText)
                                SpeciesSelectorView(selectedSpecies: $selectedSpecies)
                            }
                            
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
                                        
                                        // Debounce logic (300ms)
                                        try? await Task.sleep(nanoseconds: 300_000_000)
                                        guard !Task.isCancelled else { return }
                                        
                                        let suggestions = BreedStore.shared.suggestBreeds(for: species, query: breed)
                                        await MainActor.run {
                                            self.breedSuggestions = suggestions
                                            self.isShowingBreedSuggestions = !suggestions.isEmpty && !suggestions.contains(breed)
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
                                    .background(Color.surfaceContainerLow)
                                    .cornerRadius(AppRadius.input)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.warmSand, lineWidth: 1)
                                    )
                                    .padding(.top, 4)
                                }
                            }
                            
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
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture {
                    hideKeyboard()
                    isShowingBreedSuggestions = false
                }
            }
            .navigationTitle("Add Pet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.onSurfaceVariant)
                    .disabled(isSubmitting)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        submitForm()
                    }
                    .font(.headlineMD)
                    .foregroundColor(canSubmit ? .primary : .outline)
                    .disabled(!canSubmit || isSubmitting)
                }
            }
            .overlay {
                if isSubmitting {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        ProgressView("Adding \(name)...")
                            .padding()
                            .background(Color.surfaceBright)
                            .cornerRadius(AppRadius.input)
                            .shadow(radius: 10)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
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

// Helper to center the photo picker easily without GeometryReader complexity
struct CenterContainer<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        HStack {
            Spacer()
            content()
            Spacer()
        }
    }
}

#Preview {
    AddPetSheet()
        .environmentObject(PetStore())
        .environmentObject(AuthManager())
}
