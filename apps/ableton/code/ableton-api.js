/**
 * Production Tracker - Ableton Live API Wrapper
 *
 * Safe wrappers for Live API calls with error handling
 */

// Load utilities
include("utils.js");
include("config.js");

// ============================================================================
// LIVE API WRAPPER CLASS
// ============================================================================

/**
 * Safe Live API call wrapper
 * @param {string} path - Live object path
 * @param {string} property - Property to get (optional)
 * @returns {*} API result or null on error
 */
function safeAPICall(path, property) {
  return tryCatch(function() {
    const api = new LiveAPI(path);

    if (!api || api.id === 0) {
      logWarn("Invalid Live API path", path);
      return null;
    }

    if (property) {
      const value = api.get(property);
      return value;
    }

    return api;
  }, null, `safeAPICall(${path}, ${property})`);
}

/**
 * Create Live API observer
 * @param {string} path - Live object path
 * @param {Function} callback - Callback function
 * @param {string} property - Property to observe (optional)
 * @returns {LiveAPI} API object or null
 */
function createObserver(path, callback, property) {
  return tryCatch(function() {
    const api = new LiveAPI(callback, path);

    if (!api || api.id === 0) {
      logWarn("Failed to create observer", path);
      return null;
    }

    if (property) {
      api.property = property;
    }

    logDebug("Created observer", { path: path, property: property });
    return api;
  }, null, `createObserver(${path})`);
}

// ============================================================================
// PROJECT/SONG INFORMATION
// ============================================================================

/**
 * Get complete project information
 * @returns {Object} Project info object
 */
function getProjectInfo() {
  return {
    path: getProjectPath(),
    name: getProjectName(),
    tempo: getTempo(),
    timeSignature: getTimeSignature(),
    trackCount: getTrackCount(),
    sceneCount: getSceneCount(),
    abletonVersion: getAbletonVersion(),
    isPlaying: isPlaying(),
    loopEnabled: isLoopEnabled()
  };
}

/**
 * Get project file path
 * @returns {string} Project path or empty string
 */
function getProjectPath() {
  const path = safeAPICall("live_set", "canonical_parent");
  return path || "";
}

/**
 * Get project name from path
 * @returns {string} Project name
 */
function getProjectName() {
  const path = getProjectPath();

  if (!path || path === "") {
    return "Untitled";
  }

  return extractFilename(path);
}

/**
 * Get current tempo (BPM)
 * @returns {number} Tempo
 */
function getTempo() {
  const tempo = safeAPICall("live_set", "tempo");
  return isValidNumber(tempo) ? tempo : 120;
}

/**
 * Get time signature
 * @returns {Object} Time signature { numerator, denominator, formatted }
 */
function getTimeSignature() {
  const numerator = safeAPICall("live_set", "signature_numerator") || 4;
  const denominator = safeAPICall("live_set", "signature_denominator") || 4;

  return {
    numerator: numerator,
    denominator: denominator,
    formatted: `${numerator}/${denominator}`
  };
}

/**
 * Get Ableton Live version
 * @returns {string} Version string
 */
function getAbletonVersion() {
  const major = safeAPICall("live_app", "get_major_version") || 11;
  const minor = safeAPICall("live_app", "get_minor_version") || 0;
  const bugfix = safeAPICall("live_app", "get_bugfix_version") || 0;

  return `${major}.${minor}.${bugfix}`;
}

// ============================================================================
// TRACK INFORMATION
// ============================================================================

/**
 * Get total track count
 * @returns {number} Track count
 */
function getTrackCount() {
  const api = new LiveAPI("live_set tracks");
  const count = api.getcount();
  return isValidNumber(count) ? count : 0;
}

/**
 * Get information about specific track
 * @param {number} index - Track index
 * @returns {Object} Track info or null
 */
function getTrackInfo(index) {
  return tryCatch(function() {
    const path = `live_set tracks ${index}`;

    return {
      index: index,
      name: safeAPICall(path, "name") || `Track ${index + 1}`,
      type: getTrackType(index),
      color: safeAPICall(path, "color") || 0,
      muted: safeAPICall(path, "mute") === 1,
      solo: safeAPICall(path, "solo") === 1,
      armed: safeAPICall(path, "arm") === 1,
      volume: safeAPICall(path, "mixer_device volume") || 0,
      pan: safeAPICall(path, "mixer_device panning") || 0,
      hasAudio: safeAPICall(path, "has_audio_input") === 1,
      hasMidi: safeAPICall(path, "has_midi_input") === 1
    };
  }, null, `getTrackInfo(${index})`);
}

/**
 * Get track type
 * @param {number} index - Track index
 * @returns {string} Track type (audio, midi, return, master)
 */
function getTrackType(index) {
  const path = `live_set tracks ${index}`;
  const hasAudio = safeAPICall(path, "has_audio_input") === 1;
  const hasMidi = safeAPICall(path, "has_midi_input") === 1;
  const isReturn = safeAPICall(path, "is_foldable") === 0;

  if (isReturn) return "return";
  if (hasMidi && !hasAudio) return "midi";
  if (hasAudio) return "audio";

  return "unknown";
}

/**
 * Get all tracks information
 * @returns {Array} Array of track info objects
 */
function getAllTracksInfo() {
  const count = getTrackCount();
  const tracks = [];

  for (let i = 0; i < count; i++) {
    const trackInfo = getTrackInfo(i);
    if (trackInfo) {
      tracks.push(trackInfo);
    }
  }

  return tracks;
}

// ============================================================================
// DEVICE INFORMATION
// ============================================================================

/**
 * Get device count for track
 * @param {number} trackIndex - Track index
 * @returns {number} Device count
 */
function getDeviceCount(trackIndex) {
  const api = new LiveAPI(`live_set tracks ${trackIndex} devices`);
  const count = api.getcount();
  return isValidNumber(count) ? count : 0;
}

/**
 * Get device information
 * @param {number} trackIndex - Track index
 * @param {number} deviceIndex - Device index
 * @returns {Object} Device info or null
 */
function getDeviceInfo(trackIndex, deviceIndex) {
  return tryCatch(function() {
    const path = `live_set tracks ${trackIndex} devices ${deviceIndex}`;

    return {
      trackIndex: trackIndex,
      deviceIndex: deviceIndex,
      name: safeAPICall(path, "name") || "Unknown Device",
      className: safeAPICall(path, "class_name") || "",
      type: getDeviceType(path),
      isActive: safeAPICall(path, "is_active") === 1,
      parameterCount: getDeviceParameterCount(path)
    };
  }, null, `getDeviceInfo(${trackIndex}, ${deviceIndex})`);
}

/**
 * Get device type
 * @param {string} devicePath - Device path
 * @returns {string} Device type
 */
function getDeviceType(devicePath) {
  const className = safeAPICall(devicePath, "class_name") || "";

  if (className.indexOf("AuPlugin") !== -1) return "au";
  if (className.indexOf("VstPlugin") !== -1 || className.indexOf("Vst3Plugin") !== -1) return "vst";
  if (className.indexOf("PluginDevice") !== -1) return "plugin";

  return "native";
}

/**
 * Get device parameter count
 * @param {string} devicePath - Device path
 * @returns {number} Parameter count
 */
function getDeviceParameterCount(devicePath) {
  const api = new LiveAPI(devicePath + " parameters");
  const count = api.getcount();
  return isValidNumber(count) ? count : 0;
}

/**
 * Get all devices for track
 * @param {number} trackIndex - Track index
 * @returns {Array} Array of device info objects
 */
function getTrackDevices(trackIndex) {
  const count = getDeviceCount(trackIndex);
  const devices = [];

  for (let i = 0; i < count; i++) {
    const deviceInfo = getDeviceInfo(trackIndex, i);
    if (deviceInfo) {
      devices.push(deviceInfo);
    }
  }

  return devices;
}

// ============================================================================
// SCENE INFORMATION
// ============================================================================

/**
 * Get scene count
 * @returns {number} Scene count
 */
function getSceneCount() {
  const api = new LiveAPI("live_set scenes");
  const count = api.getcount();
  return isValidNumber(count) ? count : 0;
}

/**
 * Get scene info
 * @param {number} index - Scene index
 * @returns {Object} Scene info
 */
function getSceneInfo(index) {
  return tryCatch(function() {
    const path = `live_set scenes ${index}`;

    return {
      index: index,
      name: safeAPICall(path, "name") || `Scene ${index + 1}`,
      color: safeAPICall(path, "color") || 0,
      tempo: safeAPICall(path, "tempo") || getTempo()
    };
  }, null, `getSceneInfo(${index})`);
}

// ============================================================================
// TRANSPORT INFORMATION
// ============================================================================

/**
 * Check if transport is playing
 * @returns {boolean} True if playing
 */
function isPlaying() {
  return safeAPICall("live_set", "is_playing") === 1;
}

/**
 * Check if loop is enabled
 * @returns {boolean} True if loop enabled
 */
function isLoopEnabled() {
  return safeAPICall("live_set", "loop") === 1;
}

/**
 * Get loop start position
 * @returns {number} Loop start in beats
 */
function getLoopStart() {
  const start = safeAPICall("live_set", "loop_start");
  return isValidNumber(start) ? start : 0;
}

/**
 * Get loop length
 * @returns {number} Loop length in beats
 */
function getLoopLength() {
  const length = safeAPICall("live_set", "loop_length");
  return isValidNumber(length) ? length : 4;
}

/**
 * Get current playback position
 * @returns {number} Position in beats
 */
function getCurrentPosition() {
  const pos = safeAPICall("live_set", "current_song_time");
  return isValidNumber(pos) ? pos : 0;
}

/**
 * Get arrangement overdub state
 * @returns {boolean} True if overdub enabled
 */
function isOverdubEnabled() {
  return safeAPICall("live_set", "overdub") === 1;
}

/**
 * Get complete transport info
 * @returns {Object} Transport info
 */
function getTransportInfo() {
  return {
    isPlaying: isPlaying(),
    position: getCurrentPosition(),
    loopEnabled: isLoopEnabled(),
    loopStart: getLoopStart(),
    loopLength: getLoopLength(),
    overdub: isOverdubEnabled()
  };
}

// ============================================================================
// VIEW INFORMATION
// ============================================================================

/**
 * Get current view (arrangement or session)
 * @returns {string} View name
 */
function getCurrentView() {
  const isArrangement = safeAPICall("live_app view", "focused_document_view") === "Arranger";
  return isArrangement ? "arrangement" : "session";
}

/**
 * Check if detail view is visible
 * @returns {boolean} True if visible
 */
function isDetailViewVisible() {
  return safeAPICall("live_app view", "is_view_visible Detail") === 1;
}

// ============================================================================
// UNDO/REDO TRACKING
// ============================================================================

/**
 * Check if can undo
 * @returns {boolean} True if can undo
 */
function canUndo() {
  return safeAPICall("live_set", "can_undo") === 1;
}

/**
 * Check if can redo
 * @returns {boolean} True if can redo
 */
function canRedo() {
  return safeAPICall("live_set", "can_redo") === 1;
}

// ============================================================================
// SESSION SUMMARY
// ============================================================================

/**
 * Get complete session summary
 * @returns {Object} Session summary
 */
function getSessionSummary() {
  return {
    project: getProjectInfo(),
    tracks: getAllTracksInfo(),
    transport: getTransportInfo(),
    view: {
      current: getCurrentView(),
      detailVisible: isDetailViewVisible()
    },
    stats: {
      trackCount: getTrackCount(),
      sceneCount: getSceneCount(),
      totalDevices: getTotalDeviceCount()
    }
  };
}

/**
 * Get total device count across all tracks
 * @returns {number} Total device count
 */
function getTotalDeviceCount() {
  let total = 0;
  const trackCount = getTrackCount();

  for (let i = 0; i < trackCount; i++) {
    total += getDeviceCount(i);
  }

  return total;
}

// ============================================================================
// CHANGE DETECTION HELPERS
// ============================================================================

/**
 * Detect what changed in track
 * @param {Object} oldTrack - Old track state
 * @param {Object} newTrack - New track state
 * @returns {Array} Array of changes
 */
function detectTrackChanges(oldTrack, newTrack) {
  const changes = [];

  if (!oldTrack || !newTrack) return changes;

  if (oldTrack.name !== newTrack.name) {
    changes.push({ type: "name", old: oldTrack.name, new: newTrack.name });
  }

  if (oldTrack.muted !== newTrack.muted) {
    changes.push({ type: "mute", old: oldTrack.muted, new: newTrack.muted });
  }

  if (oldTrack.armed !== newTrack.armed) {
    changes.push({ type: "arm", old: oldTrack.armed, new: newTrack.armed });
  }

  if (oldTrack.color !== newTrack.color) {
    changes.push({ type: "color", old: oldTrack.color, new: newTrack.color });
  }

  return changes;
}

// ============================================================================
// EXPORT FOR MAX/MSP
// ============================================================================

var AbletonAPI = {
  // API helpers
  safeAPICall: safeAPICall,
  createObserver: createObserver,

  // Project info
  getProjectInfo: getProjectInfo,
  getProjectPath: getProjectPath,
  getProjectName: getProjectName,
  getTempo: getTempo,
  getTimeSignature: getTimeSignature,
  getAbletonVersion: getAbletonVersion,

  // Track info
  getTrackCount: getTrackCount,
  getTrackInfo: getTrackInfo,
  getTrackType: getTrackType,
  getAllTracksInfo: getAllTracksInfo,

  // Device info
  getDeviceCount: getDeviceCount,
  getDeviceInfo: getDeviceInfo,
  getDeviceType: getDeviceType,
  getTrackDevices: getTrackDevices,
  getTotalDeviceCount: getTotalDeviceCount,

  // Scene info
  getSceneCount: getSceneCount,
  getSceneInfo: getSceneInfo,

  // Transport
  isPlaying: isPlaying,
  isLoopEnabled: isLoopEnabled,
  getLoopStart: getLoopStart,
  getLoopLength: getLoopLength,
  getCurrentPosition: getCurrentPosition,
  getTransportInfo: getTransportInfo,

  // View
  getCurrentView: getCurrentView,
  isDetailViewVisible: isDetailViewVisible,

  // Undo/Redo
  canUndo: canUndo,
  canRedo: canRedo,

  // Summary
  getSessionSummary: getSessionSummary,

  // Change detection
  detectTrackChanges: detectTrackChanges
};
