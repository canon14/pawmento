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
    @State private var isKg: Bool = true // Not deeply persisted yet, assume double is kg
    
    // Photo State
    @State private var petImage: UIImage? = nil
    
    // Validation
    @State private var showError = false
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
                                FormTextField(placeholder: "e.g. Buddy", text: $name)
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
            .navigationTitle("Add Pet")
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
            .overlay {
                if isSubmitting {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        ProgressView("Adding \(name)...")
                            .padding()
                            .background(Color.surfaceBright)
                            .cornerRadius(12)
                            .shadow(radius: 10)
                    }
                }
            }
        }
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
            }
        }
    }
}

// Helper to center the photo picker easily without GeometryReader complexity
struct CenterContainer<Content: View>: View {
    let content: () -> Content
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
