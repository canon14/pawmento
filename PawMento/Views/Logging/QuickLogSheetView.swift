import SwiftUI

struct QuickLogSheetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var petStore: PetStore
    @EnvironmentObject var logStore: LogStore
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    @State private var selectedCategory: LogCategory?
    @State private var severity: Int = 1
    @State private var note: String = ""
    @State private var photo: UIImage?
    
    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var showErrorShake = false
    
    @State private var showDraftBanner = false
    @State private var draftToRestore: QuickLogDraft?
    
    @State private var sheetOpenedAt: Date?
    
    private var draftKey: String {
        "quickLogDraft_\(petStore.activePet?.id.uuidString ?? "")"
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
                            .font(.labelRegular)
                            .foregroundColor(.secondaryText)
                    }
                    
                    Spacer()
                    
                    Button(AppStrings.QuickLog.cancel) {
                        TelemetryEngine.shared.track(event: .quick_log_cancelled, properties: ["had_changes": !note.isEmpty || selectedCategory != nil])
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
                            showDraftBanner = false
                            UserDefaults.standard.removeObject(forKey: draftKey)
                        }
                        .font(.labelSemibold)
                        .foregroundColor(.warmTan)
                        
                        Button(AppStrings.QuickLog.discard) {
                            showDraftBanner = false
                            UserDefaults.standard.removeObject(forKey: draftKey)
                        }
                        .font(.labelSemibold)
                        .foregroundColor(.tertiaryText)
                    }
                    .padding()
                    .background(Color.cream)
                    .cornerRadius(12)
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
                                Text(AppStrings.QuickLog.save)
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
                    .offset(x: showErrorShake && !reduceMotion ? 10 : -10)
                    .animation(showErrorShake && !reduceMotion ? Animation.default.repeatCount(3).speed(4) : .default, value: showErrorShake)
                    
                    Button(AppStrings.QuickLog.moreDetails) {
                        TelemetryEngine.shared.track(event: .quick_log_more_details_tapped, properties: [
                            "carries_photo": photo != nil,
                            "has_note": !note.isEmpty
                        ])
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
    }
}
