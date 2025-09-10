# GuitarAccuracy (macOS)

A comprehensive macOS metronome and guitar accuracy training application featuring audio recording, performance analysis, and customizable audio routing. Built with SwiftUI and AVFoundation exclusively for macOS 14+.

## Features

### Core Metronome
- **Adjustable BPM**: 20-300 BPM with precise slider control and +/- step buttons
- **Rhythmic Patterns**: Quarter, eighth, eighth triplets, sixteenth, sixteenth triplets
- **Visual Metronome**: Animated pulse indicator with accent highlighting for group boundaries
- **Keyboard Shortcuts**: Space bar to start/stop metronome
- **Persistent Settings**: BPM and pattern preferences saved across app launches

### Audio Recording & Analysis
- **15-Second Recording**: High-quality audio capture with live input level monitoring
- **Pre-roll Countdown**: 5-second countdown before recording begins
- **Recording Countdown**: Real-time display of remaining recording time
- **Automatic Playback**: Plays back recorded audio after completion
- **Cancellation Support**: Stop recording at any time without analysis

### Performance Analysis
- **Timing Analysis**: Compares played notes against metronome beats
- **Color-Coded Accuracy**:
  - 🟢 Green: ≤ 20ms early/late
  - 🟡 Yellow: 21-50ms early/late  
  - 🔴 Red: > 50ms early/late
- **Accuracy Score**: Percentage of green detections vs total detections
- **Latency Compensation**: Automatically adjusts for audio input latency
- **Trimmed Analysis**: Excludes first 2 seconds of recording for cleaner results
- **Interactive Graph**: Scrollable visualization with legend and axis labels

### Audio Device Management
- **Input Selection**: Choose from available microphones and audio interfaces
- **Output Selection**: Route metronome clicks and playback to specific devices (e.g., headset)
- **Device Refresh**: Update device list without restarting app
- **Live Level Meter**: Real-time input level monitoring with dBFS display
- **Sensitivity Control**: Adjustable onset detection threshold (-80 to -10 dB)

### User Interface
- **Modern Design**: Clean, compact controls with proper spacing
- **Responsive Layout**: Auto-resizing window that maximizes for analysis view
- **Accessibility**: Full keyboard navigation and screen reader support
- **Visual Feedback**: Animated metronome pulse synchronized with audio clicks
- **Analysis Panel**: Collapsible disclosure group with scrollable content

## Prerequisites
- Xcode 16.x
- macOS 14.0+
- Homebrew (for XcodeGen)

## Setup
```bash
# Generate Xcode project and run initial build
./scripts/bootstrap-xcode.sh
```

## Open in Xcode
```bash
open macos/GuitarAccuracy.xcodeproj
```

## Run Tests
```bash
# Unit and UI tests
xcodebuild -project macos/GuitarAccuracy.xcodeproj -scheme GuitarAccuracy -destination 'platform=macOS' test
```

## Usage Guide

### Basic Metronome
1. Adjust BPM using slider or +/- buttons
2. Select rhythmic pattern from vertical picker
3. Press Space or click Start to begin metronome
4. Visual pulse indicator shows beat timing and accents

### Recording Session
1. Select input device (microphone/interface)
2. Adjust "Min Level" threshold for note detection sensitivity
3. Click "Record 15s" to start 5-second countdown
4. Metronome stops during countdown, resumes with recording
5. Play along with metronome for 15 seconds
6. Automatic playback followed by analysis results

### Analysis Results
- **Graph View**: Blue lines show expected beats, colored circles show played notes
- **Accuracy Score**: Green percentage indicates timing precision
- **Legend**: Color coding explanation for timing errors
- **Window Management**: Auto-maximizes for analysis, restores when cleared

### Audio Routing
- **Input**: Choose microphone or audio interface for recording
- **Output**: Select speakers or headset for metronome clicks and playback
- **Refresh**: Update device list when connecting/disconnecting hardware

## Technical Architecture

### Core Technologies
- **SwiftUI**: Modern declarative UI framework
- **AVFoundation**: Audio engine, recording, and playback
- **CoreAudio**: Low-level audio device management
- **DispatchSourceTimer**: Precise background timing
- **UserDefaults**: Persistent user preferences

### Audio Processing
- **Energy-Based Onset Detection**: Time-domain analysis for note detection
- **Latency Compensation**: Median offset calculation from initial onsets
- **Format Handling**: Robust audio file processing with fallbacks
- **Real-time Monitoring**: Live input level metering during recording

### Project Structure
```
macos/
├── Sources/
│   ├── App/                    # App entry point
│   ├── UI/                     # SwiftUI views
│   ├── Features/Metronome/      # ViewModels and business logic
│   └── Services/               # Audio utilities and analysis
├── Assets.xcassets/            # App icon and resources
├── Configurations/            # Build configurations
└── Tests/                     # Unit and UI tests
```

### Key Components
- **MetronomeEngine**: AVAudioEngine-based click generation
- **AudioRecorder**: 15-second recording with level monitoring
- **AudioAnalysisService**: Onset detection and timing analysis
- **AudioInputManager**: Microphone/interface device enumeration
- **AudioOutputManager**: Speaker/headset device management
- **MetronomeViewModel**: Central state management and coordination

## Security & Permissions
- **App Sandbox**: Minimal required entitlements
- **Microphone Access**: Requested at app launch
- **Audio Input**: Required for recording functionality
- **No Network**: Offline operation only

## Performance Notes
- **Background Timing**: Non-blocking metronome scheduling
- **Memory Efficient**: Streaming audio processing
- **Responsive UI**: Async operations with proper cancellation
- **Device Management**: Efficient CoreAudio enumeration

## License
MIT License - See LICENSE file for details
