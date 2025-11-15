# Max4Live Patch Structure

This document describes how to build the Max patch (ProductionTracker.amxd) that uses the JavaScript code files.

## Overview

The Max patch connects Max/MSP objects with the JavaScript logic to create a functioning M4L device. It handles:
- UI elements for user interaction
- WebSocket communication (via external tools)
- Audio recording for voice notes
- Data storage (tokens, settings)
- Live API integration

## Required Max Objects

### JavaScript Objects

```
[js tracker.js]      - Main tracker logic
[js websocket.js]    - WebSocket handler (interface definition)
[js ableton-api.js]  - Live API wrapper
```

### Live API Objects

```
[live.object]        - Various Live API observers
[live.path]          - Live object path navigation
[live.observer]      - Property observation
```

### UI Objects

```
[live.text]          - Text displays and buttons
[live.toggle]        - Toggle switches
[live.numbox]        - Number displays
[live.dial]          - Dial controls
[comment]            - Labels
```

### Audio Objects (for voice notes)

```
[ezadc~]             - Audio input
[record~]            - Audio recording
[sfrecord~]          - File recording
```

### Utility Objects

```
[metro]              - Timers
[delay]              - Delays
[route]              - Message routing
[prepend]            - Message formatting
[pak]/[unpack]       - Data packing
[pattrstorage]       - Persistent storage
```

### WebSocket Communication

Since Max doesn't have native WebSocket support, use one of:

1. **[nodejs]** object (if available)
2. **[shell]** + Node.js script
3. **[udpsend]/[udpreceive]** + local WebSocket bridge
4. **[jweb]** with JavaScript WebSocket

## Patch Layout

### Main Patch Structure

```
┌─────────────────────────────────────────────────┐
│  PRESENTATION MODE (User-facing UI)             │
│                                                  │
│  ┌─────────────────────────────────┐           │
│  │  Production Tracker             │           │
│  ├─────────────────────────────────┤           │
│  │  Status: ● Connected            │           │
│  │  Project: [project_name]        │           │
│  │  Session: [timer_display]       │           │
│  │                                  │           │
│  │  [Connect] [Voice] [Snapshot]   │           │
│  │                                  │           │
│  │  ☑ Auto-track  ☐ On Save       │           │
│  │                                  │           │
│  │  Events: [count] | [sync_time]  │           │
│  └─────────────────────────────────┘           │
│                                                  │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│  PATCHING MODE (Internal logic)                 │
│                                                  │
│  ┌──────────────┐  ┌──────────────┐            │
│  │ loadbang     │  │ js tracker   │            │
│  │ [loadbang]   │→ │ [js tracker  │            │
│  └──────────────┘  │   .js]       │            │
│                    └──────────────┘             │
│                                                  │
│  ┌──────────────────────────────────┐          │
│  │ Live API Observers                │          │
│  │ [live.object live_set]            │          │
│  │ [live.object live_set tracks]     │          │
│  │ [live.object live_set]            │          │
│  │   @property is_playing            │          │
│  └──────────────────────────────────┘          │
│                                                  │
│  ┌──────────────────────────────────┐          │
│  │ WebSocket Bridge                  │          │
│  │ [nodejs] or [shell] or [udp]      │          │
│  └──────────────────────────────────┘          │
│                                                  │
│  ┌──────────────────────────────────┐          │
│  │ Storage                           │          │
│  │ [pattrstorage production_tracker] │          │
│  └──────────────────────────────────┘          │
│                                                  │
└─────────────────────────────────────────────────┘
```

## Detailed Object Configuration

### 1. Main JavaScript Object

```
[js tracker.js @autowatch 1]
```

- `@autowatch 1` - Auto-reload when file changes (development)
- Inlets: Messages from UI and other objects
- Outlets:
  - 0: Messages to UI and other Max objects
  - 1: Error messages
  - 2: Debug output

### 2. Live API Observers

**Song Observer:**
```
[live.object]
[live.path live_set]
```

**Tracks Observer:**
```
[live.object]
[live.path live_set tracks]
```

**Transport Observer:**
```
[live.object]
[live.path live_set]
[@property is_playing]
```

### 3. UI Elements Configuration

**Status Indicator:**
```
[live.text @text "●" @mode 0]
- Use colors for different states
- Green: Connected
- Yellow: Connecting
- Red: Disconnected
- Gray: Disabled
```

**Project Name Display:**
```
[live.text @mode 0 @text ""]
- Updated from JavaScript
- Read-only
```

**Session Timer:**
```
[live.numbox @mode 0]
[sprintf %02d:%02d:%02d]
- Display as HH:MM:SS
- Updated every second
```

**Connect Button:**
```
[live.button "Connect"]
- Sends "connect" message to JavaScript
- Opens auth code input dialog
```

**Voice Note Button:**
```
[live.button "Voice Note" @mode 1]
- Mode 1 = momentary (hold to record)
- Send "start_voice_note" on press
- Send "end_voice_note" on release
```

**Snapshot Button:**
```
[live.button "Snapshot"]
- Send "create_snapshot" to JavaScript
```

**Auto-track Toggle:**
```
[live.toggle]
- Send state to JavaScript setAutoTrack()
- Stored in pattrstorage
```

**Send on Save Toggle:**
```
[live.toggle]
- Send state to JavaScript setSendOnSave()
- Stored in pattrstorage
```

### 4. WebSocket Bridge Setup

#### Option A: Using [nodejs]

```
[nodejs websocket-bridge.js]
```

Create `websocket-bridge.js`:
```javascript
const maxApi = require('max-api');
const WebSocket = require('ws');

let ws = null;

maxApi.addHandler('connect', (url) => {
  ws = new WebSocket(url);

  ws.on('open', () => {
    maxApi.outlet('ws_opened');
  });

  ws.on('message', (data) => {
    maxApi.outlet('ws_message', data);
  });

  ws.on('error', (error) => {
    maxApi.outlet('ws_error', error.message);
  });

  ws.on('close', () => {
    maxApi.outlet('ws_closed');
  });
});

maxApi.addHandler('send', (message) => {
  if (ws && ws.readyState === WebSocket.OPEN) {
    ws.send(message);
  }
});

maxApi.addHandler('disconnect', () => {
  if (ws) {
    ws.close();
  }
});
```

#### Option B: Using UDP Bridge

Create separate Node.js script that:
1. Opens WebSocket to server
2. Opens UDP server on localhost
3. Forwards messages between WebSocket and UDP

Max patch uses:
```
[udpsend localhost 8001]  - Send to bridge
[udpreceive 8002]         - Receive from bridge
```

### 5. Voice Note Recording

```
Signal Flow:
[ezadc~] → [record~ voice_buffer] → [sfrecord~] → [file]

Control:
"start_voice_recording" → [record~ 1]
"stop_voice_recording"  → [record~ 0] → trigger save

File naming:
voice_note_[timestamp].wav
```

Example patch:
```
[loadbang]
|
[t b]
|
[buffer~ voice_buffer]

[inlet~]  (from ezadc~)
|
[record~ voice_buffer]
^
|
[r start_voice_recording]

[metro 1000]  (max duration timer)
|
[counter 0 120]  (max 120 seconds)
|
[select 120]
|
[s stop_voice_recording]
```

### 6. Data Storage (pattrstorage)

```
[pattrstorage production_tracker]
|
[autopattr @autorestore 0]

Stored parameters:
- access_token (string)
- refresh_token (string)
- auto_track (int)
- send_on_save (int)
- device_id (string)
```

Setup:
```
[pattrstorage production_tracker @savemode 0]
|
[prepend store]
|
[t b]
|
[delay 100]
|
[s to_pattrstorage]

Load on bang:
[loadbang]
|
[t b b]
|         |
|         [recall 1]
|         |
|         [s to_pattrstorage]
|
[js tracker.js]
```

## Message Routing

### From UI to JavaScript

```
[live.button Connect]
|
[prepend connect]
|
[js tracker.js]
```

```
[live.toggle Auto-track]
|
[prepend setAutoTrack]
|
[js tracker.js]
```

### From JavaScript to UI

```
[js tracker.js]
|
[route ui_status ui_timer ui_events notification]
|      |         |         |           |
|      |         |         |           [prepend set]
|      |         |         |           |
|      |         |         |           [r notification_display]
|      |         |         |
|      |         |         [prepend set]
|      |         |         |
|      |         |         [r event_count_display]
|      |         |
|      |         [prepend set]
|      |         |
|      |         [r timer_display]
|      |
|      [route connected disconnected connecting]
|      |           |              |
|      [green]     [red]          [yellow]
|      |           |              |
|      [r status_color]
```

## Complete Signal Flow Example

```
User clicks "Connect" button
         ↓
[live.button "Connect"]
         ↓
bang
         ↓
[dialog] - User enters auth code
         ↓
auth_code_123
         ↓
[prepend setToken]
         ↓
[js tracker.js]
         ↓
JavaScript: setToken()
         ↓
JavaScript: connectToServer()
         ↓
outlet("ws_connect", url)
         ↓
[route ws_connect]
         ↓
[nodejs websocket-bridge.js]
         ↓
WebSocket connection established
         ↓
outlet("ws_opened")
         ↓
JavaScript: onWebSocketOpened()
         ↓
JavaScript: startSession()
         ↓
outlet("ui_status", "connected")
         ↓
[route ui_status]
         ↓
[r status_color] → Green
```

## Presentation Mode Layout

```
Dimensions: 256px × 128px

┌────────────────────────────────────────┐ 0px
│  Production Tracker          [v1.0.0]  │
├────────────────────────────────────────┤ 20px
│  Status: ●                             │ 30px
│  Project: Jungle WIP                   │ 45px
│  Session: 01:23:45                     │ 60px
├────────────────────────────────────────┤ 70px
│  [Connect]  [Voice Note]  [Snapshot]   │ 90px
├────────────────────────────────────────┤ 100px
│  ☑ Auto-track      ☐ Send on Save    │ 115px
├────────────────────────────────────────┤ 120px
│  Events: 47        Last sync: 2s ago   │ 128px
└────────────────────────────────────────┘

Coordinates (approximate):
- Title:        (5, 2)
- Version:      (200, 2)
- Status:       (5, 25)
- Project:      (5, 40)
- Timer:        (5, 55)
- Connect btn:  (5, 75) [75px wide]
- Voice btn:    (85, 75) [80px wide]
- Snapshot btn: (170, 75) [80px wide]
- Auto-track:   (5, 100)
- On Save:      (130, 100)
- Events:       (5, 120)
- Sync time:    (150, 120)
```

## Tips for Development

1. **Use @autowatch**
   ```
   [js tracker.js @autowatch 1]
   ```
   - Auto-reloads JS when file changes
   - Great for development
   - Disable for frozen device

2. **Debug with Max Console**
   - Cmd+M (Mac) / Ctrl+M (Win) to open
   - All `post()` calls appear here
   - Use `logDebug()` for verbose logging

3. **Test WebSocket separately**
   - Use a WebSocket test tool first
   - Verify server endpoints work
   - Then integrate into Max

4. **Use [print] objects**
   ```
   [js tracker.js]
   |
   [print JS_OUTPUT]
   ```
   - See all messages from JavaScript
   - Great for debugging

5. **Lock/Unlock shortcuts**
   - Cmd+E (Mac) / Ctrl+E (Win) to toggle edit mode
   - Quickly test UI changes

6. **Presentation Mode**
   - All user-facing objects must have "Include in Presentation" enabled
   - Right-click → Inspector → Presentation → Include

## Building the Patch

### Step-by-Step Guide

1. **Create new Max Audio Effect**
   - File → New → Max Audio Effect
   - Save as ProductionTracker.amxd

2. **Add JavaScript objects**
   - Add [js tracker.js]
   - Place code files in device's "code" folder
   - Or use [js tracker.js @embed 1] to embed

3. **Add Live API observers**
   - Add [live.object] for song, tracks, transport
   - Connect to JavaScript inlets

4. **Add UI elements**
   - Add buttons, toggles, text displays
   - Set presentation mode coordinates
   - Connect to JavaScript

5. **Add WebSocket bridge**
   - Choose method ([nodejs], UDP, etc.)
   - Set up message routing

6. **Add pattrstorage**
   - Create [pattrstorage] object
   - Connect to parameters to save

7. **Test thoroughly**
   - Test each feature
   - Test reconnection
   - Test error cases

8. **Freeze for distribution**
   - Remove @autowatch
   - Freeze patch (File → Freeze)
   - Test frozen version

## Troubleshooting

**JavaScript not loading:**
- Check file paths
- Check Max Console for errors
- Verify include() paths are correct

**Live API not working:**
- Verify device is on a track
- Check Live object paths
- Use [live.observer] to debug

**WebSocket not connecting:**
- Check server is running
- Verify URL and port
- Check firewall settings

**UI not updating:**
- Verify outlet connections
- Check message routing
- Use [print] to debug messages

## Resources

- Max/MSP Documentation: https://docs.cycling74.com/max8
- Live Object Model: https://docs.cycling74.com/max8/vignettes/live_object_model
- JavaScript in Max: https://docs.cycling74.com/max8/vignettes/jsbasic
