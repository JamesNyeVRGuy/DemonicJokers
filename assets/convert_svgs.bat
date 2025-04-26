@echo off
setlocal enabledelayedexpansion

:: Script to convert SVG files to PNG for Balatro mod jokers
:: This script converts SVGs to both 1x (71x95) and 2x (142x190) PNGs

:: Check if Inkscape is available
where inkscape >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Error: Inkscape is required but not installed or not in PATH.
    echo Please install Inkscape from https://inkscape.org/
    echo Make sure it's added to your PATH environment variable.
    pause
    exit /b 1
)

:: Create necessary directories
if not exist assets\1x mkdir assets\1x
if not exist assets\2x mkdir assets\2x

:: Get all SVG files in current directory
echo Processing SVG files...
for %%F in (*.svg) do (
    set "filename=%%~nF"
    
    :: Add j_ prefix if not already present
    echo !filename! | findstr /b /c:"j_" >nul
    if !ERRORLEVEL! NEQ 0 (
        set "joker_name=j_!filename!joker"
    ) else (
        set "joker_name=!filename!"
    )
    
    echo Converting %%F to !joker_name!.png (1x and 2x)
    
    :: Convert to 1x PNG (71x95)
    inkscape --export-filename="assets\1x\!joker_name!.png" --export-width=71 --export-height=95 "%%F"
    
    :: Convert to 2x PNG (142x190)
    inkscape --export-filename="assets\2x\!joker_name!.png" --export-width=142 --export-height=190 "%%F"
    
    echo ✓ Created assets\1x\!joker_name!.png and assets\2x\!joker_name!.png
)

echo.
echo Conversion complete! PNG files are in the assets\1x and assets\2x folders.
echo Place these folders in your mod directory.
pause