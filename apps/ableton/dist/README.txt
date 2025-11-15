================================
Production Tracker for Ableton Live
Max for Live Device v1.0.0
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

REQUIREMENTS
------------
1. Ableton Live 11+ with Max for Live
2. Node.js 14+ (installer will handle this for you on Windows)
3. Production Tracker account at https://muvs.dev

QUICK INSTALL - WINDOWS (ONE-CLICK)
------------------------------------
👉 See QUICK_INSTALL_WINDOWS.txt for easy installation!

Just run INSTALL.bat as Administrator - it does everything for you!

INSTALLATION - ALL PLATFORMS
-----------------------------

WINDOWS:
1. Right-click INSTALL.bat → "Run as Administrator"
2. Follow the prompts
3. Done!

Or use PowerShell:
1. Right-click INSTALL.ps1 → "Run with PowerShell"

MANUAL INSTALLATION (All Platforms):
-------------------------------------
1. Install Node.js from https://nodejs.org (if not already installed)

2. Start the WebSocket Bridge:
   - Windows: Double-click start-bridge.bat
   - Mac/Linux: Run ./start-bridge.sh

   Keep this window open while using Ableton!

3. Install the M4L device:

   WINDOWS:
   Copy ProductionTracker.amxd to:
   %USERPROFILE%\Documents\Ableton\User Library\Presets\Audio Effects\Max Audio Effect\

   MAC:
   Copy ProductionTracker.amxd to:
   ~/Music/Ableton/User Library/Presets/Audio Effects/Max Audio Effect/

   Or drag ProductionTracker.amxd directly onto a track in Ableton

4. In Ableton Live:
   - Drag "Production Tracker" device onto your Master track
   - Click the "Connect" button
   - Enter your auth token from https://muvs.dev/dashboard
   - Start making music!

QUICK START
-----------
After installation:

1. Start the WebSocket bridge (if not already running)
2. Open Ableton Live
3. Add Production Tracker device to Master track
4. Click "Connect" and enter your auth token
5. Make music - tracking happens automatically!

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

AUTO-START BRIDGE (Windows)
---------------------------
The installer can add the bridge to Windows startup automatically.
This means it will start when you log in to Windows.

Alternatively, you can manually add it:
1. Press Win+R
2. Type: shell:startup
3. Create a shortcut to start-bridge.bat in that folder

TROUBLESHOOTING
---------------
Device shows "Disconnected":
- Make sure the WebSocket bridge is running (start-bridge script)
- Check your internet connection
- Verify you're logged in at https://muvs.dev
- Check that ports 7400 and 7401 are not in use

Bridge won't start:
- Install Node.js from https://nodejs.org
- On Windows: Run as Administrator
- Check firewall settings

Events not appearing on dashboard:
- Check "Auto-track" is enabled (checkbox)
- Verify status shows green ●
- Check Max Console for errors (Cmd+M / Ctrl+M in Max)

Voice notes not working:
- Check microphone permissions
- macOS: System Preferences → Security & Privacy → Microphone
- Windows: Settings → Privacy → Microphone

Installation failed:
- Windows: Run INSTALL.bat as Administrator
- Check internet connection
- Install Node.js manually if needed

FILES INCLUDED
--------------
ProductionTracker.maxpat    - The M4L device
websocket-bridge.js         - WebSocket bridge script
package.json                - Node.js dependencies
code/                       - JavaScript code modules

WINDOWS ONLY:
INSTALL.bat                 - One-click installer (recommended!)
INSTALL.ps1                 - PowerShell installer
start-bridge.bat            - Bridge startup script
QUICK_INSTALL_WINDOWS.txt   - Quick start guide for Windows

MAC/LINUX:
start-bridge.sh             - Bridge startup script

UNINSTALLATION
--------------
WINDOWS (if installed with INSTALL.bat):
1. Delete: C:\Program Files\ProductionTracker\
2. Remove device from: %USERPROFILE%\Documents\Ableton\User Library\...
3. Delete desktop shortcut
4. Remove from startup: %APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\

MANUAL:
1. Delete the extracted folder
2. Remove .amxd from Ableton User Library
3. Remove any shortcuts you created

SUPPORT
-------
Documentation: https://muvs.dev
GitHub: https://github.com/undergnarly/Stemflow
Issues: Report on GitHub

PRIVACY
-------
Only metadata is tracked - never your actual audio or MIDI content.

Data collected:
- Session timing
- Track/device names and counts
- Tempo and time signature
- Transport state (play/stop)
- User notes and snapshots

NOT collected:
- Audio recordings (except voice notes you manually record)
- MIDI note data
- Automation values
- Plugin settings
- Keystroke or mouse data

All data is encrypted in transit (HTTPS/WSS).

VERSION
-------
v1.0.0 - Initial release

CHANGELOG
---------
v1.0.0 (2025-11-16)
- Initial release
- Automatic session tracking
- Voice notes and snapshots
- WebSocket real-time communication
- Auto-reconnection and offline queueing
- Windows one-click installer
- Auto-start option

================================
Happy producing! 🎵

Get insights at https://muvs.dev
================================
