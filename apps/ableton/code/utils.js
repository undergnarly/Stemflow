/**
 * Production Tracker - Utility Functions
 *
 * Helper functions used across the M4L device
 */

// ============================================================================
// LOGGING UTILITIES
// ============================================================================

/**
 * Log message to Max console
 * @param {string} level - Log level (INFO, WARN, ERROR, DEBUG)
 * @param {string} message - Message to log
 * @param {*} data - Optional data to log
 */
function log(level, message, data) {
  const timestamp = new Date().toISOString();
  const prefix = `[ProductionTracker][${level}][${timestamp}]`;

  if (data !== undefined) {
    post(prefix, message, JSON.stringify(data));
  } else {
    post(prefix, message);
  }
}

function logInfo(message, data) {
  log("INFO", message, data);
}

function logWarn(message, data) {
  log("WARN", message, data);
}

function logError(message, data) {
  log("ERROR", message, data);
}

function logDebug(message, data) {
  if (CONFIG.DEBUG_MODE) {
    log("DEBUG", message, data);
  }
}

// ============================================================================
// TIME UTILITIES
// ============================================================================

/**
 * Get current timestamp in milliseconds
 */
function now() {
  return Date.now();
}

/**
 * Format milliseconds to HH:MM:SS
 * @param {number} ms - Milliseconds
 * @returns {string} Formatted time
 */
function formatDuration(ms) {
  const seconds = Math.floor(ms / 1000);
  const minutes = Math.floor(seconds / 60);
  const hours = Math.floor(minutes / 60);

  const s = String(seconds % 60).padStart(2, '0');
  const m = String(minutes % 60).padStart(2, '0');
  const h = String(hours).padStart(2, '0');

  return `${h}:${m}:${s}`;
}

/**
 * Format timestamp to readable string
 * @param {number} timestamp - Unix timestamp
 * @returns {string} Formatted date/time
 */
function formatTimestamp(timestamp) {
  const date = new Date(timestamp);
  return date.toLocaleString();
}

/**
 * Get seconds ago from timestamp
 * @param {number} timestamp - Unix timestamp
 * @returns {number} Seconds ago
 */
function secondsAgo(timestamp) {
  return Math.floor((Date.now() - timestamp) / 1000);
}

// ============================================================================
// DEBOUNCING UTILITIES
// ============================================================================

/**
 * Debounce tracker - stores last event times
 */
const debounceTracker = {};

/**
 * Check if event should be debounced
 * @param {string} eventType - Type of event
 * @param {number} debounceTime - Debounce time in ms (default from CONFIG)
 * @returns {boolean} True if should debounce (skip)
 */
function shouldDebounce(eventType, debounceTime) {
  const time = debounceTime || CONFIG.DEBOUNCE_TIME;
  const lastTime = debounceTracker[eventType] || 0;
  const currentTime = Date.now();

  if (currentTime - lastTime < time) {
    return true; // Skip this event
  }

  debounceTracker[eventType] = currentTime;
  return false;
}

/**
 * Reset debounce tracker for event type
 * @param {string} eventType - Event type to reset
 */
function resetDebounce(eventType) {
  delete debounceTracker[eventType];
}

/**
 * Clear all debounce trackers
 */
function clearAllDebounce() {
  for (const key in debounceTracker) {
    delete debounceTracker[key];
  }
}

// ============================================================================
// STRING UTILITIES
// ============================================================================

/**
 * Extract filename from path
 * @param {string} path - File path
 * @returns {string} Filename
 */
function extractFilename(path) {
  if (!path || typeof path !== 'string') return 'Untitled';

  const parts = path.split(/[/\\]/); // Handle both / and \
  const filename = parts[parts.length - 1];
  return filename.replace(/\.[^/.]+$/, ''); // Remove extension
}

/**
 * Truncate string to max length
 * @param {string} str - String to truncate
 * @param {number} maxLength - Maximum length
 * @returns {string} Truncated string
 */
function truncate(str, maxLength) {
  if (!str || str.length <= maxLength) return str;
  return str.substring(0, maxLength - 3) + '...';
}

/**
 * Generate unique ID
 * @returns {string} Unique ID
 */
function generateId() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    const r = Math.random() * 16 | 0;
    const v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

// ============================================================================
// OBJECT UTILITIES
// ============================================================================

/**
 * Deep clone object
 * @param {*} obj - Object to clone
 * @returns {*} Cloned object
 */
function deepClone(obj) {
  if (obj === null || typeof obj !== 'object') return obj;

  if (obj instanceof Date) {
    return new Date(obj.getTime());
  }

  if (obj instanceof Array) {
    return obj.map(item => deepClone(item));
  }

  if (obj instanceof Object) {
    const clonedObj = {};
    for (const key in obj) {
      if (obj.hasOwnProperty(key)) {
        clonedObj[key] = deepClone(obj[key]);
      }
    }
    return clonedObj;
  }
}

/**
 * Merge objects
 * @param {Object} target - Target object
 * @param {Object} source - Source object
 * @returns {Object} Merged object
 */
function merge(target, source) {
  const result = deepClone(target);

  for (const key in source) {
    if (source.hasOwnProperty(key)) {
      if (source[key] instanceof Object && !Array.isArray(source[key])) {
        result[key] = merge(result[key] || {}, source[key]);
      } else {
        result[key] = source[key];
      }
    }
  }

  return result;
}

/**
 * Check if object is empty
 * @param {Object} obj - Object to check
 * @returns {boolean} True if empty
 */
function isEmpty(obj) {
  if (!obj) return true;
  return Object.keys(obj).length === 0;
}

// ============================================================================
// ARRAY UTILITIES
// ============================================================================

/**
 * Get last N items from array
 * @param {Array} arr - Array
 * @param {number} n - Number of items
 * @returns {Array} Last N items
 */
function lastN(arr, n) {
  if (!arr || !Array.isArray(arr)) return [];
  return arr.slice(Math.max(arr.length - n, 0));
}

/**
 * Remove item from array
 * @param {Array} arr - Array
 * @param {*} item - Item to remove
 * @returns {Array} New array without item
 */
function removeItem(arr, item) {
  if (!arr || !Array.isArray(arr)) return [];
  return arr.filter(i => i !== item);
}

/**
 * Chunk array into smaller arrays
 * @param {Array} arr - Array to chunk
 * @param {number} size - Chunk size
 * @returns {Array} Array of chunks
 */
function chunk(arr, size) {
  if (!arr || !Array.isArray(arr)) return [];

  const chunks = [];
  for (let i = 0; i < arr.length; i += size) {
    chunks.push(arr.slice(i, i + size));
  }
  return chunks;
}

// ============================================================================
// VALIDATION UTILITIES
// ============================================================================

/**
 * Check if value is valid number
 * @param {*} value - Value to check
 * @returns {boolean} True if valid number
 */
function isValidNumber(value) {
  return typeof value === 'number' && !isNaN(value) && isFinite(value);
}

/**
 * Check if string is valid
 * @param {*} value - Value to check
 * @returns {boolean} True if valid string
 */
function isValidString(value) {
  return typeof value === 'string' && value.length > 0;
}

/**
 * Sanitize string for safe use
 * @param {string} str - String to sanitize
 * @returns {string} Sanitized string
 */
function sanitize(str) {
  if (!str || typeof str !== 'string') return '';

  // Remove control characters and trim
  return str.replace(/[\x00-\x1F\x7F-\x9F]/g, '').trim();
}

// ============================================================================
// ERROR HANDLING UTILITIES
// ============================================================================

/**
 * Safe JSON parse with fallback
 * @param {string} json - JSON string
 * @param {*} fallback - Fallback value
 * @returns {*} Parsed object or fallback
 */
function safeJSONParse(json, fallback) {
  try {
    return JSON.parse(json);
  } catch (e) {
    logError("JSON parse error", e);
    return fallback || null;
  }
}

/**
 * Safe JSON stringify
 * @param {*} obj - Object to stringify
 * @param {string} fallback - Fallback string
 * @returns {string} JSON string or fallback
 */
function safeJSONStringify(obj, fallback) {
  try {
    return JSON.stringify(obj);
  } catch (e) {
    logError("JSON stringify error", e);
    return fallback || '{}';
  }
}

/**
 * Try-catch wrapper for functions
 * @param {Function} fn - Function to execute
 * @param {*} fallback - Fallback value on error
 * @param {string} errorContext - Error context for logging
 * @returns {*} Function result or fallback
 */
function tryCatch(fn, fallback, errorContext) {
  try {
    return fn();
  } catch (e) {
    logError(`Error in ${errorContext || 'function'}`, e);
    return fallback;
  }
}

// ============================================================================
// RATE LIMITING UTILITIES
// ============================================================================

/**
 * Rate limiter tracker
 */
const rateLimitTracker = {};

/**
 * Check if action is rate limited
 * @param {string} key - Rate limit key
 * @param {number} maxCount - Max count in period
 * @param {number} period - Period in ms
 * @returns {boolean} True if limited (should skip)
 */
function isRateLimited(key, maxCount, period) {
  const now = Date.now();

  if (!rateLimitTracker[key]) {
    rateLimitTracker[key] = { count: 0, resetTime: now + period };
  }

  const tracker = rateLimitTracker[key];

  // Reset if period expired
  if (now >= tracker.resetTime) {
    tracker.count = 0;
    tracker.resetTime = now + period;
  }

  // Check limit
  if (tracker.count >= maxCount) {
    return true; // Rate limited
  }

  tracker.count++;
  return false;
}

/**
 * Clear rate limit for key
 * @param {string} key - Rate limit key
 */
function clearRateLimit(key) {
  delete rateLimitTracker[key];
}

// ============================================================================
// EXPORT FOR MAX/MSP
// ============================================================================

// In Max/MSP JavaScript, functions are globally available
// No export needed, but we can define a namespace for organization

var Utils = {
  // Logging
  log: log,
  logInfo: logInfo,
  logWarn: logWarn,
  logError: logError,
  logDebug: logDebug,

  // Time
  now: now,
  formatDuration: formatDuration,
  formatTimestamp: formatTimestamp,
  secondsAgo: secondsAgo,

  // Debouncing
  shouldDebounce: shouldDebounce,
  resetDebounce: resetDebounce,
  clearAllDebounce: clearAllDebounce,

  // Strings
  extractFilename: extractFilename,
  truncate: truncate,
  generateId: generateId,
  sanitize: sanitize,

  // Objects
  deepClone: deepClone,
  merge: merge,
  isEmpty: isEmpty,

  // Arrays
  lastN: lastN,
  removeItem: removeItem,
  chunk: chunk,

  // Validation
  isValidNumber: isValidNumber,
  isValidString: isValidString,

  // Error handling
  safeJSONParse: safeJSONParse,
  safeJSONStringify: safeJSONStringify,
  tryCatch: tryCatch,

  // Rate limiting
  isRateLimited: isRateLimited,
  clearRateLimit: clearRateLimit
};
