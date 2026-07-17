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
    @State private var didChangePhoto = false
    @State private var isLoadingRemotePhoto = false
    @State private var photoLoadTask: Task<Void, Never>?
    
    // Validation
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isSubmitting = false
    
    var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedSpecies != nil
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        
                        // Photo Picker
                        CenterContainer {
                            ZStack {
                                PetPhotoWellView(selectedImage: $petImage)
                                if isLoadingRemotePhoto && petImage == nil {
                                    ProgressView()
                                }
                            }
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
                    .fontWeight(.semibold)
                    .foregroundColor(canSubmit ? .primary : .outline)
                    .disabled(!canSubmit || isSubmitting)
                }
            }
            .onAppear {
                populateData()
                loadRemotePhotoIfNeeded()
            }
            .onDisappear {
                photoLoadTask?.cancel()
                photoLoadTask = nil
            }
            .onChange(of: petImage) { oldValue, newValue in
                // Ignore the async remote preload; only user picks count as a change.
                if isLoadingRemotePhoto { return }
                if oldValue != newValue {
                    didChangePhoto = true
                }
            }
            .onChange(of: isKg) { _, newIsKg in
                convertDisplayedWeight(toKg: newIsKg)
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
            let display = isKg ? wt : (wt * 2.20462)
            self.weight = String(format: "%.1f", display)
        }
        self.petImage = editingPet.photoImage
        self.didChangePhoto = false
    }
    
    private func loadRemotePhotoIfNeeded() {
        guard petImage == nil, let url = editingPet.photoLocalURL else { return }
        
        isLoadingRemotePhoto = true
        let petId = editingPet.id
        photoLoadTask?.cancel()
        photoLoadTask = Task {
            defer {
                Task { @MainActor in
                    isLoadingRemotePhoto = false
                }
            }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard !Task.isCancelled else { return }
                guard let image = UIImage(data: data) else { return }
                await MainActor.run {
                    guard editingPet.id == petId, !didChangePhoto else { return }
                    petImage = image
                }
            } catch {
                // Keep empty well; existing URL is preserved on save when didChangePhoto is false.
            }
        }
    }
    
    private func convertDisplayedWeight(toKg: Bool) {
        let trimmed = weight.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        guard let num = formatter.number(from: trimmed)?.doubleValue else { return }
        let converted = toKg ? (num / 2.20462) : (num * 2.20462)
        weight = String(format: "%.1f", converted)
    }
    
    private func submitForm() {
        guard canSubmit, let species = selectedSpecies else {
            errorMessage = "Please fill out the required fields."
            showError = true
            return
        }
        
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
        
        var updatedPet = editingPet
        updatedPet.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedPet.species = species
        updatedPet.breed = breed.isEmpty ? nil : breed
        updatedPet.birthday = birthday
        updatedPet.weightKg = finalWeightKg
        
        // Only attach image for upload when the user picked a new one.
        if didChangePhoto, let newImage = petImage {
            updatedPet.photoImage = newImage
        } else {
            updatedPet.photoImage = nil
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
