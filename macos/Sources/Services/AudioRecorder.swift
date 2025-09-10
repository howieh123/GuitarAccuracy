import Foundation
import AVFoundation

public final class AudioRecorder: NSObject {
    private let engine = AVAudioEngine()
    private var outputURL: URL?
    private var player: AVAudioPlayer?
    private var writerFile: AVAudioFile?
    public var levelHandler: ((Double) -> Void)? // dBFS updates during recording

    public func record(for seconds: TimeInterval, deviceId: String?) async throws {
        // Request permission (macOS 10.14+)
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                if granted { cont.resume() } else {
                    cont.resume(throwing: NSError(domain: "AudioRecorder", code: 1, userInfo: [NSLocalizedDescriptionKey: "Microphone access denied"]))
                }
            }
        }

        // AVAudioEngine tap to write LPCM .caf (robust, no AAC converter)
        let input = engine.inputNode
        let format = input.inputFormat(forBus: 0)
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("recording.caf")
        if FileManager.default.fileExists(atPath: url.path) { try? FileManager.default.removeItem(at: url) }
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        self.writerFile = file
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, _ in
            // Write audio
            do { try file.write(from: buffer) } catch { fputs("write error: \(error)\n", stderr) }
            // Compute simple RMS dB on first channel for metering
            if let ch = buffer.floatChannelData?.pointee {
                let frames = Int(buffer.frameLength)
                var sum: Float = 0
                var i = 0
                while i < frames { let s = ch[i]; sum += s*s; i += 1 }
                let rms = sqrt(sum / max(1, Float(frames)))
                let db = 20.0 * log10(Double(max(rms, 1e-8)))
                self.levelHandler?(db)
            }
        }
        try engine.start()
        self.outputURL = url

        // Sleep in chunks so we can respond to cancellation
        var remaining = UInt64(seconds * 1_000_000_000)
        while remaining > 0 && !Task.isCancelled {
            let chunk = min(100_000_000, remaining) // 100ms
            try? await Task.sleep(nanoseconds: chunk)
            remaining -= chunk
        }

        input.removeTap(onBus: 0)
        engine.stop()
        // Release writer to flush
        self.writerFile = nil

        // Ensure file is readable before returning
        _ = try? AVAudioFile(forReading: url)
        // Stop metering updates at end of recording
        self.levelHandler?(Double.nan)
        self.levelHandler = nil
    }

    public func cancel() {
        let input = engine.inputNode
        input.removeTap(onBus: 0)
        engine.stop()
        writerFile = nil
        levelHandler?(Double.nan)
        levelHandler = nil
    }

    public func playback() throws {
        guard let url = outputURL else { return }
        self.player = try AVAudioPlayer(contentsOf: url)
        self.player?.prepareToPlay()
        self.player?.play()
    }

    public var lastRecordingURL: URL? { outputURL }
}


