import XCTest
import AVFoundation
@testable import GuitarAccuracy

final class OnsetDetectionTests: XCTestCase {
    
    func testOnsetDetectionWithRealGuitarRecording() throws {
        // Load the real guitar recording with 12 notes at 120 BPM
        let testFileURL = URL(fileURLWithPath: "/Users/howieh123/GuitarAccuracy/FirstProject.wav")
        
        guard FileManager.default.fileExists(atPath: testFileURL.path) else {
            XCTFail("Real guitar test file not found at: \(testFileURL.path)")
            return
        }
        
        // Expected note times for 120 BPM (0.5 seconds per beat)
        // 12 notes starting at 0.0s, each 0.5s apart
        let expectedTimes: [Double] = [
            0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 5.5
        ]
        
        print("🧪 Testing onset detection with real guitar recording (120 BPM)")
        print("📁 Test file: \(testFileURL.path)")
        print("🎵 Expected: 12 guitar notes at 0.5s intervals")
        
        // Test with different sensitivity levels
        let testCases: [(minDb: Double, description: String)] = [
            (-60.0, "Very sensitive (detects quiet notes)"),
            (-50.0, "Standard sensitivity"),
            (-40.0, "Less sensitive (ignores quiet notes)"),
            (-30.0, "Very selective (only loud notes)")
        ]
        
        for testCase in testCases {
            print("\n🔊 Testing with \(testCase.description): \(testCase.minDb) dB")
            
            do {
                let detectedTimes = try AudioAnalysisService.detectOnsets(url: testFileURL, minDb: testCase.minDb)
                
                print("📊 Results:")
                print("   Expected: \(expectedTimes.count) notes")
                print("   Detected: \(detectedTimes.count) notes")
                
                // Test 1: Correct number of detections
                if detectedTimes.count == expectedTimes.count {
                    print("   ✅ SUCCESS: Detected exactly \(detectedTimes.count) notes!")
                } else {
                    print("   ❌ FAILURE: Expected \(expectedTimes.count), got \(detectedTimes.count)")
                    
                    // Show what was detected vs expected
                    print("   Expected times: \(expectedTimes.map { String(format: "%.2f", $0) }.joined(separator: ", "))s")
                    print("   Detected times: \(detectedTimes.map { String(format: "%.2f", $0) }.joined(separator: ", "))s")
                }
                
                // Test 2: Timing accuracy (within 0.2 seconds for real guitar playing)
                let tolerance: Double = 0.2
                var accurateDetections = 0
                var timingErrors: [Double] = []
                
                for detectedTime in detectedTimes {
                    let closestExpected = expectedTimes.min { abs($0 - detectedTime) < abs($1 - detectedTime) }!
                    let error = abs(detectedTime - closestExpected)
                    timingErrors.append(error)
                    
                    if error <= tolerance {
                        accurateDetections += 1
                    }
                }
                
                print("   🎯 Timing accuracy: \(accurateDetections)/\(detectedTimes.count) within \(tolerance)s")
                
                if !timingErrors.isEmpty {
                    let avgError = timingErrors.reduce(0, +) / Double(timingErrors.count)
                    let maxError = timingErrors.max() ?? 0
                    print("   📏 Average timing error: \(String(format: "%.3f", avgError))s")
                    print("   📏 Maximum timing error: \(String(format: "%.3f", maxError))s")
                }
                
                // Test 3: No duplicate detections (within 0.3 seconds for real guitar)
                var duplicates = 0
                for i in 0..<detectedTimes.count {
                    for j in (i+1)..<detectedTimes.count {
                        if abs(detectedTimes[i] - detectedTimes[j]) < 0.3 {
                            duplicates += 1
                        }
                    }
                }
                
                if duplicates == 0 {
                    print("   ✅ No duplicate detections found")
                } else {
                    print("   ⚠️  Found \(duplicates) potential duplicate detections")
                }
                
            } catch {
                print("   ❌ Error during detection: \(error)")
                XCTFail("Detection failed with error: \(error)")
            }
        }
        
        print("\n" + String(repeating: "=", count: 60))
        print("🏁 Onset detection test completed!")
    }
    
    func testOnsetDetectionPerformance() throws {
        let testFileURL = URL(fileURLWithPath: "/Users/howieh123/GuitarAccuracy/FirstProject.wav")
        
        guard FileManager.default.fileExists(atPath: testFileURL.path) else {
            XCTFail("Real guitar test file not found at: \(testFileURL.path)")
            return
        }
        
        measure {
            do {
                _ = try AudioAnalysisService.detectOnsets(url: testFileURL, minDb: -50.0)
            } catch {
                XCTFail("Performance test failed: \(error)")
            }
        }
    }
    
    func testOnsetDetectionWithEmptyFile() {
        // Create a temporary empty audio file
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("empty-test.wav")
        
        // Create a 1-second silent audio file
        let sampleRate: Double = 44100
        let duration: Double = 1.0
        let totalSamples = Int(sampleRate * duration)
        
        let audioFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(totalSamples)
        let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        audioBuffer.frameLength = frameCount
        
        // Fill with silence
        let channelData = audioBuffer.floatChannelData![0]
        for i in 0..<totalSamples {
            channelData[i] = 0.0
        }
        
        do {
            let audioFile = try AVAudioFile(forWriting: tempURL, settings: audioFormat.settings)
            try audioFile.write(from: audioBuffer)
            
            // Test detection on silent file
            let detectedTimes = try AudioAnalysisService.detectOnsets(url: tempURL, minDb: -50.0)
            
            XCTAssertEqual(detectedTimes.count, 0, "Should detect no onsets in silent audio")
            print("✅ Silent audio test passed - detected \(detectedTimes.count) onsets")
            
            // Clean up
            try FileManager.default.removeItem(at: tempURL)
            
        } catch {
            XCTFail("Silent audio test failed: \(error)")
        }
    }
}
