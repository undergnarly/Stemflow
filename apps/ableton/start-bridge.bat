@echo off
REM Production Tracker WebSocket Bridge Startup Script (Windows)
REM This script starts the WebSocket bridge for the M4L device

echo ==================================
echo Production Tracker WebSocket Bridge
echo ==================================
echo.

REM Check if Node.js is installed
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Node.js is not installed!
    echo Please install Node.js 14+ from https://nodejs.org
    pause
    exit /b 1
)

echo Node.js version:
node -v
echo.

REM Get the directory where this script is located
cd /d "%~dp0"

REM Check if node_modules exists
if not exist "node_modules" (
    echo Installing dependencies...
    call npm install
    echo.
)

REM Check for environment variables
if exist ".env" (
    echo Loading environment from .env file...
    for /f "tokens=*" %%a in ('type .env ^| findstr /v "^#"') do set %%a
)

REM Set default WebSocket URL if not set
if "%WS_URL%"=="" (
    set WS_URL=wss://muvs.dev/ws
)

echo WebSocket URL: %WS_URL%
echo UDP Receive Port: 7400 (from Max)
echo UDP Send Port: 7401 (to Max)
echo.
echo Starting bridge...
echo Press Ctrl+C to stop
echo.

REM Start the bridge
node websocket-bridge.js

pause
