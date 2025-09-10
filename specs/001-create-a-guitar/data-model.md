# Data Model: GuitarAccuracy Metronome

## Entities
- MetronomeSettings
  - bpm: Int (20...300)
  - pattern: Pattern
- Pattern (enum)
  - quarter, eighth, eighthTriplet, sixteenth, sixteenthTriplet
- PlaybackState
  - isRunning: Bool

## Derived Values
- ticksPerSecond = (Double(bpm) / 60.0) * multiplier(pattern)
- multiplier(pattern): 1, 2, 3, 4, 6

## Validation
- bpm must be within range and integer
- pattern must be one of supported cases
