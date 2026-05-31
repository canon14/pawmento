import SwiftUI

struct QuickLogSheetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var petStore: PetStore
    @EnvironmentObject var logStore: LogStore
    
    @State private var selectedCategory: LogCategory?
    @State private var severity: Int = 1
    @State private var note: String = ""
    @State private var photo: UIImage?
    
    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var showErrorShake = false
    
    var body: some View {
        ZStack {
            Color.warmCream.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Quick Log")
                            .font(.headlineSM)
                            .foregroundColor(.primaryText)
                        
                        // Subtitle
                        let petName = petStore.activePet?.name ?? "your pet"
                        Text("\(petName) · just now")
                            .font(.labelRegular)
                            .foregroundColor(.secondaryText)
                    }
                    
                    Spacer()
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.bodyMD)
                    .foregroundColor(.tertiaryText)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                
                Divider()
                    .background(Color.warmSand.opacity(0.3))
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        PhotoNoteRowView(note: $note, photo: $photo)
                            .padding(.horizontal, 20)
                        
                        CategoryScrollerView(selectedCategory: $selectedCategory)
                            .padding(.leading, 20)
                        
                        if selectedCategory == .symptom {
                            SeveritySliderView(severity: $severity)
                                .padding(.horizontal, 20)
                        }
                        
                        Spacer(minLength: 120) // Room for floating CTA
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            
            // Floating CTA (Rides above keyboard automatically in SwiftUI)
            VStack {
                Spacer()
                
                VStack(spacing: 12) {
                    Button(action: saveLog) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 8)
                            } else if showSuccess {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 18, weight: .bold))
                            } else {
                                Text("Save")
                                    .font(.ctaOnboarding)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            selectedCategory == nil ? Color.warmTan.opacity(0.4) : Color.warmTan
                        )
                        .cornerRadius(14)
                        .shadow(color: Color.warmTan.opacity(selectedCategory == nil ? 0 : 0.2), radius: 8, x: 0, y: 4)
                    }
                    .disabled(selectedCategory == nil || isSaving || showSuccess)
                    .offset(x: showErrorShake ? 10 : -10)
                    .animation(showErrorShake ? Animation.default.repeatCount(3).speed(4) : .default, value: showErrorShake)
                    
                    Button("More details ↗") {
                        dismiss()
                    }
                    .font(.labelMD)
                    .foregroundColor(.warmTan)
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.warmCream.opacity(0), Color.warmCream]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .onAppear {
            if let activePet = petStore.activePet {
                selectedCategory = logStore.getLastUsedCategory(for: activePet.id)
            }
        }
    }
    
    private func saveLog() {
        guard let category = selectedCategory, let petId = petStore.activePet?.id else {
            showErrorShake = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showErrorShake = false
            }
            return
        }
        
        isSaving = true
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let log = LogEntry(
                petId: petId,
                category: category,
                severity: category == .symptom ? severity : nil,
                note: note.isEmpty ? nil : note,
                photoLocalURL: nil
            )
            
            logStore.saveLog(log)
            
            isSaving = false
            showSuccess = true
            let successGenerator = UINotificationFeedbackGenerator()
            successGenerator.notificationOccurred(.success)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dismiss()
            }
        }
    }
}
