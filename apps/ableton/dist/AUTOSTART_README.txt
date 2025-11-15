================================
PRODUCTION TRACKER - AUTO-START OPTIONS
================================

The WebSocket bridge can be started automatically in several ways.
Choose the option that works best for you:

================================
OPTION 1: WINDOWS STARTUP (RECOMMENDED - EASIEST)
================================

The installer already asked you about this!

If you chose "Yes" when asked about auto-start during installation,
the bridge is ALREADY set up to start automatically with Windows.

You don't need to do anything else!

To verify:
1. Press Win+R
2. Type: shell:startup
3. Look for "Production Tracker Bridge" shortcut

To disable auto-start:
1. Press Win+R
2. Type: shell:startup
3. Delete "Production Tracker Bridge" shortcut

================================
OPTION 2: WINDOWS SERVICE (MOST RELIABLE)
================================

This runs the bridge as a background Windows service.

Advantages:
- Starts before you log in
- Runs even if not logged in
- Automatically restarts if crashes
- Most reliable option

To install as service:
1. Right-click "create-windows-service.bat"
2. Select "Run as Administrator"
3. Follow the prompts

The service will:
- Start automatically with Windows
- Run in background (no window)
- Restart automatically if it stops

To remove service later:
- Run: sc delete ProductionTrackerBridge
  (as Administrator in Command Prompt)

================================
OPTION 3: MANUAL START (SIMPLEST)
================================

If you don't want auto-start:

1. Double-click the desktop shortcut:
   "Production Tracker Bridge"

   OR

2. Double-click "start-bridge.bat" before opening Ableton

The bridge will run until you close the window.

================================
OPTION 4: AUTO-START FROM MAX PATCH (ADVANCED)
================================

The Max device can try to start the bridge automatically.

This is already built into the device!

When you load the device in Ableton, it will:
1. Check if bridge is running
2. If not, try to start it automatically
3. Show status in Max console

NOTE: This requires the bridge to be installed in:
      C:\Program Files\ProductionTracker\

================================
WHICH OPTION SHOULD I USE?
================================

FOR MOST USERS:
→ Option 1 (Windows Startup) - Already done by installer!

FOR POWER USERS:
→ Option 2 (Windows Service) - Most reliable, runs as service

FOR TESTING:
→ Option 3 (Manual) - Full control, can see console output

================================
HOW TO CHECK IF BRIDGE IS RUNNING
================================

Method 1: Task Manager
1. Press Ctrl+Shift+Esc
2. Look for "Node.js: Server-side JavaScript"
3. Check command line contains "websocket-bridge.js"

Method 2: Command Prompt
Run: tasklist | findstr "node.exe"
Should see "node.exe" if running

Method 3: Check ports
Run: netstat -an | findstr ":7400"
Should see port 7400 listening

================================
TROUBLESHOOTING
================================

Bridge won't start:
- Make sure Node.js is installed
- Check ports 7400 and 7401 are not in use
- Run as Administrator
- Check firewall settings

Bridge starts but disconnects:
- Check internet connection
- Verify you're logged in at https://muvs.dev
- Check Max console for errors

Multiple instances running:
- Run: taskkill /F /IM node.exe
- Then start bridge again with only one method

================================
UNINSTALL AUTO-START
================================

To completely remove auto-start:

1. Remove from Windows Startup:
   - Press Win+R → shell:startup
   - Delete "Production Tracker Bridge" shortcut

2. Remove Windows Service (if installed):
   - Run as Admin: sc delete ProductionTrackerBridge

3. Remove from Program Files:
   - Delete: C:\Program Files\ProductionTracker\

================================
SUPPORT
================================

For help, visit: https://muvs.dev

If bridge won't start, send the log file:
- Location: (same folder as INSTALL.bat)
- File: install.log
