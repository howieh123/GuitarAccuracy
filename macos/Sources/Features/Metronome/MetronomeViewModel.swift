import Foundation

@MainActor
public final class MetronomeViewModel: ObservableObject {
    @Published public var bpm: Int
    @Published public var pattern: Pattern
    @Published public var isRunning: Bool
    @Published public var inputDevices: [AudioInputDevice] = []
    @Published public var selectedInputDeviceId: String? {
        didSet {
            UserDefaults.standard.set(selectedInputDeviceId, forKey: "audio.input.deviceId")
        }
    }
    @Published public var isPreRoll: Bool = false
    @Published public var preRollSeconds: Int = 0
    @Published public var isRecording: Bool = false
    @Published public var remainingSeconds: Int = 0
    @Published public var analysisSeries: AnalysisSeries? = nil
    @Published public var inputLevelDb: Double = .nan
    @Published public var onsetMinDb: Double = -30.0 {
        didSet {
            UserDefaults.standard.set(onsetMinDb, forKey: "analysis.minDb")
        }
    }
    @Published public var tickCount: Int = 0
    @Published public var outputDevices: [AudioOutputDevice] = []
    @Published public var selectedOutputUID: String? {
        didSet {
            UserDefaults.standard.set(selectedOutputUID, forKey: "audio.output.uid")
            // Configure the metronome engine to use the selected output device
            engine.configureOutputDevice(deviceUID: selectedOutputUID)
        }
    }

    private let engine: MetronomeEngine
    private let recorder = AudioRecorder()
    private var timer: Timer?
    private var dispatchTimer: DispatchSourceTimer?
    private var preRollTimer: DispatchSourceTimer?
    private var recordingTimer: DispatchSourceTimer?
    private var recordingTask: Task<Void, Never>? = nil

    public init(bpm: Int = 120, pattern: Pattern = .quarter, engine: MetronomeEngine = MetronomeEngine()) {
        let storedBPM = UserDefaults.standard.integer(forKey: "metronome.bpm")
        self.bpm = storedBPM == 0 ? bpm : storedBPM
        if let raw = UserDefaults.standard.string(forKey: "metronome.pattern"),
           let restored = MetronomeViewModel.decodePattern(raw) {
            self.pattern = restored
        } else {
            self.pattern = pattern
        }
        self.isRunning = false
        self.engine = engine
        self.inputDevices = AudioInputManager.listAudioInputDevices()
        self.selectedInputDeviceId = UserDefaults.standard.string(forKey: "audio.input.deviceId")
        if let storedMin = UserDefaults.standard.object(forKey: "analysis.minDb") as? Double {
            self.onsetMinDb = storedMin
        }
        self.outputDevices = AudioOutputManager.listOutputDevices()
        self.selectedOutputUID = UserDefaults.standard.string(forKey: "audio.output.uid") ?? AudioOutputManager.defaultOutputUID()
        
        // Configure the engine with the selected output device
        if let outputUID = self.selectedOutputUID {
            engine.configureOutputDevice(deviceUID: outputUID)
        }
    }

    public func start() {
        guard !isRunning else { return }
        isRunning = true
        schedule()
    }

    public func refreshDevices() {
        self.inputDevices = AudioInputManager.listAudioInputDevices()
        self.outputDevices = AudioOutputManager.listOutputDevices()
        
        // Reconfigure the engine with the current output device selection
        engine.configureOutputDevice(deviceUID: selectedOutputUID)
    }

    public func record15s() {
        // Toggle: if currently pre-rolling or recording, cancel and reset
        if isPreRoll || isRecording {
            cancelRecordingFlow()
            return
        }

        isPreRoll = true
        preRollSeconds = 5
        // Stop metronome during countdown
        if isRunning { stop() }
        preRollTimer?.cancel()
        let pr = DispatchSource.makeTimerSource(queue: .main)
        pr.schedule(deadline: .now() + 1, repeating: 1)
        pr.setEventHandler { [weak self] in
            guard let self else { return }
            if self.preRollSeconds > 0 { self.preRollSeconds -= 1 }
            if self.preRollSeconds <= 0 {
                self.preRollTimer?.cancel()
                self.preRollTimer = nil
                self.isPreRoll = false
                self.startRecording15s()
            }
        }
        preRollTimer = pr
        pr.resume()
    }

    private func startRecording15s() {
        isRecording = true
        remainingSeconds = 15
        // Start metronome at the same moment as recording begins
        if !isRunning { start() } else { schedule() }
        recordingTimer?.cancel()
        let rt = DispatchSource.makeTimerSource(queue: .main)
        rt.schedule(deadline: .now() + 1, repeating: 1)
        rt.setEventHandler { [weak self] in
            guard let self else { return }
            if self.remainingSeconds > 0 { self.remainingSeconds -= 1 }
            if self.remainingSeconds <= 0 {
                self.recordingTimer?.cancel()
                self.recordingTimer = nil
            }
        }
        recordingTimer = rt
        rt.resume()

        recordingTask = Task { [weak self] in
            guard let self else { return }
            do {
                recorder.levelHandler = { [weak self] db in
                    Task { @MainActor in self?.inputLevelDb = db }
                }
                try await recorder.record(for: 15.0, deviceId: selectedInputDeviceId)
                let cancelled = Task.isCancelled
                await MainActor.run { self.stop() }
                if !cancelled {
                    try recorder.playback()
                    if let url = recorder.lastRecordingURL {
                        let rawOnsets = try AudioAnalysisService.detectOnsets(url: url, minDb: onsetMinDb)
                        // Exclude first 2 seconds; re-base to 0
                        let trimmed = rawOnsets.filter { $0 >= 2.0 }.map { $0 - 2.0 }
                        let series = AudioAnalysisService.buildSeries(onsets: trimmed, bpm: bpm, pattern: pattern, duration: 13.0)
                        await MainActor.run { self.analysisSeries = series }
                    }
                }
            } catch {
                print("Recording error: \(error)")
            }
            await MainActor.run {
                self.recordingTimer?.cancel()
                self.recordingTimer = nil
                self.isRecording = false
                self.remainingSeconds = 0
                self.recordingTask = nil
            }
        }
    }

    private func cancelRecordingFlow() {
        preRollTimer?.cancel()
        preRollTimer = nil
        recordingTimer?.cancel()
        recordingTimer = nil
        isPreRoll = false
        isRecording = false
        preRollSeconds = 0
        remainingSeconds = 0
        recordingTask?.cancel()
        recorder.cancel()
    }

    public func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        dispatchTimer?.cancel()
        dispatchTimer = nil
        engine.stopPlayback()
    }

    public func schedule() {
        timer?.invalidate()
        dispatchTimer?.cancel()
        let hz = MetronomeMath.ticksPerSecond(bpm: bpm, pattern: pattern)
        guard hz > 0 else { return }
        let interval = 1.0 / hz
        // Restart visual tick cycle on (re)schedule so accent aligns to start
        tickCount = 0
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInitiated))
        timer.schedule(deadline: .now() + interval, repeating: interval)
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            self.engine.scheduleClick()
            Task { @MainActor in
                self.tickCount &+= 1
            }
        }
        self.dispatchTimer = timer
        timer.resume()
    }

    // Persistence hooks
    public func storePreferences() {
        UserDefaults.standard.set(self.bpm, forKey: "metronome.bpm")
        UserDefaults.standard.set(MetronomeViewModel.encodePattern(self.pattern), forKey: "metronome.pattern")
    }

    private static func encodePattern(_ p: Pattern) -> String {
        switch p {
        case .quarter: return "quarter"
        case .eighth: return "eighth"
        case .eighthTriplet: return "eighthTriplet"
        case .sixteenth: return "sixteenth"
        case .sixteenthTriplet: return "sixteenthTriplet"
        }
    }

    private static func decodePattern(_ s: String) -> Pattern? {
        switch s {
        case "quarter": return .quarter
        case "eighth": return .eighth
        case "eighthTriplet": return .eighthTriplet
        case "sixteenth": return .sixteenth
        case "sixteenthTriplet": return .sixteenthTriplet
        default: return nil
        }
    }
}


