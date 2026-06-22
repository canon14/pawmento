import SwiftUI

struct BreedBenchmarkDetailScreen: View {
    @Environment(\.dismiss) var dismiss
    let benchmark: BreedBenchmark
    let petName: String
    var onAskCoach: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // Header text
                    Text("How \(petName) Compares to Other \(benchmark.breed)s")
                        .font(.headlineLG)
                        .foregroundColor(.primaryText)
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)
                    
                    Text("Based on data from \(benchmark.breed)s at age \(benchmark.age).")
                        .font(.labelMD)
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                    
                    // Gauges
                    VStack(spacing: 32) {
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
                    .padding(.top, 16)
                    
                    // AI CTA
                    Button(action: {
                        dismiss()
                        onAskCoach()
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Ask AI Coach about these results")
                        }
                        .font(.headlineSM)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.ink900)
                        .cornerRadius(AppRadius.md)
                    }
                    .padding(.top, 24)
                }
                .padding(20)
            }
            .background(Color.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                    .font(.headlineMD)
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
                Text("\(percentile)th Percentile")
                    .font(.labelSemibold)
                    .foregroundColor(color)
            }
            
            // Custom Gauge Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.ink900.opacity(0.1))
                        .frame(height: 16)
                    
                    Capsule()
                        .fill(color)
                        .frame(width: max(24, geo.size.width * CGFloat(percentile) / 100.0), height: 16)
                    
                    // Indicator dot
                    Circle()
                        .fill(Color.surface0)
                        .shadow(radius: 2)
                        .frame(width: 24, height: 24)
                        .offset(x: max(0, (geo.size.width * CGFloat(percentile) / 100.0) - 12))
                }
            }
            .frame(height: 24)
            
            // Interpretive Text
            Text(interpretiveText(for: title, percentile: percentile))
                .font(.bodyMD)
                .foregroundColor(.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
        }
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
