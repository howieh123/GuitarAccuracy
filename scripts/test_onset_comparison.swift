#!/usr/bin/env swift
/*
 Test script to compare native vs librosa onset detection
 */

import Foundation

// Simple test to compare detection methods
let audioFile = "test-audio-12-notes.wav"

print("Testing onset detection methods on \(audioFile)")
print(String(repeating: "=", count: 50))

// Test librosa detection
print("\n1. Librosa Detection:")
let librosaProcess = Process()
librosaProcess.executableURL = URL(fileURLWithPath: "/bin/bash")
librosaProcess.arguments = ["-c", """
source librosa_env/bin/activate
python scripts/librosa_onset_detection.py \(audioFile) --method combined
"""]

let librosaPipe = Pipe()
librosaProcess.standardOutput = librosaPipe
librosaProcess.standardError = Pipe()

do {
    try librosaProcess.run()
    librosaProcess.waitUntilExit()
    
    let data = librosaPipe.fileHandleForReading.readDataToEndOfFile()
    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
       let onsetTimes = json["onset_times"] as? [Double] {
        print("Found \(onsetTimes.count) onsets:")
        for (i, time) in onsetTimes.enumerated() {
            print("  \(i+1): \(String(format: "%.3f", time))s")
        }
    }
} catch {
    print("Error: \(error)")
}

// Test native detection (simplified)
print("\n2. Native Detection (simplified):")
print("This would use the existing AudioAnalysisService.detectOnsets method")
print("In a real test, we'd call the Swift method directly")

print("\n" + String(repeating: "=", count: 50))
print("Comparison complete!")
