#!/usr/bin/env swift

import Foundation
import AVFoundation

// Test script for onset detection algorithm
// Tests against the known 12-note test file

func testOnsetDetection() {
    let testFileURL = URL(fileURLWithPath: "/Users/howieh123/GuitarAccuracy/test-audio-12-notes.wav")
    
    // Check if test file exists
    guard FileManager.default.fileExists(atPath: testFileURL.path) else {
        print("❌ Test audio file not found at: \(testFileURL.path)")
        print("💡 Run: swift /Users/howieh123/GuitarAccuracy/scripts/create-test-audio.swift")
        return
    }
    
    print("🧪 Testing Onset Detection Algorithm")
    print("📁 Test file: \(testFileURL.path)")
    print("🎯 Expected: 12 notes detected")
    print("=" * 50)
    
    // Expected note times (from the test file generation)
    let expectedTimes: [Double] = [
        0.00,  // Note 1
        0.90,  // Note 2
        1.80,  // Note 3
        2.70,  // Note 4
        3.60,  // Note 5
        4.50,  // Note 6
        5.40,  // Note 7
        6.30,  // Note 8
        7.20,  // Note 9
        8.10,  // Note 10
        9.00,  // Note 11
        9.90   // Note 12
    ]
    
    // Test with different minimum dB levels
    let testLevels: [Double] = [-60.0, -50.0, -40.0, -30.0]
    
    for minDb in testLevels {
        print("\n🔊 Testing with minimum dB: \(minDb)")
        
        do {
            // This would call our actual detection function
            // For now, we'll simulate the detection results
            let detectedTimes = try detectOnsets(url: testFileURL, minDb: minDb)
            
            print("📊 Results:")
            print("   Expected notes: \(expectedTimes.count)")
            print("   Detected notes: \(detectedTimes.count)")
            
            if detectedTimes.count == expectedTimes.count {
                print("   ✅ SUCCESS: Detected exactly \(detectedTimes.count) notes!")
            } else {
                print("   ❌ FAILURE: Expected \(expectedTimes.count), got \(detectedTimes.count)")
            }
            
            // Check timing accuracy (within 0.1 seconds)
            let tolerance: Double = 0.1
            var accurateDetections = 0
            
            for detectedTime in detectedTimes {
                let closestExpected = expectedTimes.min { abs($0 - detectedTime) < abs($1 - detectedTime) }!
                if abs(detectedTime - closestExpected) <= tolerance {
                    accurateDetections += 1
                }
            }
            
            print("   🎯 Timing accuracy: \(accurateDetections)/\(detectedTimes.count) within \(tolerance)s")
            
            // Show detected times
            print("   📍 Detected times: \(detectedTimes.map { String(format: "%.2f", $0) }.joined(separator: ", "))s")
            
        } catch {
            print("   ❌ Error during detection: \(error)")
        }
    }
    
    print("\n" + "=" * 50)
    print("🏁 Test completed!")
}

// Mock function - this would be replaced with actual AudioAnalysisService.detectOnsets call
func detectOnsets(url: URL, minDb: Double) throws -> [Double] {
    // For now, return a mock result
    // In reality, this would call: AudioAnalysisService.detectOnsets(url: url, minDb: minDb)
    
    // Simulate some detection results for testing
    switch minDb {
    case -60.0:
        return [0.05, 0.92, 1.78, 2.72, 3.58, 4.48, 5.42, 6.28, 7.22, 8.08, 9.02, 9.88] // Close to expected
    case -50.0:
        return [0.05, 0.92, 1.78, 2.72, 3.58, 4.48, 5.42, 6.28, 7.22, 8.08, 9.02] // Missing one note
    case -40.0:
        return [0.05, 0.92, 1.78, 2.72, 3.58, 4.48, 5.42, 6.28, 7.22, 8.08, 9.02, 9.88, 9.95] // Extra detection
    case -30.0:
        return [0.05, 0.92, 1.78, 2.72, 3.58, 4.48, 5.42, 6.28, 7.22, 8.08] // Missing several notes
    default:
        return []
    }
}

// Run the test
testOnsetDetection()

