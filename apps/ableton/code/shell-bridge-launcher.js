/**
 * Simple Shell-based Bridge Launcher
 * Automatically starts WebSocket bridge when Max device loads
 * This version uses Max shell object to execute commands
 */

autowatch = 1;

inlets = 1;
outlets = 2; // 0: messages, 1: errors

var bridgeStarted = false;
var bridgeCheckTask = null;
var startAttempts = 0;
var maxStartAttempts = 3;

// Detect platform
var isWindows = (max.os.indexOf("windows") >= 0 || max.os.indexOf("win") >= 0);
var isMac = (max.os.indexOf("mac") >= 0);

/**
 * Load on device startup
 */
function loadbang() {
    post("Shell Bridge Launcher loaded\n");
    post("Platform: " + max.os + "\n");
    post("Max version: " + max.version + "\n");

    // Wait a bit before starting
    var t = new Task(tryStartBridge, this);
    t.schedule(2000);
}

/**
 * Try to start the bridge
 */
function tryStartBridge() {
    if (bridgeStarted) {
        post("Bridge already started\n");
        return;
    }

    if (startAttempts >= maxStartAttempts) {
        post("Max start attempts reached - bridge may need manual start\n");
        outlet(1, "max_attempts_reached");
        return;
    }

    startAttempts++;
    post("Attempting to start bridge (attempt " + startAttempts + "/" + maxStartAttempts + ")\n");

    var command = getBridgeStartCommand();

    if (!command) {
        post("ERROR: Could not determine start command for platform\n");
        outlet(1, "platform_unsupported");
        return;
    }

    post("Executing: " + command + "\n");

    // Send command to outlet (should be connected to shell object in Max patch)
    outlet(0, "exec", command);

    bridgeStarted = true;
    outlet(0, "bridge_started");

    // Start health check
    startHealthCheck();
}

/**
 * Get platform-specific bridge start command
 */
function getBridgeStartCommand() {
    var bridgeScript = "websocket-bridge.js";

    if (isWindows) {
        // Windows: Check Program Files first, then local
        var programFilesPath = "C:\\Program Files\\ProductionTracker\\websocket-bridge.js";
        var localPath = "websocket-bridge.js";

        // Try to start from Program Files (if installed via installer)
        // Using cmd /c start to run in background without blocking Max
        return "cmd /c start /MIN \"ProductionTracker Bridge\" node \"" + programFilesPath + "\" || start /MIN \"ProductionTracker Bridge\" node \"" + localPath + "\"";

    } else if (isMac) {
        // Mac: Try /usr/local first, then local
        var installPath = "/usr/local/lib/ProductionTracker/websocket-bridge.js";
        var localPath = "./websocket-bridge.js";

        return "node " + installPath + " > /dev/null 2>&1 & || node " + localPath + " > /dev/null 2>&1 &";

    } else {
        return null;
    }
}

/**
 * Check if bridge is still running (health check)
 */
function startHealthCheck() {
    if (bridgeCheckTask) {
        bridgeCheckTask.cancel();
    }

    bridgeCheckTask = new Task(checkBridgeHealth, this);
    bridgeCheckTask.interval = 30000; // Check every 30 seconds
    bridgeCheckTask.repeat();
}

/**
 * Check bridge health
 */
function checkBridgeHealth() {
    post("Checking bridge health...\n");

    var checkCommand;

    if (isWindows) {
        // Check if node.exe is running
        checkCommand = "tasklist | findstr /I \"node.exe\"";
    } else if (isMac) {
        checkCommand = "pgrep -f websocket-bridge";
    }

    if (checkCommand) {
        outlet(0, "check", checkCommand);
    }
}

/**
 * Receive health check result
 * Call this from Max patch when check result is received
 */
function healthCheckResult(isHealthy) {
    if (!isHealthy && bridgeStarted) {
        post("Bridge appears to have stopped - will retry starting\n");
        bridgeStarted = false;
        startAttempts = 0; // Reset attempts
        tryStartBridge();
    }
}

/**
 * Manual start command
 */
function start() {
    post("Manual start requested\n");
    bridgeStarted = false;
    startAttempts = 0;
    tryStartBridge();
}

/**
 * Stop bridge
 */
function stop() {
    post("Stopping bridge...\n");

    var stopCommand;

    if (isWindows) {
        stopCommand = "taskkill /F /IM node.exe /FI \"WINDOWTITLE eq ProductionTracker Bridge*\"";
    } else if (isMac) {
        stopCommand = "pkill -f websocket-bridge.js";
    }

    if (stopCommand) {
        outlet(0, "exec", stopCommand);
    }

    bridgeStarted = false;

    if (bridgeCheckTask) {
        bridgeCheckTask.cancel();
        bridgeCheckTask = null;
    }

    outlet(0, "bridge_stopped");
}

/**
 * Get bridge status
 */
function status() {
    if (bridgeStarted) {
        post("Bridge status: Running\n");
        outlet(0, "status", "running");
    } else {
        post("Bridge status: Stopped\n");
        outlet(0, "status", "stopped");
    }
}

/**
 * Cleanup on device removal
 */
function notifydeleted() {
    if (bridgeCheckTask) {
        bridgeCheckTask.cancel();
    }
    // Optionally stop bridge when device is removed
    // stop();
}

/**
 * Message from inlet
 */
function msg_int(v) {
    if (v > 0) {
        start();
    } else {
        stop();
    }
}

function anything() {
    var args = arrayfromargs(arguments);
    var command = args[0];

    switch(command) {
        case "start":
            start();
            break;
        case "stop":
            stop();
            break;
        case "status":
            status();
            break;
        case "health":
            healthCheckResult(args[1] > 0);
            break;
        default:
            post("Unknown command: " + command + "\n");
    }
}
