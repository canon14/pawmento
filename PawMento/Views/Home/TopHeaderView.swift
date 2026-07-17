import SwiftUI

struct TopHeaderView: View {
    @EnvironmentObject var petStore: PetStore
    var loggingStreak: Int = 0
    @State private var showSettings = false
    
    // Time-of-day aware emoji
    private var greetingEmoji: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 6 { return "🌙" }
        if hour < 12 { return "☀️" }
        if hour < 18 { return "🌤️" }
        return "🌙"
    }
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                // Pet avatar: prefer photoImage → photoLocalURL → species emoji
                Group {
                    if let pet = petStore.activePet, let image = pet.photoImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else if let pet = petStore.activePet, let photoURL = pet.photoLocalURL {
                        CachedAsyncImage(url: photoURL) { img in
                            img.resizable().scaledToFill()
                        } placeholder: {
                            speciesEmojiCircle
                        }
                    } else {
                        speciesEmojiCircle
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(greetingTimeOfDay) \(greetingEmoji)")
                        .font(.headlineSM)
                        .foregroundColor(.primary)
                        .tracking(-0.5)
                    
                    HStack(spacing: 8) {
                        Text(formattedDate)
                            .font(.labelMD)
                            .foregroundColor(.onSurfaceVariant)
                        
                        if petStore.activePet != nil {
                            StreakChip(streak: loggingStreak)
                        }
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                showSettings = true
            }) {
                Image(systemName: "gear")
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
                    .background(Color.surfaceContainer)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.background)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
    
    // MARK: - Species emoji fallback (no photo available)
    
    private var speciesEmojiCircle: some View {
        let emoji: String = {
            guard let pet = petStore.activePet else { return "🐾" }
            switch pet.species {
            case .dog: return "🐶"
            case .cat: return "🐱"
            case .rabbit: return "🐰"
            case .other: return "🐾"
            }
        }()
        
        return Circle()
            .fill(Color.primaryContainer)
            .frame(width: 40, height: 40)
            .overlay(
                Text(emoji)
                    .font(.headlineMD)
            )
    }
    
    private var greetingTimeOfDay: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 18 { return "Good afternoon" }
        return "Good evening"
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }()
    
    private var formattedDate: String {
        Self.dateFormatter.string(from: Date())
    }
}

#Preview {
    TopHeaderView()
        .environmentObject(PetStore())
}
