#!/usr/bin/env swift

import Foundation
import AVFoundation

// Create a test audio file with exactly 12 guitar notes
// Each note will be a simple sine wave with envelope to simulate guitar attack

func createTestAudioFile() {
    let sampleRate: Double = 44100
    let duration: Double = 10.0 // 10 seconds total
    let noteDuration: Double = 0.8 // Each note lasts 0.8 seconds
    let silenceBetween: Double = 0.1 // 0.1 seconds silence between notes
    
    let totalSamples = Int(sampleRate * duration)
    var audioData = [Float](repeating: 0, count: totalSamples)
    
    // Generate 12 notes with different frequencies (guitar string frequencies)
    let guitarFrequencies: [Double] = [
        82.41,   // E2 (6th string open)
        110.00,  // A2 (5th string open)  
        146.83,  // D3 (4th string open)
        196.00,  // G3 (3rd string open)
        246.94,  // B3 (2nd string open)
        329.63,  // E4 (1st string open)
        87.31,   // F2
        123.47,  // B2
        155.56,  // Eb3
        220.00,  // A3
        277.18,  // C#4
        369.99   // F#4
    ]
    
    var currentTime: Double = 0
    
    for (index, frequency) in guitarFrequencies.enumerated() {
        let noteStart = currentTime
        let noteEnd = noteStart + noteDuration
        
        // Generate note with attack envelope (simulates guitar pluck)
        for sample in 0..<Int(noteDuration * sampleRate) {
            let time = noteStart + Double(sample) / sampleRate
            let sampleIndex = Int(time * sampleRate)
            
            if sampleIndex < totalSamples {
                // Create attack envelope (fast attack, slow decay)
                let noteProgress = Double(sample) / (noteDuration * sampleRate)
                let envelope = pow(1.0 - noteProgress, 2.0) * exp(-noteProgress * 8.0)
                
                // Generate sine wave with slight harmonic content
                let fundamental = sin(2.0 * .pi * frequency * time)
                let harmonic = 0.3 * sin(2.0 * .pi * frequency * 2.0 * time) // Add some harmonic
                
                let amplitude: Float = 0.3 * Float(envelope)
                audioData[sampleIndex] = amplitude * Float(fundamental + harmonic)
            }
        }
        
        currentTime = noteEnd + silenceBetween
        
        print("Generated note \(index + 1)/12: \(String(format: "%.2f", frequency)) Hz at \(String(format: "%.2f", noteStart))s")
    }
    
    // Create audio file
    let outputURL = URL(fileURLWithPath: "/Users/howieh123/GuitarAccuracy/test-audio-12-notes.wav")
    
    // Create audio format
    let audioFormat = AVAudioFormat(
        standardFormatWithSampleRate: sampleRate,
        channels: 1
    )!
    
    // Create audio buffer
    let frameCount = AVAudioFrameCount(totalSamples)
    let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
    audioBuffer.frameLength = frameCount
    
    // Fill buffer with audio data
    let channelData = audioBuffer.floatChannelData![0]
    for i in 0..<totalSamples {
        channelData[i] = audioData[i]
    }
    
    // Write to file
    do {
        let audioFile = try AVAudioFile(forWriting: outputURL, settings: audioFormat.settings)
        try audioFile.write(from: audioBuffer)
        print("\n✅ Test audio file created successfully!")
        print("📁 File: \(outputURL.path)")
        print("🎵 Contains exactly 12 guitar notes")
        print("⏱️  Duration: \(duration) seconds")
        print("🎼 Notes: E2, A2, D3, G3, B3, E4, F2, B2, Eb3, A3, C#4, F#4")
    } catch {
        print("❌ Error creating audio file: \(error)")
    }
}

// Run the script
createTestAudioFile()

