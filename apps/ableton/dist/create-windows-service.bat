@echo off
REM ========================================
REM Create Windows Service for Production Tracker Bridge
REM This allows the bridge to run automatically in background
REM ========================================

echo.
echo ========================================
echo  Production Tracker Service Installer
echo ========================================
echo.

REM Check for admin rights
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo [!] This script requires Administrator privileges.
    echo [!] Please right-click and select "Run as Administrator"
    echo.
    pause
    exit /b 1
)

SET "BRIDGE_PATH=C:\Program Files\ProductionTracker\websocket-bridge.js"
SET "NODE_PATH=C:\Program Files\nodejs\node.exe"
SET "SERVICE_NAME=ProductionTrackerBridge"

REM Check if Node.js exists
if not exist "%NODE_PATH%" (
    echo [!] Node.js not found at: %NODE_PATH%
    echo [!] Please install Node.js first
    pause
    exit /b 1
)

REM Check if bridge exists
if not exist "%BRIDGE_PATH%" (
    echo [!] Bridge not found at: %BRIDGE_PATH%
    echo [!] Please run INSTALL.bat first
    pause
    exit /b 1
)

echo [*] Installing Production Tracker as Windows Service...
echo.

REM Download nssm (Non-Sucking Service Manager) if not exists
SET "NSSM_PATH=%~dp0nssm.exe"

if not exist "%NSSM_PATH%" (
    echo [*] Downloading service manager (nssm)...

    powershell -Command "(New-Object Net.WebClient).DownloadFile('https://nssm.cc/ci/nssm-2.24-101-g897c7ad/win64/nssm.exe', '%NSSM_PATH%')"

    if %ERRORLEVEL% NEQ 0 (
        echo [!] Failed to download nssm
        echo [!] Please download manually from https://nssm.cc
        pause
        exit /b 1
    )
)

REM Stop and remove existing service if it exists
sc query %SERVICE_NAME% >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [*] Removing existing service...
    "%NSSM_PATH%" stop %SERVICE_NAME%
    "%NSSM_PATH%" remove %SERVICE_NAME% confirm
)

REM Install service
echo [*] Installing service...
"%NSSM_PATH%" install %SERVICE_NAME% "%NODE_PATH%" "%BRIDGE_PATH%"

REM Configure service
echo [*] Configuring service...
"%NSSM_PATH%" set %SERVICE_NAME% DisplayName "Production Tracker Bridge"
"%NSSM_PATH%" set %SERVICE_NAME% Description "WebSocket bridge for Production Tracker M4L device"
"%NSSM_PATH%" set %SERVICE_NAME% Start SERVICE_AUTO_START
"%NSSM_PATH%" set %SERVICE_NAME% AppDirectory "C:\Program Files\ProductionTracker"

REM Set restart policy
"%NSSM_PATH%" set %SERVICE_NAME% AppThrottle 10000
"%NSSM_PATH%" set %SERVICE_NAME% AppExit Default Restart
"%NSSM_PATH%" set %SERVICE_NAME% AppRestartDelay 5000

REM Start service
echo [*] Starting service...
"%NSSM_PATH%" start %SERVICE_NAME%

if %ERRORLEVEL% EQU 0 (
    echo.
    echo [√] Service installed and started successfully!
    echo.
    echo The Production Tracker bridge will now:
    echo  - Start automatically when Windows starts
    echo  - Run in the background
    echo  - Restart automatically if it crashes
    echo.
    echo Service name: %SERVICE_NAME%
    echo.
    echo To manage the service:
    echo  - Start:   sc start %SERVICE_NAME%
    echo  - Stop:    sc stop %SERVICE_NAME%
    echo  - Status:  sc query %SERVICE_NAME%
    echo  - Remove:  "%NSSM_PATH%" remove %SERVICE_NAME% confirm
    echo.
) else (
    echo.
    echo [!] Failed to start service
    echo [!] Check if ports 7400 and 7401 are available
    echo.
)

pause
