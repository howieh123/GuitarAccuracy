import SwiftUI

struct AnalysisGraphView: View {
    let series: AnalysisSeries

    private func xPos(t: Double, width: CGFloat) -> CGFloat {
        let dur = max(series.duration, 0.01)
        return CGFloat(t / dur) * width
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Played vs Metronome (time axis)").font(.headline)
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
                            .fill(Color.green)
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
        }
    }
}


