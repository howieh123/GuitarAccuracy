# Quickstart Validation: GuitarAccuracy Metronome

## Build
```bash
/Users/howieh123/GuitarAccuracy/scripts/bootstrap-xcode.sh
```

## Run
```bash
open /Users/howieh123/GuitarAccuracy/macos/GuitarAccuracy.xcodeproj
# Cmd+R to run from Xcode
```

## Validate Timing
- Set BPM = 120, select quarter notes → expect ~2.0 Hz clicks
- Switch to eighth → ~4.0 Hz
- Switch to eighth triplets → ~6.0 Hz
- Switch to sixteenth → ~8.0 Hz
- Switch to sixteenth triplets → ~12.0 Hz

## UI Checks
- Start/Stop button toggles state
- BPM slider range 20–300 with 1 BPM step
- Pattern picker switches immediately without audio glitches
- Dark mode renders legibly
