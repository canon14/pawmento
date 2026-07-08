import SwiftUI

struct LogDetailSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var petStore: PetStore
    @EnvironmentObject var logStore: LogStore
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    // Injected for Edit Mode
    var existingLog: LogEntry?
    
    // Injected for Create Detailed Log Mode
    var initialCategory: LogCategory? = nil
    var initialSeverity: Int = 1
    var initialNote: String = ""
    var initialPhoto: UIImage? = nil
    
    @State private var selectedCategory: LogCategory?
    @State private var severity: Int = 1
    @State private var note: String = ""
    @State private var photo: UIImage?
    @State private var recordedAt: Date = Date()
    
    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var showErrorShake = false
    @State private var showDeleteConfirmation = false
    
    @State private var errorMessage = ""
    @State private var showErrorAlert = false
    
    var body: some View {
        ZStack {
            Color.warmCream.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(existingLog == nil ? "Detailed Log" : "Edit Log")
                            .font(.headlineSM)
                            .foregroundColor(.primaryText)
                        
                        let petName = petStore.activePet?.name ?? "your pet"
                        Text("For \(petName)")
                            .font(.bodyXS)
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
                        // Date Picker
                        HStack {
                            Text("Date & Time")
                                .font(.labelSM)
                                .foregroundColor(.secondaryText)
                            Spacer()
                            DatePicker("", selection: $recordedAt, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                                .tint(.primary)
                        }
                        .padding(.horizontal, 20)
                        
                        CategoryScrollerView(selectedCategory: $selectedCategory)
                            .padding(.leading, 20)
                        
                        if selectedCategory == .symptom {
                            SeveritySliderView(severity: $severity)
                                .padding(.horizontal, 20)
                        }
                        
                        // Note and Photo (Reusing existing components or custom)
                        PhotoNoteRowView(note: $note, photo: $photo)
                            .padding(.horizontal, 20)
                            
                        // Show existing photo if one exists and user hasn't selected a new one
                        if photo == nil, let photoURL = existingLog?.photoLocalURL {
                            CachedAsyncImage(url: photoURL) { image in
                                image.resizable()
                            } placeholder: {
                                Color.gray.opacity(0.2)
                            }
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .cornerRadius(AppRadius.input)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)
                
                // Footer
                VStack(spacing: 12) {
                    Button(action: saveLog) {
                        HStack {
                            if isSaving {
                                ProgressView().tint(.white).padding(.trailing, 8)
                            } else if showSuccess {
                                Image(systemName: "checkmark").font(.headlineSM)
                            } else {
                                Text("Save Details").font(.cta)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(selectedCategory == nil ? Color.primary.opacity(0.4) : Color.primary)
                        .cornerRadius(AppRadius.input)
                    }
                    .disabled(selectedCategory == nil || isSaving || showSuccess)
                    .offset(x: showErrorShake && !reduceMotion ? 10 : -10)
                    .animation(showErrorShake && !reduceMotion ? Animation.default.repeatCount(3).speed(4) : .default, value: showErrorShake)
                    
                    if existingLog != nil {
                        Button("Delete Log", role: .destructive) {
                            showDeleteConfirmation = true
                        }
                        .font(.labelMD)
                        .foregroundColor(.red)
                        .padding(.bottom, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16)
                .background(Color.warmCream)
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            if let log = existingLog {
                selectedCategory = log.category
                severity = log.severity ?? 1
                note = log.note ?? ""
                recordedAt = log.recordedAt
            } else {
                selectedCategory = initialCategory
                severity = initialSeverity
                note = initialNote
                photo = initialPhoto
            }
        }
        .confirmationDialog("Are you sure you want to delete this log?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                deleteLog()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    private func saveLog() {
        guard let category = selectedCategory, let petId = petStore.activePet?.id else {
            triggerErrorShake()
            return
        }
        
        isSaving = true
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        Task {
            guard let userId = await authManager.getCurrentUserId() else {
                await MainActor.run { isSaving = false; triggerErrorShake() }
                return
            }
            
            var compressedPhoto: UIImage? = nil
            if let img = photo, let compressedData = img.jpegData(compressionQuality: 0.5) {
                compressedPhoto = UIImage(data: compressedData)
            }
            
            let finalNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let log = LogEntry(
                id: existingLog?.id ?? UUID(),
                petId: petId,
                category: category,
                severity: category == .symptom ? severity : nil,
                note: finalNote.isEmpty ? nil : finalNote,
                photoLocalURL: existingLog?.photoLocalURL,
                photoImage: compressedPhoto,
                recordedAt: recordedAt
            )
            
            
            do {
                if existingLog != nil {
                    try await logStore.updateLog(log, userId: userId)
                } else {
                    try await logStore.saveLog(log, userId: userId)
                }
                
                await MainActor.run {
                    isSaving = false
                    showSuccess = true
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        toastManager.show(existingLog != nil ? "Log updated" : "Detailed log saved")
                        dismiss()
                    }
                }
            } catch {
                TelemetryEngine.shared.track(event: .error_occurred, properties: ["message": "Failed to save detailed log: \(error.localizedDescription)"])
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Failed to save log: \(error.localizedDescription)"
                    showErrorAlert = true
                }
            }
        }
    }
    
    private func deleteLog() {
        guard let log = existingLog else { return }
        Task {
            if let userId = await authManager.getCurrentUserId() {
                do {
                    try await logStore.deleteLog(log, userId: userId)
                    await MainActor.run {
                        toastManager.show("Log deleted")
                        dismiss()
                    }
                } catch {
                    TelemetryEngine.shared.track(event: .error_occurred, properties: ["message": "Failed to delete log: \(error.localizedDescription)"])
                    await MainActor.run {
                        errorMessage = "Failed to delete log: \(error.localizedDescription)"
                        showErrorAlert = true
                    }
                }
            }
        }
    }
    
    private func triggerErrorShake() {
        showErrorShake = true
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showErrorShake = false
        }
    }
}
