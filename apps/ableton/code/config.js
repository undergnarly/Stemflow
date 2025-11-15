/**
 * Production Tracker - Max4Live Device Configuration
 *
 * Configuration settings for the M4L device
 */

// Main configuration object
const CONFIG = {
  // ============================================================================
  // SERVER ENDPOINTS
  // ============================================================================
  API_URL: "http://localhost:8000",
  WS_URL: "ws://localhost:8000",

  // For production, these should be configurable via UI
  // or environment detection

  // ============================================================================
  // TIMING CONFIGURATION
  // ============================================================================

  // How often to send heartbeat (milliseconds)
  HEARTBEAT_INTERVAL: 30000, // 30 seconds

  // Minimum time between similar events (debouncing)
  DEBOUNCE_TIME: 1000, // 1 second

  // Reconnection delays (exponential backoff)
  RECONNECT_DELAYS: [1000, 2000, 4000, 8000, 16000, 30000],

  // Session timeout (consider session ended after this inactivity)
  SESSION_TIMEOUT: 600000, // 10 minutes

  // ============================================================================
  // QUEUE AND LIMITS
  // ============================================================================

  // Maximum events to queue when disconnected
  MAX_QUEUE_SIZE: 100,

  // Maximum voice note duration (seconds)
  MAX_VOICE_NOTE_DURATION: 120, // 2 minutes

  // Maximum events per batch send
  MAX_BATCH_SIZE: 50,

  // ============================================================================
  // FEATURE FLAGS
  // ============================================================================

  // Auto-track session events by default
  AUTO_TRACK_DEFAULT: true,

  // Create version on every project save
  SEND_ON_SAVE_DEFAULT: false,

  // Enable debug logging
  DEBUG_MODE: false,

  // Enable voice notes feature
  ENABLE_VOICE_NOTES: true,

  // Enable snapshots feature
  ENABLE_SNAPSHOTS: true,

  // ============================================================================
  // AUDIO CONFIGURATION
  // ============================================================================

  // Voice note audio settings
  VOICE_NOTE_SAMPLE_RATE: 44100,
  VOICE_NOTE_CHANNELS: 1, // mono
  VOICE_NOTE_FORMAT: "wav",
  VOICE_NOTE_BIT_DEPTH: 16,

  // ============================================================================
  // UI CONFIGURATION
  // ============================================================================

  // Device dimensions (pixels)
  DEVICE_WIDTH: 256,
  DEVICE_HEIGHT: 128,

  // UI update intervals
  UI_UPDATE_INTERVAL: 1000, // Update timer every second

  // Notification duration
  NOTIFICATION_DURATION: 3000, // 3 seconds

  // ============================================================================
  // STORAGE KEYS
  // ============================================================================

  // Keys for pattrstorage (Max persistent storage)
  TOKEN_KEY: "pt_access_token",
  REFRESH_KEY: "pt_refresh_token",
  SESSION_KEY: "pt_session_id",
  USER_ID_KEY: "pt_user_id",
  DEVICE_ID_KEY: "pt_device_id",

  // Settings keys
  SETTINGS_PREFIX: "pt_settings_",

  // ============================================================================
  // EVENT TYPES
  // ============================================================================

  EVENT_TYPES: {
    // Session events
    SESSION_START: "session_start",
    SESSION_END: "session_end",
    SESSION_HEARTBEAT: "session_heartbeat",

    // Track events
    TRACK_ADD: "track_add",
    TRACK_REMOVE: "track_remove",
    TRACK_RENAME: "track_rename",
    TRACK_MUTE: "track_mute",
    TRACK_UNMUTE: "track_unmute",
    TRACK_ARM: "track_arm",
    TRACK_DISARM: "track_disarm",

    // Device events
    DEVICE_ADD: "device_add",
    DEVICE_REMOVE: "device_remove",
    DEVICE_ENABLE: "device_enable",
    DEVICE_DISABLE: "device_disable",

    // Transport events
    TRANSPORT_PLAY: "transport_play",
    TRANSPORT_STOP: "transport_stop",
    TRANSPORT_PAUSE: "transport_pause",

    // Project events
    PROJECT_SAVE: "project_save",
    PROJECT_RENAME: "project_rename",
    TEMPO_CHANGE: "tempo_change",

    // User action events
    VOICE_NOTE_START: "voice_note_start",
    VOICE_NOTE_END: "voice_note_end",
    SNAPSHOT_REQUEST: "snapshot_request",

    // System events
    ERROR: "error",
    DEBUG: "debug_log"
  },

  // ============================================================================
  // ERROR MESSAGES
  // ============================================================================

  ERROR_MESSAGES: {
    WEBSOCKET: "Connection lost. Reconnecting...",
    AUTH: "Authentication failed. Please reconnect.",
    API: "Failed to read project data.",
    VOICE: "Voice note recording failed.",
    SNAPSHOT: "Failed to create snapshot.",
    TOKEN_EXPIRED: "Session expired. Please reconnect.",
    NETWORK: "Network error. Check your connection.",
    UNKNOWN: "An unknown error occurred."
  },

  // ============================================================================
  // STATUS STATES
  // ============================================================================

  STATUS: {
    DISCONNECTED: "disconnected",
    CONNECTING: "connecting",
    CONNECTED: "connected",
    ERROR: "error",
    DISABLED: "disabled"
  },

  // ============================================================================
  // COLORS (for UI)
  // ============================================================================

  COLORS: {
    BACKGROUND: "#1a1a1a",
    TEXT: "#e0e0e0",
    ACCENT: "#00a8ff",
    SUCCESS: "#00ff88",
    WARNING: "#ffaa00",
    ERROR: "#ff4444",
    DISABLED: "#666666"
  }
};

// Export for use in other modules
// In Max/MSP JS, we use global scope
if (typeof module !== 'undefined' && module.exports) {
  module.exports = CONFIG;
}
