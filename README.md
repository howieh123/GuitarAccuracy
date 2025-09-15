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
- **Pre-roll Countdown**: 4-second countdown before recording begins
- **Recording Countdown**: Real-time display of remaining recording time
- **Automatic Playback**: Plays back recorded audio after completion
- **Cancellation Support**: Stop recording at any time without analysis

### Performance Analysis
- **Interval-Based Analysis**: Measures timing consistency between consecutive notes
- **Aubio Onset Detection**: Advanced audio analysis using the aubio library for precise note detection
- **Color-Coded Accuracy**:
  - 🟢 Green: ≤ 35ms timing error (excellent)
  - 🟡 Yellow: 36-100ms timing error (good)
  - 🔴 Red: > 100ms timing error (needs work)
- **Weighted Accuracy Score**: Green notes = 1.0 points, Yellow notes = 0.5 points, Red notes = 0.0 points
- **False Positive Filtering**: Ignores onsets in first 100ms to prevent audio artifacts
- **Interactive Graph**: Scrollable visualization with first note in gray (no interval to measure)

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
- Python 3.x with aubio library

## Setup

### Install Dependencies
```bash
# Install aubio library for onset detection
pip3 install aubio

# Generate Xcode project and run initial build
./scripts/bootstrap-xcode.sh
```

### Python Environment
The app uses a Python script (`AubioOnset.py`) for advanced onset detection. Make sure Python 3.x and the aubio library are installed and accessible from the command line.

## Building from Command Line

You can build the app without opening Xcode using the provided build script:

```bash
# Basic build (Debug configuration)
./build

# Build Release configuration
./build --configuration Release

# Clean build and run tests
./build --clean --test

# Create distribution archive
./build --archive

# Verbose build output
./build --verbose

# Show all options
./build --help
```

The build script automatically:
- Generates the Xcode project using XcodeGen
- Handles dependencies (installs XcodeGen via Homebrew if needed)
- Provides colored output and progress information
- Creates organized build artifacts in the `build-output/` directory
- Supports both Debug and Release configurations

## Open in Xcode
```bash
open macos/GuitarAccuracy.xcodeproj
```

## Run Tests
```bash
# Using the build script
./build --test

# Or directly with xcodebuild
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
3. Click "Record 15s (4s countdown)" to start 4-second countdown
4. Metronome plays during countdown and continues with recording
5. Play along with metronome for 15 seconds
6. Automatic playback followed by rhythm consistency analysis

### Analysis Results
- **Graph View**: Colored circles show played notes with interval-based timing analysis
- **Rhythm Accuracy**: Weighted percentage based on timing consistency between consecutive notes
- **First Note**: Displayed in gray (no interval to measure)
- **Interval Analysis**: Each note's timing measured against the previous note
- **Debug Output**: Detailed timing analysis in console for practice improvement

### Audio Routing
- **Input**: Choose microphone or audio interface for recording
- **Output**: Select speakers or headset for metronome clicks and playback
- **Refresh**: Update device list when connecting/disconnecting hardware

## Analysis Methodology

### Interval-Based Rhythm Analysis
Unlike traditional metronome-based analysis, GuitarAccuracy measures the consistency of timing between consecutive notes. This approach:

- **Measures Rhythm Consistency**: Analyzes the timing between each note and the previous note
- **No Metronome Dependency**: Works regardless of metronome accuracy or latency issues
- **Realistic Scoring**: Uses guitar-appropriate timing tolerances (35ms, 100ms thresholds)
- **Weighted Accuracy**: Green notes count as 1.0 points, yellow as 0.5 points, red as 0.0 points

### Expected Intervals by Pattern
- **Quarter Notes**: 1.000s between notes (60 BPM)
- **Eighth Notes**: 0.500s between notes (60 BPM)
- **Eighth Triplets**: 0.333s between notes (60 BPM)
- **Sixteenth Notes**: 0.250s between notes (60 BPM)
- **Sixteenth Triplets**: 0.167s between notes (60 BPM)

### Scoring Thresholds
- **🟢 Green (Excellent)**: ≤ 35ms error from expected interval
- **🟡 Yellow (Good)**: 36-100ms error from expected interval
- **🔴 Red (Needs Work)**: > 100ms error from expected interval

## Technical Architecture

### Core Technologies
- **SwiftUI**: Modern declarative UI framework
- **AVFoundation**: Audio engine, recording, and playback
- **CoreAudio**: Low-level audio device management
- **DispatchSourceTimer**: Precise background timing
- **UserDefaults**: Persistent user preferences

### Audio Processing
- **Aubio Onset Detection**: Advanced spectral analysis using the aubio library for precise note detection
- **Interval-Based Analysis**: Measures timing consistency between consecutive notes rather than absolute timing
- **Adaptive Thresholds**: Dynamic sensitivity adjustment based on expected note count
- **False Positive Filtering**: Ignores onsets in first 100ms to prevent audio artifacts
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
- **AudioAnalysisService**: Interval-based timing analysis and aubio integration
- **AubioOnset.py**: Python script for advanced onset detection using aubio library
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
