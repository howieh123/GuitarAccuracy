import SwiftUI

struct AnalysisGraphView: View {
    let series: AnalysisSeries
    
    // Calculate minimum width needed based on content
    private var minGraphWidth: CGFloat {
        let numElements = max(series.expectedBeats.count, series.playedOnsets.count)
        let minSpacing: CGFloat = 20 // Minimum pixels between elements
        let baseWidth: CGFloat = 400 // Base width for the graph
        let dynamicWidth = CGFloat(numElements) * minSpacing
        return max(baseWidth, dynamicWidth)
    }

    private func xPos(t: Double, width: CGFloat) -> CGFloat {
        let dur = max(series.duration, 0.01)
        return CGFloat(t / dur) * width
    }

    private func intervalErrorMs(for onsetIndex: Int) -> Double {
        guard onsetIndex > 0 else { return 0.0 } // First note has no interval to measure
        
        let onsets = series.playedOnsets.sorted()
        guard onsetIndex < onsets.count else { return 0.0 }
        
        let currentOnset = onsets[onsetIndex]
        let previousOnset = onsets[onsetIndex - 1]
        let actualInterval = currentOnset - previousOnset
        
        // Calculate expected interval based on BPM and pattern
        let expectedInterval = calculateExpectedInterval()
        
        return abs(actualInterval - expectedInterval) * 1000.0
    }
    
    private func printIntervalAnalysis() {
        let onsets = series.playedOnsets.sorted()
        guard onsets.count > 1 else { return }
        
        let expectedInterval = calculateExpectedInterval()
        let totalIntervals = onsets.count - 1
        print("🎵 Interval Analysis (BPM: \(series.bpm), Pattern: \(series.pattern), Expected: \(String(format: "%.3f", expectedInterval))s, Total intervals: \(totalIntervals)):")
        
        var intervalsOver35ms: [(Int, Double, Double)] = []
        
        for i in 1..<onsets.count {
            let currentOnset = onsets[i]
            let previousOnset = onsets[i - 1]
            let actualInterval = currentOnset - previousOnset
            let errorMs = abs(actualInterval - expectedInterval) * 1000.0
            
            print("  Interval \(i)/\(totalIntervals): \(String(format: "%.3f", previousOnset))s → \(String(format: "%.3f", currentOnset))s = \(String(format: "%.3f", actualInterval))s (error: \(String(format: "%.1f", errorMs))ms)")
            
            if errorMs > 35.0 {
                intervalsOver35ms.append((i, actualInterval, errorMs))
            }
        }
        
        print("📊 Analysis complete: \(totalIntervals) intervals processed")
        
        if !intervalsOver35ms.isEmpty {
            print("🚨 Intervals > 35ms error (\(intervalsOver35ms.count) out of \(totalIntervals)):")
            for (index, actualInterval, errorMs) in intervalsOver35ms {
                print("  - Interval \(index): \(String(format: "%.3f", actualInterval))s (error: \(String(format: "%.1f", errorMs))ms)")
            }
        } else {
            print("✅ All intervals within 35ms tolerance!")
        }
    }
    
    private func calculateExpectedInterval() -> Double {
        // Calculate the expected interval between notes based on BPM and pattern
        let beatInterval = 60.0 / Double(series.bpm) // seconds per beat
        
        switch series.pattern {
        case .quarter:
            return beatInterval // 1 beat = 1 note
        case .eighth:
            return beatInterval / 2.0 // 2 notes per beat
        case .eighthTriplet:
            return beatInterval / 3.0 // 3 notes per beat
        case .sixteenth:
            return beatInterval / 4.0 // 4 notes per beat
        case .sixteenthTriplet:
            return beatInterval / 6.0 // 6 notes per beat
        }
    }

    private func colorForOnset(_ onset: Double) -> Color {
        // Find the index of this onset in the sorted array
        let onsets = series.playedOnsets.sorted()
        guard let index = onsets.firstIndex(of: onset) else { return .red }
        
        // First note has no interval to measure, so use neutral color
        guard index > 0 else { return .gray }
        
        let err = intervalErrorMs(for: index)
        if err <= 35.0 { return .green }
        if err <= 100.0 { return .yellow }
        return .red
    }

    private var accuracyText: String {
        let onsets = series.playedOnsets.sorted()
        guard onsets.count > 1 else { return "Accuracy: — (need 2+ notes)" }
        
        let totalIntervals = onsets.count - 1
        var totalPoints = 0.0
        
        for i in 1..<onsets.count {
            let errorMs = intervalErrorMs(for: i)
            if errorMs <= 35.0 {
                totalPoints += 1.0  // Green = 1.0 point
            } else if errorMs <= 100.0 {
                totalPoints += 0.5  // Yellow = 0.5 points
            }
            // Red = 0.0 points (not counted)
        }
        
        let maxPossiblePoints = Double(totalIntervals)
        let pct = (totalPoints / maxPossiblePoints) * 100.0
        
        // Count actual green and yellow for display
        let greenCount = (1..<onsets.count).reduce(0) { acc, index in
            acc + (intervalErrorMs(for: index) <= 35.0 ? 1 : 0)
        }
        let yellowCount = (1..<onsets.count).reduce(0) { acc, index in
            let errorMs = intervalErrorMs(for: index)
            return acc + (errorMs > 35.0 && errorMs <= 100.0 ? 1 : 0)
        }
        
        return String(format: "Rhythm Accuracy: %.0f%% (%.1f/%.0f pts: %d green + %d yellow)", pct, totalPoints, maxPossiblePoints, greenCount, yellowCount)
    }
    
    private func printDebugInfo() {
        let onsets = series.playedOnsets.sorted()
        guard onsets.count > 1 else { return }
        
        // Debug: Print all onset times (only once)
        print("🎵 All onset times: \(onsets.map { String(format: "%.3f", $0) })")
        print("🎵 BPM: \(series.bpm), Pattern: \(series.pattern), Expected interval: \(String(format: "%.3f", calculateExpectedInterval()))s")
        
        // Print detailed interval analysis
        printIntervalAnalysis()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Rhythm Consistency Analysis").font(.headline)
                Spacer()
                Text(accuracyText)
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .onAppear {
                printDebugInfo()
            }
            
            ScrollView(.horizontal, showsIndicators: true) {
                HStack {
                    Spacer(minLength: 0)
                    GeometryReader { geo in
                        let w = max(geo.size.width, minGraphWidth)
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
                        .frame(width: w, height: h)
                    }
                    .frame(width: minGraphWidth, height: 180)
                    Spacer(minLength: 0)
                }
            }

            // Simple axis ticks in seconds and ms
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Spacer(minLength: 0)
                    HStack(spacing: 12) {
                        let totalMs = Int(series.duration * 1000)
                        Text("0s")
                        Spacer()
                        Text("\(totalMs)ms / \(String(format: "%.2f", series.duration))s").monospacedDigit()
                    }
                    .frame(width: minGraphWidth)
                    .font(.caption)
                    Spacer(minLength: 0)
                }
            }

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
        .padding(.horizontal, 16)
    }
}


