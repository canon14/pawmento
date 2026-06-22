import SwiftUI
import Charts

struct InlineChartView: View {
    let data: VisualizationData
    
    var body: some View {
        switch data.chartType {
        case "sparkline":
            SparklineChart(dataPoints: data.dataPoints)
        case "bar":
            SimpleBarChart(dataPoints: data.dataPoints, labels: data.labels)
        case "streak":
            StreakChart(dataPoints: data.dataPoints)
        default:
            LineChart(dataPoints: data.dataPoints)
        }
    }
}

private struct SparklineChart: View {
    let dataPoints: [Double]
    
    var body: some View {
        Chart {
            ForEach(Array(dataPoints.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Index", index),
                    y: .value("Value", value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.primary.opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: 3))
                
                AreaMark(
                    x: .value("Index", index),
                    y: .value("Value", value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.primary.opacity(0.3), Color.primary.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
    }
}

private struct SimpleBarChart: View {
    let dataPoints: [Double]
    let labels: [String]?
    
    var body: some View {
        Chart {
            ForEach(Array(dataPoints.enumerated()), id: \.offset) { index, value in
                let label = (labels != nil && index < labels!.count) ? labels![index] : "\(index)"
                BarMark(
                    x: .value("Category", label),
                    y: .value("Count", value)
                )
                .foregroundStyle(Color.amber)
                .cornerRadius(AppRadius.sm)
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .foregroundStyle(Color.ink500)
            }
        }
        .chartYAxis(.hidden)
    }
}

private struct StreakChart: View {
    let dataPoints: [Double]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(dataPoints.enumerated()), id: \.offset) { index, value in
                RoundedRectangle(cornerRadius: 4)
                    .fill(value > 0 ? Color.primary : Color.ink200)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct LineChart: View {
    let dataPoints: [Double]
    
    var body: some View {
        Chart {
            ForEach(Array(dataPoints.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Index", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(Color.coral500)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                PointMark(
                    x: .value("Index", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(Color.coral500)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
    }
}
