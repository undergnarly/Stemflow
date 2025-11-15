/**
 * Production Tracker - Main Tracker Logic
 *
 * Core functionality for tracking Ableton Live sessions
 * Integrates Live API, WebSocket communication, and event management
 */

// Load dependencies
include("config.js");
include("utils.js");
include("ableton-api.js");
include("websocket.js");

// ============================================================================
// GLOBAL STATE
// ============================================================================

var tracker = {
  // Session state
  sessionActive: false,
  sessionStartTime: 0,
  sessionDuration: 0,
  sessionId: null,

  // Settings
  autoTrack: CONFIG.AUTO_TRACK_DEFAULT,
  sendOnSave: CONFIG.SEND_ON_SAVE_DEFAULT,

  // Counters
  eventCount: 0,
  saveCount: 0,
  actionCount: 0,

  // Last known state (for change detection)
  lastState: {
    trackCount: 0,
    tempo: 0,
    isPlaying: false,
    projectPath: ""
  },

  // Timers
  heartbeatTimer: null,
  uiUpdateTimer: null,

  // Live API observers
  observers: {},

  // Recording state
  voiceNoteRecording: false,
  voiceNoteStartTime: 0
};

// ============================================================================
// INITIALIZATION
// ============================================================================

/**
 * Initialize the tracker
 * Called when device loads
 */
function init() {
  logInfo("Production Tracker initializing...");

  // Load stored settings
  loadSettings();

  // Setup Live API observers
  setupLiveAPI();

  // Start UI update timer
  startUIUpdate();

  // Load stored token and try to connect
  const token = loadToken();
  if (token) {
    connectToServer(token);
  } else {
    logInfo("No token found - awaiting user authentication");
    updateUIStatus(CONFIG.STATUS.DISCONNECTED);
  }

  logInfo("Production Tracker initialized");
}

/**
 * Setup Live API observers
 */
function setupLiveAPI() {
  logInfo("Setting up Live API observers");

  try {
    // Song-level observer
    tracker.observers.song = createObserver("live_set", onSongChange);

    // Tracks observer
    tracker.observers.tracks = createObserver("live_set tracks", onTracksChange);

    // Transport observer
    tracker.observers.transport = createObserver("live_set", onTransportChange, "is_playing");

    // Tempo observer
    tracker.observers.tempo = createObserver("live_set", onTempoChange, "tempo");

    // Project path observer (for save detection)
    tracker.observers.path = createObserver("live_set", onPathChange, "canonical_parent");

    logInfo("Live API observers created successfully");

  } catch (e) {
    logError("Failed to setup Live API observers", e);
  }
}

/**
 * Cleanup on device unload
 */
function cleanup() {
  logInfo("Production Tracker cleanup");

  // End session if active
  if (tracker.sessionActive) {
    endSession();
  }

  // Stop timers
  stopTimers();

  // Cleanup WebSocket
  WebSocketClient.cleanup();

  // Remove observers
  for (var key in tracker.observers) {
    if (tracker.observers[key]) {
      tracker.observers[key].property = "";
    }
  }
}

// ============================================================================
// SESSION MANAGEMENT
// ============================================================================

/**
 * Start tracking session
 */
function startSession() {
  if (tracker.sessionActive) {
    logWarn("Session already active");
    return;
  }

  logInfo("Starting session");

  tracker.sessionActive = true;
  tracker.sessionStartTime = now();
  tracker.eventCount = 0;
  tracker.saveCount = 0;
  tracker.actionCount = 0;

  // Get current project state
  const projectInfo = AbletonAPI.getProjectInfo();
  tracker.lastState.projectPath = projectInfo.path;
  tracker.lastState.trackCount = projectInfo.trackCount;
  tracker.lastState.tempo = projectInfo.tempo;

  // Send session_start event
  const sessionStartEvent = {
    type: CONFIG.EVENT_TYPES.SESSION_START,
    timestamp: tracker.sessionStartTime,
    data: {
      projectPath: projectInfo.path,
      projectName: projectInfo.name,
      bpm: projectInfo.tempo,
      timeSignature: projectInfo.timeSignature.formatted,
      totalTracks: projectInfo.trackCount,
      totalScenes: AbletonAPI.getSceneCount(),
      abletonVersion: projectInfo.abletonVersion,
      deviceId: getDeviceId()
    }
  };

  WebSocketClient.sendEvent(sessionStartEvent);

  // Start heartbeat
  startHeartbeat();

  // Update UI
  updateUIStatus("session_active");

  logInfo("Session started", { projectName: projectInfo.name });
}

/**
 * End tracking session
 */
function endSession() {
  if (!tracker.sessionActive) {
    return;
  }

  logInfo("Ending session");

  // Calculate final duration
  tracker.sessionDuration = now() - tracker.sessionStartTime;

  // Send session_end event
  const sessionEndEvent = {
    type: CONFIG.EVENT_TYPES.SESSION_END,
    timestamp: now(),
    data: {
      sessionId: tracker.sessionId,
      duration: Math.floor(tracker.sessionDuration / 1000), // seconds
      actionCount: tracker.actionCount,
      saveCount: tracker.saveCount,
      eventCount: tracker.eventCount,
      summary: getSessionSummary()
    }
  };

  WebSocketClient.sendEvent(sessionEndEvent);

  // Stop heartbeat
  stopHeartbeat();

  // Reset state
  tracker.sessionActive = false;
  tracker.sessionId = null;

  // Update UI
  updateUIStatus("session_ended");

  logInfo("Session ended", {
    duration: formatDuration(tracker.sessionDuration),
    events: tracker.eventCount
  });
}

/**
 * Get session summary
 * @returns {Object} Summary object
 */
function getSessionSummary() {
  const currentState = AbletonAPI.getProjectInfo();

  return {
    tracksAdded: Math.max(0, currentState.trackCount - tracker.lastState.trackCount),
    devicesAdded: AbletonAPI.getTotalDeviceCount(),
    tempoChanges: currentState.tempo !== tracker.lastState.tempo ? 1 : 0,
    playTime: 0 // TODO: Track actual play time
  };
}

// ============================================================================
// HEARTBEAT
// ============================================================================

/**
 * Start heartbeat timer
 */
function startHeartbeat() {
  if (tracker.heartbeatTimer) {
    stopHeartbeat();
  }

  tracker.heartbeatTimer = setInterval(function() {
    sendHeartbeat();
  }, CONFIG.HEARTBEAT_INTERVAL);

  logDebug("Heartbeat started");
}

/**
 * Stop heartbeat timer
 */
function stopHeartbeat() {
  if (tracker.heartbeatTimer) {
    clearInterval(tracker.heartbeatTimer);
    tracker.heartbeatTimer = null;
  }

  logDebug("Heartbeat stopped");
}

/**
 * Send heartbeat event
 */
function sendHeartbeat() {
  if (!tracker.sessionActive) {
    return;
  }

  const heartbeatEvent = {
    type: CONFIG.EVENT_TYPES.SESSION_HEARTBEAT,
    timestamp: now(),
    data: {
      sessionId: tracker.sessionId,
      duration: Math.floor((now() - tracker.sessionStartTime) / 1000),
      isPlaying: AbletonAPI.isPlaying(),
      currentView: AbletonAPI.getCurrentView(),
      lastAction: "" // TODO: Track last action type
    }
  };

  WebSocketClient.sendEvent(heartbeatEvent);

  logDebug("Heartbeat sent");
}

// ============================================================================
// EVENT HANDLERS - LIVE API CALLBACKS
// ============================================================================

/**
 * Handle song-level changes
 * @param {Array} args - Live API callback arguments
 */
function onSongChange(args) {
  if (!tracker.autoTrack || !tracker.sessionActive) {
    return;
  }

  logDebug("Song change detected", args);

  // General song change - check what changed
  checkForChanges();
}

/**
 * Handle track list changes
 * @param {Array} args - Live API callback arguments
 */
function onTracksChange(args) {
  if (!tracker.autoTrack || !tracker.sessionActive) {
    return;
  }

  if (shouldDebounce("tracks_change")) {
    return;
  }

  logDebug("Tracks change detected", args);

  const currentCount = AbletonAPI.getTrackCount();
  const previousCount = tracker.lastState.trackCount;

  if (currentCount > previousCount) {
    // Track added
    const newTrack = AbletonAPI.getTrackInfo(currentCount - 1);
    sendTrackEvent("add", newTrack);
  } else if (currentCount < previousCount) {
    // Track removed
    sendTrackEvent("remove", { index: previousCount - 1 });
  }

  tracker.lastState.trackCount = currentCount;
}

/**
 * Handle transport (play/stop) changes
 * @param {number} isPlaying - 1 if playing, 0 if stopped
 */
function onTransportChange(isPlaying) {
  if (!tracker.autoTrack || !tracker.sessionActive) {
    return;
  }

  const playing = isPlaying === 1;

  if (playing === tracker.lastState.isPlaying) {
    return; // No change
  }

  logDebug("Transport change", { isPlaying: playing });

  const transportEvent = {
    type: CONFIG.EVENT_TYPES.TRANSPORT_PLAY,
    timestamp: now(),
    data: {
      sessionId: tracker.sessionId,
      action: playing ? "play" : "stop",
      position: AbletonAPI.getCurrentPosition(),
      loopEnabled: AbletonAPI.isLoopEnabled()
    }
  };

  WebSocketClient.sendEvent(transportEvent);
  tracker.actionCount++;

  tracker.lastState.isPlaying = playing;
}

/**
 * Handle tempo changes
 * @param {number} tempo - New tempo value
 */
function onTempoChange(tempo) {
  if (!tracker.autoTrack || !tracker.sessionActive) {
    return;
  }

  if (shouldDebounce("tempo_change", 2000)) {
    return;
  }

  if (tempo === tracker.lastState.tempo) {
    return;
  }

  logDebug("Tempo change", { tempo: tempo });

  const tempoEvent = {
    type: CONFIG.EVENT_TYPES.TEMPO_CHANGE,
    timestamp: now(),
    data: {
      sessionId: tracker.sessionId,
      oldTempo: tracker.lastState.tempo,
      newTempo: tempo
    }
  };

  WebSocketClient.sendEvent(tempoEvent);
  tracker.actionCount++;

  tracker.lastState.tempo = tempo;
}

/**
 * Handle project path changes (save detection)
 * @param {string} path - Project path
 */
function onPathChange(path) {
  if (!tracker.sessionActive) {
    return;
  }

  // Path change usually means project was saved or "saved as"
  if (path !== tracker.lastState.projectPath) {
    onProjectSave(path);
    tracker.lastState.projectPath = path;
  }
}

/**
 * Handle project save
 * @param {string} path - Project path
 */
function onProjectSave(path) {
  logInfo("Project saved", { path: path });

  tracker.saveCount++;

  const saveEvent = {
    type: CONFIG.EVENT_TYPES.PROJECT_SAVE,
    timestamp: now(),
    data: {
      sessionId: tracker.sessionId,
      saveCount: tracker.saveCount,
      projectPath: path
    }
  };

  WebSocketClient.sendEvent(saveEvent);
  tracker.actionCount++;

  // If "send on save" is enabled, create snapshot
  if (tracker.sendOnSave) {
    createSnapshot("Auto-save snapshot");
  }

  // Update UI
  updateUISaveCount(tracker.saveCount);
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Check for any changes in project state
 */
function checkForChanges() {
  // This is called periodically to catch changes that don't have specific observers
  // For now, we rely on specific observers
}

/**
 * Send track-related event
 * @param {string} action - Action (add, remove, rename, etc.)
 * @param {Object} trackData - Track data
 */
function sendTrackEvent(action, trackData) {
  const event = {
    type: CONFIG.EVENT_TYPES.TRACK_ADD, // Will be changed based on action
    timestamp: now(),
    data: {
      sessionId: tracker.sessionId,
      action: action,
      trackName: trackData.name || "",
      trackType: trackData.type || "unknown",
      trackIndex: trackData.index || 0,
      metadata: {
        color: trackData.color,
        armed: trackData.armed
      }
    }
  };

  // Adjust event type based on action
  switch (action) {
    case "add":
      event.type = CONFIG.EVENT_TYPES.TRACK_ADD;
      break;
    case "remove":
      event.type = CONFIG.EVENT_TYPES.TRACK_REMOVE;
      break;
    case "rename":
      event.type = CONFIG.EVENT_TYPES.TRACK_RENAME;
      break;
    case "mute":
      event.type = CONFIG.EVENT_TYPES.TRACK_MUTE;
      break;
    case "unmute":
      event.type = CONFIG.EVENT_TYPES.TRACK_UNMUTE;
      break;
  }

  WebSocketClient.sendEvent(event);
  tracker.eventCount++;
  tracker.actionCount++;
}

// ============================================================================
// USER ACTIONS
// ============================================================================

/**
 * Start voice note recording
 */
function startVoiceNote() {
  if (!CONFIG.ENABLE_VOICE_NOTES) {
    logWarn("Voice notes disabled");
    return;
  }

  if (tracker.voiceNoteRecording) {
    logWarn("Already recording voice note");
    return;
  }

  logInfo("Starting voice note");

  tracker.voiceNoteRecording = true;
  tracker.voiceNoteStartTime = now();

  // Send start event
  const startEvent = {
    type: CONFIG.EVENT_TYPES.VOICE_NOTE_START,
    timestamp: tracker.voiceNoteStartTime,
    data: {
      sessionId: tracker.sessionId,
      position: AbletonAPI.getCurrentPosition(),
      isPlaying: AbletonAPI.isPlaying()
    }
  };

  WebSocketClient.sendEvent(startEvent);

  // Start audio recording (via Max object)
  outlet(0, "start_voice_recording");

  // Update UI
  updateUIRecording(true);
}

/**
 * End voice note recording
 */
function endVoiceNote() {
  if (!tracker.voiceNoteRecording) {
    return;
  }

  logInfo("Ending voice note");

  tracker.voiceNoteRecording = false;

  const duration = Math.floor((now() - tracker.voiceNoteStartTime) / 1000);

  // Stop audio recording (via Max object)
  outlet(0, "stop_voice_recording");

  // Voice note will be sent when audio file is ready
  // Max patcher should call sendVoiceNoteWithAudio() when file is ready

  // Update UI
  updateUIRecording(false);
}

/**
 * Send voice note with audio file
 * Called from Max patcher when audio file is ready
 * @param {string} audioFilePath - Path to recorded audio file
 */
function sendVoiceNoteWithAudio(audioFilePath) {
  if (!audioFilePath) {
    logError("No audio file path provided for voice note");
    return;
  }

  const duration = Math.floor((now() - tracker.voiceNoteStartTime) / 1000);

  const endEvent = {
    type: CONFIG.EVENT_TYPES.VOICE_NOTE_END,
    timestamp: now(),
    data: {
      sessionId: tracker.sessionId,
      audioFile: audioFilePath, // Will be uploaded by backend
      duration: duration,
      position: AbletonAPI.getCurrentPosition()
    }
  };

  WebSocketClient.sendEvent(endEvent);
  tracker.actionCount++;

  logInfo("Voice note sent", { duration: duration });
  showNotification("Voice note recorded (" + duration + "s)");
}

/**
 * Create snapshot of current project state
 * @param {string} name - Snapshot name (optional)
 */
function createSnapshot(name) {
  if (!CONFIG.ENABLE_SNAPSHOTS) {
    logWarn("Snapshots disabled");
    return;
  }

  logInfo("Creating snapshot", { name: name });

  const snapshotName = name || "Snapshot " + new Date().toLocaleTimeString();
  const currentState = AbletonAPI.getProjectInfo();

  const snapshotEvent = {
    type: CONFIG.EVENT_TYPES.SNAPSHOT_REQUEST,
    timestamp: now(),
    data: {
      sessionId: tracker.sessionId,
      name: snapshotName,
      currentState: {
        trackCount: currentState.trackCount,
        deviceCount: AbletonAPI.getTotalDeviceCount(),
        projectDuration: 0, // TODO: Calculate project duration
        tempo: currentState.tempo
      }
    }
  };

  WebSocketClient.sendEvent(snapshotEvent);
  tracker.actionCount++;

  showNotification("Snapshot created: " + snapshotName);
}

// ============================================================================
// SERVER CONNECTION
// ============================================================================

/**
 * Connect to server with token
 * @param {string} token - JWT access token
 */
function connectToServer(token) {
  if (!token || token === "") {
    logError("Cannot connect: invalid token");
    return;
  }

  logInfo("Connecting to server");

  // Initialize WebSocket
  WebSocketClient.init(token);
}

/**
 * Handle successful connection
 * Called from WebSocket module
 */
function onServerConnected() {
  logInfo("Connected to server");

  // Start session automatically
  if (!tracker.sessionActive) {
    startSession();
  }
}

/**
 * Handle connection lost
 * Called from WebSocket module
 */
function onServerDisconnected() {
  logWarn("Disconnected from server");

  // Session continues, events are queued
  // Don't end session on temporary disconnect
}

/**
 * Handle session started confirmation from server
 * @param {string} sessionId - Session ID from server
 */
function onSessionStarted(sessionId) {
  tracker.sessionId = sessionId;

  logInfo("Session confirmed", { sessionId: sessionId });

  // Update UI
  updateUISessionId(sessionId);
}

// ============================================================================
// SETTINGS
// ============================================================================

/**
 * Load settings from persistent storage
 */
function loadSettings() {
  // Request settings from Max patcher
  // Settings are stored in pattrstorage
  outlet(0, "load_settings");

  // Max patcher should respond by calling setAutoTrack(), setSendOnSave(), etc.
}

/**
 * Save settings to persistent storage
 */
function saveSettings() {
  outlet(0, "save_settings", tracker.autoTrack, tracker.sendOnSave);
}

/**
 * Set auto-track setting
 * @param {number} enabled - 1 or 0
 */
function setAutoTrack(enabled) {
  tracker.autoTrack = enabled === 1;
  logInfo("Auto-track set to", tracker.autoTrack);
  saveSettings();
}

/**
 * Set send-on-save setting
 * @param {number} enabled - 1 or 0
 */
function setSendOnSave(enabled) {
  tracker.sendOnSave = enabled === 1;
  logInfo("Send-on-save set to", tracker.sendOnSave);
  saveSettings();
}

// ============================================================================
// TOKEN MANAGEMENT
// ============================================================================

/**
 * Load token from persistent storage
 * @returns {string} Token or empty string
 */
function loadToken() {
  // Request from Max patcher storage
  outlet(0, "load_token");

  // Max should respond by calling setToken()
  // For now, return empty
  return "";
}

/**
 * Save token to persistent storage
 * @param {string} token - Access token
 */
function saveToken(token) {
  outlet(0, "save_token", token);
}

/**
 * Set token (called from Max patcher)
 * @param {string} token - Access token
 */
function setToken(token) {
  saveToken(token);
  connectToServer(token);
}

// ============================================================================
// UI UPDATES
// ============================================================================

/**
 * Start UI update timer
 */
function startUIUpdate() {
  if (tracker.uiUpdateTimer) {
    return;
  }

  tracker.uiUpdateTimer = setInterval(function() {
    updateUI();
  }, CONFIG.UI_UPDATE_INTERVAL);
}

/**
 * Stop UI update timer
 */
function stopUIUpdate() {
  if (tracker.uiUpdateTimer) {
    clearInterval(tracker.uiUpdateTimer);
    tracker.uiUpdateTimer = null;
  }
}

/**
 * Update UI with current state
 */
function updateUI() {
  if (tracker.sessionActive) {
    const duration = now() - tracker.sessionStartTime;
    updateUITimer(duration);
  }

  updateUIEventCount(tracker.eventCount);
}

/**
 * Update UI status
 * @param {string} status - Status string
 */
function updateUIStatus(status) {
  outlet(0, "ui_status", status);
}

/**
 * Update UI timer
 * @param {number} duration - Duration in milliseconds
 */
function updateUITimer(duration) {
  outlet(0, "ui_timer", formatDuration(duration));
}

/**
 * Update UI event count
 * @param {number} count - Event count
 */
function updateUIEventCount(count) {
  outlet(0, "ui_events", count);
}

/**
 * Update UI save count
 * @param {number} count - Save count
 */
function updateUISaveCount(count) {
  outlet(0, "ui_saves", count);
}

/**
 * Update UI session ID
 * @param {string} sessionId - Session ID
 */
function updateUISessionId(sessionId) {
  outlet(0, "ui_session_id", truncate(sessionId, 8));
}

/**
 * Update UI recording state
 * @param {boolean} recording - True if recording
 */
function updateUIRecording(recording) {
  outlet(0, "ui_recording", recording ? 1 : 0);
}

/**
 * Show notification in UI
 * @param {string} message - Notification message
 */
function showNotification(message) {
  outlet(0, "notification", message);
  logInfo("Notification: " + message);
}

// ============================================================================
// UTILITY
// ============================================================================

/**
 * Get or create device ID
 * @returns {string} Device ID
 */
function getDeviceId() {
  // Request from storage or generate new
  // For now, generate
  return generateId();
}

/**
 * Stop all timers
 */
function stopTimers() {
  stopHeartbeat();
  stopUIUpdate();
}

// ============================================================================
// MAX/MSP INTERFACE
// ============================================================================

// Functions callable from Max patcher via messages

function bang() {
  // Bang message - could toggle session or send status
  if (tracker.sessionActive) {
    post("Session active:", formatDuration(now() - tracker.sessionStartTime));
  } else {
    post("No active session");
  }
}

// ============================================================================
// EXPORTS
// ============================================================================

// Main entry point - called automatically by Max
init();
