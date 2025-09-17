# FFmpeg Batch: Auto-NVENC (GPU) or x264 (CPU) Video Compressor

This Windows batch script compresses all videos in the current folder using GPU acceleration (NVENC) when available, and automatically falls back to CPU (libx264) if NVENC isn’t detected. It preserves audio/subtitle streams when present, sets web-friendly MP4 metadata, and writes outputs into a chosen sub-folder.

---

## Features

- **Auto-detects NVENC**: Quick one-second probe; uses `h264_nvenc` if supported, else falls back to `libx264`.  
- **Quality-first presets**:  
  - NVENC: `-rc:v vbr -cq:v <0–51> -b:v 0` for constant-quality VBR (CQ).  
  - x264 fallback: `-crf <0–51>` with a sensible preset.  
- **Stream-smart mapping**: Copies all primary streams (`-map 0:v:0 -map 0:a? -map 0:s?`) and **copies subtitles** without re-encoding.  
- **Fast start for the web**: Moves MP4 “moov” atom to the front with `-movflags +faststart` so playback starts sooner on the web.  
- **CUDA decode path**: Requests hardware acceleration via `-hwaccel cuda` when present. (FFmpeg will gracefully fall back if unsupported.)  
- **Multiple formats in one go**: Processes `*.mp4`, `*.mkv`, `*.wmv` (case-insensitive).

---

## The Script

```bat
@echo off
setlocal enabledelayedexpansion

:: ------------------ Settings ------------------
set "CQ=18"             :: Lower = higher quality (typical 19–28)
set "ABITRATE=320k"     :: Audio bitrate
set "OUTDIR=compressed3"

:: ------------------ Prep ----------------------
if not exist "%OUTDIR%" mkdir "%OUTDIR%"

echo Probing for NVENC support...
:: Tiny one-second test. If it fails, we'll use CPU.
ffmpeg -v error -f lavfi -i testsrc2=size=128x72:rate=24 -t 1 -c:v h264_nvenc -f null - >nul 2>&1
if %errorlevel%==0 (
    set "VENC=h264_nvenc"
    set "VOPTS=-rc:v vbr -cq:v %CQ% -b:v 0 -preset p4"
    echo ✓ NVENC available. Using GPU encoder: !VENC!
) else (
    set "VENC=libx264"
    :: For libx264, map CQ to CRF (roughly similar scale)
    set "VOPTS=-crf %CQ% -preset medium"
    echo ⚠ NVENC not available. Falling back to CPU encoder: !VENC!
    echo   (Ensure a recent NVIDIA driver and an FFmpeg build with NVENC support.)
)

echo.
echo Starting compression into "%OUTDIR%"...

for %%F in (*.mp4 *.MP4 *.mkv *.MKV *.wmv *.WMV) do (
    if exist "%%F" (
        set "name=%%~nF"
        set "ext=%%~xF"
        echo ---
        echo Compressing: %%F

        ffmpeg -hide_banner -hwaccel cuda -i "%%F" ^
          -map 0:v:0 -map 0:a? -map 0:s? ^
          -c:v !VENC! !VOPTS! ^
          -c:a aac -b:a %ABITRATE% ^
          -c:s copy ^
          -movflags +faststart ^
          -metadata title="%name% (compressed)" ^
          "%OUTDIR%\!name!-compressed!ext!"
    )
)

echo.
echo Done. Files saved in "%OUTDIR%".
pause
