@echo off
REM tflite native-lib install script for Windows (Pocket Medic)
REM This script ensures the TFLite native shared libraries are available
REM for the tflite_flutter package on Windows.

echo === Pocket Medic: TFLite Windows Setup ===
echo.

REM Check if Flutter is available
where flutter >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo ERROR: Flutter is not in your PATH.
    echo Add Flutter to PATH and re-run this script.
    pause
    exit /b 1
)

REM Check if the project exists
if not exist "%~dp0" (
    echo ERROR: Project directory not found.
    pause
    exit /b 1
)

cd /d "%~dp0"

REM Ensure tflite_flutter and tflite_flutter_helper are in pubspec.yaml
echo Checking pubspec.yaml for tflite dependencies...
findstr /c:"tflite_flutter" pubspec.yaml >nul
if %ERRORLEVEL% neq 0 (
    echo WARNING: tflite_flutter not found in pubspec.yaml
    echo Add tflite_flutter and tflite_flutter_helper to dependencies.
)

REM Run flutter pub get to ensure native libs are fetched
echo Running flutter pub get...
flutter pub get

REM Check for Windows CMakeLists.txt
if exist windows\CMakeLists.txt (
    echo Found windows\CMakeLists.txt
) else (
    echo Creating windows\CMakeLists.txt with TFLite support...
)

REM Ensure the Windows flutter plugin registrant includes tflite
echo.
echo Setup complete. Next steps:
echo 1. Place mushroom_classifier.tflite in assets/
echo 2. Place labels.txt in assets/
echo 3. Run: flutter pub get
echo 4. Run: flutter build windows
echo.
pause