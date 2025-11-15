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
2. Node.js 14+ (for WebSocket bridge)
3. Production Tracker account at https://muvs.dev

INSTALLATION
------------
1. Install Node.js from https://nodejs.org (if not already installed)

2. Extract this ZIP file to a permanent location:
   - macOS: ~/Documents/ProductionTracker/
   - Windows: C:\Users\YourName\Documents\ProductionTracker\

3. Start the WebSocket Bridge:
   - macOS/Linux: Double-click start-bridge.sh
   - Windows: Double-click start-bridge.bat

   Keep this window open while using Ableton!

4. Install the M4L device:
   - Copy ProductionTracker.amxd to:
     macOS: ~/Music/Ableton/User Library/Presets/Audio Effects/Max Audio Effect/
     Windows: \Documents\Ableton\User Library\Presets\Audio Effects\Max Audio Effect\

   - Or drag ProductionTracker.amxd directly onto a track in Ableton

5. In Ableton Live:
   - Drag "Production Tracker" device onto your Master track
   - Click the "Connect" button
   - Enter your auth token from https://muvs.dev/dashboard
   - Start making music!

QUICK START
-----------
1. Start the WebSocket bridge (start-bridge script)
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

TROUBLESHOOTING
---------------
Device shows "Disconnected":
- Make sure the WebSocket bridge is running (start-bridge script)
- Check your internet connection
- Verify you're logged in at https://muvs.dev

Bridge won't start:
- Install Node.js from https://nodejs.org
- Make sure ports 7400 and 7401 are not in use

Events not appearing on dashboard:
- Check "Auto-track" is enabled (checkbox)
- Verify status shows green ●
- Check Max Console for errors (Cmd+M / Ctrl+M in Max)

Voice notes not working:
- Check microphone permissions
- macOS: System Preferences → Security & Privacy → Microphone
- Windows: Settings → Privacy → Microphone

FILES INCLUDED
--------------
ProductionTracker.amxd    - The M4L device
websocket-bridge.js       - WebSocket bridge script
package.json              - Node.js dependencies
start-bridge.sh           - macOS/Linux startup script
start-bridge.bat          - Windows startup script
README.txt                - This file

SUPPORT
-------
Documentation: See docs/INSTALLATION.md for detailed instructions
Website: https://muvs.dev
Issues: Check GitHub repository

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
- Automation
- Plugin settings
- Keystroke or mouse data

VERSION
-------
v1.0.0 - Initial release

================================
Happy producing! 🎵
================================
