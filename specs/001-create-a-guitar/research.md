# Research: GuitarAccuracy macOS Metronome

## Unknowns and Clarifications
- Visual beat emphasis (accented first subdivision) [NEEDS CLARIFICATION]
- Volume control and click sound choice [NEEDS CLARIFICATION]
- Persistence of last-used BPM and pattern [NEEDS CLARIFICATION]

## Best Practices and Decisions
- UI: SwiftUI for modern macOS UI; avoid iOS-only APIs.
- Audio: AVAudioEngine + AVAudioPlayerNode for low-latency click scheduling; pre-load short click sample.
- Timing: Compute intervals by BPM and subdivision multiplier: quarter (1x), eighth (2x), eighth triplets (3x), sixteenth (4x), sixteenth triplets (6x). Frequency = BPM/60 * multiplier.
- Concurrency: Use Swift Concurrency; UI updates on @MainActor; audio scheduling on background.
- Logging: os.Logger categories for UI and audio.
- Testing: XCTest for rate computation; XCUITest to verify controls exist and start/stop interactions.

## Alternatives Considered
- Core Audio low-level scheduling → Higher complexity; AVAudioEngine sufficient.
- Timer-based clicks → Potential jitter; engine scheduling preferred.

## Rationale
- Maximizes macOS-native tooling and testability while meeting timing requirements.
