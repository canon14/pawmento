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
                        .font(.system(size: 12))
                        .foregroundColor(.warmTan)
                }
            }
            .sheet(isPresented: $showSwitcher) {
                PetSwitcherSheet(isPresented: $showSwitcher)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: { showActionMenu = true }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 17))
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
                
                Button("Edit") {
                    showEditSheet = true
                }
                .font(.system(size: 17))
                .foregroundColor(.warmTan)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(Color.cream)
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
                .shadow(color: viewModel.wellnessScore >= 80 ? Color.sage.opacity(0.4) : Color.clear, radius: 10, x: 0, y: 0)
                
                // Identity Stack
                VStack(alignment: .leading, spacing: 2) {
                    Text(pet.name)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.primaryText)
                    
                    Text(pet.breed ?? "Mixed Breed")
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)
                    
                    Text("\(ageString) · \(Int(pet.weightKg ?? 0)) lbs")
                        .font(.system(size: 13))
                        .foregroundColor(.tertiaryText)
                    
                    Text("Neutered male") // Mock
                        .font(.system(size: 13))
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
                        .stroke(Color.warmSand, lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.wellnessScore) / 100.0)
                        .stroke(ringColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.8), value: viewModel.wellnessScore)
                    
                    Text("\(viewModel.wellnessScore)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primaryText)
                }
                .frame(width: 80, height: 80)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Wellness Score")
                        .font(.system(size: 15, weight: .semibold))
                    HStack(spacing: 8) {
                        Text(viewModel.scoreTrend)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(trendColor)
                        Text(viewModel.scoreDelta)
                            .font(.system(size: 12))
                            .foregroundColor(.secondaryText)
                    }
                }
                .padding(.leading, 12)
                
                Spacer()
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onEnded { value in
                    // Simple swipe logic: Left or Right to switch pets
                    let pets = petStore.pets
                    guard pets.count > 1, let currentIndex = pets.firstIndex(where: { $0.id == pet.id }) else { return }
                    
                    if value.translation.width < -50 { // Swipe Left (Next)
                        let nextIndex = (currentIndex + 1) % pets.count
                        petStore.activePet = pets[nextIndex]
                    } else if value.translation.width > 50 { // Swipe Right (Previous)
                        let prevIndex = (currentIndex - 1 + pets.count) % pets.count
                        petStore.activePet = pets[prevIndex]
                    }
                }
        )
    }
    
    private var ringColor: Color {
        if viewModel.wellnessScore >= 80 { return .sage }
        if viewModel.wellnessScore >= 60 { return .warmTan }
        return .warmCoral
    }
    
    private var trendColor: Color {
        if viewModel.scoreTrend.contains("↗") { return .sage }
        if viewModel.scoreTrend.contains("↘") { return .warmCoral }
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
                    .foregroundColor(.warmTan)
                    .font(.system(size: 20))
                Text("AI Coach · \(pet.name)")
                    .font(.system(size: 13, weight: .semibold))
            }
            
            if viewModel.isGeneratingInsight {
                HStack {
                    ProgressView()
                    Text("Thinking...")
                        .font(.system(size: 15))
                        .foregroundColor(.secondaryText)
                }
            } else {
                Text(viewModel.aiInsight ?? "Log \(pet.name) for a few more days and I'll start noticing patterns.")
                    .font(.system(size: 15))
                    .foregroundColor(.primaryText)
                    .lineSpacing(4)
            }
            
            Button(action: { showPaywall = true }) {
                HStack {
                    Spacer()
                    Text("See Full Pattern Analysis")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.warmTan)
                    Spacer()
                    Text("Premium 🔒")
                        .font(.system(size: 11))
                        .foregroundColor(.warmTan)
                }
                .frame(height: 48)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.warmTan, lineWidth: 1))
            }
            .alert("PawMento Premium", isPresented: $showPaywall) {
                Button("Maybe Later", role: .cancel) {}
                Button("Upgrade") {}
            } message: {
                Text("Deep pattern analysis and predictive alerts are available with a Premium subscription.")
            }
            
            Button(action: { showCoach = true }) {
                Text("Ask the Coach about \(pet.name) →")
                    .font(.system(size: 14))
                    .foregroundColor(.warmTan)
            }
            .fullScreenCover(isPresented: $showCoach) {
                CoachChatView()
            }
        }
        .padding(20)
        .background(Color.cream)
        .cornerRadius(20)
    }
}

struct HealthStatsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Health Stats")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                Spacer()
                Text("Last 30 d")
                    .font(.system(size: 13))
                    .foregroundColor(.tertiaryText)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                StatTileView(title: "Energy", value: "6.2", trend: "↘ -18%", isPositive: false)
                StatTileView(title: "Appetite", value: "8.4", trend: "→ stable", isPositive: true)
                StatTileView(title: "Sleep", value: "13.2h", trend: "↗ +12%", isPositive: false)
                StatTileView(title: "Hydration", value: "1.4L", trend: "→ stable", isPositive: true)
            }
        }
    }
}

struct StatTileView: View {
    let title: String
    let value: String
    let trend: String
    let isPositive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primaryText)
            
            // Mock Sparkline
            Path { path in
                path.move(to: CGPoint(x: 0, y: 20))
                path.addLine(to: CGPoint(x: 20, y: 10))
                path.addLine(to: CGPoint(x: 40, y: 15))
                path.addLine(to: CGPoint(x: 60, y: 5))
                path.addLine(to: CGPoint(x: 80, y: 20))
            }
            .stroke(Color.warmTan, lineWidth: 2)
            .frame(height: 24)
            
            HStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.primaryText)
                
                Text(trend)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isPositive ? .sage : .warmCoral)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.warmSand, lineWidth: 0.5))
    }
}

struct RecentActivityPreview: View {
    let logs: [LogEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                Spacer()
                Text("See all \(max(logs.count, 247)) →")
                    .font(.system(size: 14))
                    .foregroundColor(.warmTan)
            }
            
            VStack(spacing: 0) {
                if logs.isEmpty {
                    Text("Log Buddy's first activity to see it here.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)
                        .padding()
                } else {
                    ForEach(logs.prefix(5)) { log in
                        HStack {
                            Text(log.category.emoji)
                                .font(.system(size: 24))
                            Text(log.category.rawValue)
                                .font(.system(size: 15))
                                .foregroundColor(.primaryText)
                            Spacer()
                            Text(log.note ?? "")
                                .font(.system(size: 14))
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
            .background(Color.white)
            .cornerRadius(16)
        }
    }
}

struct CareTeamCard: View {
    let providers: [MockCareProvider]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Care Team")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
            
            VStack(alignment: .leading, spacing: 12) {
                if let vet = providers.first {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vet.name)
                                .font(.system(size: 16, weight: .semibold))
                            Text(vet.role)
                                .font(.system(size: 13))
                                .foregroundColor(.tertiaryText)
                            
                            HStack {
                                Text("📞 \(vet.phone)")
                                    .foregroundColor(.warmTan)
                                Text("📍 \(vet.distance)")
                                    .foregroundColor(.primaryText)
                            }
                            .font(.system(size: 14))
                            .padding(.top, 4)
                        }
                        Spacer()
                        Text(vet.clinic)
                            .font(.system(size: 14, weight: .medium))
                    }
                    
                    Divider().background(Color.warmSand.opacity(0.3)).padding(.vertical, 4)
                    
                    Text("Emergency: BluePearl 24/7 · (555) 999-0000")
                        .font(.system(size: 14))
                    Text("Insurance: Trupanion · Policy #TR-449821")
                        .font(.system(size: 14))
                    Text("Microchip: 985 113 003 882 471")
                        .font(.system(size: 14))
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
    }
}

struct VetPDFCTACard: View {
    var body: some View {
        HStack(spacing: 12) {
            Text("📄")
                .font(.system(size: 28))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Generate Vet PDF for Buddy")
                    .font(.system(size: 16, weight: .semibold))
                Text("Last 30 days · 47 entries")
                    .font(.system(size: 13))
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            Text("Pro")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.warmTan)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .overlay(Capsule().stroke(Color.warmTan, lineWidth: 1))
        }
        .padding(18)
        .background(Color.cream)
        .cornerRadius(20)
    }
}

struct MedicationsCard: View {
    let medications: [Medication]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Medications & Routines")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
            
            VStack(spacing: 0) {
                ForEach(medications) { med in
                    HStack {
                        Text(med.name.contains("Apoquel") ? "💊" : "💉")
                            .font(.system(size: 24))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(med.name)
                                .font(.system(size: 15, weight: .medium))
                            
                            if med.streakCount > 0 {
                                Text("Logged today · \(med.streakCount) day streak ✓")
                                    .font(.system(size: 12))
                                    .foregroundColor(.sage)
                            } else if let nextDue = med.nextDueDate {
                                Text("Next: \(nextDue, formatter: shortDateFormatter)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondaryText)
                            } else {
                                Text("No streak")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondaryText)
                            }
                        }
                        Spacer()
                        Text(med.frequency)
                            .font(.system(size: 14))
                            .foregroundColor(.secondaryText)
                    }
                    .padding(16)
                    
                    if med.id != medications.last?.id {
                        Divider().background(Color.warmSand.opacity(0.2))
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(16)
        }
    }
}

let shortDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
    return formatter
}()
struct VitalRecordsList: View {
    let records = [
        "Vaccinations · Up to date · Next Aug 14",
        "Weight history · 68 lbs (stable)",
        "Allergies · Chicken, environmental",
        "Conditions · Atopic dermatitis"
    ]
    
    @State private var showManageRecords = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Vital Records")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                Spacer()
                Button(action: { showManageRecords = true }) {
                    Text("Manage →")
                        .font(.system(size: 14))
                        .foregroundColor(.warmTan)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(records, id: \.self) { record in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.warmTan)
                            .font(.system(size: 16, weight: .bold))
                        Text(record)
                            .font(.system(size: 15))
                            .foregroundColor(.primaryText)
                    }
                }
            }
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
    @EnvironmentObject var petStore: PetStore
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        Button(action: {
            showingFirstAlert = true
        }) {
            Text("Archive \(pet.name)'s profile")
                .font(.system(size: 15))
                .foregroundColor(.warmCoral)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.warmCoral, lineWidth: 1))
        }
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
                Task {
                    if let ownerId = await authManager.getCurrentUserId() {
                        await petStore.archivePet(pet, ownerId: ownerId)
                    }
                }
            }
        } message: {
            Text("This action will immediately remove \(pet.name) from your active pets.")
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
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
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
                                    Circle().stroke(petStore.activePet?.id == pet.id ? Color.sage : Color.clear, lineWidth: 3)
                                )
                                
                                Text(pet.name)
                                    .font(.system(size: 14, weight: petStore.activePet?.id == pet.id ? .semibold : .medium))
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
