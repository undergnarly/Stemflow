# Production Tracker - Installation Guide

Step-by-step guide to installing and setting up the Production Tracker Max4Live device.

## Requirements

### Software Requirements

- **Ableton Live 11.0 or higher**
  - Max4Live must be installed (included in Live Suite, or available as a separate purchase)
- **Internet connection** (for communication with Production Tracker server)
- **Production Tracker account** (register at the web application)

### System Requirements

- **macOS:** 10.13 or higher
- **Windows:** 10 or higher
- **RAM:** 8GB minimum (16GB recommended)
- **Disk Space:** 50MB for device and cache

## Installation Steps

### 1. Download the Device

Download `ProductionTracker.amxd` from:
- GitHub Releases: [link]
- Production Tracker website: [link]
- Or build from source (see DEVELOPMENT.md)

### 2. Install in Ableton Live

**Method A: User Library (Recommended)**

1. Open Ableton Live
2. In the **Browser**, navigate to **User Library**
3. Right-click on **User Library** → **Show in Finder** (Mac) or **Show in Explorer** (Windows)
4. Create a new folder called **"Production Tracker"**
5. Copy `ProductionTracker.amxd` into this folder
6. Return to Ableton Live - the device should now appear in **User Library → Production Tracker**

**Method B: Drag and Drop**

1. Locate the downloaded `ProductionTracker.amxd` file
2. Drag it directly onto the **Master track** in Ableton Live
3. The device will be loaded (but not saved to library)

### 3. Add Device to Master Track

1. In Ableton Live, locate **Production Tracker** in your **User Library**
2. **Drag** the device onto your **Master track**
3. The device should now appear in the Master track's device chain

> **Important:** Always place the device on the **Master track** for proper session tracking.

### 4. Create Production Tracker Account

If you haven't already:

1. Open your web browser
2. Navigate to the Production Tracker web application: `http://localhost:3000` (or production URL)
3. Click **"Register"**
4. Fill in your details:
   - Email
   - Name
   - Password
5. Click **"Create Account"**
6. You'll be logged in automatically

### 5. Connect Device to Account

1. In the Production Tracker web app, navigate to **Settings** → **Devices**
2. Click **"Add New Device"**
3. A **connection code** will be displayed (e.g., `ABC-123-XYZ`)
4. In Ableton Live, click the **"Connect"** button on the M4L device
5. Enter the connection code when prompted
6. Click **"OK"**
7. The device status should change to **"● Connected"** (green dot)

### 6. Verify Connection

1. Check that the device shows **"● Connected"** status
2. Start playing or editing your project
3. In the web app, you should see:
   - Active session indicator
   - Real-time event updates
   - Project name displayed

## Configuration

### Device Settings

Once connected, configure the device to your preferences:

#### Auto-track (Recommended: ON)

- **Toggle:** ☑ Auto-track
- **Function:** Automatically tracks all project changes
- **When OFF:** Only manual actions (voice notes, snapshots) are tracked

#### Send on Save (Optional: OFF by default)

- **Toggle:** ☐ Send on Save
- **Function:** Creates an automatic snapshot every time you save the project
- **When ON:** Every Cmd+S / Ctrl+S creates a new version

### Server Settings (Advanced)

By default, the device connects to `localhost:8000`. To change:

1. Edit `config.js` in the device code (requires Max4Live knowledge)
2. Change `API_URL` and `WS_URL` values
3. Save and reload device

### Firewall Settings

If connection fails, check firewall:

**macOS:**
1. System Preferences → Security & Privacy → Firewall
2. Ensure "Max" is allowed

**Windows:**
1. Control Panel → Windows Defender Firewall → Allow an app
2. Ensure "Max" and "Ableton Live" are allowed

## Troubleshooting

### Device Not Appearing in User Library

**Solution:**
- Restart Ableton Live
- Check file was copied to correct location
- Verify file extension is `.amxd`

### "Connect" Button Does Nothing

**Solution:**
- Ensure backend server is running
- Check network connection
- Verify firewall settings
- Check Max Console for errors (see below)

### Status Shows "Disconnected" (Red)

**Possible causes:**
- Backend server not running
- Network issues
- Invalid token/credentials
- Firewall blocking connection

**Solutions:**
1. Verify backend server is running (`http://localhost:8000/health`)
2. Try reconnecting (click "Connect" again)
3. Check web browser can access web app
4. Restart Ableton Live

### No Events Appearing in Web App

**Possible causes:**
- Auto-track is disabled
- WebSocket connection issue
- Session not started

**Solutions:**
1. Check **☑ Auto-track** is enabled
2. Verify status is **"● Connected"**
3. Make a change in your project (add track, change tempo)
4. Check web app Session view for events

### Voice Notes Not Working

**Possible causes:**
- Microphone not enabled
- Audio input not configured
- Recording permission not granted

**Solutions:**
1. macOS: System Preferences → Security & Privacy → Microphone → Allow Ableton Live
2. Windows: Settings → Privacy → Microphone → Allow Ableton Live
3. Check Ableton preferences → Audio → Input Device

### Opening Max Console for Debugging

If you need to see detailed logs:

1. With the device selected, press **Cmd+M** (Mac) or **Ctrl+M** (Windows)
2. Max Console window will open
3. Look for messages starting with **[ProductionTracker]**
4. Check for ERROR or WARN messages

## Uninstallation

To remove the device:

1. Remove device from Master track in your projects
2. Delete `ProductionTracker.amxd` from User Library folder
3. (Optional) In web app, go to Settings → Devices → Remove device

## Next Steps

Once installed and connected:

1. **Start a session** - The device automatically starts tracking when connected
2. **Try voice notes** - Press and hold the "Voice Note" button, speak, and release
3. **Create snapshots** - Click "Snapshot" to save the current state
4. **View in web app** - Check the web app to see your session data and AI insights

## Support

If you encounter issues:

1. Check the [Troubleshooting](#troubleshooting) section above
2. Review DEVELOPMENT.md for technical details
3. Check the GitHub Issues page
4. Contact support (if available)

## Updates

To update to a new version:

1. Download the new version
2. Remove old device from Master track
3. Delete old `.amxd` file from User Library
4. Install new version following steps above
5. No need to reconnect - your authentication is saved

---

**Congratulations!** You're now ready to use Production Tracker to accelerate your music production workflow! 🎵
