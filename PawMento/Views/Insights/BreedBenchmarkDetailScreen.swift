import SwiftUI

struct BreedBenchmarkDetailScreen: View {
    @Environment(\.dismiss) var dismiss
    let benchmark: BreedBenchmark
    let petName: String
    var onAskCoach: () -> Void
    
    @State private var animateGauges = false
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    
                    // Header
                    VStack(spacing: 8) {
                        Text("How \(petName) Compares")
                            .font(.headlineLG)
                            .foregroundColor(.primaryText)
                        
                        Text("to other \(benchmark.breed)s at age \(benchmark.age)")
                            .font(.bodyMD)
                            .foregroundColor(.secondaryText)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)
                    
                    // Gauges
                    VStack(spacing: 28) {
                        benchmarkGauge(
                            title: "Activity Level",
                            percentile: benchmark.activityPercentile,
                            color: .amber
                        )
                        
                        benchmarkGauge(
                            title: "Rest & Sleep",
                            percentile: benchmark.sleepPercentile,
                            color: .primary
                        )
                        
                        benchmarkGauge(
                            title: "Health Alerts",
                            percentile: benchmark.symptomsPercentile,
                            color: .coral500
                        )
                    }
                    .padding(.top, 8)
                    
                    // AI CTA
                    Button(action: {
                        dismiss()
                        onAskCoach()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16))
                            Text("Ask AI Coach about these results")
                                .font(.headlineSM)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(
                                colors: [Color.primary, Color.primary.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                        .shadow(color: Color.primary.opacity(0.2), radius: 6, x: 0, y: 3)
                    }
                    .padding(.top, 12)
                }
                .padding(20)
            }
            .background(Color.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.headlineLG)
                            .foregroundColor(.tertiaryText)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                    animateGauges = true
                }
            }
        }
    }
    
    @ViewBuilder
    private func benchmarkGauge(title: String, percentile: Int, color: Color) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text(title)
                    .font(.headlineSM)
                    .foregroundColor(.primaryText)
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                    Text("\(percentile)th Percentile")
                        .font(.labelSM)
                        .foregroundColor(color)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(color.opacity(0.12))
                .clipShape(Capsule())
            }
            
            // Animated Gauge Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.1))
                        .frame(height: 14)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(24, geo.size.width * CGFloat(percentile) / 100.0 * (animateGauges ? 1.0 : 0.0)),
                            height: 14
                        )
                    
                    // Indicator dot
                    Circle()
                        .fill(Color.surfaceContainerLowest)
                        .shadow(color: color.opacity(0.3), radius: 3, x: 0, y: 1)
                        .frame(width: 22, height: 22)
                        .offset(
                            x: max(0, (geo.size.width * CGFloat(percentile) / 100.0 * (animateGauges ? 1.0 : 0.0)) - 11)
                        )
                }
            }
            .frame(height: 22)
            
            // Interpretive Text
            Text(interpretiveText(for: title, percentile: percentile))
                .font(.bodyMD)
                .foregroundColor(.secondaryText)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 2)
        }
        .padding(16)
        .background(Color.surfaceContainerLowest)
        .cornerRadius(AppRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
    }
    
    private func interpretiveText(for category: String, percentile: Int) -> String {
        switch category {
        case "Activity Level":
            if percentile >= 75 {
                return "\(petName) is highly active compared to other \(benchmark.breed)s. Make sure you are feeding a high-protein diet to support this energy exertion."
            } else if percentile <= 25 {
                return "\(petName) is less active than the average \(benchmark.breed). You might want to consider adding another daily walk or play session."
            } else {
                return "\(petName)'s activity levels are perfectly typical for a \(benchmark.breed) of this age."
            }
        case "Rest & Sleep":
            if percentile >= 75 {
                return "\(petName) is getting more sleep than most \(benchmark.breed)s. This is great for recovery, but monitor for signs of lethargy if this is a sudden change."
            } else if percentile <= 25 {
                return "\(petName) sleeps less than average. Consider creating a quieter sleeping environment to encourage better rest."
            } else {
                return "\(petName) is getting a very normal amount of sleep for their breed and age."
            }
        case "Health Alerts":
            if percentile >= 75 {
                return "\(petName) has had more health symptoms logged than the average \(benchmark.breed). Keep a close eye on these alerts and consider consulting your vet."
            } else if percentile <= 25 {
                return "Great news! \(petName) has fewer health symptoms than most \(benchmark.breed)s. Keep up the good work!"
            } else {
                return "\(petName) has an average number of health alerts for their breed."
            }
        default:
            return ""
        }
    }
}
