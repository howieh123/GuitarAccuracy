import Foundation
import AVFoundation

public final class MetronomeEngine {
    private let audioEngine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var clickBuffer: AVAudioPCMBuffer?
    private var audioFormat: AVAudioFormat?

    public init() {
        audioEngine.attach(player)
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        audioFormat = format
        audioEngine.connect(player, to: audioEngine.mainMixerNode, format: format)
        prepareClickBuffer()
        try? audioEngine.start()
    }

    private func prepareClickBuffer() {
        guard let format = audioFormat else { return }
        // Generate a short click (sine burst)
        let duration: Double = 0.01
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let freq = 2000.0
        let amp = 0.8
        if let channel = buffer.floatChannelData?[0] {
            for i in 0..<Int(frameCount) {
                let t = Double(i) / sampleRate
                channel[i] = Float(sin(2.0 * .pi * freq * t) * amp)
            }
        }
        self.clickBuffer = buffer
    }

    public func scheduleClick() {
        guard let click = clickBuffer else { return }
        player.scheduleBuffer(click, at: nil, options: .interrupts, completionHandler: nil)
        if !player.isPlaying {
            player.play()
        }
    }

    public func stopPlayback() {
        if player.isPlaying {
            player.stop()
        }
    }
}


