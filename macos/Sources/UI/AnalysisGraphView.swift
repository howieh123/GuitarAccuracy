import SwiftUI

struct AnalysisGraphView: View {
    let series: AnalysisSeries

    private func xPos(t: Double, width: CGFloat) -> CGFloat {
        let dur = max(series.duration, 0.01)
        return CGFloat(t / dur) * width
    }

    private func nearestErrorMs(for onset: Double) -> Double {
        guard let nearest = series.expectedBeats.min(by: { abs($0 - onset) < abs($1 - onset) }) else {
            return .infinity
        }
        return abs(onset - nearest) * 1000.0
    }

    private func colorForOnset(_ onset: Double) -> Color {
        let err = nearestErrorMs(for: onset)
        if err <= 20.0 { return .green }
        if err <= 50.0 { return .yellow }
        return .red
    }

    private var accuracyText: String {
        let total = series.playedOnsets.count
        guard total > 0 else { return "Accuracy: —" }
        let greenCount = series.playedOnsets.reduce(0) { acc, t in
            acc + (nearestErrorMs(for: t) <= 20.0 ? 1 : 0)
        }
        let pct = Double(greenCount) / Double(total) * 100.0
        return String(format: "Accuracy: %.0f%% (%d/%d green)", pct, greenCount, total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Played vs Metronome (time axis)").font(.headline)
                Spacer()
                Text(accuracyText)
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack(alignment: .topLeading) {
                    Rectangle().fill(Color.gray.opacity(0.12))
                    // Expected beats
                    ForEach(Array(series.expectedBeats.enumerated()), id: \.offset) { _, t in
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 2, height: h)
                            .position(x: xPos(t: t, width: w), y: h/2)
                            .accessibilityLabel(String(format: "Expected @ %.3fs", t))
                    }
                    // Played onsets
                    ForEach(Array(series.playedOnsets.enumerated()), id: \.offset) { _, t in
                        Circle()
                            .fill(colorForOnset(t))
                            .frame(width: 8, height: 8)
                            .position(x: xPos(t: t, width: w), y: h*0.5)
                            .accessibilityLabel(String(format: "Played @ %.3fs", t))
                    }
                }
            }
            .frame(height: 180)

            // Simple axis ticks in seconds and ms
            HStack(spacing: 12) {
                let totalMs = Int(series.duration * 1000)
                Text("0s")
                Spacer()
                Text("\(totalMs)ms / \(String(format: "%.2f", series.duration))s").monospacedDigit()
            }
            .font(.caption)

            // Legend
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Circle().fill(Color.green).frame(width: 8, height: 8)
                    Text("≤ 20 ms early/late")
                }
                HStack(spacing: 6) {
                    Circle().fill(Color.yellow).frame(width: 8, height: 8)
                    Text("21 – 50 ms early/late")
                }
                HStack(spacing: 6) {
                    Circle().fill(Color.red).frame(width: 8, height: 8)
                    Text("> 50 ms early/late")
                }
                Spacer()
            }
            .font(.caption)
        }
    }
}


