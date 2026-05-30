import SwiftUI

struct WellnessScoreHero: View {
    @EnvironmentObject var petStore: PetStore
    @State private var progress: CGFloat = 0.0
    
    var body: some View {
        let petName = petStore.activePet?.name ?? "Your pet"
        
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                // Background Gradient
                RadialGradient(
                    gradient: Gradient(colors: [Color(hex: "#F7F3ED"), Color(hex: "#FFFDF9")]),
                    center: .top,
                    startRadius: 0,
                    endRadius: 200
                )
                
                // Content
                VStack(spacing: 0) {
                    
                    ZStack {
                        // Progress Ring Background
                        Circle()
                            .stroke(Color(hex: "#F5F3EF"), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        
                        // Progress Ring Active
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.primary, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 1.0).delay(0.1), value: progress)
                        
                        // Score Text
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            Text("78")
                                .font(.headlineXL)
                                .foregroundColor(.primary)
                            Text("/100")
                                .font(.labelMD)
                                .foregroundColor(.onSurfaceVariant)
                        }
                    }
                    .frame(width: 160, height: 160)
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                    
                    Text("\(petName)'s having a good day ✨")
                        .font(.headlineSM)
                        .foregroundColor(.onSurface)
                        .padding(.bottom, 8)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14, weight: .bold))
                        Text("Up 4 points from yesterday")
                            .font(.labelMD)
                    }
                    .foregroundColor(Color.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.primaryContainer.opacity(0.3))
                    .clipShape(Capsule())
                    .padding(.bottom, 20)
                    
                    Button(action: {
                        // View trends action
                    }) {
                        HStack(spacing: 4) {
                            Text("View trends")
                                .font(.labelMD)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity)
                
                // Premium Badge
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                    Text("Premium")
                        .font(.labelSM)
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.secondaryContainer.opacity(0.5))
                .clipShape(Capsule())
                .padding(20)
            }
        }
        .background(Color.surfaceContainerLowest)
        .cornerRadius(24)
        .warmShadow()
        .onAppear {
            progress = 0.78
        }
    }
}

#Preview {
    WellnessScoreHero()
        .environmentObject(PetStore())
        .padding()
        .background(Color.background)
}
