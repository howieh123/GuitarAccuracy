# Tasks: GuitarAccuracy macOS Metronome

**Input**: Design documents from `/Users/howieh123/GuitarAccuracy/specs/001-create-a-guitar/`
**Prerequisites**: plan.md (required), research.md, data-model.md

## Phase 3.1: Setup
- [ ] T001 Ensure shared scheme exists and CI builds
      - open: `/Users/howieh123/GuitarAccuracy/macos/GuitarAccuracy.xcodeproj`
      - cmd: `xcodebuild -project /Users/howieh123/GuitarAccuracy/macos/GuitarAccuracy.xcodeproj -scheme GuitarAccuracy -configuration Debug -destination 'platform=macOS' build`
- [ ] T002 Verify `.xcconfig` values and minimum macOS version (14.0)
      - files: `/Users/howieh123/GuitarAccuracy/macos/Configurations/Debug.xcconfig`, `/Users/howieh123/GuitarAccuracy/macos/Configurations/Release.xcconfig`
- [ ] T003 [P] Add SwiftFormat/SwiftLint config and CI step
      - files: `/Users/howieh123/GuitarAccuracy/.swiftformat`, `/Users/howieh123/GuitarAccuracy/.swiftlint.yml`

## Phase 3.2: Tests First (TDD)
- [ ] T004 [P] Unit tests for BPM→rate computation
      - file: `/Users/howieh123/GuitarAccuracy/macos/Tests/Unit/MetronomeMathTests.swift`
- [ ] T005 [P] Unit tests for pattern switching while running
      - file: `/Users/howieh123/GuitarAccuracy/macos/Tests/Unit/PatternSwitchingTests.swift`
- [ ] T006 UI tests for start/stop, BPM slider, pattern picker
      - file: `/Users/howieh123/GuitarAccuracy/macos/Tests/UITests/MetronomeUITests.swift`

## Phase 3.3: Core Implementation
- [ ] T007 [P] Implement `MetronomeMath.swift` (multiplier, ticks/sec)
      - file: `/Users/howieh123/GuitarAccuracy/macos/Sources/Services/MetronomeMath.swift`
- [ ] T008 [P] Implement `MetronomeEngine.swift` (AVAudioEngine scheduling)
      - file: `/Users/howieh123/GuitarAccuracy/macos/Sources/Services/MetronomeEngine.swift`
- [ ] T009 Implement `MetronomeViewModel.swift` (state, bindings, commands)
      - file: `/Users/howieh123/GuitarAccuracy/macos/Sources/Features/Metronome/MetronomeViewModel.swift`
- [ ] T010 Implement `MetronomeView.swift` (SwiftUI UI: slider, picker, start/stop)
      - file: `/Users/howieh123/GuitarAccuracy/macos/Sources/UI/MetronomeView.swift`
- [ ] T011 Wire `GuitarAccuracyApp.swift` to show `MetronomeView`
      - file: `/Users/howieh123/GuitarAccuracy/macos/Sources/App/GuitarAccuracyApp.swift`
- [ ] T012 Add `os.Logger` categories and replace prints
      - files: `/Users/howieh123/GuitarAccuracy/macos/Sources/**`

## Phase 3.4: Integration
- [ ] T013 Validate timing stability with Instruments and adjust buffer scheduling
      - action: Use Time Profiler and System Trace while running at 60/120/240 BPM
- [ ] T014 Verify app sandbox entitlements are minimal and documented
      - file: `/Users/howieh123/GuitarAccuracy/macos/GuitarAccuracy.entitlements`

## Phase 3.5: Polish
- [ ] T015 [P] Add accessibility labels and keyboard shortcuts (e.g., Space to toggle)
      - files: `/Users/howieh123/GuitarAccuracy/macos/Sources/UI/MetronomeView.swift`
- [ ] T016 [P] Update `README` and Quickstart with screenshots
      - file: `/Users/howieh123/GuitarAccuracy/specs/001-create-a-guitar/quickstart.md`
- [ ] T017 Raise unit test coverage to ≥80%

## Dependencies
- Tests (T004-T006) before implementation (T007-T012)
- T009 blocks T010 and T011

## Parallel Example
```
Task: "Unit tests for BPM→rate computation"
Task: "Unit tests for pattern switching while running"
Task: "UI tests for start/stop, BPM slider, pattern picker"
```

## Validation Checklist
- [ ] Tests precede implementation; failing states recorded
- [ ] Each task specifies exact file path
- [ ] Parallel tasks modify different files
- [ ] CI build command included
- [ ] Accessibility considerations addressed
