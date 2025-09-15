#!/usr/bin/env python3
"""
Aubio-based onset detection script for guitar accuracy analysis.
This replaces the librosa-based LibrosaOnset.py with aubio for more accurate onset detection.
"""

import sys
import os
from aubio import source, onset

def detect_onsets_aubio(filename, expected_notes=14, min_wait_frames=30):
    """
    Detect onsets using aubio library.
    
    Args:
        filename: Path to audio file
        expected_notes: Expected number of notes (for adaptive parameters)
        min_wait_frames: Minimum frames between onsets
    
    Returns:
        List of onset times in seconds
    """
    
    # FFT and hop size parameters
    win_s = 512                 # fft size
    hop_s = win_s // 2          # hop size
    
    # Open audio file
    s = source(filename, 0, hop_s)
    samplerate = s.samplerate
    
    # Create onset detector with adaptive parameters
    # Use different onset detection methods based on expected notes
    if expected_notes <= 8:
        # Few notes - use more sensitive detection
        onset_method = "hfc"  # High Frequency Content
        threshold = 0.3
    elif expected_notes <= 16:
        # Medium notes - balanced detection
        onset_method = "default"  # Default method (usually energy-based)
        threshold = 0.5
    else:
        # Many notes - less sensitive detection
        onset_method = "energy"  # Energy-based
        threshold = 0.7
    
    o = onset(onset_method, win_s, hop_s, samplerate)
    o.set_threshold(threshold)
    
    # List of onsets, in samples
    onsets = []
    
    # Total number of frames read
    total_frames = 0
    
    print(f"Using aubio onset detection:")
    print(f"  - Method: {onset_method}")
    print(f"  - Threshold: {threshold}")
    print(f"  - Window size: {win_s}")
    print(f"  - Hop size: {hop_s}")
    print(f"  - Sample rate: {samplerate}")
    
    while True:
        samples, read = s()
        if o(samples):
            onset_time = o.get_last_s()
            print(f"Onset detected at: {onset_time:.4f}s")
            onsets.append(onset_time)
        total_frames += read
        if read < hop_s: 
            break
    
    # Apply minimum time separation (refractory period)
    if min_wait_frames > 0:
        min_wait_seconds = min_wait_frames * hop_s / samplerate
        filtered_onsets = []
        last_onset = -min_wait_seconds
        
        for onset_time in onsets:
            if onset_time - last_onset >= min_wait_seconds:
                filtered_onsets.append(onset_time)
                last_onset = onset_time
        
        onsets = filtered_onsets
    
    # Filter out onsets that are too close to the beginning (likely false positives)
    min_onset_time = 0.1  # Ignore onsets in the first 100ms
    original_count = len(onsets)
    onsets = [onset for onset in onsets if onset >= min_onset_time]
    filtered_count = original_count - len(onsets)
    if filtered_count > 0:
        print(f"Filtered out {filtered_count} onsets before {min_onset_time}s (likely false positives)")
    
    # Filter out onsets beyond the expected recording duration (15 seconds)
    # This prevents detection of notes after the recording should have stopped
    max_recording_time = 15.0
    original_count = len(onsets)
    onsets = [onset for onset in onsets if onset <= max_recording_time]
    filtered_count = original_count - len(onsets)
    if filtered_count > 0:
        print(f"Filtered out {filtered_count} onsets beyond {max_recording_time}s")
    
    return onsets

def main():
    """Main function to run aubio onset detection."""
    
    # Get command line arguments for expected note count and minimum wait frames
    expected_notes = 14  # default
    min_wait_frames = 30  # default
    
    if len(sys.argv) >= 2:
        expected_notes = int(sys.argv[1])
    if len(sys.argv) >= 3:
        min_wait_frames = int(sys.argv[2])
    
    # Audio file path
    audio_file = './results.wav'
    
    if not os.path.exists(audio_file):
        print(f"Error: Audio file {audio_file} not found")
        sys.exit(1)
    
    try:
        # Detect onsets using aubio
        onset_times = detect_onsets_aubio(audio_file, expected_notes, min_wait_frames)
        
        # Save onset times to file
        with open('./results.beatmap.txt', 'wt') as f:
            f.write('\n'.join(['%.4f' % onset_time for onset_time in onset_times]))
        
        print(f"\nDetected {len(onset_times)} onsets (expected: {expected_notes})")
        print(f"Onset times: {onset_times}")
        
    except Exception as e:
        print(f"Error during onset detection: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
