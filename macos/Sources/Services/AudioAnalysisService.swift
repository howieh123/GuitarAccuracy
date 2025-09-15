import Foundation
import AVFoundation
import Accelerate

public struct AnalysisSeries {
    public let expectedBeats: [Double] // seconds
    public let playedOnsets: [Double]  // seconds
    public let duration: Double        // seconds
    public let bpm: Int               // beats per minute
    public let pattern: Pattern       // note pattern
}

public enum AudioAnalysisService {
    
    // MARK: - Enhanced Onset Detection
    
    /// Enhanced onset detection using aubio (Python) for accurate guitar note detection
    /// Uses aubio library for more robust and accurate onset detection
    public static func detectOnsets(url: URL, minDb: Double = -50.0, bpm: Int? = nil, pattern: Pattern? = nil) throws -> [Double] {
        // Try aubio-based detection first - this is now our primary method
        if let aubioOnsets = try? detectOnsetsAubio(url: url, minDb: minDb, bpm: bpm, pattern: pattern) {
            return aubioOnsets
        }
        
        // Fall back to native implementation only if aubio fails
        print("Warning: Aubio onset detection failed, falling back to native implementation")
        return try detectOnsetsLegacy(url: url, minDb: minDb)
    }
    
    /// Legacy simple energy-based onset detector (kept for fallback)
    public static func detectOnsetsLegacy(url: URL, minDb: Double = -50.0) throws -> [Double] {
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

        let hop = 256  // Smaller hop for better temporal resolution
        let win = 1024 // Smaller window for faster attack detection
        var onsetTimes: [Double] = []
        var lastOnset: Double = -1
        let minLinear = pow(10.0, minDb / 20.0) // dBFS to linear
        
        // Multiple detection methods for better guitar note detection
        var energyHistory: [Float] = []
        var spectralCentroidHistory: [Float] = []
        let historyLength = 8 // Keep history for trend analysis
        
        for start in stride(from: 0, to: max(0, frameCount - win), by: hop) {
            let end = start + win
            let t = Double(start) / processing.sampleRate
            
            // 1. Energy-based detection (RMS)
            var energy: Float = 0
            var i = start
            while i < end { 
                let s = monoData[i]
                energy += s * s
                i += 1 
            }
            energy = sqrt(energy / Float(win)) // RMS
            
            // 2. Spectral centroid (brightness) - helps detect plucked strings
            var spectralCentroid: Float = 0
            var magnitudeSum: Float = 0
            let fftSize = min(512, win)
            for k in 0..<fftSize {
                let freq = Float(k) * Float(processing.sampleRate) / Float(fftSize)
                // Simple magnitude approximation using windowed samples
                let sampleIdx = start + (k * win / fftSize)
                if sampleIdx < frameCount {
                    let magnitude = abs(monoData[Int(sampleIdx)])
                    spectralCentroid += freq * magnitude
                    magnitudeSum += magnitude
                }
            }
            if magnitudeSum > 0 {
                spectralCentroid /= magnitudeSum
            }
            
            // Update history
            energyHistory.append(energy)
            spectralCentroidHistory.append(spectralCentroid)
            if energyHistory.count > historyLength {
                energyHistory.removeFirst()
                spectralCentroidHistory.removeFirst()
            }
            
            // Detection criteria
            var isOnset = false
            
            // Method 1: Energy spike detection (more selective)
            if energyHistory.count >= 5 { // Require more history for stability
                let currentEnergy = energyHistory.last!
                let avgEnergy = energyHistory.dropLast().reduce(0, +) / Float(energyHistory.count - 1)
                let energyRatio = currentEnergy / max(avgEnergy, 1e-6)
                
                // Higher threshold and require significant energy level
                if energyRatio > 4.0 && currentEnergy > Float(minLinear) * 2.0 {
                    isOnset = true
                }
            }
            
            // Method 2: Spectral centroid change (more conservative)
            if !isOnset && spectralCentroidHistory.count >= 5 {
                let currentCentroid = spectralCentroidHistory.last!
                let avgCentroid = spectralCentroidHistory.dropLast().reduce(0, +) / Float(spectralCentroidHistory.count - 1)
                
                // Higher threshold for brightness increase
                if currentCentroid > avgCentroid * 1.8 && energy > Float(minLinear) * 1.5 {
                    isOnset = true
                }
            }
            
            // Method 3: High-frequency energy detection (more selective)
            if !isOnset && energy > Float(minLinear) * 1.5 {
                var highFreqEnergy: Float = 0
                let highFreqStart = win * 3 / 4 // Focus on upper quarter of spectrum
                var j = start + highFreqStart
                while j < end {
                    highFreqEnergy += monoData[j] * monoData[j]
                    j += 1
                }
                highFreqEnergy = sqrt(highFreqEnergy / Float(win / 4))
                
                // Higher threshold for high-frequency content
                let totalEnergy = energy
                if highFreqEnergy > totalEnergy * 0.5 {
                    isOnset = true
                }
            }
            
            // Apply minimum time separation (refractory period) - longer for guitar
            if isOnset && (lastOnset < 0 || t - lastOnset > 0.2) { // Even longer refractory to eliminate double notes
                onsetTimes.append(t)
                lastOnset = t
            }
        }
        return onsetTimes
    }
    
    // MARK: - Aubio Integration
    
    /// Calculate expected note count based on BPM and pattern
    private static func calculateExpectedNoteCount(bpm: Int?, pattern: Pattern?) -> Int {
        guard let bpm = bpm, let pattern = pattern else { return 14 } // default fallback
        
        let duration = 15.0 // seconds (full recording duration)
        let beatInterval = 60.0 / Double(bpm)
        
        switch pattern {
        case .quarter:
            return max(1, Int(duration / beatInterval))
        case .eighth:
            return max(1, Int(duration / (beatInterval / 2)))
        case .eighthTriplet:
            return max(1, Int(duration / (beatInterval / 3)))
        case .sixteenth:
            return max(1, Int(duration / (beatInterval / 4)))
        case .sixteenthTriplet:
            return max(1, Int(duration / (beatInterval / 6)))
        }
    }
    
    /// Detect onsets using aubio (Python) for improved accuracy
    /// Uses aubio library for more robust and accurate onset detection
    private static func detectOnsetsAubio(url: URL, minDb: Double, bpm: Int?, pattern: Pattern?) throws -> [Double]? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        
        // Get the script directory - use absolute path to project root
        let scriptDir = URL(fileURLWithPath: "/Users/howieh123/GuitarAccuracy")
        
        // Create bash script to activate virtual environment and run Python
        // The audio file is already in the correct location (results.wav in project directory)
        let activatePath = scriptDir.appendingPathComponent("librosa_env/bin/activate").path
        
        // Calculate expected note count and timing parameters based on BPM and pattern
        let expectedNoteCount = calculateExpectedNoteCount(bpm: bpm, pattern: pattern)
        let beatInterval = bpm.map { 60.0 / Double($0) } ?? 1.0 // seconds between beats
        let minWaitFrames = max(1, Int(beatInterval * 0.3 * 22050 / 512)) // minimum frames between onsets
        
        let bashScript = """
        source \(activatePath)
        cd "\(scriptDir.path)"
        python AubioOnset.py \(expectedNoteCount) \(minWaitFrames)
        """
        
        process.arguments = ["-c", bashScript]
        
        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        // Read and print the output for debugging
        if let outputData = try? pipe.fileHandleForReading.readToEnd(),
           let output = String(data: outputData, encoding: .utf8) {
            print("📊 Aubio script output: \(output)")
        }
        
        if let errorData = try? errorPipe.fileHandleForReading.readToEnd(),
           let error = String(data: errorData, encoding: .utf8) {
            print("⚠️ Aubio script errors: \(error)")
        }
        
        if process.terminationStatus != 0 {
            // If aubio fails, return nil to fall back to native implementation
            print("❌ Aubio script failed with exit code: \(process.terminationStatus)")
            return nil
        }
        
        // Read the beatmap.txt file that AubioOnset.py creates
        let beatmapPath = scriptDir.appendingPathComponent("results.beatmap.txt")
        guard let beatmapData = try? Data(contentsOf: beatmapPath),
              let beatmapString = String(data: beatmapData, encoding: .utf8) else {
            return nil
        }
        
        // Parse the onset times from the text file
        let onsetTimes = beatmapString.components(separatedBy: .newlines)
            .compactMap { line in
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : Double(trimmed)
            }
        
        return onsetTimes.isEmpty ? nil : onsetTimes
    }
    
    // MARK: - Helper Functions
    
    /// Convert multi-channel audio to mono
    private static func convertToMono(channels: UnsafePointer<UnsafeMutablePointer<Float>>, frameCount: Int, channelCount: Int) -> [Float] {
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
                while i < frameCount { 
                    monoData[i] += src[i] / Float(channelCount)
                    i += 1 
                }
            }
        }
        
        return monoData
    }
    
    /// Enhanced onset detection using multiple algorithms
    private static func detectOnsetsEnhanced(audioData: [Float], sampleRate: Float, minDb: Double) -> [Double] {
        let hopSize = 512      // Good balance between temporal resolution and computation
        let windowSize = 2048  // Larger window for better frequency resolution
        let minLinear = pow(10.0, minDb / 20.0)
        
        // Storage for onset strength values (two-pass approach)
        var onsetStrengths: [Float] = []
        
        // Storage for spectral analysis
        var previousMagnitudes: [Float] = []
        var previousPhases: [Float] = []
        
        // Detection method weights - maximum sensitivity approach
        let energyWeight: Float = 0.6      // High energy weight (most reliable)
        let spectralFluxWeight: Float = 0.25 // Moderate spectral flux weight
        let phaseDeviationWeight: Float = 0.15 // Lower phase weight (can be noisy)
        
        for start in stride(from: 0, to: max(0, audioData.count - windowSize), by: hopSize) {
            let end = start + windowSize
            
            // Extract window
            let window = Array(audioData[start..<end])
            
            // Apply windowing function (Hann window)
            let windowedData = applyHannWindow(window)
            
            // Compute FFT
            let (magnitudes, phases) = computeFFT(windowedData)
            
            // 1. Energy-based detection (improved)
            let energy = sqrt(magnitudes.reduce(0, { $0 + $1 * $1 }) / Float(magnitudes.count))
            
            // 2. Spectral flux detection
            var spectralFlux: Float = 0
            if !previousMagnitudes.isEmpty && previousMagnitudes.count == magnitudes.count {
                for i in 0..<magnitudes.count {
                    let diff = magnitudes[i] - previousMagnitudes[i]
                    if diff > 0 {
                        spectralFlux += diff
                    }
                }
            }
            
            // 3. Phase deviation detection (excellent for guitar plucks)
            var phaseDeviation: Float = 0
            if !previousPhases.isEmpty && previousPhases.count == phases.count {
                for i in 0..<phases.count {
                    let phaseDiff = phases[i] - previousPhases[i]
                    // Unwrap phase difference
                    let unwrappedDiff = atan2(sin(phaseDiff), cos(phaseDiff))
                    phaseDeviation += abs(unwrappedDiff)
                }
                phaseDeviation /= Float(phases.count)
            }
            
            // Combined onset strength
            var onsetStrength: Float = 0
            
            // Energy contribution - very sensitive threshold
            if energy > Float(minLinear) * 0.5 {  // Very low threshold to catch quiet notes
                onsetStrength += energyWeight * min(energy / Float(minLinear), 6.0) // Higher max
            }
            
            // Spectral flux contribution - very sensitive threshold
            if spectralFlux > 0.05 {  // Very low threshold to catch quiet notes
                onsetStrength += spectralFluxWeight * min(spectralFlux, 4.0) // Higher max
            }
            
            // Phase deviation contribution - very sensitive threshold
            if phaseDeviation > 0.2 {  // Very low threshold to catch quiet notes
                onsetStrength += phaseDeviationWeight * min(phaseDeviation, 5.0) // Higher max
            }
            
            // Store onset strength for peak detection
            onsetStrengths.append(onsetStrength)
            
            // Update previous frame data
            previousMagnitudes = magnitudes
            previousPhases = phases
        }
        
        // Second pass: Find peaks in onset strength curve
        return findPeaksInOnsetStrengths(onsetStrengths, hopSize: hopSize, sampleRate: sampleRate)
    }
    
    /// Find peaks in onset strength curve to avoid double detections
    private static func findPeaksInOnsetStrengths(_ strengths: [Float], hopSize: Int, sampleRate: Float) -> [Double] {
        guard !strengths.isEmpty else { return [] }
        
        let threshold: Float = 0.06 // Optimal threshold to catch all notes with minimal duplicates
        let minSeparation: Float = 0.09 // Optimal separation to prevent duplicates while keeping all notes
        let minSeparationFloat = minSeparation * sampleRate / Float(hopSize)
        let minSeparationSamples = Int(minSeparationFloat)
        
        var peaks: [(time: Double, strength: Float)] = []
        
        // Find local maxima that exceed threshold (less strict local maximum check)
        for i in 1..<(strengths.count - 1) {
            let currentStrength = strengths[i]
            
            // Must exceed threshold and be a local maximum (balanced)
            if currentStrength > threshold &&
               currentStrength >= strengths[i - 1] &&  // Allow equal neighbors
               currentStrength >= strengths[i + 1] {   // Allow equal neighbors
                
                let time = Double(i * hopSize) / Double(sampleRate)
                peaks.append((time: time, strength: currentStrength))
            }
        }
        
        // Remove nearby peaks, keeping the strongest
        var filteredPeaks: [Double] = []
        var lastPeakIndex = -1
        
        for (index, peak) in peaks.enumerated() {
            if lastPeakIndex < 0 || index - lastPeakIndex >= minSeparationSamples {
                // No nearby peak, add this one
                filteredPeaks.append(peak.time)
                lastPeakIndex = index
            } else {
                // Nearby peak exists, keep the stronger one
                let lastPeak = peaks[lastPeakIndex]
                if peak.strength > lastPeak.strength {
                    // Replace the last peak with this stronger one
                    filteredPeaks[filteredPeaks.count - 1] = peak.time
                    lastPeakIndex = index
                }
                // Otherwise, ignore this weaker peak
            }
        }
        
        return filteredPeaks
    }
    
    /// Apply Hann window to reduce spectral leakage
    private static func applyHannWindow(_ data: [Float]) -> [Float] {
        var windowed = [Float](repeating: 0, count: data.count)
        let n = Float(data.count - 1)
        
        for i in 0..<data.count {
            let windowValue = 0.5 * (1 - cos(2 * Float.pi * Float(i) / n))
            windowed[i] = data[i] * windowValue
        }
        
        return windowed
    }
    
    /// Compute FFT and return magnitude and phase spectra
    private static func computeFFT(_ data: [Float]) -> (magnitudes: [Float], phases: [Float]) {
        let n = data.count
        let log2n = vDSP_Length(log2(Float(n)))
        let fftSetup = vDSP_create_fftsetup(log2n, Int32(kFFTRadix2))!
        
        defer { vDSP_destroy_fftsetup(fftSetup) }
        
        // Prepare input for real FFT
        var realParts = [Float](repeating: 0, count: n / 2)
        var imagParts = [Float](repeating: 0, count: n / 2)
        
        // Convert real data to split complex format
        realParts.withUnsafeMutableBufferPointer { realPtr in
            imagParts.withUnsafeMutableBufferPointer { imagPtr in
                data.withUnsafeBufferPointer { dataPtr in
                    var splitComplex = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)
                    vDSP_ctoz(UnsafePointer<DSPComplex>(OpaquePointer(dataPtr.baseAddress!)), 2, &splitComplex, 1, vDSP_Length(n / 2))
                    
                    // Perform FFT
                    vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, Int32(FFT_FORWARD))
                }
            }
        }
        
        // Calculate magnitudes and phases
        var magnitudes = [Float](repeating: 0, count: n / 2)
        var phases = [Float](repeating: 0, count: n / 2)
        
        realParts.withUnsafeBufferPointer { realPtr in
            imagParts.withUnsafeBufferPointer { imagPtr in
                var splitComplex = DSPSplitComplex(realp: UnsafeMutablePointer(mutating: realPtr.baseAddress!), imagp: UnsafeMutablePointer(mutating: imagPtr.baseAddress!))
                
                vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(n / 2))
                vDSP_zvphas(&splitComplex, 1, &phases, 1, vDSP_Length(n / 2))
            }
        }
        
        // Convert magnitude squares to magnitudes using sqrt
        for i in 0..<magnitudes.count {
            magnitudes[i] = sqrt(magnitudes[i])
        }
        
        return (magnitudes: magnitudes, phases: phases)
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
        
        // No latency compensation needed for interval-based analysis
        // We're measuring timing between consecutive notes, not absolute timing
        
        print("🎵 Using raw onset times for interval analysis:")
        print("  Onset times: \(onsets.prefix(3).map { String(format: "%.3f", $0) })")
        print("  BPM: \(bpm), Pattern: \(pattern)")
        
        return AnalysisSeries(expectedBeats: beats,
                              playedOnsets: onsets,
                              duration: duration,
                              bpm: bpm,
                              pattern: pattern)
    }
}


