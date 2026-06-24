import SwiftUI
import PhotosUI

struct EditPetSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var petStore: PetStore
    @EnvironmentObject var authManager: AuthManager
    
    let editingPet: Pet
    
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
                                    .font(.labelSemibold)
                                    .foregroundColor(.primaryText)
                                FormTextField(placeholder: "e.g. Max", text: $name)
                            }
                            
                            // Species
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Species")
                                    .font(.labelSemibold)
                                    .foregroundColor(.primaryText)
                                SpeciesSelectorView(selectedSpecies: $selectedSpecies)
                            }
                            
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
                                    .onChange(of: breed) { _, newValue in
                                        if let species = selectedSpecies {
                                            breedSuggestions = BreedStore.shared.suggestBreeds(for: species, query: newValue)
                                            isShowingBreedSuggestions = !breedSuggestions.isEmpty && !breedSuggestions.contains(newValue)
                                        } else {
                                            isShowingBreedSuggestions = false
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
                                    .background(Color.surface0)
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
                                        .font(.labelSemibold)
                                        .foregroundColor(.primaryText)
                                    Text("(optional)")
                                        .font(.labelRegular)
                                        .foregroundColor(.secondaryText)
                                }
                                BirthdayPickerField(selectedDateComponents: $birthday)
                            }
                            
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
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture {
                    hideKeyboard()
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.onSurfaceVariant)
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
            .onAppear {
                populateData()
            }
            .overlay {
                if isSubmitting {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        ProgressView("Saving...")
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
    
    private func populateData() {
        self.name = editingPet.name
        self.selectedSpecies = editingPet.species
        self.breed = editingPet.breed ?? ""
        self.birthday = editingPet.birthday
        if let wt = editingPet.weightKg {
            self.weight = String(format: "%.1f", wt)
        }
        self.petImage = editingPet.photoImage // We might want to load from photoLocalURL if image isn't loaded, but for MVP this is fine.
    }
    
    private func submitForm() {
        guard canSubmit, let species = selectedSpecies else {
            errorMessage = "Please fill out the required fields."
            showError = true
            return
        }
        
        isSubmitting = true
        
        var updatedPet = editingPet
        updatedPet.name = name
        updatedPet.species = species
        updatedPet.breed = breed.isEmpty ? nil : breed
        updatedPet.birthday = birthday
        updatedPet.weightKg = Double(weight)
        
        // If they chose a new image
        if let newImage = petImage {
            updatedPet.photoImage = newImage
        }
        
        Task {
            guard let ownerId = await authManager.getCurrentUserId() else {
                print("Cannot update pet: No authenticated user.")
                await MainActor.run {
                    errorMessage = "Your session expired. Please sign out and sign back in to save changes."
                    showError = true
                    isSubmitting = false
                }
                return
            }
            
            do {
                try await petStore.updatePet(updatedPet, ownerId: ownerId)
                await MainActor.run {
                    isSubmitting = false
                    dismiss()
                }
            } catch {
                TelemetryEngine.shared.track(event: .error_occurred, properties: ["message": "Failed to update pet: \(error.localizedDescription)"])
                await MainActor.run {
                    errorMessage = "Failed to update profile: \(error.localizedDescription)"
                    showError = true
                    isSubmitting = false
                }
            }
        }
    }
}
