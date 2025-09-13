#!/usr/bin/env python3
"""
Librosa-based onset detection for GuitarAccuracy
This script provides enhanced onset detection using librosa's advanced algorithms
"""

import sys
import json
import librosa
import numpy as np
import argparse
from pathlib import Path

def detect_onsets_librosa(audio_file, min_db=-50.0, method='combined'):
    """
    Detect onsets using librosa with multiple algorithms
    
    Args:
        audio_file: Path to audio file
        min_db: Minimum dB threshold for detection
        method: Detection method ('onset', 'beat', 'combined')
    
    Returns:
        List of onset times in seconds
    """
    try:
        # Load audio file
        y, sr = librosa.load(audio_file, sr=None)
        
        # Convert dB to linear threshold
        min_linear = 10 ** (min_db / 20.0)
        
        if method == 'onset':
            return detect_onsets_only(y, sr, min_linear)
        elif method == 'beat':
            return detect_beats_only(y, sr, min_linear)
        elif method == 'combined':
            return detect_combined(y, sr, min_linear)
        else:
            raise ValueError(f"Unknown method: {method}")
            
    except Exception as e:
        print(f"Error processing {audio_file}: {e}", file=sys.stderr)
        return []

def detect_onsets_only(y, sr, min_linear):
    """Detect onsets using librosa's onset detection algorithms"""
    
    # Compute onset strength envelope using multiple methods
    onset_env = librosa.onset.onset_strength(
        y=y, 
        sr=sr,
        aggregate=np.median,  # More robust than mean
        fmax=8000,  # Focus on guitar frequency range
        hop_length=512
    )
    
    # Detect onsets with adaptive thresholding
    onset_frames = librosa.onset.onset_detect(
        onset_envelope=onset_env,
        sr=sr,
        hop_length=512,
        units='time',
        pre_max=3,  # Look 3 frames before
        post_max=3,  # Look 3 frames after
        pre_avg=3,   # Average over 3 frames before
        post_avg=5,  # Average over 5 frames after
        delta=0.2,   # Minimum relative threshold
        wait=10      # Minimum frames between onsets
    )
    
    # Convert to time
    onset_times = librosa.frames_to_time(onset_frames, sr=sr, hop_length=512)
    
    # Filter by energy threshold
    onset_times = [t for t in onset_times if np.max(np.abs(y[int(t*sr):int(t*sr)+1024])) > min_linear]
    
    return onset_times.tolist()

def detect_beats_only(y, sr, min_linear):
    """Detect beats using librosa's beat tracking"""
    
    # Compute onset strength envelope
    onset_env = librosa.onset.onset_strength(
        y=y, 
        sr=sr,
        aggregate=np.median,
        fmax=8000,
        hop_length=512
    )
    
    # Track beats
    tempo, beat_frames = librosa.beat.beat_track(
        onset_envelope=onset_env,
        sr=sr,
        hop_length=512,
        units='time',
        tightness=100,  # Higher = more strict tempo tracking
        trim=False
    )
    
    # Convert to time
    beat_times = librosa.frames_to_time(beat_frames, sr=sr, hop_length=512)
    
    # Filter by energy threshold
    beat_times = [t for t in beat_times if np.max(np.abs(y[int(t*sr):int(t*sr)+1024])) > min_linear]
    
    return beat_times.tolist()

def detect_combined(y, sr, min_linear):
    """Combined onset and beat detection for guitar accuracy"""
    
    # Compute onset strength envelope
    onset_env = librosa.onset.onset_strength(
        y=y, 
        sr=sr,
        aggregate=np.median,
        fmax=8000,
        hop_length=512
    )
    
    # Detect onsets
    onset_frames = librosa.onset.onset_detect(
        onset_envelope=onset_env,
        sr=sr,
        hop_length=512,
        units='time',
        pre_max=3,
        post_max=3,
        pre_avg=3,
        post_avg=5,
        delta=0.15,  # Slightly lower threshold for guitar
        wait=8       # Shorter wait for faster playing
    )
    
    # Track beats for tempo reference
    tempo, beat_frames = librosa.beat.beat_track(
        onset_envelope=onset_env,
        sr=sr,
        hop_length=512,
        units='time',
        tightness=80,  # Moderate strictness
        trim=False
    )
    
    # Convert to time
    onset_times = librosa.frames_to_time(onset_frames, sr=sr, hop_length=512)
    beat_times = librosa.frames_to_time(beat_frames, sr=sr, hop_length=512)
    
    # Filter onsets by energy threshold
    onset_times = [t for t in onset_times if np.max(np.abs(y[int(t*sr):int(t*sr)+1024])) > min_linear]
    
    # If we have beats, use them to filter onsets
    if len(beat_times) > 0:
        # Find onsets that are close to beats (within 200ms)
        beat_threshold = 0.2
        filtered_onsets = []
        
        for onset in onset_times:
            # Find closest beat
            closest_beat = min(beat_times, key=lambda x: abs(x - onset))
            if abs(closest_beat - onset) < beat_threshold:
                filtered_onsets.append(onset)
        
        # If we filtered out too many, use original onsets
        if len(filtered_onsets) < len(onset_times) * 0.3:
            return onset_times.tolist()
        else:
            return filtered_onsets
    else:
        return onset_times.tolist()

def main():
    parser = argparse.ArgumentParser(description='Librosa onset detection for GuitarAccuracy')
    parser.add_argument('audio_file', help='Path to audio file')
    parser.add_argument('--min-db', type=float, default=-50.0, help='Minimum dB threshold')
    parser.add_argument('--method', choices=['onset', 'beat', 'combined'], default='combined', 
                       help='Detection method')
    parser.add_argument('--output', help='Output JSON file (default: stdout)')
    
    args = parser.parse_args()
    
    # Check if file exists
    if not Path(args.audio_file).exists():
        print(f"Error: File {args.audio_file} not found", file=sys.stderr)
        sys.exit(1)
    
    # Detect onsets
    onset_times = detect_onsets_librosa(args.audio_file, args.min_db, args.method)
    
    # Prepare output
    result = {
        'onset_times': onset_times,
        'method': args.method,
        'min_db': args.min_db,
        'count': len(onset_times)
    }
    
    # Output results
    if args.output:
        with open(args.output, 'w') as f:
            json.dump(result, f, indent=2)
    else:
        print(json.dumps(result, indent=2))

if __name__ == '__main__':
    main()
