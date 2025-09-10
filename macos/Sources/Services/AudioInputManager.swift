import Foundation
import AVFoundation

public struct AudioInputDevice: Identifiable, Hashable {
    public let id: String // AVCaptureDevice.uniqueID
    public let name: String // AVCaptureDevice.localizedName
}

public enum AudioInputManager {
    public static func listAudioInputDevices() -> [AudioInputDevice] {
        let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: [
            AVCaptureDevice.DeviceType.microphone,
            AVCaptureDevice.DeviceType.external
        ], mediaType: .audio, position: .unspecified)
        return discovery.devices.map { AudioInputDevice(id: $0.uniqueID, name: $0.localizedName) }
    }

    public static func findDevice(by id: String?) -> AVCaptureDevice? {
        let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: [
            AVCaptureDevice.DeviceType.microphone,
            AVCaptureDevice.DeviceType.external
        ], mediaType: .audio, position: .unspecified)
        guard let id else { return AVCaptureDevice.default(for: .audio) ?? discovery.devices.first }
        return discovery.devices.first { $0.uniqueID == id } ?? AVCaptureDevice.default(for: .audio) ?? discovery.devices.first
    }
}


