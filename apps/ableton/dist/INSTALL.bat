@echo off
REM ========================================
REM Production Tracker - One-Click Installer
REM With Detailed Logging
REM ========================================

SETLOCAL EnableDelayedExpansion

REM Setup logging
SET "LOG_FILE=%~dp0install.log"
SET "INSTALL_DIR=%~dp0"

REM Clear old log
echo. > "%LOG_FILE%"

REM Log function
call :LOG "========================================"
call :LOG "Production Tracker Installer"
call :LOG "========================================"
call :LOG "Install directory: %INSTALL_DIR%"
call :LOG "Log file: %LOG_FILE%"
call :LOG "Date: %DATE% %TIME%"
call :LOG ""

echo.
echo ========================================
echo   Production Tracker Installer
echo ========================================
echo.
echo Log file: %LOG_FILE%
echo.

REM Get current directory
cd /d "%INSTALL_DIR%"

REM Check for admin rights
call :LOG "Checking admin rights..."
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    call :LOG "ERROR: No admin rights detected"
    echo [!] This installer requires Administrator privileges.
    echo [!] Please right-click and select "Run as Administrator"
    echo.
    call :LOG "Installation aborted - no admin rights"
    pause
    exit /b 1
)
call :LOG "Admin rights: OK"

echo [*] Installing Production Tracker...
echo.

REM ========================================
REM Step 1: Check Node.js
REM ========================================
call :LOG ""
call :LOG "[1/6] Checking Node.js installation..."
echo [1/6] Checking Node.js installation...

where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    call :LOG "Node.js not found - will install"
    echo [!] Node.js is not installed.
    echo.
    echo [*] Downloading Node.js installer...
    call :LOG "Downloading Node.js from https://nodejs.org/dist/v20.10.0/node-v20.10.0-x64.msi"

    REM Download Node.js installer
    powershell -Command "(New-Object Net.WebClient).DownloadFile('https://nodejs.org/dist/v20.10.0/node-v20.10.0-x64.msi', '%TEMP%\nodejs-installer.msi')" 2>> "%LOG_FILE%"

    if !ERRORLEVEL! NEQ 0 (
        call :LOG "ERROR: Failed to download Node.js - error code !ERRORLEVEL!"
        echo [!] Failed to download Node.js
        echo [!] Please install Node.js manually from https://nodejs.org
        echo [!] Check %LOG_FILE% for details
        pause
        exit /b 1
    )

    call :LOG "Download successful"
    echo [*] Installing Node.js...
    call :LOG "Running Node.js installer..."

    msiexec /i "%TEMP%\nodejs-installer.msi" /quiet /qn /norestart /log "%TEMP%\nodejs-install.log" 2>> "%LOG_FILE%"
    SET NODE_INSTALL_ERROR=!ERRORLEVEL!

    call :LOG "MSI installer exit code: !NODE_INSTALL_ERROR!"

    if exist "%TEMP%\nodejs-install.log" (
        call :LOG "Node.js installer log:"
        type "%TEMP%\nodejs-install.log" >> "%LOG_FILE%"
    )

    REM Wait for installation
    call :LOG "Waiting 15 seconds for installation to complete..."
    timeout /t 15 /nobreak >nul

    REM Add Node.js to PATH for current session
    set "PATH=%PATH%;C:\Program Files\nodejs"
    call :LOG "Added Node.js to PATH: C:\Program Files\nodejs"

    REM Verify installation
    where node >nul 2>nul
    if !ERRORLEVEL! NEQ 0 (
        call :LOG "ERROR: Node.js not found in PATH after installation"
        echo [!] Node.js installation may have failed
        echo [!] Please check %LOG_FILE% for details
        echo [!] You may need to install Node.js manually from https://nodejs.org
        pause
        exit /b 1
    )

    call :LOG "Node.js installation: SUCCESS"
    echo [√] Node.js installed successfully
) else (
    for /f "delims=" %%i in ('node -v 2^>nul') do set NODE_VERSION=%%i
    call :LOG "Node.js already installed: !NODE_VERSION!"
    echo [√] Node.js !NODE_VERSION! is already installed
)

echo.

REM ========================================
REM Step 2: Install dependencies
REM ========================================
call :LOG ""
call :LOG "[2/6] Installing dependencies..."
echo [2/6] Installing dependencies...

if not exist "package.json" (
    call :LOG "ERROR: package.json not found in %CD%"
    echo [!] ERROR: package.json not found
    echo [!] Make sure you extracted all files from the ZIP
    pause
    exit /b 1
)

call :LOG "Found package.json"
call :LOG "Running: npm install"

if not exist "node_modules" (
    call npm install --verbose >> "%LOG_FILE%" 2>&1
    SET NPM_ERROR=!ERRORLEVEL!
    call :LOG "npm install exit code: !NPM_ERROR!"

    if !NPM_ERROR! NEQ 0 (
        call :LOG "ERROR: npm install failed"
        echo [!] Failed to install dependencies
        echo [!] Check %LOG_FILE% for details
        pause
        exit /b 1
    )
    call :LOG "Dependencies installed successfully"
) else (
    call :LOG "node_modules already exists - skipping npm install"
)

echo [√] Dependencies installed
echo.

REM ========================================
REM Step 3: Install to Program Files
REM ========================================
call :LOG ""
call :LOG "[3/6] Installing to Program Files..."
echo [3/6] Installing to Program Files...

SET "TARGET_DIR=%ProgramFiles%\ProductionTracker"
call :LOG "Target directory: %TARGET_DIR%"

REM Create directory
if not exist "%TARGET_DIR%" (
    mkdir "%TARGET_DIR%" 2>> "%LOG_FILE%"
    call :LOG "Created directory: %TARGET_DIR%"
) else (
    call :LOG "Directory already exists: %TARGET_DIR%"
)

REM Copy files
call :LOG "Copying files to %TARGET_DIR%..."
echo [*] Copying files to %TARGET_DIR%...

xcopy /Y /Q "websocket-bridge.js" "%TARGET_DIR%\" >> "%LOG_FILE%" 2>&1
call :LOG "  - websocket-bridge.js: error code !ERRORLEVEL!"

xcopy /Y /Q "package.json" "%TARGET_DIR%\" >> "%LOG_FILE%" 2>&1
call :LOG "  - package.json: error code !ERRORLEVEL!"

xcopy /Y /Q /E "node_modules" "%TARGET_DIR%\node_modules\" >> "%LOG_FILE%" 2>&1
call :LOG "  - node_modules: error code !ERRORLEVEL!"

if exist "code" (
    xcopy /Y /Q /E "code" "%TARGET_DIR%\code\" >> "%LOG_FILE%" 2>&1
    call :LOG "  - code directory: error code !ERRORLEVEL!"
)

call :LOG "Files copied successfully"
echo [√] Files installed to Program Files
echo.

REM ========================================
REM Step 4: Install Ableton device
REM ========================================
call :LOG ""
call :LOG "[4/6] Installing Ableton device..."
echo [4/6] Installing Ableton device...

REM Find Ableton User Library
SET "ABLETON_LIBRARY=%USERPROFILE%\Documents\Ableton\User Library\Presets\Audio Effects\Max Audio Effect"
call :LOG "Checking Ableton library path: %ABLETON_LIBRARY%"

if not exist "%ABLETON_LIBRARY%" (
    call :LOG "First path not found, trying alternative..."
    SET "ABLETON_LIBRARY=%USERPROFILE%\Music\Ableton\User Library\Presets\Audio Effects\Max Audio Effect"
    call :LOG "Trying: %ABLETON_LIBRARY%"
)

if not exist "%ABLETON_LIBRARY%" (
    call :LOG "No existing Ableton library found - creating default path"
    echo [*] Creating Ableton User Library folder...
    mkdir "%USERPROFILE%\Documents\Ableton\User Library\Presets\Audio Effects\Max Audio Effect" 2>> "%LOG_FILE%"
    SET CREATE_ERROR=!ERRORLEVEL!
    call :LOG "mkdir exit code: !CREATE_ERROR!"
    SET "ABLETON_LIBRARY=%USERPROFILE%\Documents\Ableton\User Library\Presets\Audio Effects\Max Audio Effect"
)

call :LOG "Final Ableton library path: %ABLETON_LIBRARY%"

REM Copy device
SET DEVICE_COPIED=0

if exist "ProductionTracker.amxd" (
    call :LOG "Found ProductionTracker.amxd - copying to Ableton"
    xcopy /Y /Q "ProductionTracker.amxd" "%ABLETON_LIBRARY%\" >> "%LOG_FILE%" 2>&1
    SET COPY_ERROR=!ERRORLEVEL!
    call :LOG "Copy .amxd exit code: !COPY_ERROR!"
    if !COPY_ERROR! EQU 0 (
        echo [√] Device (.amxd) installed to: %ABLETON_LIBRARY%
        SET DEVICE_COPIED=1
    )
) else if exist "ProductionTracker.maxpat" (
    call :LOG "Found ProductionTracker.maxpat - copying to Ableton"
    xcopy /Y /Q "ProductionTracker.maxpat" "%ABLETON_LIBRARY%\" >> "%LOG_FILE%" 2>&1
    SET COPY_ERROR=!ERRORLEVEL!
    call :LOG "Copy .maxpat exit code: !COPY_ERROR!"
    if !COPY_ERROR! EQU 0 (
        echo [√] Device (.maxpat) installed to: %ABLETON_LIBRARY%
        SET DEVICE_COPIED=1
    )
) else if exist "dist\ProductionTracker.amxd" (
    call :LOG "Found dist\ProductionTracker.amxd - copying to Ableton"
    xcopy /Y /Q "dist\ProductionTracker.amxd" "%ABLETON_LIBRARY%\" >> "%LOG_FILE%" 2>&1
    SET COPY_ERROR=!ERRORLEVEL!
    call :LOG "Copy dist\.amxd exit code: !COPY_ERROR!"
    if !COPY_ERROR! EQU 0 (
        echo [√] Device (.amxd from dist) installed to: %ABLETON_LIBRARY%
        SET DEVICE_COPIED=1
    )
) else if exist "dist\ProductionTracker.maxpat" (
    call :LOG "Found dist\ProductionTracker.maxpat - copying to Ableton"
    xcopy /Y /Q "dist\ProductionTracker.maxpat" "%ABLETON_LIBRARY%\" >> "%LOG_FILE%" 2>&1
    SET COPY_ERROR=!ERRORLEVEL!
    call :LOG "Copy dist\.maxpat exit code: !COPY_ERROR!"
    if !COPY_ERROR! EQU 0 (
        echo [√] Device (.maxpat from dist) installed to: %ABLETON_LIBRARY%
        SET DEVICE_COPIED=1
    )
) else (
    call :LOG "ERROR: No device file found (searched: ProductionTracker.amxd, ProductionTracker.maxpat, dist/...)"
    call :LOG "Current directory contents:"
    dir >> "%LOG_FILE%" 2>&1
)

if !DEVICE_COPIED! EQU 0 (
    echo [!] Warning: Device file not found
    echo [!] Please manually copy the .amxd file to:
    echo     %ABLETON_LIBRARY%
    call :LOG "WARNING: Device not copied"
)

REM Also copy code folder to Ableton library for Max to find
if exist "code" (
    SET "CODE_TARGET=%ABLETON_LIBRARY%\ProductionTracker-code"
    call :LOG "Copying code folder to: !CODE_TARGET!"
    xcopy /Y /Q /E "code" "!CODE_TARGET!\" >> "%LOG_FILE%" 2>&1
    call :LOG "Code folder copy exit code: !ERRORLEVEL!"
)

echo.

REM ========================================
REM Step 5: Create Windows Service for auto-start
REM ========================================
call :LOG ""
call :LOG "[5/6] Setting up auto-start..."
echo [5/6] Setting up auto-start...

REM Create startup script that checks if bridge is running
SET "STARTUP_SCRIPT=%TARGET_DIR%\start-bridge-autostart.bat"
call :LOG "Creating startup script: %STARTUP_SCRIPT%"

(
echo @echo off
echo REM Auto-start script for Production Tracker Bridge
echo REM Checks if already running before starting
echo.
echo tasklist /FI "IMAGENAME eq node.exe" /FI "WINDOWTITLE eq Production Tracker Bridge*" 2^>NUL ^| find /I /N "node.exe"^>NUL
echo if %%ERRORLEVEL%% EQU 0 ^(
echo     REM Already running
echo     exit /b 0
echo ^)
echo.
echo REM Start bridge minimized
echo start /MIN "Production Tracker Bridge" node "%TARGET_DIR%\websocket-bridge.js"
) > "%STARTUP_SCRIPT%"

call :LOG "Startup script created"

echo.

REM ========================================
REM Step 6: Create shortcuts
REM ========================================
call :LOG ""
call :LOG "[6/6] Creating shortcuts..."
echo [6/6] Creating shortcuts...

REM Create desktop shortcut
SET "SHORTCUT_PATH=%USERPROFILE%\Desktop\Production Tracker Bridge.lnk"
call :LOG "Creating desktop shortcut: %SHORTCUT_PATH%"

powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%SHORTCUT_PATH%'); $Shortcut.TargetPath = 'node.exe'; $Shortcut.Arguments = '\"%TARGET_DIR%\websocket-bridge.js\"'; $Shortcut.WorkingDirectory = '%TARGET_DIR%'; $Shortcut.IconLocation = 'shell32.dll,13'; $Shortcut.Description = 'Production Tracker WebSocket Bridge'; $Shortcut.Save()" 2>> "%LOG_FILE%"

call :LOG "Desktop shortcut exit code: !ERRORLEVEL!"
echo [√] Desktop shortcut created
echo.

REM Installation complete
call :LOG ""
call :LOG "========================================"
call :LOG "Installation Complete!"
call :LOG "========================================"

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
echo Installation log saved to: %LOG_FILE%
echo.

REM Ask about autostart
choice /C YN /M "Do you want to start the bridge automatically with Windows?"
if !ERRORLEVEL! EQU 1 (
    call :LOG "User chose to enable autostart"
    REM Add to startup
    SET "STARTUP_PATH=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Production Tracker Bridge.lnk"

    powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%STARTUP_PATH%'); $Shortcut.TargetPath = '%STARTUP_SCRIPT%'; $Shortcut.WorkingDirectory = '%TARGET_DIR%'; $Shortcut.WindowStyle = 7; $Shortcut.Save()" 2>> "%LOG_FILE%"

    call :LOG "Startup shortcut created: %STARTUP_PATH%"
    echo [√] Autostart enabled
    echo.
) else (
    call :LOG "User chose NOT to enable autostart"
)

echo.
choice /C YN /M "Do you want to start the bridge now?"
if !ERRORLEVEL! EQU 1 (
    call :LOG "User chose to start bridge now"
    start "Production Tracker Bridge" node "%TARGET_DIR%\websocket-bridge.js"
    echo.
    echo [√] Bridge started
    echo.
    echo The bridge is now running in the background.
    echo Check the new console window for status.
    call :LOG "Bridge started successfully"
) else (
    call :LOG "User chose NOT to start bridge now"
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
echo If you had any issues, please send the file:
echo %LOG_FILE%
echo.

call :LOG "Installation script completed successfully"
pause
exit /b 0

REM ========================================
REM Logging function
REM ========================================
:LOG
echo %~1 >> "%LOG_FILE%"
goto :eof
