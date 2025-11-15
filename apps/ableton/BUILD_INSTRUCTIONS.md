# Building the Production Tracker M4L Device

This guide explains how to build the Production Tracker Max for Live device from the source files.

## Prerequisites

1. **Ableton Live 11+** with Max for Live
2. **Max/MSP 8+** (included with Ableton Suite, or standalone)
3. **Node.js 14+** (for WebSocket bridge)

## File Structure

```
apps/ableton/
├── ProductionTracker.maxpat     # Max patch (created)
├── websocket-bridge.js          # WebSocket bridge script
├── package.json                 # Node.js dependencies
├── code/                        # JavaScript code for Max
│   ├── tracker.js              # Main tracking logic
│   ├── websocket.js            # WebSocket interface
│   ├── ableton-api.js          # Live API wrapper
│   ├── config.js               # Configuration
│   └── utils.js                # Utilities
├── docs/                        # Documentation
└── BUILD_INSTRUCTIONS.md        # This file
```

## Step 1: Install Node.js Dependencies

The WebSocket bridge requires Node.js and the `ws` module.

```bash
cd apps/ableton
npm install
```

## Step 2: Open the Max Patch

1. Open **Ableton Live**
2. Open **Max for Live** editor:
   - Create a new MIDI or Audio track
   - Go to **Max for Live** in the browser
   - Right-click in empty space → **Edit**
3. Or open Max/MSP standalone and:
   - **File → Open** → Navigate to `apps/ableton/ProductionTracker.maxpat`

## Step 3: Configure JavaScript Paths

The patch references JavaScript files in the `code/` folder. Verify paths are correct:

1. In the Max patch, find the `[js tracker.js]` object
2. Open it (double-click)
3. Verify the include paths at the top work:
   ```javascript
   include("config.js");
   include("utils.js");
   include("websocket.js");
   include("ableton-api.js");
   ```
4. If files aren't found, update to absolute paths or ensure `code/` folder is in the right location

## Step 4: Set Up Presentation Mode

The UI needs to be arranged in Presentation mode:

1. In Max, press **Cmd+Alt+E** (Mac) or **Ctrl+Alt+E** (Win) to enter edit mode
2. Select each UI object (buttons, toggles, labels)
3. Right-click → **Inspector**
4. Enable **"Include in Presentation"** checkbox
5. Switch to Presentation mode: **View → Presentation**
6. Arrange objects according to layout:
   - Device size: 256px × 128px
   - See `docs/MAX_PATCH_STRUCTURE.md` for exact coordinates

## Step 5: Connect Message Routing

Ensure all connections are made:

### UI Buttons → Tracker
```
[live.button Connect] → [prepend connect] → [js tracker.js]
[live.button Voice Note] → [prepend voice_note] → [js tracker.js]
[live.button Snapshot] → [prepend snapshot] → [js tracker.js]
[live.toggle Auto-track] → [prepend setAutoTrack] → [js tracker.js]
[live.toggle Send on Save] → [prepend setSendOnSave] → [js tracker.js]
```

### Tracker → WebSocket → UDP
```
[js tracker.js] outlet 0 → [udpsend localhost 7400]
[udpreceive 7401] → [js tracker.js] inlet
```

### Live API → Tracker
```
[live.path live_set] → [live.object] → [js ableton-api.js] → [js tracker.js]
```

### Storage
```
[loadbang] → [pattrstorage production_tracker]
[pattrstorage] ← [all toggles and settings to save]
```

## Step 6: Add Live API Observers

For automatic tracking, add observers:

```
1. Song Observer:
   [live.path live_set] → [live.object]

2. Tracks Observer:
   [live.path live_set tracks] → [live.object]

3. Transport Observer:
   [live.path live_set] → [live.object]
   @property is_playing
```

Connect these to `[js ableton-api.js]` to capture events.

## Step 7: Configure WebSocket URL

In `code/config.js`, set the backend URL:

```javascript
const CONFIG = {
  API_URL: "https://muvs.dev",
  WS_URL: "wss://muvs.dev/ws",
  // ... other settings
};
```

## Step 8: Test the Patch

1. **Start the WebSocket bridge** in a terminal:
   ```bash
   cd apps/ableton
   npm start
   ```
   You should see:
   ```
   UDP bridge listening on 0.0.0.0:7400
   WebSocket Bridge started
   ```

2. **Test in Max:**
   - Press the **Connect** button
   - Check Max Console (Cmd+M / Ctrl+M) for logs
   - Verify UDP messages are sent/received

3. **Test Live API:**
   - Add/remove a track in Ableton
   - Check if events are captured
   - Look for messages in Max Console

## Step 9: Save as .amxd Device

Once everything works:

1. In Max, go to **File → Save As...**
2. Choose **Max for Live Device (.amxd)** as file type
3. Save as `ProductionTracker.amxd`
4. The .amxd file is a self-contained device

## Step 10: Package for Distribution

Create a distributable package:

```
ProductionTracker-v1.0.0/
├── ProductionTracker.amxd        # The device
├── websocket-bridge.js           # Bridge script
├── package.json                  # Dependencies
├── README.md                     # User instructions
└── INSTALLATION.md               # Installation guide
```

Zip this folder for distribution.

## Testing Checklist

Before distributing, test:

- [ ] Device loads without errors
- [ ] Connect button opens auth dialog
- [ ] WebSocket bridge connects to server
- [ ] Session tracking starts/stops
- [ ] Track changes are detected
- [ ] Transport state changes are captured
- [ ] Voice note button records audio
- [ ] Snapshot button creates snapshots
- [ ] Auto-track toggle works
- [ ] Send-on-save toggle works
- [ ] Device survives Live restart (settings saved)
- [ ] Reconnection works after network interruption
- [ ] UI updates correctly (status, timer, counts)

## Common Build Issues

### "js: can't find file"
- Verify JavaScript files are in `code/` folder next to .maxpat
- Or use absolute paths in `[js]` objects
- Or embed with `@embed 1`

### "live.object: no object"
- Ensure device is on a track in Live
- Check Live API paths are correct
- Verify Live Set is the active set

### UDP messages not received
- Check WebSocket bridge is running
- Verify ports 7400/7401 are not in use
- Check firewall settings

### WebSocket connection fails
- Verify backend server is running
- Check URL in config.js
- Ensure SSL certificates are valid (wss://)

### UI doesn't appear
- Check "Include in Presentation" is enabled
- Verify presentation coordinates
- Press **View → Presentation** in Max

## Development Tips

1. **Use @autowatch** during development:
   ```
   [js tracker.js @autowatch 1]
   ```
   Auto-reloads when files change

2. **Use Max Console** for debugging:
   - Cmd+M (Mac) / Ctrl+M (Win)
   - All `post()` calls appear here

3. **Test WebSocket separately** first:
   - Use a WebSocket client to test backend
   - Then integrate into Max

4. **Use [print]** objects for debugging:
   ```
   [js tracker.js] → [print TRACKER]
   ```

5. **Lock/Unlock quickly**:
   - Cmd+E (Mac) / Ctrl+E (Win) toggles edit mode

## Freezing for Distribution

For final distribution:

1. Remove `@autowatch` from all `[js]` objects
2. Test thoroughly
3. **File → Freeze** (optional, makes device load faster)
4. Test frozen version
5. Save as .amxd

**Note:** Frozen devices can't be edited by users, but load faster.

## Next Steps

After building:

1. See `docs/INSTALLATION.md` for user installation instructions
2. See `docs/DEVELOPMENT.md` for development/contribution guide
3. See `README.md` for feature documentation

## Support

If you encounter issues:

1. Check `docs/MAX_PATCH_STRUCTURE.md` for detailed architecture
2. Review Max Console for errors
3. Verify all prerequisites are met
4. Check GitHub Issues for known problems

## Resources

- [Max/MSP Documentation](https://docs.cycling74.com/max8)
- [Live Object Model](https://docs.cycling74.com/max8/vignettes/live_object_model)
- [JavaScript in Max](https://docs.cycling74.com/max8/vignettes/jsbasic)
- [Max for Live Guide](https://www.ableton.com/en/manual/max-for-live/)
