@echo off
setlocal enabledelayedexpansion

:: ------------------ Settings ------------------
set "CQ=18"             :: Lower = higher quality (typical 19–28)
set "ABITRATE=320k"     :: Audio bitrate
set "OUTDIR=compressed"

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
    echo   (Update NVIDIA driver to 570+ to enable NVENC on FFmpeg built with SDK 13.) 
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
