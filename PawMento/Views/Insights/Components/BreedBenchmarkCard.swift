import SwiftUI

struct BreedBenchmarkCard: View {
    let benchmark: BreedBenchmark
    let isPremium: Bool
    var onCardTapped: (() -> Void)?
    
    private var isLocked: Bool {
        !isPremium
    }
    
    var body: some View {
        Button(action: {
            onCardTapped?()
        }) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(alignment: .top) {
                    Text("🐕 vs other \(benchmark.breed), age \(benchmark.age)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.ink900)
                    
                    Spacer()
                    
                    Text("Premium")
                        .font(.system(size: 8, weight: .bold))
                        .padding(.horizontal, 6)
                        .frame(height: 14)
                        .background(Color.ink900)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                
                // Bars
                VStack(spacing: 12) {
                    benchmarkRow(label: "Activity", percentile: benchmark.activityPercentile, isLocked: isLocked)
                    benchmarkRow(label: "Symptoms", percentile: benchmark.symptomsPercentile, isLocked: isLocked)
                    benchmarkRow(label: "Sleep", percentile: benchmark.sleepPercentile, isLocked: isLocked)
                }
                .blur(radius: isLocked ? 4 : 0)
                
                // Footer
                Text("See full breakdown ›")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.primary)
                    .padding(.top, 4)
                    .blur(radius: isLocked ? 2 : 0)
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.ink900.opacity(0.1), lineWidth: 1)
            )
            .overlay(
                Group {
                    if isLocked {
                        VStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.ink900)
                            Text("Unlock Benchmarks")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.ink900)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(12)
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func benchmarkRow(label: String, percentile: Int, isLocked: Bool) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.ink900)
                .frame(width: 80, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.ink900.opacity(0.1))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(Color.primary)
                        .frame(width: geo.size.width * CGFloat(percentile) / 100.0, height: 8)
                }
            }
            .frame(height: 8)
            
            Text(label == "Symptoms" ? "better than \(percentile)%" : "\(percentile)nd percentile")
                .font(.caption)
                .foregroundColor(.ink900.opacity(0.6))
                .frame(width: 120, alignment: .leading) // approximate tabular width
        }
    }
}
