/**
 * Bridge Launcher for Max/MSP
 * Automatically starts the WebSocket bridge when device loads
 */

inlets = 1;
outlets = 2; // 0: status messages, 1: errors

var bridgeProcess = null;
var bridgePath = "";
var isRunning = false;
var checkInterval = null;

// Platform detection
var isMac = (max.os.indexOf("mac") >= 0);
var isWindows = (max.os.indexOf("win") >= 0);

/**
 * Initialize on load
 */
function loadbang() {
    post("Bridge Launcher initialized\n");

    // Find bridge location
    findBridge();

    // Check if bridge is already running
    checkBridgeStatus();

    // Start monitoring
    startMonitoring();
}

/**
 * Find WebSocket bridge location
 */
function findBridge() {
    var possiblePaths = [];

    if (isWindows) {
        possiblePaths = [
            "C:\\Program Files\\ProductionTracker\\websocket-bridge.js",
            "C:\\Program Files (x86)\\ProductionTracker\\websocket-bridge.js",
            max.filepath + "\\websocket-bridge.js",
            max.filepath + "\\..\\websocket-bridge.js"
        ];
    } else if (isMac) {
        possiblePaths = [
            "/Applications/ProductionTracker/websocket-bridge.js",
            "/usr/local/lib/ProductionTracker/websocket-bridge.js",
            max.filepath + "/websocket-bridge.js",
            max.filepath + "/../websocket-bridge.js"
        ];
    }

    // Check each path
    for (var i = 0; i < possiblePaths.length; i++) {
        var f = new File(possiblePaths[i], "read");
        if (f.isopen) {
            bridgePath = possiblePaths[i];
            f.close();
            post("Found bridge at: " + bridgePath + "\n");
            outlet(0, "bridge_found", bridgePath);
            return;
        }
        f.close();
    }

    post("Warning: Bridge not found in standard locations\n");
    outlet(1, "bridge_not_found");
}

/**
 * Start the WebSocket bridge
 */
function startBridge() {
    if (isRunning) {
        post("Bridge is already running\n");
        return;
    }

    if (!bridgePath || bridgePath === "") {
        findBridge();
        if (!bridgePath || bridgePath === "") {
            post("ERROR: Cannot start bridge - path not found\n");
            outlet(1, "start_failed", "bridge_not_found");
            return;
        }
    }

    post("Starting WebSocket bridge...\n");

    var cmd;

    if (isWindows) {
        // Windows: Start minimized in background
        cmd = "start /MIN \"Production Tracker Bridge\" node \"" + bridgePath + "\"";
    } else if (isMac) {
        // Mac: Start in background
        cmd = "node \"" + bridgePath + "\" > /dev/null 2>&1 &";
    }

    post("Running command: " + cmd + "\n");

    // Execute command via shell object (need to send to outlet for shell object to receive)
    outlet(0, "exec", cmd);

    isRunning = true;
    outlet(0, "bridge_started");
}

/**
 * Stop the WebSocket bridge
 */
function stopBridge() {
    if (!isRunning) {
        post("Bridge is not running\n");
        return;
    }

    post("Stopping WebSocket bridge...\n");

    var cmd;

    if (isWindows) {
        // Kill node process running websocket-bridge
        cmd = "taskkill /F /FI \"WINDOWTITLE eq Production Tracker Bridge*\"";
    } else if (isMac) {
        // Kill node process
        cmd = "pkill -f websocket-bridge.js";
    }

    outlet(0, "exec", cmd);

    isRunning = false;
    outlet(0, "bridge_stopped");
}

/**
 * Check if bridge is running
 */
function checkBridgeStatus() {
    var cmd;

    if (isWindows) {
        // Check if node process with our bridge is running
        cmd = "tasklist /FI \"IMAGENAME eq node.exe\" | findstr node.exe";
    } else if (isMac) {
        cmd = "ps aux | grep websocket-bridge | grep -v grep";
    }

    // Send command to check
    outlet(0, "check", cmd);
}

/**
 * Receive check result
 */
function checkResult(running) {
    if (running && !isRunning) {
        post("Bridge detected as running\n");
        isRunning = true;
        outlet(0, "bridge_running");
    } else if (!running && isRunning) {
        post("Bridge stopped unexpectedly\n");
        isRunning = false;
        outlet(0, "bridge_stopped");

        // Auto-restart
        task.schedule(5000, function() {
            startBridge();
        });
    }
}

/**
 * Start monitoring bridge status
 */
function startMonitoring() {
    // Check every 10 seconds
    if (checkInterval) {
        checkInterval.cancel();
    }

    checkInterval = new Task(function() {
        checkBridgeStatus();
    }, this);

    checkInterval.interval = 10000;
    checkInterval.repeat();
}

/**
 * Stop monitoring
 */
function stopMonitoring() {
    if (checkInterval) {
        checkInterval.cancel();
        checkInterval = null;
    }
}

/**
 * Handle messages from inlet
 */
function msg_int(v) {
    if (v === 1) {
        startBridge();
    } else {
        stopBridge();
    }
}

function start() {
    startBridge();
}

function stop() {
    stopBridge();
}

function check() {
    checkBridgeStatus();
}

/**
 * Cleanup on device close
 */
function notifydeleted() {
    stopMonitoring();
}
