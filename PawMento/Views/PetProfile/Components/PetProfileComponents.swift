struct FeatureFlags {
    static let isEllipsisActionsEnabled = false
}

import SwiftUI

struct PetProfileTopBar: View {
    let petName: String
    @EnvironmentObject var petStore: PetStore
    
    @State private var showSwitcher: Bool = false
    @State private var showEditSheet: Bool = false
    @State private var showActionMenu: Bool = false
    
    var body: some View {
        HStack {
            // Spacer to keep title centered since we removed the back button
            Spacer()
                .frame(width: 44)
            
            Spacer()
            
            Button(action: { showSwitcher = true }) {
                HStack(spacing: 4) {
                    Text(petName)
                        .font(.headlineSM)
                        .foregroundColor(.primaryText)
                    Image(systemName: "chevron.down")
                        .font(.captionTabular)
                        .foregroundColor(.primary)
                }
            }
            .sheet(isPresented: $showSwitcher) {
                PetSwitcherSheet(isPresented: $showSwitcher)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                if FeatureFlags.isEllipsisActionsEnabled {
                    Button(action: { showActionMenu = true }) {
                        Image(systemName: "ellipsis")
                            .font(.bodyLG)
                            .foregroundColor(.secondaryText)
                    }
                    .confirmationDialog("Profile Actions", isPresented: $showActionMenu, titleVisibility: .hidden) {
                        Button("Share Profile") {
                            // Implement sharing
                        }
                        Button("Export Medical History") {
                            // Implement export
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                }
                
                Button("Edit") {
                    showEditSheet = true
                }
                .font(.bodyLG)
                .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(
            Color.surfaceContainerLowest.opacity(0.8)
                .background(.ultraThinMaterial)
        )
        .sheet(isPresented: $showEditSheet) {
            if let activePet = petStore.activePet {
                EditPetSheet(editingPet: activePet)
            }
        }
    }
}

struct HeroCardView: View {
    let pet: Pet
    @ObservedObject var viewModel: PetProfileViewModel
    @EnvironmentObject var petStore: PetStore
    
    var body: some View {
        VStack {
            HStack(spacing: 16) {
                // Photo Well
                ZStack {
                    if let photoURL = pet.photoLocalURL {
                        CachedAsyncImage(url: photoURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.warmSand
                                .overlay(ProgressView())
                        }
                    } else if let image = pet.photoImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.warmSand
                    }
                }
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(Color.warmSand, lineWidth: 4)
                )
                .shadow(color: viewModel.wellnessScore >= 80 ? Color.primary.opacity(0.4) : Color.clear, radius: 16, x: 0, y: 8)
                
                // Identity Stack
                VStack(alignment: .leading, spacing: 2) {
                    Text(pet.name)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.primaryText)
                    
                    Text(pet.breed ?? "Mixed Breed")
                        .font(.bodySM)
                        .foregroundColor(.secondaryText)
                    
                    Text("\(ageString) · \(formattedWeight)")
                        .font(.bodyXS)
                        .foregroundColor(.tertiaryText)
                }
                
                Spacer()
            }
            
            Divider()
                .padding(.vertical, 16)
            
            // Wellness Ring Row
            HStack {
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.05), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.wellnessScore) / 100.0)
                        .stroke(LinearGradient(colors: [ringColor, ringColor.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.8), value: viewModel.wellnessScore)
                    
                    Text("\(viewModel.wellnessScore)")
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .font(.headlineLG)
                        .foregroundColor(.primaryText)
                }
                .frame(width: 80, height: 80)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Wellness Score")
                        .font(.labelMD)
                    HStack(spacing: 8) {
                        Text(viewModel.scoreTrend)
                            .font(.labelSM)
                            .foregroundColor(trendColor)
                        Text(viewModel.scoreDelta)
                            .font(.captionTabular)
                            .foregroundColor(.secondaryText)
                    }
                }
                .padding(.leading, 12)
                
                Spacer()
            }
        }
        .padding(20)
        .background(Color.surfaceContainerLowest)
        .cornerRadius(AppRadius.card)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        .contentShape(Rectangle())
    }
    
    private var formattedWeight: String {
        guard let kg = pet.weightKg else { return "Unknown weight" }
        let isMetric = Locale.current.measurementSystem == .metric
        if isMetric {
            return "\(Int(round(kg))) kg"
        } else {
            let lbs = kg * 2.20462
            return "\(Int(round(lbs))) lbs"
        }
    }
    
    private var ringColor: Color {
        if viewModel.wellnessScore >= 80 { return .primary }
        if viewModel.wellnessScore >= 60 { return .amber }
        return .error
    }
    
    private var trendColor: Color {
        if viewModel.scoreTrend.contains("↗") { return .primary }
        if viewModel.scoreTrend.contains("↘") { return .error }
        return .secondaryText
    }
    
    private var ageString: String {
        guard let bday = pet.birthday, let bdayDate = Calendar.current.date(from: bday),
              let year = Calendar.current.dateComponents([.year], from: bdayDate, to: Date()).year else { return "Unknown age" }
        return "\(year) yrs"
    }
}

struct AICoachCardView: View {
    let pet: Pet
    @ObservedObject var viewModel: PetProfileViewModel
    @State private var showPaywall = false
    @State private var showCoach = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "pawprint.fill")
                    .foregroundColor(.primary)
                    .font(.headlineSM)
                Text("AI Coach · \(pet.name)")
                    .font(.labelSM)
            }
            
            if viewModel.isGeneratingInsight {
                HStack {
                    ProgressView()
                    Text("Thinking...")
                        .font(.labelMD)
                        .foregroundColor(.secondaryText)
                }
            } else {
                Text(viewModel.aiInsight ?? "Log \(pet.name) for a few more days and I'll start noticing patterns.")
                    .font(.labelMD)
                    .foregroundColor(.primaryText)
                    .lineSpacing(4)
            }
            
            Button(action: { showPaywall = true }) {
                HStack {
                    Spacer()
                    Text("See Full Pattern Analysis")
                        .font(.labelMD)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("Premium 🔒")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(LinearGradient(colors: [Color.primary, Color.primary.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .clipShape(Capsule())
                }
                .frame(height: 48)
                .background(Color.surfaceContainerLowest)
                .cornerRadius(AppRadius.input)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary, lineWidth: 1))
            }
            .alert("PawMento Premium", isPresented: $showPaywall) {
                Button("Maybe Later", role: .cancel) {}
                Button("Upgrade") {}
            } message: {
                Text("Deep pattern analysis and predictive alerts are available with a Premium subscription.")
            }
            
            Button(action: { showCoach = true }) {
                HStack {
                    Text("Ask the Coach about \(pet.name)")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.labelSM)
                .foregroundColor(.white)
                .padding()
                .background(Color.primary)
                .cornerRadius(16)
            }
            .buttonStyle(SquishyCardStyle())
            .fullScreenCover(isPresented: $showCoach) {
                CoachChatView()
            }
        }
        .padding(20)
        .background(
            Color.surfaceContainerLowest.opacity(0.8)
                .background(.ultraThinMaterial)
        )
        .cornerRadius(AppRadius.card)
    }
}

struct HealthStatsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SectionHeader("Health Stats")
                Spacer()
                Text("Last 30 d")
                    .font(.bodyXS)
                    .foregroundColor(.tertiaryText)
            }
            
            VStack(spacing: 8) {
                Text("Not enough data yet")
                    .font(.labelMD)
                    .foregroundColor(.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(20)
            .background(Color.surfaceContainerLowest)
            .cornerRadius(AppRadius.md)
        }
    }
}

struct RecentActivityPreview: View {
    let logs: [LogEntry]
    let petName: String
    
    @State private var showTimeline = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SectionHeader("Recent Activity")
                Spacer()
                Button(action: { showTimeline = true }) {
                    Text("See all \(logs.count) →")
                        .font(.bodySM)
                        .foregroundColor(.primary)
                }
            }
            
            VStack(spacing: 0) {
                if logs.isEmpty {
                    Text("Log \(petName)'s first activity to see it here.")
                        .font(.bodySM)
                        .foregroundColor(.secondaryText)
                        .padding()
                } else {
                    ForEach(logs.prefix(5)) { log in
                        HStack {
                            Text(log.category.emoji)
                                .font(.headlineMD)
                            Text(log.category.rawValue)
                                .font(.labelMD)
                                .foregroundColor(.primaryText)
                            Spacer()
                            Text(log.note ?? "")
                                .font(.bodySM)
                                .foregroundColor(.secondaryText)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(maxWidth: 100, alignment: .trailing)
                        }
                        .frame(height: 56)
                        .padding(.horizontal, 16)
                        
                        if log.id != logs.prefix(5).last?.id {
                            Divider().background(Color.warmSand.opacity(0.2))
                        }
                    }
                }
            }
            .background(Color.surfaceContainerLowest)
            .cornerRadius(AppRadius.md)
        }
        .sheet(isPresented: $showTimeline) {
            FullTimelineView()
        }
    }
}

struct CareTeamCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader("Care Team")
            
            VStack(alignment: .leading, spacing: 12) {
                Text("No care team added yet.")
                    .font(.labelMD)
                    .foregroundColor(.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color.surfaceContainerLowest)
            .cornerRadius(AppRadius.card)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
    }
}

struct VetPDFCTACard: View {
    let logCount: Int
    @State private var showPaywall = false
    
    var body: some View {
        Button(action: { showPaywall = true }) {
            HStack(spacing: 12) {
                Text("📄")
                    .font(.displaySM)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Generate Vet PDF")
                        .font(.bodyMD)
                        .foregroundColor(.primaryText)
                    Text("Last 30 days · \(logCount) entries")
                        .font(.bodyXS)
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                Text("Pro")
                    .font(.captionTabular)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .overlay(Capsule().stroke(Color.primary, lineWidth: 1))
            }
            .padding(18)
            .background(
            Color.surfaceContainerLowest.opacity(0.8)
                .background(.ultraThinMaterial)
        )
            .cornerRadius(AppRadius.card)
        }
        .alert("PawMento Premium", isPresented: $showPaywall) {
            Button("Maybe Later", role: .cancel) {}
            Button("Upgrade") {}
        } message: {
            Text("Generate professional PDF reports to share with your vet, available with a Premium subscription.")
        }
    }
}

let shortDateAndTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, h:mm a"
    return formatter
}()

struct MedicationsCard: View {
    let medications: [Medication]
    var onMedicationsChanged: (() -> Void)? = nil
    
    @EnvironmentObject private var medicationStore: MedicationStore
    
    @State private var showAddSheet = false
    @State private var editingMedication: Medication?
    @State private var loggingMedicationId: UUID?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SectionHeader("Medications & Routines")
                Spacer()
                Button(action: { showAddSheet = true }) {
                    Text("Add Medication")
                        .font(.bodySM)
                        .foregroundColor(.primary)
                }
            }
            
            if medications.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("No medications or routines added yet.")
                        .font(.labelMD)
                        .foregroundColor(.secondaryText)
                    
                    Button(action: { showAddSheet = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add your first medication")
                        }
                        .font(.labelMD)
                        .foregroundColor(.primary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.surfaceContainerLowest)
                .cornerRadius(AppRadius.md)
            } else {
                VStack(spacing: 0) {
                    ForEach(medications) { med in
                        medicationRow(med)
                        
                        if med.id != medications.last?.id {
                            Divider().background(Color.warmSand.opacity(0.2))
                        }
                    }
                }
                .background(Color.surfaceContainerLowest)
                .cornerRadius(AppRadius.md)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            MedicationSheet()
                .onDisappear { onMedicationsChanged?() }
        }
        .sheet(item: $editingMedication) { medication in
            MedicationSheet(existingMedication: medication)
                .onDisappear { onMedicationsChanged?() }
        }
    }
    
    @ViewBuilder
    private func medicationRow(_ med: Medication) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(med.form?.lowercased() == "injectable" ? "💉" : "💊")
                .font(.headlineMD)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("\(med.name)\(med.dose.map { " · \($0)" } ?? "")")
                    .font(.labelMD)
                
                if med.loggedToday {
                    Text("Logged today · \(med.streakCount) day streak ✓")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.primary.opacity(0.1))
                        .clipShape(Capsule())
                } else if let nextDue = med.nextDueDate {
                    if nextDue < Date() {
                        Text("Overdue: \(nextDue, formatter: shortDateAndTimeFormatter)")
                            .font(.captionTabular)
                            .foregroundColor(.error)
                    } else {
                        Text("Next: \(nextDue, formatter: shortDateAndTimeFormatter)")
                            .font(.captionTabular)
                            .foregroundColor(.secondaryText)
                    }
                } else {
                    Text(med.streakCount > 0 ? "\(med.streakCount) day streak" : "No streak")
                        .font(.captionTabular)
                        .foregroundColor(.secondaryText)
                }
                
                HStack(spacing: 8) {
                    if med.medicationFrequency != .asNeeded {
                        Button(action: { Task { await logDose(for: med) } }) {
                            HStack(spacing: 4) {
                                if loggingMedicationId == med.id {
                                    ProgressView()
                                        .controlSize(.small)
                                }
                                Text(med.loggedToday ? "Logged" : "Log Dose")
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundColor(med.loggedToday ? .secondaryText : .white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(med.loggedToday ? Color.warmSand.opacity(0.3) : Color.primary)
                            .clipShape(Capsule())
                        }
                        .disabled(med.loggedToday || loggingMedicationId == med.id)
                    }
                    
                    Button("Edit") {
                        editingMedication = med
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primary)
                }
            }
            
            Spacer(minLength: 0)
            
            Text(med.frequency)
                .font(.bodySM)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.trailing)
        }
        .padding(16)
    }
    
    private func logDose(for medication: Medication) async {
        loggingMedicationId = medication.id
        defer { loggingMedicationId = nil }
        
        do {
            try await medicationStore.logDoseTaken(medication)
            ToastManager.shared.show("Dose logged for \(medication.name)")
            onMedicationsChanged?()
        } catch let error as MedicationStoreError {
            ToastManager.shared.show(error.localizedDescription, duration: 4.0)
        } catch {
            ToastManager.shared.show("Failed to log dose. Check your connection.", duration: 4.0)
        }
    }
}

let shortDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
    return formatter
}()
struct VitalRecordsList: View {
    @State private var showManageRecords = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SectionHeader("Vital Records")
                Spacer()
                Button(action: { showManageRecords = true }) {
                    Text("Manage →")
                        .font(.bodySM)
                        .foregroundColor(.primary)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("No vital records added yet.")
                    .font(.labelMD)
                    .foregroundColor(.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.surfaceContainerLowest)
            .cornerRadius(AppRadius.md)
        }
        .sheet(isPresented: $showManageRecords) {
            ManageRecordsSheet()
        }
    }
}

struct ArchiveButton: View {
    let pet: Pet
    @State private var showingFirstAlert = false
    @State private var showingSecondAlert = false
    @State private var isArchiving = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @EnvironmentObject var petStore: PetStore
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        Button(action: {
            showingFirstAlert = true
        }) {
            HStack {
                if isArchiving {
                    ProgressView().tint(.error).padding(.trailing, 8)
                }
                Text(isArchiving ? "Archiving..." : "Archive \(pet.name)'s profile")
            }
                .font(.labelMD)
                .foregroundColor(.error)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.error.opacity(0.1))
                .cornerRadius(16)
        }
        .buttonStyle(SquishyCardStyle())
        .disabled(isArchiving)
        .alert("Archive \(pet.name)?", isPresented: $showingFirstAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Yes, Archive", role: .destructive) {
                showingSecondAlert = true
            }
        } message: {
            Text("This will hide \(pet.name) from your dashboard. You can restore them within 90 days from Settings.")
        }
        .alert("Are you absolutely sure?", isPresented: $showingSecondAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Archive", role: .destructive) {
                isArchiving = true
                Task {
                    if let ownerId = await authManager.getCurrentUserId() {
                        do {
                            try await petStore.archivePet(pet, ownerId: ownerId)
                        } catch {
                            TelemetryEngine.shared.track(event: .error_occurred, properties: ["message": "Failed to archive pet: \(error.localizedDescription)"])
                            await MainActor.run {
                                errorMessage = "Failed to archive profile: \(error.localizedDescription)"
                                showErrorAlert = true
                                isArchiving = false
                            }
                        }
                    } else {
                        isArchiving = false
                    }
                }
            }
        } message: {
            Text("This action will immediately remove \(pet.name) from your active pets.")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

struct PetSwitcherSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var petStore: PetStore
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Switch Pet")
                    .font(.headlineSM)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.headlineMD)
                        .foregroundColor(.warmSand)
                }
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(petStore.pets) { pet in
                        Button(action: {
                            petStore.activePet = pet
                            isPresented = false
                        }) {
                            VStack {
                                ZStack {
                                    if let url = pet.photoLocalURL {
                                        CachedAsyncImage(url: url) { image in
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Color.warmSand
                                        }
                                    } else if let image = pet.photoImage {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } else {
                                        Color.warmSand
                                    }
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .overlay(
                                    Circle().stroke(petStore.activePet?.id == pet.id ? Color.primary : Color.clear, lineWidth: 3)
                                )
                                
                                Text(pet.name)
                                    .font(.bodySM)
                                    .foregroundColor(.primaryText)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            Spacer()
        }
        .presentationDetents([.height(220)])
        .presentationDragIndicator(.visible)
        .background(Color.cream.ignoresSafeArea())
    }
}
