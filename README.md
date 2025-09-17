FFmpeg Batch: Auto-NVENC (GPU) or x264 (CPU) Video Compressor

This Windows batch script compresses all videos in the current folder using GPU acceleration (NVENC) when available, and automatically falls back to CPU (libx264) if NVENC isn’t detected. It preserves audio/subtitle streams when present, sets web-friendly MP4 metadata, and writes outputs into a chosen sub-folder.

Features

Auto-detects NVENC: Quick one-second probe; uses h264_nvenc if supported, else falls back to libx264. 
NVIDIA Docs
+1

Quality-first presets:

NVENC: -rc:v vbr -cq:v <0–51> -b:v 0 for constant-quality VBR (CQ). 
ffmpeg.org
+1

x264 fallback: -crf <0–51> with a sensible preset.

Stream-smart mapping: Copies all primary streams (-map 0:v:0 -map 0:a? -map 0:s?) and copies subtitles without re-encoding. (The ? makes streams optional—no failure if absent.) 
ffmpeg.org

Fast start for the web: Moves MP4 “moov” atom to the front with -movflags +faststart so playback starts sooner on the web. 
Reddit
+1

CUDA decode path: Requests hardware acceleration via -hwaccel cuda when present. (FFmpeg will gracefully fall back if unsupported.) 
ffmpeg.org

Multiple formats in one go: Processes *.mp4, *.mkv, *.wmv (case-insensitive).
