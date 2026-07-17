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
