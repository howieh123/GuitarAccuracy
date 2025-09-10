import SwiftUI
import AVFoundation

@main
struct GuitarAccuracyApp: App {
    init() {
        // Prompt for microphone access at app launch
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { _ in }
        }
    }
    var body: some Scene {
        WindowGroup {
            MetronomeView()
        }
        .windowResizability(.contentSize)
    }
}
