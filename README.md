# GuitarAccuracy (macOS)

A macOS-only metronome app with adjustable BPM and rhythmic subdivisions (quarter, eighth, eighth triplets, sixteenth, sixteenth triplets). Built with SwiftUI and AVFoundation. No iOS APIs used.

## Prerequisites
- Xcode (16.x)
- macOS 14+
- Homebrew (for XcodeGen)

## Setup
```bash
# One-time: generate the Xcode project and run a Debug build
./scripts/bootstrap-xcode.sh
```

## Open in Xcode
```bash
open macos/GuitarAccuracy.xcodeproj
```

## Run Tests (CLI)
```bash
xcodebuild -project macos/GuitarAccuracy.xcodeproj -scheme GuitarAccuracy -destination 'platform=macOS' test
```

## App Usage
- BPM slider: 20–300, 1 BPM steps
- Pattern picker: segmented control for the subdivisions
- Start/Stop: Space keyboard shortcut
- Preferences persist (BPM, pattern) across launches

## Notes
- Entitlements: App Sandbox only (least privilege)
- Audio: AVAudioEngine schedules short click sample
- Timing: background DispatchSourceTimer; no main-thread blocking
- Logging: os.Logger ready to add categories (future work)

## Project Structure
- macos/Sources/App: App entry
- macos/Sources/UI: SwiftUI views
- macos/Sources/Features: ViewModels
- macos/Sources/Services: Audio/timing utilities
- macos/Tests: Unit and UI tests

## License
MIT
