#!/usr/bin/env swift
/*
 Librosa Onset Detection Bridge for GuitarAccuracy
 This Swift script provides a bridge to the Python librosa onset detection
 */

import Foundation

struct LibrosaOnsetResult: Codable {
    let onsetTimes: [Double]
    let method: String
    let minDb: Double
    let count: Int
    
    enum CodingKeys: String, CodingKey {
        case onsetTimes = "onset_times"
        case method
        case minDb = "min_db"
        case count
    }
}

class LibrosaOnsetDetector {
    private let pythonPath: String
    private let scriptPath: String
    
    init() {
        // Get the directory where this script is located
        let scriptURL = URL(fileURLWithPath: #file)
        let scriptDir = scriptURL.deletingLastPathComponent()
        
        self.scriptPath = scriptDir.appendingPathComponent("librosa_onset_detection.py").path
        // Use the absolute path to the Python executable
        let pythonLink = scriptDir.appendingPathComponent("librosa_env/bin/python").path
        let pythonPath = try? FileManager.default.destinationOfSymbolicLink(atPath: pythonLink)
        self.pythonPath = pythonPath ?? "/opt/homebrew/opt/python@3.13/bin/python3.13"
    }
    
    func detectOnsets(audioFile: String, minDb: Double = -50.0, method: String = "combined") -> Result<[Double], Error> {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        
        // Create a bash script that activates the virtual environment and runs Python
        let bashScript = """
        source \(scriptPath.replacingOccurrences(of: "librosa_onset_detection.py", with: "librosa_env/bin/activate"))
        python \(scriptPath) \(audioFile) --min-db \(minDb) --method \(method)
        """
        
        process.arguments = ["-c", bashScript]
        
        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus != 0 {
                let errorString = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "Unknown error"
                return .failure(NSError(domain: "LibrosaOnsetDetector", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: errorString]))
            }
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let result = try JSONDecoder().decode(LibrosaOnsetResult.self, from: data)
            return .success(result.onsetTimes)
            
        } catch {
            return .failure(error)
        }
    }
}

// Command line interface
if CommandLine.arguments.count < 2 {
    print("Usage: \(CommandLine.arguments[0]) <audio_file> [min_db] [method]")
    exit(1)
}

let audioFile = CommandLine.arguments[1]
let minDb = CommandLine.arguments.count > 2 ? Double(CommandLine.arguments[2]) ?? -50.0 : -50.0
let method = CommandLine.arguments.count > 3 ? CommandLine.arguments[3] : "combined"

let detector = LibrosaOnsetDetector()
let result = detector.detectOnsets(audioFile: audioFile, minDb: minDb, method: method)

switch result {
case .success(let onsetTimes):
    print("Onset times: \(onsetTimes)")
case .failure(let error):
    print("Error: \(error.localizedDescription)")
    exit(1)
}
