# ========================================
# Production Tracker - PowerShell Installer
# ========================================

param(
    [switch]$NoAutostart,
    [switch]$NoBridgeStart
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================"
Write-Host "   Production Tracker Installer"
Write-Host "========================================"
Write-Host ""

# Check for admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[!] This installer requires Administrator privileges." -ForegroundColor Red
    Write-Host "[!] Please right-click and select 'Run as Administrator'" -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Get install directory
$InstallDir = $PSScriptRoot
Set-Location $InstallDir

Write-Host "[*] Installing Production Tracker..." -ForegroundColor Cyan
Write-Host ""

# ========================================
# Step 1: Check Node.js
# ========================================
Write-Host "[1/5] Checking Node.js installation..." -ForegroundColor Yellow

try {
    $nodeVersion = node -v
    Write-Host "[√] Node.js $nodeVersion is already installed" -ForegroundColor Green
} catch {
    Write-Host "[!] Node.js is not installed." -ForegroundColor Red
    Write-Host ""
    Write-Host "[*] Downloading Node.js installer..." -ForegroundColor Cyan

    $nodeInstaller = "$env:TEMP\nodejs-installer.msi"
    $nodeUrl = "https://nodejs.org/dist/v20.10.0/node-v20.10.0-x64.msi"

    try {
        Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeInstaller -UseBasicParsing

        Write-Host "[*] Installing Node.js..." -ForegroundColor Cyan
        Start-Process msiexec.exe -ArgumentList "/i `"$nodeInstaller`" /quiet /qn /norestart" -Wait

        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        Write-Host "[√] Node.js installed successfully" -ForegroundColor Green
    } catch {
        Write-Host "[!] Failed to install Node.js" -ForegroundColor Red
        Write-Host "[!] Please install Node.js manually from https://nodejs.org" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}

Write-Host ""

# ========================================
# Step 2: Install dependencies
# ========================================
Write-Host "[2/5] Installing dependencies..." -ForegroundColor Yellow

if (-not (Test-Path "node_modules")) {
    try {
        npm install --silent | Out-Null
        Write-Host "[√] Dependencies installed" -ForegroundColor Green
    } catch {
        Write-Host "[!] Failed to install dependencies" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
} else {
    Write-Host "[√] Dependencies already installed" -ForegroundColor Green
}

Write-Host ""

# ========================================
# Step 3: Install to Program Files
# ========================================
Write-Host "[3/5] Installing to Program Files..." -ForegroundColor Yellow

$TargetDir = "$env:ProgramFiles\ProductionTracker"

if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
}

Write-Host "[*] Copying files to $TargetDir..." -ForegroundColor Cyan

Copy-Item "websocket-bridge.js" "$TargetDir\" -Force
Copy-Item "package.json" "$TargetDir\" -Force
Copy-Item "node_modules" "$TargetDir\" -Recurse -Force

Write-Host "[√] Files installed to Program Files" -ForegroundColor Green
Write-Host ""

# ========================================
# Step 4: Install Ableton device
# ========================================
Write-Host "[4/5] Installing Ableton device..." -ForegroundColor Yellow

$AbletonLibrary = "$env:USERPROFILE\Documents\Ableton\User Library\Presets\Audio Effects\Max Audio Effect"

if (-not (Test-Path $AbletonLibrary)) {
    $AbletonLibrary = "$env:USERPROFILE\Music\Ableton\User Library\Presets\Audio Effects\Max Audio Effect"
}

if (-not (Test-Path $AbletonLibrary)) {
    Write-Host "[*] Creating Ableton User Library folder..." -ForegroundColor Cyan
    $AbletonLibrary = "$env:USERPROFILE\Documents\Ableton\User Library\Presets\Audio Effects\Max Audio Effect"
    New-Item -ItemType Directory -Path $AbletonLibrary -Force | Out-Null
}

$deviceFile = $null
if (Test-Path "ProductionTracker.amxd") {
    $deviceFile = "ProductionTracker.amxd"
} elseif (Test-Path "ProductionTracker.maxpat") {
    $deviceFile = "ProductionTracker.maxpat"
}

if ($deviceFile) {
    Copy-Item $deviceFile "$AbletonLibrary\" -Force
    Write-Host "[√] Device installed to: $AbletonLibrary" -ForegroundColor Green
} else {
    Write-Host "[!] Warning: Device file not found" -ForegroundColor Yellow
    Write-Host "[!] Please manually copy the .amxd file to:" -ForegroundColor Yellow
    Write-Host "    $AbletonLibrary" -ForegroundColor Yellow
}

Write-Host ""

# ========================================
# Step 5: Create shortcuts
# ========================================
Write-Host "[5/5] Creating shortcuts..." -ForegroundColor Yellow

# Desktop shortcut
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$ShortcutPath = "$DesktopPath\Production Tracker Bridge.lnk"

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = "node.exe"
$Shortcut.Arguments = "`"$TargetDir\websocket-bridge.js`""
$Shortcut.WorkingDirectory = $TargetDir
$Shortcut.IconLocation = "shell32.dll,13"
$Shortcut.Description = "Production Tracker WebSocket Bridge"
$Shortcut.Save()

Write-Host "[√] Desktop shortcut created" -ForegroundColor Green
Write-Host ""

# ========================================
# Completion
# ========================================
Write-Host ""
Write-Host "========================================"
Write-Host "  Installation Complete!"
Write-Host "========================================"
Write-Host ""
Write-Host "The Production Tracker has been installed:"
Write-Host ""
Write-Host "  [√] WebSocket Bridge: $TargetDir" -ForegroundColor Green
Write-Host "  [√] Ableton Device: $AbletonLibrary" -ForegroundColor Green
Write-Host "  [√] Desktop Shortcut: Created" -ForegroundColor Green
Write-Host ""

# Autostart
if (-not $NoAutostart) {
    $response = Read-Host "Do you want to start the bridge automatically with Windows? (Y/N)"
    if ($response -eq 'Y' -or $response -eq 'y') {
        $StartupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\Production Tracker Bridge.lnk"

        $StartupShortcut = $WshShell.CreateShortcut($StartupPath)
        $StartupShortcut.TargetPath = "node.exe"
        $StartupShortcut.Arguments = "`"$TargetDir\websocket-bridge.js`""
        $StartupShortcut.WorkingDirectory = $TargetDir
        $StartupShortcut.WindowStyle = 7  # Minimized
        $StartupShortcut.Save()

        Write-Host "[√] Autostart enabled" -ForegroundColor Green
        Write-Host ""
    }
}

# Start bridge now
if (-not $NoBridgeStart) {
    $response = Read-Host "Do you want to start the bridge now? (Y/N)"
    if ($response -eq 'Y' -or $response -eq 'y') {
        Start-Process -FilePath "node.exe" -ArgumentList "`"$TargetDir\websocket-bridge.js`"" -WorkingDirectory $TargetDir -WindowStyle Normal

        Write-Host ""
        Write-Host "[√] Bridge started" -ForegroundColor Green
        Write-Host ""
        Write-Host "The bridge is now running in a new window." -ForegroundColor Cyan
    }
}

Write-Host ""
Write-Host "========================================"
Write-Host "  Next Steps:"
Write-Host "========================================"
Write-Host ""
Write-Host "  1. Open Ableton Live"
Write-Host "  2. Find 'Production Tracker' in Max Audio Effect"
Write-Host "  3. Drag it to your Master track"
Write-Host "  4. Click 'Connect' and enter your auth token"
Write-Host "     (Get token from https://muvs.dev/dashboard)"
Write-Host "  5. Start making music!"
Write-Host ""
Write-Host "For support, visit: https://muvs.dev"
Write-Host ""

Read-Host "Press Enter to exit"
