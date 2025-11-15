@echo off
REM ========================================
REM Production Tracker - One-Click Installer
REM ========================================

SETLOCAL EnableDelayedExpansion

echo.
echo ========================================
echo   Production Tracker Installer
echo ========================================
echo.

REM Get current directory
SET "INSTALL_DIR=%~dp0"
cd /d "%INSTALL_DIR%"

REM Check for admin rights
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo [!] This installer requires Administrator privileges.
    echo [!] Please right-click and select "Run as Administrator"
    echo.
    pause
    exit /b 1
)

echo [*] Installing Production Tracker...
echo.

REM ========================================
REM Step 1: Check Node.js
REM ========================================
echo [1/5] Checking Node.js installation...

where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [!] Node.js is not installed.
    echo.
    echo [*] Downloading Node.js installer...

    REM Download Node.js installer
    powershell -Command "(New-Object Net.WebClient).DownloadFile('https://nodejs.org/dist/v20.10.0/node-v20.10.0-x64.msi', '%TEMP%\nodejs-installer.msi')"

    if !ERRORLEVEL! NEQ 0 (
        echo [!] Failed to download Node.js
        echo [!] Please install Node.js manually from https://nodejs.org
        pause
        exit /b 1
    )

    echo [*] Installing Node.js...
    msiexec /i "%TEMP%\nodejs-installer.msi" /quiet /qn /norestart

    REM Wait for installation
    timeout /t 10 /nobreak >nul

    REM Add Node.js to PATH for current session
    set "PATH=%PATH%;C:\Program Files\nodejs"

    echo [√] Node.js installed successfully
) else (
    for /f "delims=" %%i in ('node -v') do set NODE_VERSION=%%i
    echo [√] Node.js !NODE_VERSION! is already installed
)

echo.

REM ========================================
REM Step 2: Install dependencies
REM ========================================
echo [2/5] Installing dependencies...

if not exist "node_modules" (
    call npm install --silent
    if !ERRORLEVEL! NEQ 0 (
        echo [!] Failed to install dependencies
        pause
        exit /b 1
    )
)

echo [√] Dependencies installed
echo.

REM ========================================
REM Step 3: Install to Program Files
REM ========================================
echo [3/5] Installing to Program Files...

SET "TARGET_DIR=%ProgramFiles%\ProductionTracker"

REM Create directory
if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"

REM Copy files
echo [*] Copying files to %TARGET_DIR%...
xcopy /Y /Q "websocket-bridge.js" "%TARGET_DIR%\" >nul
xcopy /Y /Q "package.json" "%TARGET_DIR%\" >nul
xcopy /Y /Q /E "node_modules" "%TARGET_DIR%\node_modules\" >nul

echo [√] Files installed to Program Files
echo.

REM ========================================
REM Step 4: Install Ableton device
REM ========================================
echo [4/5] Installing Ableton device...

REM Find Ableton User Library
SET "ABLETON_LIBRARY=%USERPROFILE%\Documents\Ableton\User Library\Presets\Audio Effects\Max Audio Effect"

if not exist "%ABLETON_LIBRARY%" (
    REM Try alternative location
    SET "ABLETON_LIBRARY=%USERPROFILE%\Music\Ableton\User Library\Presets\Audio Effects\Max Audio Effect"
)

if not exist "%ABLETON_LIBRARY%" (
    echo [*] Creating Ableton User Library folder...
    mkdir "%USERPROFILE%\Documents\Ableton\User Library\Presets\Audio Effects\Max Audio Effect" 2>nul
    SET "ABLETON_LIBRARY=%USERPROFILE%\Documents\Ableton\User Library\Presets\Audio Effects\Max Audio Effect"
)

REM Copy device
if exist "ProductionTracker.amxd" (
    xcopy /Y /Q "ProductionTracker.amxd" "%ABLETON_LIBRARY%\" >nul
    echo [√] Device installed to: %ABLETON_LIBRARY%
) else if exist "ProductionTracker.maxpat" (
    xcopy /Y /Q "ProductionTracker.maxpat" "%ABLETON_LIBRARY%\" >nul
    echo [√] Device installed to: %ABLETON_LIBRARY%
) else (
    echo [!] Warning: Device file not found
    echo [!] Please manually copy the .amxd file to:
    echo     %ABLETON_LIBRARY%
)

echo.

REM ========================================
REM Step 5: Create shortcuts and autostart
REM ========================================
echo [5/5] Creating shortcuts...

REM Create desktop shortcut
SET "SHORTCUT_PATH=%USERPROFILE%\Desktop\Production Tracker Bridge.lnk"

powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%SHORTCUT_PATH%'); $Shortcut.TargetPath = 'node.exe'; $Shortcut.Arguments = '\"%TARGET_DIR%\websocket-bridge.js\"'; $Shortcut.WorkingDirectory = '%TARGET_DIR%'; $Shortcut.IconLocation = 'shell32.dll,13'; $Shortcut.Description = 'Production Tracker WebSocket Bridge'; $Shortcut.Save()"

echo [√] Desktop shortcut created
echo.

REM Ask about autostart
echo.
echo ========================================
echo  Installation Complete!
echo ========================================
echo.
echo The Production Tracker has been installed:
echo.
echo   [√] WebSocket Bridge: %TARGET_DIR%
echo   [√] Ableton Device: %ABLETON_LIBRARY%
echo   [√] Desktop Shortcut: Created
echo.

choice /C YN /M "Do you want to start the bridge automatically with Windows?"
if !ERRORLEVEL! EQU 1 (
    REM Add to startup
    SET "STARTUP_PATH=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Production Tracker Bridge.lnk"

    powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%STARTUP_PATH%'); $Shortcut.TargetPath = 'node.exe'; $Shortcut.Arguments = '\"%TARGET_DIR%\websocket-bridge.js\"'; $Shortcut.WorkingDirectory = '%TARGET_DIR%'; $Shortcut.WindowStyle = 7; $Shortcut.Save()"

    echo [√] Autostart enabled
    echo.
)

echo.
choice /C YN /M "Do you want to start the bridge now?"
if !ERRORLEVEL! EQU 1 (
    start "Production Tracker Bridge" node "%TARGET_DIR%\websocket-bridge.js"
    echo.
    echo [√] Bridge started
    echo.
    echo The bridge is now running in the background.
    echo Check the new console window for status.
)

echo.
echo ========================================
echo  Next Steps:
echo ========================================
echo.
echo  1. Open Ableton Live
echo  2. Find "Production Tracker" in Max Audio Effect
echo  3. Drag it to your Master track
echo  4. Click "Connect" and enter your auth token
echo     (Get token from https://muvs.dev/dashboard)
echo  5. Start making music!
echo.
echo For support, visit: https://muvs.dev
echo.
pause
