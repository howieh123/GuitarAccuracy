import Foundation
import AVFoundation

public struct AnalysisSeries {
    public let expectedBeats: [Double] // seconds
    public let playedOnsets: [Double]  // seconds
    public let duration: Double        // seconds
}

public enum AudioAnalysisService {
    // Simple energy-based onset detector (time-domain energy diff with refractory)
    public static func detectOnsets(url: URL, minDb: Double = -50.0) throws -> [Double] {
        let file = try AVAudioFile(forReading: url)
        let processing = file.processingFormat
        let frames = AVAudioFrameCount(file.length)
        guard frames > 0 else { return [] }
        // Read in the file's native processing format to avoid -50 format errors
        guard let inBuffer = AVAudioPCMBuffer(pcmFormat: processing, frameCapacity: frames) else { return [] }
        try file.read(into: inBuffer)

        // Ensure float32 non-interleaved; if already float, use it, otherwise bail gracefully
        guard processing.commonFormat == .pcmFormatFloat32,
              let channels = inBuffer.floatChannelData,
              processing.isInterleaved == false else {
            // Fallback: no data accessible for simple detector
            return []
        }

        // Downmix to mono if needed
        let channelCount = Int(processing.channelCount)
        let frameCount = Int(inBuffer.frameLength)
        var monoData = [Float](repeating: 0, count: frameCount)
        if channelCount == 1 {
            monoData.withUnsafeMutableBufferPointer { dst in
                let src = channels[0]
                dst.baseAddress!.initialize(from: src, count: frameCount)
            }
        } else {
            for c in 0..<channelCount {
                let src = channels[c]
                var i = 0
                while i < frameCount { monoData[i] += src[i] / Float(channelCount); i += 1 }
            }
        }

        let hop = 512
        let win = 2048
        var onsetTimes: [Double] = []
        var prevEnergy: Float = 0
        var lastOnset: Double = -1
        let minLinear = pow(10.0, minDb / 20.0) // dBFS to linear
        for start in stride(from: 0, to: max(0, frameCount - win), by: hop) {
            var energy: Float = 0
            let end = start + win
            var i = start
            while i < end { let s = monoData[i]; energy += s*s; i += 1 }
            let diff = energy - prevEnergy
            let t = Double(start) / processing.sampleRate
            // Require both energy rise and absolute level above threshold
            if diff > max(0.001 * energy, 0.002)
                && energy > Float(minLinear * minLinear * Double(win))
                && (lastOnset < 0 || t - lastOnset > 0.05) {
                onsetTimes.append(t)
                lastOnset = t
            }
            prevEnergy = 0.9*energy + 0.1*prevEnergy
        }
        return onsetTimes
    }

    public static func expectedBeats(bpm: Int, pattern: Pattern, duration: Double) -> [Double] {
        let hz = MetronomeMath.ticksPerSecond(bpm: bpm, pattern: pattern)
        guard hz > 0 else { return [] }
        let step = 1.0 / hz
        var t = 0.0
        var beats: [Double] = []
        while t <= duration + 1e-6 { beats.append(t); t += step }
        return beats
    }

    // Estimate constant latency offset by comparing detected onsets to nearest expected beats
    private static func estimateLatencyOffsetSeconds(onsets: [Double], expected: [Double]) -> Double {
        guard !onsets.isEmpty, !expected.isEmpty else { return 0 }
        let sampleCount = min(10, onsets.count)
        var deltas: [Double] = []
        deltas.reserveCapacity(sampleCount)
        for i in 0..<sampleCount {
            let o = onsets[i]
            if let nearest = expected.min(by: { abs($0 - o) < abs($1 - o) }) {
                deltas.append(o - nearest)
            }
        }
        guard !deltas.isEmpty else { return 0 }
        // Median for robustness
        let sorted = deltas.sorted()
        let mid = sorted.count / 2
        let median = sorted.count % 2 == 0 ? 0.5 * (sorted[mid-1] + sorted[mid]) : sorted[mid]
        // Clamp to ±200ms to avoid extreme shifts
        return max(-0.2, min(0.2, median))
    }

    public static func buildSeries(onsets: [Double], bpm: Int, pattern: Pattern, duration: Double) -> AnalysisSeries {
        let beats = expectedBeats(bpm: bpm, pattern: pattern, duration: duration)
        let offset = estimateLatencyOffsetSeconds(onsets: onsets, expected: beats)
        let adjusted = onsets.map { max(0, $0 - offset) }
        return AnalysisSeries(expectedBeats: beats,
                              playedOnsets: adjusted,
                              duration: duration)
    }
}


