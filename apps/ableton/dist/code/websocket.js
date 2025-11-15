/**
 * Production Tracker - WebSocket Client
 *
 * Handles WebSocket communication with backend server
 * Includes reconnection logic, event queueing, and error handling
 */

// Load dependencies
include("utils.js");
include("config.js");

// Note: Max/MSP doesn't have native WebSocket support in JavaScript
// This is a specification/template for how WebSocket communication should work
// Actual implementation would need to use Max objects like [jweb] or [nodejs]
// or communicate with an external Node.js process

// ============================================================================
// WEBSOCKET STATE
// ============================================================================

var wsState = {
  connection: null,
  isConnected: false,
  reconnectAttempts: 0,
  reconnectTimer: null,
  lastPingTime: 0,
  currentSessionId: null
};

// Event queue for offline events
var eventQueue = [];

// Outlets for sending messages to Max patcher
var OUTLET_STATUS = 0;
var OUTLET_MESSAGE = 1;
var OUTLET_ERROR = 2;

// ============================================================================
// CONNECTION MANAGEMENT
// ============================================================================

/**
 * Initialize WebSocket connection
 * @param {string} token - JWT access token
 */
function initWebSocket(token) {
  if (!token || token === "") {
    logError("Cannot init WebSocket: no token provided");
    updateStatus(CONFIG.STATUS.ERROR);
    return false;
  }

  const wsUrl = `${CONFIG.WS_URL}/ws/session?token=${token}`;

  logInfo("Initiating WebSocket connection", wsUrl);
  updateStatus(CONFIG.STATUS.CONNECTING);

  // In actual implementation, this would create a WebSocket connection
  // For Max/MSP, we'd send a message to a Max object that handles WebSocket
  // Example: outlet(OUTLET_MESSAGE, "ws_connect", wsUrl);

  // Simulated connection (replace with actual WebSocket in Max)
  connectWebSocket(wsUrl);

  return true;
}

/**
 * Connect WebSocket (implementation-specific)
 * This is a template - actual implementation depends on Max WebSocket solution
 */
function connectWebSocket(url) {
  // In Max/MSP, this would typically be handled by:
  // - A [nodejs] object running a Node.js script
  // - A [jweb] object with JavaScript
  // - An external helper application
  // - Or communicating with a local Node.js server

  // For now, we'll define the interface that Max objects should implement:

  // Send connection request to Max
  outlet(OUTLET_MESSAGE, "ws_connect", url);

  // Max patcher should respond with:
  // - "ws_opened" on success
  // - "ws_error" on failure
  // - "ws_closed" when connection closes
  // - "ws_message" when message received
}

/**
 * Handle WebSocket opened event
 * Called from Max patcher when connection succeeds
 */
function onWebSocketOpened() {
  logInfo("WebSocket connected");

  wsState.isConnected = true;
  wsState.reconnectAttempts = 0;
  wsState.lastPingTime = now();

  updateStatus(CONFIG.STATUS.CONNECTED);

  // Clear reconnect timer
  if (wsState.reconnectTimer) {
    clearTimeout(wsState.reconnectTimer);
    wsState.reconnectTimer = null;
  }

  // Flush queued events
  flushEventQueue();

  // Notify tracker to start session
  outlet(OUTLET_MESSAGE, "session_ready");
}

/**
 * Handle WebSocket message received
 * Called from Max patcher when message arrives
 * @param {string} messageData - JSON string of message
 */
function onWebSocketMessage(messageData) {
  const message = safeJSONParse(messageData);

  if (!message) {
    logError("Failed to parse WebSocket message", messageData);
    return;
  }

  logDebug("WebSocket message received", message);

  // Handle different message types
  switch (message.type) {
    case "session_started":
      handleSessionStarted(message.data);
      break;

    case "ai_suggestion":
      handleAISuggestion(message.data);
      break;

    case "version_created":
      handleVersionCreated(message.data);
      break;

    case "session_update":
      handleSessionUpdate(message.data);
      break;

    case "error":
      handleServerError(message.data);
      break;

    case "pong":
      handlePong(message.data);
      break;

    default:
      logWarn("Unknown message type", message.type);
  }
}

/**
 * Handle WebSocket error
 * Called from Max patcher on error
 * @param {string} errorMessage - Error message
 */
function onWebSocketError(errorMessage) {
  logError("WebSocket error", errorMessage);
  updateStatus(CONFIG.STATUS.ERROR);

  // Notify tracker
  outlet(OUTLET_ERROR, "connection_error", errorMessage);
}

/**
 * Handle WebSocket closed
 * Called from Max patcher when connection closes
 */
function onWebSocketClosed() {
  logWarn("WebSocket connection closed");

  wsState.isConnected = false;
  updateStatus(CONFIG.STATUS.DISCONNECTED);

  // Notify tracker
  outlet(OUTLET_MESSAGE, "connection_closed");

  // Attempt reconnection
  scheduleReconnect();
}

// ============================================================================
// RECONNECTION LOGIC
// ============================================================================

/**
 * Schedule reconnection attempt
 */
function scheduleReconnect() {
  if (wsState.reconnectTimer) {
    return; // Already scheduled
  }

  const delays = CONFIG.RECONNECT_DELAYS;
  const attemptIndex = Math.min(wsState.reconnectAttempts, delays.length - 1);
  const delay = delays[attemptIndex];

  logInfo(`Scheduling reconnect in ${delay}ms (attempt ${wsState.reconnectAttempts + 1})`);

  wsState.reconnectTimer = setTimeout(function() {
    attemptReconnect();
  }, delay);
}

/**
 * Attempt to reconnect
 */
function attemptReconnect() {
  wsState.reconnectTimer = null;
  wsState.reconnectAttempts++;

  logInfo("Attempting reconnection", { attempt: wsState.reconnectAttempts });

  // Get stored token
  const token = getStoredToken();

  if (!token) {
    logError("Cannot reconnect: no token available");
    updateStatus(CONFIG.STATUS.ERROR);
    return;
  }

  // Try to connect
  initWebSocket(token);
}

/**
 * Cancel reconnection attempts
 */
function cancelReconnect() {
  if (wsState.reconnectTimer) {
    clearTimeout(wsState.reconnectTimer);
    wsState.reconnectTimer = null;
  }

  wsState.reconnectAttempts = 0;
}

// ============================================================================
// MESSAGE SENDING
// ============================================================================

/**
 * Send event to server
 * @param {Object} event - Event object
 * @returns {boolean} True if sent, false if queued
 */
function sendEvent(event) {
  if (!event || typeof event !== 'object') {
    logError("Invalid event object", event);
    return false;
  }

  // Ensure timestamp
  if (!event.timestamp) {
    event.timestamp = now();
  }

  // Add session ID if available
  if (wsState.currentSessionId && !event.data.sessionId) {
    event.data = event.data || {};
    event.data.sessionId = wsState.currentSessionId;
  }

  if (wsState.isConnected) {
    return sendEventNow(event);
  } else {
    return queueEvent(event);
  }
}

/**
 * Send event immediately
 * @param {Object} event - Event object
 * @returns {boolean} True if sent successfully
 */
function sendEventNow(event) {
  const json = safeJSONStringify(event);

  if (!json) {
    logError("Failed to stringify event", event);
    return false;
  }

  logDebug("Sending event", event);

  // Send to Max patcher for WebSocket transmission
  outlet(OUTLET_MESSAGE, "ws_send", json);

  return true;
}

/**
 * Queue event for later sending
 * @param {Object} event - Event object
 * @returns {boolean} True if queued
 */
function queueEvent(event) {
  // Check queue size limit
  if (eventQueue.length >= CONFIG.MAX_QUEUE_SIZE) {
    // Remove oldest event
    const removed = eventQueue.shift();
    logWarn("Event queue full, removed oldest event", removed.type);
  }

  eventQueue.push(event);
  logDebug("Event queued", { type: event.type, queueSize: eventQueue.length });

  // Update UI
  outlet(OUTLET_MESSAGE, "queue_size", eventQueue.length);

  return true;
}

/**
 * Flush all queued events
 */
function flushEventQueue() {
  if (eventQueue.length === 0) {
    return;
  }

  logInfo("Flushing event queue", { count: eventQueue.length });

  // Send events in batches
  const batches = chunk(eventQueue, CONFIG.MAX_BATCH_SIZE);

  batches.forEach(function(batch) {
    batch.forEach(function(event) {
      sendEventNow(event);
    });
  });

  // Clear queue
  eventQueue = [];

  // Update UI
  outlet(OUTLET_MESSAGE, "queue_size", 0);
}

/**
 * Clear event queue
 */
function clearEventQueue() {
  const count = eventQueue.length;
  eventQueue = [];

  logInfo("Event queue cleared", { count: count });

  outlet(OUTLET_MESSAGE, "queue_size", 0);
}

// ============================================================================
// HEARTBEAT / PING
// ============================================================================

/**
 * Send heartbeat/ping to server
 */
function sendHeartbeat() {
  if (!wsState.isConnected) {
    return;
  }

  const heartbeat = {
    type: "ping",
    timestamp: now(),
    data: {
      sessionId: wsState.currentSessionId
    }
  };

  sendEventNow(heartbeat);
  wsState.lastPingTime = now();

  logDebug("Heartbeat sent");
}

/**
 * Handle pong response
 * @param {Object} data - Pong data
 */
function handlePong(data) {
  const latency = now() - wsState.lastPingTime;
  logDebug("Pong received", { latency: latency });

  outlet(OUTLET_MESSAGE, "latency", latency);
}

// ============================================================================
// MESSAGE HANDLERS
// ============================================================================

/**
 * Handle session started confirmation
 * @param {Object} data - Session data
 */
function handleSessionStarted(data) {
  if (!data || !data.sessionId) {
    logError("Invalid session_started data", data);
    return;
  }

  wsState.currentSessionId = data.sessionId;

  logInfo("Session started", { sessionId: data.sessionId });

  // Notify tracker
  outlet(OUTLET_MESSAGE, "session_started", data.sessionId);

  // Store session ID
  storeSessionId(data.sessionId);
}

/**
 * Handle AI suggestion from server
 * @param {Object} data - Suggestion data
 */
function handleAISuggestion(data) {
  if (!data) {
    logError("Invalid AI suggestion data");
    return;
  }

  logInfo("AI suggestion received", {
    type: data.suggestionType,
    priority: data.priority
  });

  // Show notification in UI
  const message = truncate(data.content, 100);
  showNotification(message, data.priority);

  // Forward to tracker
  outlet(OUTLET_MESSAGE, "ai_suggestion", safeJSONStringify(data));

  // High priority alerts could open web app
  if (data.priority === "high") {
    outlet(OUTLET_MESSAGE, "alert", data.content);
  }
}

/**
 * Handle version created confirmation
 * @param {Object} data - Version data
 */
function handleVersionCreated(data) {
  if (!data || !data.version) {
    logError("Invalid version_created data");
    return;
  }

  logInfo("Version created", { versionId: data.version.id });

  showNotification(`Version ${data.version.name || 'snapshot'} created`);

  outlet(OUTLET_MESSAGE, "version_created", safeJSONStringify(data));
}

/**
 * Handle session update from server
 * @param {Object} data - Update data
 */
function handleSessionUpdate(data) {
  logDebug("Session update received", data);

  outlet(OUTLET_MESSAGE, "session_update", safeJSONStringify(data));
}

/**
 * Handle server error
 * @param {Object} data - Error data
 */
function handleServerError(data) {
  const message = data.message || "Unknown server error";
  const code = data.code || "UNKNOWN";

  logError("Server error", { code: code, message: message });

  showNotification(`Error: ${message}`, "error");

  outlet(OUTLET_ERROR, "server_error", code, message);
}

// ============================================================================
// TOKEN MANAGEMENT
// ============================================================================

/**
 * Get stored access token
 * @returns {string} Token or empty string
 */
function getStoredToken() {
  // Request token from Max patcher storage
  outlet(OUTLET_MESSAGE, "get_token");

  // Max patcher should respond via a separate inlet
  // For now, return empty (actual implementation in Max)
  return "";
}

/**
 * Store session ID
 * @param {string} sessionId - Session ID
 */
function storeSessionId(sessionId) {
  outlet(OUTLET_MESSAGE, "store_session_id", sessionId);
}

// ============================================================================
// UI HELPERS
// ============================================================================

/**
 * Update connection status
 * @param {string} status - Status (from CONFIG.STATUS)
 */
function updateStatus(status) {
  outlet(OUTLET_STATUS, status);
}

/**
 * Show notification in UI
 * @param {string} message - Notification message
 * @param {string} level - Level (info, warning, error) or priority (low, medium, high)
 */
function showNotification(message, level) {
  level = level || "info";

  outlet(OUTLET_MESSAGE, "notification", message, level);

  logInfo("Notification", { message: message, level: level });
}

// ============================================================================
// DISCONNECT / CLEANUP
// ============================================================================

/**
 * Disconnect WebSocket
 */
function disconnect() {
  logInfo("Disconnecting WebSocket");

  // Cancel reconnection
  cancelReconnect();

  // Close connection
  if (wsState.isConnected) {
    outlet(OUTLET_MESSAGE, "ws_disconnect");
  }

  // Reset state
  wsState.isConnected = false;
  wsState.currentSessionId = null;

  updateStatus(CONFIG.STATUS.DISCONNECTED);
}

/**
 * Cleanup on device unload
 */
function cleanup() {
  logInfo("WebSocket cleanup");

  disconnect();
  clearEventQueue();
}

// ============================================================================
// HTTP FALLBACK
// ============================================================================

/**
 * Send events via HTTP POST as fallback
 * @param {Array} events - Array of events to send
 */
function sendEventsHTTP(events) {
  if (!events || events.length === 0) {
    return;
  }

  logInfo("Sending events via HTTP fallback", { count: events.length });

  const token = getStoredToken();

  if (!token) {
    logError("Cannot send HTTP: no token");
    return;
  }

  const url = `${CONFIG.API_URL}/api/sessions/events`;
  const payload = safeJSONStringify({ events: events });

  // Send HTTP POST request via Max object
  outlet(OUTLET_MESSAGE, "http_post", url, token, payload);
}

// ============================================================================
// EXPORT FOR MAX/MSP
// ============================================================================

var WebSocketClient = {
  // Connection
  init: initWebSocket,
  disconnect: disconnect,
  cleanup: cleanup,

  // Event handlers (called from Max)
  onOpened: onWebSocketOpened,
  onMessage: onWebSocketMessage,
  onError: onWebSocketError,
  onClosed: onWebSocketClosed,

  // Sending
  sendEvent: sendEvent,
  sendHeartbeat: sendHeartbeat,

  // Queue management
  flushEventQueue: flushEventQueue,
  clearEventQueue: clearEventQueue,

  // State
  isConnected: function() { return wsState.isConnected; },
  getSessionId: function() { return wsState.currentSessionId; },
  getQueueSize: function() { return eventQueue.length; },

  // HTTP fallback
  sendEventsHTTP: sendEventsHTTP
};
