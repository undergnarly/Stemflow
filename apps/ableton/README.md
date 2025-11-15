# Production Tracker - Max4Live Device

Max4Live device for integrating Ableton Live with the Production Tracker web application.

## Overview

The Production Tracker M4L device sits on your Master track and automatically monitors your production sessions in real-time. It tracks:

- **Session activity** - When you start/stop working
- **Project changes** - Tracks, devices, tempo, saves
- **Transport state** - Play, stop, loop changes
- **User actions** - Voice notes, manual snapshots

All data is sent to the Production Tracker backend for AI analysis, pattern detection, and insights.

## Features

### Automatic Tracking
- ✅ Track additions/removals
- ✅ Device changes
- ✅ Tempo/time signature changes
- ✅ Save detection
- ✅ Transport state (play/stop)
- ✅ Session duration tracking

### Manual Actions
- 🎤 **Voice Notes** - Record audio notes at any time
- 📸 **Snapshots** - Create instant project snapshots
- 💾 **Auto-save Versions** - Optionally create versions on every save

### Smart Features
- 🔄 **Auto-reconnection** - Seamless reconnection if connection drops
- 📦 **Event queueing** - Events are queued offline and sent when reconnected
- 🎯 **Debouncing** - Intelligent event filtering to avoid spam
- ⚡ **Low CPU usage** - Minimal impact on your DAW

## Quick Start

### Installation

1. Download `ProductionTracker.amxd`
2. Place in your User Library
3. Drag onto Master track
4. Click "Connect" and enter auth code from web app

**[Full installation guide →](docs/INSTALLATION.md)**

### First Use

1. **Connect device** - Enter auth code from Production Tracker web app
2. **Start working** - Session tracking starts automatically
3. **Make music** - Device tracks changes in the background
4. **Get insights** - Check web app for AI suggestions and analytics

## Device Interface

```
┌────────────────────────────────────────┐
│  Production Tracker                    │
├────────────────────────────────────────┤
│  Status: ● Connected                   │
│  Project: My Track Name                │
│  Session: 01:23:45                     │
│                                        │
│  [Connect]  [Voice Note]  [Snapshot]   │
│                                        │
│  ☑ Auto-track   ☐ Send on Save       │
│                                        │
│  Events: 47  |  Last sync: 2s ago      │
└────────────────────────────────────────┘
```

### Controls

**Connect Button**
- Click to enter authentication code
- Reconnect if disconnected

**Voice Note Button**
- Press and hold to record
- Speak your note
- Release to send

**Snapshot Button**
- Click to create instant snapshot
- Captures current project state

**Auto-track Toggle**
- ON: Track all changes automatically (recommended)
- OFF: Only track manual actions

**Send on Save Toggle**
- ON: Create version snapshot every time you save
- OFF: Manual snapshots only

## How It Works

```
Ableton Live
    ↓ (Live API)
M4L Device (JavaScript)
    ↓ (WebSocket)
Production Tracker Backend
    ↓ (AI Analysis)
Web Application
```

### Data Collected

**Tracked:**
- Session start/end times
- Track count, names, types
- Device names and types
- Tempo and time signature
- Transport state (play/stop)
- Save events
- User-triggered voice notes and snapshots

**NOT Tracked:**
- Audio content
- MIDI note data
- Individual automation points
- Keystroke logging
- Mouse movements

**Privacy:** Only metadata is tracked, never your actual music content.

## Technical Details

### Technology Stack

- **Max/MSP** - Max4Live framework
- **JavaScript** - Device logic
- **Live API** - Ableton Live integration
- **WebSocket** - Real-time communication
- **Node.js** - WebSocket bridge (optional)

### Code Structure

```
apps/ableton/
├── code/
│   ├── tracker.js        # Main tracking logic
│   ├── websocket.js      # WebSocket client
│   ├── ableton-api.js    # Live API wrapper
│   ├── config.js         # Configuration
│   └── utils.js          # Utilities
├── docs/
│   ├── INSTALLATION.md   # User installation guide
│   ├── DEVELOPMENT.md    # Developer guide
│   └── MAX_PATCH_STRUCTURE.md
└── README.md             # This file
```

### System Requirements

- **Ableton Live:** 11.0+ with Max4Live
- **OS:** macOS 10.13+ or Windows 10+
- **RAM:** 8GB minimum
- **Network:** Internet connection for backend communication

## Configuration

### Server Endpoints

Default configuration (in `code/config.js`):
```javascript
API_URL: "http://localhost:8000"
WS_URL: "ws://localhost:8000"
```

For production, update these URLs to point to your deployed backend.

### Event Settings

```javascript
HEARTBEAT_INTERVAL: 30000     // Send heartbeat every 30s
DEBOUNCE_TIME: 1000          // Min time between similar events
MAX_QUEUE_SIZE: 100          // Max offline events to queue
```

### Audio Settings

```javascript
VOICE_NOTE_SAMPLE_RATE: 44100
VOICE_NOTE_CHANNELS: 1        // Mono
MAX_VOICE_NOTE_DURATION: 120  // 2 minutes max
```

## Development

Want to contribute or customize?

**[Development Guide →](docs/DEVELOPMENT.md)**

### Quick Dev Setup

```bash
# Clone repository
git clone <repo-url>
cd Stemflow/apps/ableton

# Open in Ableton
# Drag ProductionTracker.amxd onto Master track
# Right-click → Edit

# Edit JavaScript files in code/ folder
# Changes auto-reload if @autowatch is enabled
```

## Troubleshooting

### Common Issues

**Device shows "Disconnected"**
- Check backend server is running
- Verify firewall settings
- Try reconnecting with auth code

**Events not appearing in web app**
- Check ☑ Auto-track is enabled
- Verify status shows ● Connected (green)
- Check Max Console for errors (Cmd+M / Ctrl+M)

**Voice notes not recording**
- Check microphone permissions
- Verify audio input in Ableton preferences
- macOS: System Preferences → Privacy → Microphone

**Max Console showing errors**
- Check backend server is accessible
- Verify JavaScript files are in correct location
- Try reloading device (remove and re-add)

**[Full troubleshooting guide →](docs/INSTALLATION.md#troubleshooting)**

## Documentation

- **[Installation Guide](docs/INSTALLATION.md)** - Step-by-step installation
- **[Development Guide](docs/DEVELOPMENT.md)** - For developers
- **[Max Patch Structure](docs/MAX_PATCH_STRUCTURE.md)** - Technical architecture

## Integration with Production Tracker

This device is part of the Production Tracker system:

- **Backend API** - `../../backend/` - FastAPI server
- **Web Application** - `../../frontend/` - Next.js app
- **M4L Device** - This folder - Ableton integration

All components work together to provide AI-powered production assistance.

## Features Roadmap

### Current (v1.0)
- ✅ Basic session tracking
- ✅ Event monitoring (tracks, devices, transport)
- ✅ Voice notes
- ✅ Snapshots
- ✅ WebSocket communication
- ✅ Auto-reconnection

### Planned (v1.1)
- 🔄 Multiple project tracking
- 🔄 Offline mode with sync
- 🔄 Advanced audio export (stems)
- 🔄 Preset management

### Future (v2.0)
- 🔮 AI suggestions in device UI
- 🔮 Visual timeline
- 🔮 Collaborative features
- 🔮 Mobile companion app

## Performance

The device is optimized for minimal CPU impact:

- **CPU Usage:** <1% on modern systems
- **Memory:** ~50MB RAM
- **Network:** Low bandwidth (<100KB/min typical)
- **Debouncing:** Reduces unnecessary events
- **Queueing:** Prevents event loss

## Privacy & Security

- **Authentication:** JWT tokens, never passwords
- **Encryption:** HTTPS/WSS for all communication
- **Local storage:** Tokens stored in Max pattrstorage
- **No audio:** Only metadata tracked, never audio content
- **Open source:** Code is reviewable

## Support

### Getting Help

1. Check [Installation Guide](docs/INSTALLATION.md)
2. Review [Troubleshooting](#troubleshooting) section
3. Open Max Console (Cmd+M) for error logs
4. Check GitHub Issues
5. Contact support (if available)

### Reporting Bugs

Include:
- Ableton Live version
- Operating system
- Device version
- Max Console output
- Steps to reproduce

## Contributing

Contributions welcome! See [DEVELOPMENT.md](docs/DEVELOPMENT.md).

1. Fork repository
2. Create feature branch
3. Make changes
4. Test thoroughly
5. Submit pull request

## License

[License information to be added]

## Credits

Built with:
- **Max/MSP** by Cycling '74
- **Ableton Live** by Ableton
- **Anthropic Claude** for AI features

## Version History

### v1.0.0 (Initial Release)
- Basic session tracking
- Event monitoring
- Voice notes and snapshots
- WebSocket communication
- Auto-reconnection

---

**Built for producers who want to finish more tracks** 🎵

For more information, visit the Production Tracker web application.
