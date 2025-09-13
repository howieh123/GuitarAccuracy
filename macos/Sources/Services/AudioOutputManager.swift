import Foundation
import CoreAudio

public struct AudioOutputDevice: Identifiable, Hashable {
    public let id: String // Device UID
    public let name: String
}

public enum AudioOutputManager {
    private static func deviceIDs() -> [AudioDeviceID] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize) == noErr else {
            return []
        }
        let count = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: count)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize, &deviceIDs) == noErr else {
            return []
        }
        return deviceIDs
    }

    private static func hasOutputChannels(_ deviceID: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        if AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &dataSize) != noErr || dataSize == 0 {
            return false
        }
        let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: Int(dataSize))
        defer { bufferList.deallocate() }
        if AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, bufferList) != noErr {
            return false
        }
        let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
        var channels: UInt32 = 0
        for b in buffers { channels += b.mNumberChannels }
        return channels > 0
    }

    private static func stringProperty(_ deviceID: AudioDeviceID, selector: AudioObjectPropertySelector) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize = UInt32(MemoryLayout<CFString?>.size)
        var cfStr: CFString? = nil
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, withUnsafeMutablePointer(to: &cfStr) { $0 })
        if status == noErr, let s = cfStr as String? { return s }
        return nil
    }

    public static func listOutputDevices() -> [AudioOutputDevice] {
        deviceIDs()
            .filter { hasOutputChannels($0) }
            .compactMap { did in
                let uid = stringProperty(did, selector: kAudioDevicePropertyDeviceUID)
                let name = stringProperty(did, selector: kAudioObjectPropertyName) ?? uid
                if let uid, let name { return AudioOutputDevice(id: uid, name: name) }
                return nil
            }
    }

    public static func defaultOutputUID() -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = AudioDeviceID(0)
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        if AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize, &deviceID) != noErr {
            return nil
        }
        return stringProperty(deviceID, selector: kAudioDevicePropertyDeviceUID)
    }

    public static func setDefaultOutput(uid: String) -> Bool {
        // Find device ID by UID
        guard let target = deviceIDs().first(where: { stringProperty($0, selector: kAudioDevicePropertyDeviceUID) == uid }) else { return false }
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dev = target
        let dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, dataSize, &dev)
        return status == noErr
    }
}


