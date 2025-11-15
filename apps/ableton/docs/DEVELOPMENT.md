# Production Tracker - Development Guide

Guide for developers working on the Max4Live device.

## Development Environment Setup

### Prerequisites

- **Ableton Live 11+** with Max4Live
- **Max 8.5+** (standalone, for advanced development)
- **Node.js 20+** (for WebSocket bridge)
- **Git** (for version control)
- **Code editor** (VS Code recommended)

### Project Structure

```
apps/ableton/
├── ProductionTracker.amxd     # Main M4L device (binary)
├── code/                      # JavaScript source files
│   ├── tracker.js            # Main logic
│   ├── websocket.js          # WebSocket client
│   ├── ableton-api.js        # Live API wrapper
│   ├── config.js             # Configuration
│   └── utils.js              # Utilities
├── resources/
│   ├── icons/                # UI icons
│   └── presets/              # Device presets
├── build/                    # Build output
│   └── ProductionTracker.amxd
├── tests/                    # Test patches
│   └── test-connection.maxpat
├── docs/                     # Documentation
│   ├── INSTALLATION.md
│   ├── DEVELOPMENT.md
│   └── MAX_PATCH_STRUCTURE.md
└── README.md
```

## Development Workflow

### 1. Clone Repository

```bash
git clone <repository-url>
cd Stemflow/apps/ableton
```

### 2. Open Device in Edit Mode

1. Open Ableton Live
2. Drag `ProductionTracker.amxd` onto Master track
3. Right-click device → **Edit**
4. Max editor opens with the patch

### 3. Enable Auto-watch for JavaScript

In the Max patch:
1. Select the `[js tracker.js]` object
2. Inspector → `@autowatch 1`
3. JavaScript files will auto-reload on save

### 4. Make Changes

#### Editing JavaScript Files

1. Open JavaScript files in your code editor
2. Edit code (e.g., `code/tracker.js`)
3. Save file
4. Changes automatically reload (if `@autowatch 1`)
5. Check Max Console for errors

#### Editing Max Patch

1. Unlock patch: **Cmd+E** (Mac) / **Ctrl+E** (Win)
2. Edit objects, connections, UI
3. Lock patch: **Cmd+E** again
4. Test changes

### 5. Debug

#### Max Console

- Open: **Cmd+M** (Mac) / **Ctrl+M** (Win)
- Shows all `post()` output from JavaScript
- Shows Max errors and warnings

#### JavaScript Debugging

Add debug statements:
```javascript
logDebug("Variable value", { myVar: myVar });
post("Quick debug:", myVar);
```

#### Enable Debug Mode

In `config.js`:
```javascript
DEBUG_MODE: true
```

All `logDebug()` calls will now output to console.

#### Live API Debugging

Test Live API calls in Max Console:
```
[live.object] → [print]
```

Or in JavaScript:
```javascript
const api = new LiveAPI("live_set");
post("Tempo:", api.get("tempo"));
```

### 6. Test

#### Manual Testing

1. Make changes in Live (add track, change tempo, etc.)
2. Check Max Console for event logs
3. Check web app for received events
4. Verify UI updates

#### Test Patches

Create test patches in `tests/` folder:

**Example: test-track-events.maxpat**
```
[loadbang]
|
[qmetro 1000]
|
[counter 0 10]
|
[js tracker.js]
```

Simulates rapid track changes.

### 7. Build for Distribution

1. Remove `@autowatch` from JavaScript objects
2. Embed JavaScript files (optional):
   - `[js tracker.js @embed 1]`
3. Test without autowatch
4. File → **Freeze**
5. Save as `.amxd` file
6. Copy to `build/` folder

## WebSocket Bridge Development

Since Max doesn't have native WebSocket, we need a bridge.

### Option 1: Node.js Bridge (Recommended)

Create `websocket-bridge.js`:

```javascript
const maxApi = require('max-api');
const WebSocket = require('ws');

let ws = null;

// Connect to WebSocket
maxApi.addHandler('ws_connect', (url) => {
  if (ws) ws.close();

  ws = new WebSocket(url);

  ws.on('open', () => {
    maxApi.outlet('ws_opened');
  });

  ws.on('message', (data) => {
    maxApi.outlet('ws_message', data.toString());
  });

  ws.on('error', (error) => {
    maxApi.outlet('ws_error', error.message);
  });

  ws.on('close', () => {
    maxApi.outlet('ws_closed');
  });
});

// Send message
maxApi.addHandler('ws_send', (message) => {
  if (ws && ws.readyState === WebSocket.OPEN) {
    ws.send(message);
  }
});

// Disconnect
maxApi.addHandler('ws_disconnect', () => {
  if (ws) {
    ws.close();
    ws = null;
  }
});
```

In Max patch:
```
[js tracker.js]
|
[route ws_connect ws_send ws_disconnect]
|       |         |
|       |         [nodejs websocket-bridge.js]
|       |
[nodejs websocket-bridge.js]
```

Install dependencies:
```bash
npm install ws
npm install max-api
```

### Option 2: UDP Bridge

Create separate Node.js app:

```javascript
// websocket-udp-bridge.js
const WebSocket = require('ws');
const dgram = require('dgram');

const udpServer = dgram.createSocket('udp4');
const WS_URL = 'ws://localhost:8000/ws/session';

let ws = null;

// UDP Server (receive from Max)
udpServer.on('message', (msg, rinfo) => {
  const data = JSON.parse(msg.toString());

  if (data.type === 'connect') {
    // Connect WebSocket
    ws = new WebSocket(data.url);

    ws.on('open', () => {
      sendToMax({ type: 'ws_opened' });
    });

    ws.on('message', (wsMsg) => {
      sendToMax({ type: 'ws_message', data: wsMsg.toString() });
    });

    ws.on('error', (error) => {
      sendToMax({ type: 'ws_error', error: error.message });
    });

    ws.on('close', () => {
      sendToMax({ type: 'ws_closed' });
    });
  } else if (data.type === 'send') {
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.send(data.message);
    }
  }
});

function sendToMax(data) {
  const msg = Buffer.from(JSON.stringify(data));
  udpServer.send(msg, 8002, 'localhost');
}

udpServer.bind(8001);
console.log('Bridge listening on UDP 8001');
```

In Max patch:
```
[udpsend localhost 8001]  - Send to bridge
[udpreceive 8002]         - Receive from bridge
```

## Code Style Guidelines

### JavaScript

- Use semicolons
- Use camelCase for variables and functions
- Use UPPER_CASE for constants
- Add JSDoc comments for functions
- Keep functions small and focused

```javascript
/**
 * Get project information
 * @returns {Object} Project info object
 */
function getProjectInfo() {
  return {
    name: getProjectName(),
    tempo: getTempo()
  };
}
```

### Max Patch

- Use descriptive object names
- Comment complex routing with `[comment]`
- Keep presentation mode clean and organized
- Use consistent colors for object types

## Testing Checklist

Before committing:

- [ ] JavaScript syntax is valid (no errors in Max Console)
- [ ] Live API calls work correctly
- [ ] WebSocket connection succeeds
- [ ] Events are sent correctly
- [ ] UI updates properly
- [ ] Voice notes record and upload
- [ ] Snapshots are created
- [ ] Settings persist after restart
- [ ] Reconnection works after disconnect
- [ ] Works with frozen/embedded device

## Common Development Tasks

### Adding a New Event Type

1. Add to `CONFIG.EVENT_TYPES` in `config.js`:
   ```javascript
   CLIP_ADD: "clip_add"
   ```

2. Create event in `tracker.js`:
   ```javascript
   function onClipAdded(clipData) {
     const event = {
       type: CONFIG.EVENT_TYPES.CLIP_ADD,
       timestamp: now(),
       data: {
         sessionId: tracker.sessionId,
         clipName: clipData.name,
         trackIndex: clipData.trackIndex
       }
     };

     WebSocketClient.sendEvent(event);
   }
   ```

3. Set up Live API observer in Max patch
4. Test event sending

### Adding a New UI Element

1. Add object in Max patch (presentation mode)
2. Set coordinates and size
3. Connect to JavaScript:
   ```
   [live.button "My Button"]
   |
   [prepend myAction]
   |
   [js tracker.js]
   ```

4. Handle in JavaScript:
   ```javascript
   function myAction() {
     logInfo("Button clicked");
     // Do something
   }
   ```

### Adding a New Setting

1. Add to `config.js`:
   ```javascript
   MY_SETTING_DEFAULT: true
   ```

2. Add to tracker state:
   ```javascript
   var tracker = {
     // ...
     mySetting: CONFIG.MY_SETTING_DEFAULT
   };
   ```

3. Add getter/setter:
   ```javascript
   function setMySetting(value) {
     tracker.mySetting = value === 1;
     saveSettings();
   }
   ```

4. Add UI toggle in Max patch
5. Add to pattrstorage

## Performance Optimization

### Debouncing Events

Use `shouldDebounce()` for frequent events:

```javascript
function onParameterChange(param) {
  if (shouldDebounce("param_change", 2000)) {
    return; // Skip if called within 2 seconds
  }

  // Send event
}
```

### Throttling Live API Calls

Avoid calling Live API in tight loops:

```javascript
// BAD
for (let i = 0; i < trackCount; i++) {
  const name = AbletonAPI.getTrackInfo(i).name;
}

// GOOD - batch if possible
const tracks = AbletonAPI.getAllTracksInfo();
```

### Event Queueing

Large events should be batched:

```javascript
// In config.js
MAX_BATCH_SIZE: 50

// In websocket.js
const batches = chunk(eventQueue, CONFIG.MAX_BATCH_SIZE);
```

## Debugging WebSocket Issues

### Check Connection

```bash
# Test backend WebSocket endpoint
wscat -c ws://localhost:8000/ws/session?token=YOUR_TOKEN
```

### Monitor Traffic

In Max Console, enable WebSocket logging:
```javascript
// In websocket.js
function sendEventNow(event) {
  logDebug("Sending event", event); // Enable this
  // ...
}
```

### Test HTTP Fallback

If WebSocket fails, test HTTP:
```bash
curl -X POST http://localhost:8000/api/sessions/events \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"events":[{"type":"test"}]}'
```

## Troubleshooting

### JavaScript Not Reloading

- Ensure `@autowatch 1` is set
- Try toggling edit mode
- Restart Ableton Live

### Live API Returns Null

- Check object path is correct
- Verify object exists in Live
- Try using `live.observer` to debug

### Max Crashes

- Check for infinite loops in JavaScript
- Avoid too many Live API calls in succession
- Check array bounds

### High CPU Usage

- Reduce heartbeat frequency
- Increase debounce times
- Disable debug logging

## Resources

- **Max/MSP Docs:** https://docs.cycling74.com/max8
- **Live Object Model:** https://docs.cycling74.com/max8/vignettes/live_object_model
- **JavaScript in Max:** https://docs.cycling74.com/max8/vignettes/jsbasic
- **Max API Reference:** https://docs.cycling74.com/max8/refpages/ref-toc
- **WebSocket RFC:** https://tools.ietf.org/html/rfc6455

## Contributing

1. Create feature branch: `git checkout -b feature/my-feature`
2. Make changes
3. Test thoroughly
4. Commit with clear message
5. Push and create pull request
6. Ensure CI passes

## Version Control

### Git Ignore

Add to `.gitignore`:
```
*.maxpat~
*.amxd~
build/*
*.log
```

### Committing Max Patches

Max patches are binary/JSON files. Use clear commit messages:

```
git add ProductionTracker.amxd
git commit -m "Add voice note duration limit UI"
```

## Deployment

### Building Release

1. Remove debug code
2. Remove `@autowatch`
3. Test thoroughly
4. Freeze device
5. Test frozen device
6. Tag release:
   ```bash
   git tag v1.0.0
   git push --tags
   ```

### Distribution Checklist

- [ ] All debug logging removed
- [ ] `@autowatch` removed
- [ ] Device frozen
- [ ] Tested on clean system
- [ ] Documentation updated
- [ ] Version number updated
- [ ] README updated
- [ ] CHANGELOG created

---

Happy coding! 🎵
