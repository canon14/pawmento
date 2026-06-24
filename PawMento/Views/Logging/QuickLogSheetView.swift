import SwiftUI

struct QuickLogSheetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var petStore: PetStore
    @EnvironmentObject var logStore: LogStore
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    @State private var selectedCategory: LogCategory?
    @State private var severity: Int = 1
    @State private var note: String = ""
    @State private var dose: String = ""
    @State private var photo: UIImage?
    
    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var showErrorShake = false
    
    @State private var errorMessage = ""
    @State private var showErrorAlert = false
    
    @State private var showDraftBanner = false
    @State private var draftToRestore: QuickLogDraft?
    
    @State private var showDetailedLog = false
    
    @State private var sheetOpenedAt: Date?
    
    private var draftKey: String {
        "quickLogDraft_\(petStore.activePet?.id.uuidString ?? "")"
    }
    
    private var hasContent: Bool {
        !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (selectedCategory == .med && !dose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
    
    var body: some View {
        ZStack {
            Color.warmCream.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(AppStrings.QuickLog.title)
                            .font(.headlineSM)
                            .foregroundColor(.primaryText)
                        
                        // Subtitle
                        let petName = petStore.activePet?.name ?? "your pet"
                        Text(AppStrings.QuickLog.subtitleJustNow(petName))
                            .font(.bodyXS)
                            .foregroundColor(.secondaryText)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        TelemetryEngine.shared.track(event: .quick_log_cancelled, properties: ["had_changes": !note.isEmpty || selectedCategory != nil])
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.tertiaryText)
                            .frame(width: 32, height: 32)
                            .background(Color.surface0)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                
                // Padding instead of harsh divider
                Color.clear.frame(height: 24)
                
                if showDraftBanner, let draft = draftToRestore {
                    HStack(spacing: 12) {
                        Text(AppStrings.QuickLog.restoreUnsavedLog)
                            .font(.labelSM)
                        Spacer()
                        Button(AppStrings.QuickLog.restore) {
                            if let catVal = draft.categoryRawValue, let cat = LogCategory(rawValue: catVal) {
                                selectedCategory = cat
                            }
                            note = draft.note ?? ""
                            severity = draft.severity ?? 1
                            dose = ""
                            showDraftBanner = false
                            UserDefaults.standard.removeObject(forKey: draftKey)
                        }
                        .font(.labelSM)
                        .foregroundColor(.primary)
                        
                        Button(AppStrings.QuickLog.discard) {
                            showDraftBanner = false
                            UserDefaults.standard.removeObject(forKey: draftKey)
                        }
                        .font(.labelSM)
                        .foregroundColor(.tertiaryText)
                    }
                    .padding()
                    .background(Color.cream)
                    .cornerRadius(AppRadius.input)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                
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
                        
                        if selectedCategory == .med {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Medication Dose")
                                    .font(.labelSM)
                                    .foregroundColor(.primaryText)
                                TextField("e.g. 16mg, 1 tablet", text: $dose)
                                    .padding()
                                    .background(Color.surface0)
                                    .cornerRadius(16)
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.05), lineWidth: 1))
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 24) // Spacing before the sticky footer
                }
                .scrollDismissesKeyboard(.interactively)
                
            }
            .safeAreaInset(edge: .bottom) {
                // Floating Glass Footer
                VStack(spacing: 12) {
                    let isDisabled = selectedCategory == nil || !hasContent
                    
                    Button(action: saveLog) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 8)
                            } else if showSuccess {
                                Image(systemName: "checkmark")
                                    .font(.headlineSM)
                            } else {
                                Text(AppStrings.QuickLog.save)
                                    .font(.headlineSM)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: isDisabled
                                    ? [Color.primary.opacity(0.35), Color.primary.opacity(0.25)]
                                    : [Color.primary, Color.primary.opacity(0.85)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.input))
                        .shadow(
                            color: isDisabled ? Color.clear : Color.primary.opacity(0.3),
                            radius: isDisabled ? 0 : 8,
                            x: 0,
                            y: isDisabled ? 0 : 4
                        )
                        .scaleEffect(isDisabled ? 0.97 : (isSaving ? 0.95 : 1.0))
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isDisabled)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSaving)
                    }
                    .disabled(isDisabled || isSaving || showSuccess)
                    .offset(x: showErrorShake && !reduceMotion ? 8 : 0)
                    .animation(
                        showErrorShake && !reduceMotion
                            ? .spring(response: 0.12, dampingFraction: 0.2).repeatCount(3)
                            : .default,
                        value: showErrorShake
                    )
                    
                    Button(AppStrings.QuickLog.moreDetails) {
                        TelemetryEngine.shared.track(event: .quick_log_more_details_tapped, properties: [
                            "carries_photo": photo != nil,
                            "has_note": !note.isEmpty
                        ])
                        showDetailedLog = true
                    }
                    .font(.labelMD)
                    .foregroundColor(.primary)
                    .padding(.bottom, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16)
                .background(
                    Color.surfaceContainerLowest.opacity(0.8)
                        .background(.ultraThinMaterial)
                )
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.primary.opacity(0.05)),
                    alignment: .top
                )
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .fullScreenCover(isPresented: $showDetailedLog) {
            LogDetailSheet(
                initialCategory: selectedCategory,
                initialSeverity: severity,
                initialNote: note,
                initialPhoto: photo
            )
        }
        .onAppear {
            if let data = UserDefaults.standard.data(forKey: draftKey),
               let draft = try? JSONDecoder().decode(QuickLogDraft.self, from: data) {
                if abs(draft.savedAt.timeIntervalSinceNow) < 300 { // 5 mins
                    draftToRestore = draft
                    showDraftBanner = true
                } else {
                    UserDefaults.standard.removeObject(forKey: draftKey)
                }
            }
            
            if !showDraftBanner, let activePet = petStore.activePet {
                selectedCategory = logStore.getLastUsedCategory(for: activePet.id)
                if selectedCategory != nil {
                    TelemetryEngine.shared.track(event: .quick_log_category_selected, properties: [
                        "category": selectedCategory!.rawValue,
                        "was_preselected": true
                    ])
                }
            }
            
            sheetOpenedAt = Date()
            TelemetryEngine.shared.track(event: .quick_log_opened)
        }
        .onDisappear {
            if !isSaving && !showSuccess {
                if !note.isEmpty || selectedCategory != nil {
                    if let petId = petStore.activePet?.id {
                        let draft = QuickLogDraft(
                            petId: petId,
                            categoryRawValue: selectedCategory?.rawValue,
                            note: note,
                            severity: severity,
                            savedAt: Date()
                        )
                        if let data = try? JSONEncoder().encode(draft) {
                            UserDefaults.standard.set(data, forKey: draftKey)
                        }
                    }
                }
            } else if showSuccess {
                UserDefaults.standard.removeObject(forKey: draftKey)
            }
        }
    }
    
    private func saveLog() {
        guard let category = selectedCategory, let petId = petStore.activePet?.id, hasContent else {
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
        
        Task {
            guard let userId = await authManager.getCurrentUserId() else {
                await MainActor.run {
                    isSaving = false
                    showErrorShake = true
                }
                return
            }
            
            var compressedPhoto: UIImage? = nil
            if let img = photo, let compressedData = img.jpegData(compressionQuality: 0.5) {
                compressedPhoto = UIImage(data: compressedData)
            }
            
            var finalNote = note
            if category == .med && !dose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let doseText = "Dose: \(dose.trimmingCharacters(in: .whitespacesAndNewlines))"
                finalNote = note.isEmpty ? doseText : "\(doseText)\n\n\(note)"
            }
            let noteToSave = finalNote.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let log = LogEntry(
                petId: petId,
                category: category,
                severity: category == .symptom ? severity : nil,
                note: noteToSave.isEmpty ? nil : noteToSave,
                photoLocalURL: nil,
                photoImage: compressedPhoto
            )
            
            do {
                try await logStore.saveLog(log, userId: userId)
                
                await MainActor.run {
                    isSaving = false
                    showSuccess = true
                    let successGenerator = UINotificationFeedbackGenerator()
                    successGenerator.notificationOccurred(.success)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        let petName = petStore.activePet?.name ?? "your pet"
                        
                        var timeToSaveMs = 0
                        if let opened = sheetOpenedAt {
                            timeToSaveMs = Int(Date().timeIntervalSince(opened) * 1000)
                        }
                        
                        TelemetryEngine.shared.track(event: .quick_log_saved, properties: [
                            "time_to_save_ms": timeToSaveMs,
                            "has_photo": photo != nil,
                            "has_note": !note.isEmpty,
                            "category": category.rawValue,
                            "severity": category == .symptom ? severity : -1
                        ])
                        
                        toastManager.show(AppStrings.QuickLog.loggedFor(petName), actionLabel: AppStrings.QuickLog.undo) {
                            // Undo logic
                            TelemetryEngine.shared.track(event: .quick_log_undo_tapped, properties: ["delete_log_id": log.id.uuidString])
                            if let index = logStore.logs.firstIndex(where: { $0.id == log.id }) {
                                logStore.logs.remove(at: index)
                            }
                        }
                        dismiss()
                    }
                }
            } catch {
                TelemetryEngine.shared.track(event: .error_occurred, properties: ["message": "Failed to save quick log: \(error.localizedDescription)"])
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Failed to save log: \(error.localizedDescription)"
                    showErrorAlert = true
                }
            }
        }
    }
}
