import SwiftUI

struct TopHeaderView: View {
    @EnvironmentObject var petStore: PetStore
    @State private var showSettings = false
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                if let pet = petStore.activePet, let image = pet.photoImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                } else {
                    let emoji: String = {
                        guard let pet = petStore.activePet else { return "🐾" }
                        switch pet.species {
                        case .dog: return "🐶"
                        case .cat: return "🐱"
                        case .rabbit: return "🐰"
                        case .other: return "🐾"
                        }
                    }()
                    
                    Circle()
                        .fill(Color.primaryContainer)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(emoji)
                                .font(.system(size: 20))
                        )
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(greetingTimeOfDay) ☀️")
                        .font(.headlineSM)
                        .foregroundColor(.primary)
                        .tracking(-0.5) // tracking-tight
                    
                    Text(formattedDate)
                        .font(.labelMD)
                        .foregroundColor(.onSurfaceVariant)
                }
            }
            
            Spacer()
            
            Button(action: {
                showSettings = true
            }) {
                Image(systemName: "gear") // Replaced bell with gear
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
    
    private var greetingTimeOfDay: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 18 { return "Good afternoon" }
        return "Good evening"
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }
}

#Preview {
    TopHeaderView()
}
