================================
Production Tracker for Ableton Live
Max for Live Device v1.0.1
================================

WHAT IS THIS?
-------------
This Max for Live (M4L) device tracks your production sessions in Ableton Live and sends data to the Production Tracker web application for AI-powered insights and analytics.

FEATURES
--------
✓ Automatic session tracking
✓ Track and device change monitoring
✓ Tempo and time signature detection
✓ Voice notes with audio recording
✓ Project snapshots
✓ Real-time sync to web dashboard
✓ Auto-start bridge (no manual start needed!)

REQUIREMENTS
------------
1. Ableton Live 11+ with Max for Live
2. Node.js 14+ (installer handles this automatically on Windows)
3. Production Tracker account at https://muvs.dev

SUPER EASY INSTALL - WINDOWS (ONE-CLICK!)
------------------------------------------

👉 Just run INSTALL.bat as Administrator!

1. Extract this ZIP to any folder
2. Right-click INSTALL.bat → "Run as Administrator"
3. Wait ~2 minutes
4. Done! Everything is installed and auto-starts!

The installer will:
✓ Install Node.js if needed (automatic download)
✓ Install all dependencies
✓ Copy device to Ableton
✓ Set up auto-start (bridge runs when Windows starts!)
✓ Create desktop shortcut

After installation, the bridge will:
✓ Start automatically every time you boot Windows
✓ Run in background (you don't need to do anything!)
✓ Just open Ableton and the device will connect!

NO NEED TO MANUALLY START THE BRIDGE! 🎉

See QUICK_INSTALL_WINDOWS.txt for details.

INSTALLATION - ALL PLATFORMS
-----------------------------

WINDOWS (ONE-CLICK):
→ See "SUPER EASY INSTALL" above!

MAC/LINUX (MANUAL):
1. Install Node.js from https://nodejs.org
2. Run: npm install
3. Run: ./start-bridge.sh (keep it running)
4. Copy ProductionTracker.amxd to Ableton User Library:
   ~/Music/Ableton/User Library/Presets/Audio Effects/Max Audio Effect/
5. Open Ableton and add device to Master track

AUTO-START OPTIONS
------------------

The bridge can start automatically! See AUTOSTART_README.txt for:

✓ OPTION 1: Windows Startup (RECOMMENDED - Done by installer!)
  - Starts when Windows starts
  - No manual action needed
  - Already set up if you chose "Yes" during install

✓ OPTION 2: Windows Service (MOST RELIABLE)
  - Runs as background service
  - Restarts automatically if crashes
  - Run: create-windows-service.bat (as Admin)

✓ OPTION 3: Manual Start
  - Double-click desktop shortcut when needed
  - Or double-click start-bridge.bat

The Windows installer already sets up Option 1 for you!

QUICK START (AFTER INSTALL)
----------------------------

Windows users - if you chose auto-start during install:
1. Just open Ableton Live! (bridge is already running)
2. Add "Production Tracker" device to Master track
3. Click "Connect" and enter your auth token from https://muvs.dev/dashboard
4. Start making music!

Manual start users:
1. Start bridge (double-click desktop shortcut or start-bridge.bat)
2. Open Ableton Live
3. Add device to Master track
4. Click "Connect" and enter auth token
5. Make music!

CONTROLS
--------
Connect Button - Connect to Production Tracker server
Voice Note - Hold to record a voice note
Snapshot - Create instant project snapshot
Auto-track - Enable/disable automatic tracking (recommended: ON)
Send on Save - Create snapshot on every save (optional)

STATUS INDICATORS
-----------------
● Green  = Connected to server
● Yellow = Connecting/reconnecting
● Red    = Disconnected
● Gray   = Disabled

TROUBLESHOOTING
---------------

Device shows "Disconnected":
- Check if bridge is running:
  • Windows: Look for node.exe in Task Manager
  • Or double-click desktop shortcut to start it
- Check your internet connection
- Verify you're logged in at https://muvs.dev

Installation failed:
- Run INSTALL.bat as Administrator
- Send install.log file for support

Bridge won't auto-start:
- See AUTOSTART_README.txt for options
- Try running create-windows-service.bat as Admin

Events not appearing:
- Check "Auto-track" checkbox is enabled
- Verify status shows green ●
- Check Max Console (Cmd+M / Ctrl+M in Max)

Voice notes not working:
- Check microphone permissions
- Windows: Settings → Privacy → Microphone
- macOS: System Preferences → Security → Microphone

FILES INCLUDED
--------------
INSTALL.bat                 - ONE-CLICK INSTALLER (Windows) ⭐
INSTALL.ps1                 - PowerShell installer
QUICK_INSTALL_WINDOWS.txt   - Quick start guide ⭐
AUTOSTART_README.txt        - Auto-start options guide ⭐
create-windows-service.bat  - Install as Windows service
README.txt                  - This file

ProductionTracker.maxpat    - The M4L device
websocket-bridge.js         - WebSocket bridge
package.json                - Node.js dependencies
code/                       - JavaScript modules

start-bridge.bat            - Manual bridge start (Windows)
start-bridge.sh             - Manual bridge start (Mac/Linux)

DETAILED LOGGING
----------------

When you run INSTALL.bat, it creates install.log with detailed information.

If you have any issues, send install.log for support!

The log includes:
- Every step of installation
- Error messages with details
- File paths and commands
- Success/failure codes

UNINSTALLATION
--------------

WINDOWS:
1. Remove auto-start:
   - Press Win+R → type: shell:startup
   - Delete "Production Tracker Bridge" shortcut

2. Remove service (if installed):
   - Run as Admin: sc delete ProductionTrackerBridge

3. Delete files:
   - C:\Program Files\ProductionTracker\
   - Ableton device from User Library
   - Desktop shortcut

MANUAL:
- Delete extracted folder
- Remove .amxd from Ableton User Library
- Remove shortcuts

SUPPORT
-------
Website: https://muvs.dev
Documentation: See AUTOSTART_README.txt and QUICK_INSTALL_WINDOWS.txt
Log file: install.log (created during installation)

PRIVACY
-------
Only metadata is tracked - never audio or MIDI content.

Collected:
- Session timing
- Track/device names and counts
- Tempo and time signature
- Transport state
- User notes and snapshots

NOT collected:
- Audio recordings (except your voice notes)
- MIDI note data
- Automation
- Plugin settings
- Personal data

VERSION
-------
v1.0.1 - Auto-start improvements

CHANGELOG
---------
v1.0.1 (2025-11-16)
- Added automatic bridge startup with Windows
- Added detailed installation logging
- Added Windows service option
- Improved error handling
- Better M4L device detection

v1.0.0 (2025-11-16)
- Initial release

================================
Happy producing! 🎵

After installation, just open Ableton!
The bridge runs automatically in background.

Get insights at https://muvs.dev
================================
