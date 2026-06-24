import SwiftUI

struct BreedBenchmarkCard: View {
    let benchmark: BreedBenchmark
    let isPremium: Bool
    var onCardTapped: (() -> Void)?
    
    @State private var animatedPercent: Double = 0
    
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
                    HStack(spacing: 6) {
                        Text("🐕")
                            .font(.system(size: 14))
                        Text("vs other \(benchmark.breed), age \(benchmark.age)")
                            .font(.headlineSM)
                            .foregroundColor(.primaryText)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 3) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 8))
                        Text("Premium")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.ink900.opacity(0.9))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
                
                // Animated Bars
                VStack(spacing: 14) {
                    benchmarkRow(label: "Activity", percentile: benchmark.activityPercentile, color: .amber, isLocked: isLocked)
                    benchmarkRow(label: "Symptoms", percentile: benchmark.symptomsPercentile, color: .coral500, isLocked: isLocked)
                    benchmarkRow(label: "Sleep", percentile: benchmark.sleepPercentile, color: .primary, isLocked: isLocked)
                }
                .blur(radius: isLocked ? 4 : 0)
                
                // Footer
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Text("See full breakdown")
                            .font(.labelSemibold)
                            .foregroundColor(.primary)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.primary.opacity(0.6))
                    }
                }
                .blur(radius: isLocked ? 2 : 0)
            }
            .padding(20)
            .background(Color.surfaceContainerLowest)
            .cornerRadius(AppRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 3)
            .overlay(
                Group {
                    if isLocked {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.primary.opacity(0.1))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.primary)
                            }
                            Text("Unlock Benchmarks")
                                .font(.labelSemibold)
                                .foregroundColor(.primaryText)
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.input)
                                .fill(.ultraThinMaterial)
                        )
                    }
                }
            )
        }
        .buttonStyle(SquishyCardStyle())
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animatedPercent = 1.0
            }
        }
    }
    
    @ViewBuilder
    private func benchmarkRow(label: String, percentile: Int, color: Color, isLocked: Bool) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.labelSemibold)
                .foregroundColor(.primaryText)
                .frame(width: 72, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.12))
                        .frame(height: 10)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.75)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(percentile) / 100.0 * animatedPercent, height: 10)
                }
            }
            .frame(height: 10)
            
            Text(label == "Symptoms" ? "better than \(percentile)%" : "\(percentile)th %ile")
                .font(.labelSM)
                .foregroundColor(.secondaryText)
                .frame(width: 90, alignment: .trailing)
        }
    }
}
