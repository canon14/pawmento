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
    @State private var showMoreDetails = false
    
    @State private var showWelcome = false
    @State private var welcomeName = ""
    @State private var welcomeAppeared = false
    
    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var hasValidName: Bool {
        !trimmedName.isEmpty
    }
    
    var canSubmit: Bool {
        hasValidName && selectedSpecies != nil
    }
    
    var ctaText: String {
        if !hasValidName {
            return "Add your pet →"
        }
        return "Add \(trimmedName) →"
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Navigation Bar — Cancel only; submit is the bottom primary CTA
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.bodyMD)
                    .foregroundColor(.tertiaryText)
                    .disabled(isSubmitting || showWelcome)
                    
                    Spacer()
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
                                FormTextField(placeholder: "e.g. Max", text: $name, isError: showError && !hasValidName)
                                if showError && !hasValidName {
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
                            
                            // Optional details disclosure
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    showMoreDetails.toggle()
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Text("Add more details (optional)")
                                        .font(.labelMD)
                                        .foregroundColor(.secondaryText)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.tertiaryText)
                                        .rotationEffect(.degrees(showMoreDetails ? 180 : 0))
                                }
                                .padding(.vertical, 12)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .padding(.bottom, showMoreDetails ? 16 : 8)
                            
                            if showMoreDetails {
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
                    }
                    .padding(.horizontal, 24)
                }
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture {
                    hideKeyboard()
                    isShowingBreedSuggestions = false
                }
                .safeAreaInset(edge: .bottom) {
                    Button(action: submitForm) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 8)
                                Text("Adding \(trimmedName)…")
                            } else {
                                Text(ctaText)
                            }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!canSubmit || isSubmitting || showWelcome)
                    .padding(.horizontal, AppSpacing.gutter)
                    .padding(.top, 8)
                    .padding(.bottom, AppSpacing.gutter)
                    .background(Color.warmCream.ignoresSafeArea(edges: .bottom))
                }
            }
            .background(Color.warmCream.ignoresSafeArea())
            .allowsHitTesting(!showWelcome)
            
            if showWelcome {
                welcomeOverlay
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var welcomeOverlay: some View {
        ZStack {
            Color.warmCream.opacity(0.96)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Group {
                    if let petImage {
                        Image(uiImage: petImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color.cream)
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                }
                .frame(width: 96, height: 96)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 1))
                .scaleEffect(welcomeAppeared ? 1 : 0.4)
                
                Text("Welcome, \(welcomeName)!")
                    .font(.headlineMD)
                    .foregroundColor(.primaryText)
                    .opacity(welcomeAppeared ? 1 : 0)
                    .offset(y: welcomeAppeared ? 0 : 8)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                welcomeAppeared = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Welcome, \(welcomeName)!")
    }
    
    private func presentWelcomeThenDismiss(name: String, photoWarning: String?) {
        welcomeName = name
        showWelcome = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        if let photoWarning {
            ToastManager.shared.show(photoWarning, duration: 4.0)
        }
        
        // Always dismiss after hold — even if overlay fails to animate
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            dismiss()
            onComplete()
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
            name: trimmedName,
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
                let result = try await petStore.addPet(newPet, ownerId: ownerId)
                await MainActor.run {
                    isSubmitting = false
                    presentWelcomeThenDismiss(
                        name: trimmedName,
                        photoWarning: result.photoUploadWarning
                    )
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
