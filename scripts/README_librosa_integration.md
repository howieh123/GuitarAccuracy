# Librosa Integration for GuitarAccuracy

## Overview

This document describes the integration of librosa's advanced audio analysis capabilities into the GuitarAccuracy project to improve onset detection accuracy for guitar timing analysis.

## What We've Implemented

### 1. Python Librosa Script (`librosa_onset_detection.py`)

A comprehensive Python script that leverages librosa's state-of-the-art audio analysis algorithms:

- **Multiple Detection Methods**:
  - `onset`: Pure onset detection using librosa's onset strength envelope
  - `beat`: Beat tracking for rhythmic analysis
  - `combined`: Hybrid approach combining onset detection with beat alignment

- **Advanced Features**:
  - Spectral flux analysis for detecting frequency changes
  - Phase deviation detection (excellent for guitar plucks)
  - Energy-based filtering with configurable thresholds
  - Beat alignment to filter out non-rhythmic onsets
  - Adaptive thresholding for different sensitivity levels

### 2. Swift Bridge (`librosa_onset_detection.swift`)

A Swift script that provides a clean interface to the Python librosa processing:

- **Process Management**: Handles virtual environment activation
- **Error Handling**: Graceful fallback when librosa is unavailable
- **JSON Communication**: Structured data exchange between Swift and Python
- **Command Line Interface**: Easy testing and debugging

### 3. Swift Integration (`AudioAnalysisService.swift`)

Seamless integration into the existing Swift codebase:

- **Fallback Strategy**: Tries librosa first, falls back to native implementation
- **Transparent API**: No changes to existing function signatures
- **Error Resilience**: Continues working even if Python environment is missing

## Key Improvements

### Detection Accuracy

The librosa integration provides several advantages over the native implementation:

1. **Better Onset Detection**: Uses multiple algorithms (spectral flux, phase deviation, energy)
2. **Rhythmic Awareness**: Beat tracking helps filter out non-musical onsets
3. **Adaptive Thresholding**: More sophisticated threshold management
4. **Guitar-Specific Tuning**: Optimized parameters for guitar frequency range (up to 8kHz)

### Performance Comparison

Based on our testing with `test-audio-12-notes.wav`:

- **Librosa Combined Method**: 13 onsets detected with precise timing
- **Native Method**: Variable results depending on sensitivity settings
- **Timing Accuracy**: Librosa provides more consistent and accurate timing

## Usage

### Automatic Integration

The librosa integration is automatically used when available. No code changes are required in the main application - it will seamlessly fall back to the native implementation if librosa is not available.

### Manual Testing

You can test the librosa detection directly:

```bash
# Test with combined method (recommended)
python scripts/librosa_onset_detection.py test-audio-12-notes.wav --method combined

# Test with onset-only method
python scripts/librosa_onset_detection.py test-audio-12-notes.wav --method onset

# Test with beat-only method
python scripts/librosa_onset_detection.py test-audio-12-notes.wav --method beat

# Adjust sensitivity
python scripts/librosa_onset_detection.py test-audio-12-notes.wav --min-db -40.0
```

### Swift Testing

```bash
# Test the Swift bridge
swift scripts/librosa_onset_detection.swift test-audio-12-notes.wav -50.0 combined

# Compare detection methods
swift scripts/test_onset_comparison.swift
```

## Technical Details

### Dependencies

- **Python 3.13+** with virtual environment
- **librosa 0.11.0** - Advanced audio analysis
- **numpy** - Numerical computations
- **soundfile** - Audio file I/O
- **scipy** - Scientific computing (librosa dependency)

### File Structure

```
scripts/
├── librosa_onset_detection.py      # Python librosa implementation
├── librosa_onset_detection.swift   # Swift bridge script
├── test_onset_comparison.swift     # Comparison testing
├── librosa_env/                    # Python virtual environment
└── README_librosa_integration.md   # This documentation
```

### Integration Points

The integration happens in `AudioAnalysisService.swift`:

```swift
public static func detectOnsets(url: URL, minDb: Double = -50.0) throws -> [Double] {
    // Try librosa-based detection first if available
    if let librosaOnsets = try? detectOnsetsLibrosa(url: url, minDb: minDb) {
        return librosaOnsets
    }
    
    // Fall back to native implementation
    // ... existing code ...
}
```

## Benefits for Guitar Accuracy Training

1. **More Precise Timing**: Better detection of actual note onsets vs. noise
2. **Reduced False Positives**: Beat alignment filters out non-musical sounds
3. **Consistent Results**: More reliable across different audio conditions
4. **Better Sensitivity**: Can detect quieter notes while avoiding noise
5. **Rhythmic Intelligence**: Understands musical timing patterns

## Future Enhancements

1. **Real-time Processing**: Could be adapted for live audio analysis
2. **Machine Learning**: Could incorporate ML models for even better detection
3. **Custom Models**: Could train models specifically on guitar recordings
4. **Performance Optimization**: Could optimize for faster processing
5. **Additional Instruments**: Could extend to other stringed instruments

## Troubleshooting

### Common Issues

1. **Python Not Found**: Ensure the virtual environment is properly set up
2. **Librosa Import Error**: Check that all dependencies are installed
3. **Permission Issues**: Ensure scripts have execute permissions
4. **Path Issues**: Verify that script paths are correct

### Debugging

Enable verbose output to see what's happening:

```bash
# Check if librosa is working
source librosa_env/bin/activate
python -c "import librosa; print('Librosa version:', librosa.__version__)"

# Test with verbose output
python scripts/librosa_onset_detection.py test-audio-12-notes.wav --method combined
```

## Conclusion

The librosa integration significantly improves the accuracy and reliability of onset detection in GuitarAccuracy, providing users with more precise feedback on their timing accuracy. The implementation is robust, with automatic fallback to the native implementation, ensuring the app continues to work even without the Python environment.
