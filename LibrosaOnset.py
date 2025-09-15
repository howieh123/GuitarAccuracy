import os
import librosa

def main():
    file_path = './FirstProject.wav'
    x, sr = librosa.load(file_path)
    # Use the correct function signature for newer librosa versions
    onset_frames = librosa.onset.onset_detect(y=x, sr=sr, units='frames')
    onset_times = librosa.frames_to_time(onset_frames, sr=sr)
    # remove extension, .mp3, .wav etc.
    file_name_no_extension, _ = os.path.splitext(file_path)
    output_name = file_name_no_extension + '.beatmap.txt'
    with open(output_name, 'wt') as f:
        f.write('\n'.join(['%.4f' % onset_time for onset_time in onset_times]))

if __name__ == '__main__':
    main()
