#!/usr/bin/env node

/**
 * WebSocket Bridge for Production Tracker M4L Device
 *
 * This bridge connects the Max/MSP patch to the Production Tracker backend
 * using WebSocket. It receives messages via UDP from Max and forwards them
 * to the WebSocket server, and vice versa.
 *
 * Communication flow:
 * Max patch <-> UDP (localhost:7400/7401) <-> This Bridge <-> WebSocket (Backend)
 */

const dgram = require('dgram');
const WebSocket = require('ws');

// Configuration
const CONFIG = {
  // UDP ports for Max communication
  UDP_RECEIVE_PORT: 7400,  // Receive from Max
  UDP_SEND_PORT: 7401,     // Send to Max
  UDP_HOST: 'localhost',

  // WebSocket configuration
  WS_URL: process.env.WS_URL || 'wss://muvs.dev/ws',

  // Reconnection settings
  RECONNECT_INTERVAL: 5000,
  MAX_RECONNECT_ATTEMPTS: 10,

  // Heartbeat
  HEARTBEAT_INTERVAL: 30000,

  // Debug mode
  DEBUG: process.env.DEBUG === 'true'
};

class WebSocketBridge {
  constructor() {
    // UDP socket for Max communication
    this.udpSocket = dgram.createSocket('udp4');

    // WebSocket connection
    this.ws = null;
    this.reconnectAttempts = 0;
    this.reconnectTimer = null;
    this.heartbeatTimer = null;

    // Connection state
    this.isConnected = false;
    this.authToken = null;

    // Message queue for offline mode
    this.messageQueue = [];
    this.maxQueueSize = 100;

    this.setupUDP();
  }

  log(...args) {
    if (CONFIG.DEBUG) {
      console.log('[Bridge]', new Date().toISOString(), ...args);
    }
  }

  error(...args) {
    console.error('[Bridge ERROR]', new Date().toISOString(), ...args);
  }

  /**
   * Setup UDP server to receive messages from Max
   */
  setupUDP() {
    this.udpSocket.on('listening', () => {
      const address = this.udpSocket.address();
      console.log(`UDP bridge listening on ${address.address}:${address.port}`);
      this.log('Ready to receive messages from Max');
    });

    this.udpSocket.on('message', (msg, rinfo) => {
      try {
        const message = msg.toString('utf8');
        this.log('Received from Max:', message);
        this.handleMaxMessage(message);
      } catch (err) {
        this.error('Error handling Max message:', err);
      }
    });

    this.udpSocket.on('error', (err) => {
      this.error('UDP socket error:', err);
    });

    this.udpSocket.bind(CONFIG.UDP_RECEIVE_PORT);
  }

  /**
   * Handle messages from Max
   */
  handleMaxMessage(message) {
    try {
      const parsed = JSON.parse(message);

      // Handle bridge commands
      if (parsed.type === 'bridge_command') {
        this.handleBridgeCommand(parsed);
        return;
      }

      // Forward to WebSocket if connected
      if (this.isConnected && this.ws && this.ws.readyState === WebSocket.OPEN) {
        this.ws.send(message);
        this.log('Forwarded to WebSocket:', message);
      } else {
        // Queue message if offline
        this.queueMessage(parsed);
        this.log('Queued message (offline):', parsed.type);
      }
    } catch (err) {
      this.error('Error parsing Max message:', err);
    }
  }

  /**
   * Handle bridge-specific commands
   */
  handleBridgeCommand(data) {
    switch (data.command) {
      case 'connect':
        this.authToken = data.token;
        this.connectWebSocket();
        break;

      case 'disconnect':
        this.disconnectWebSocket();
        break;

      case 'set_url':
        CONFIG.WS_URL = data.url;
        this.log('WebSocket URL updated to:', data.url);
        break;

      default:
        this.log('Unknown bridge command:', data.command);
    }
  }

  /**
   * Connect to WebSocket server
   */
  connectWebSocket() {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.log('Already connected to WebSocket');
      return;
    }

    this.log('Connecting to WebSocket:', CONFIG.WS_URL);

    try {
      const headers = {};
      if (this.authToken) {
        headers['Authorization'] = `Bearer ${this.authToken}`;
      }

      this.ws = new WebSocket(CONFIG.WS_URL, { headers });

      this.ws.on('open', () => {
        this.onWebSocketOpen();
      });

      this.ws.on('message', (data) => {
        this.onWebSocketMessage(data);
      });

      this.ws.on('error', (error) => {
        this.onWebSocketError(error);
      });

      this.ws.on('close', (code, reason) => {
        this.onWebSocketClose(code, reason);
      });

    } catch (err) {
      this.error('Error creating WebSocket connection:', err);
      this.scheduleReconnect();
    }
  }

  /**
   * Disconnect from WebSocket
   */
  disconnectWebSocket() {
    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = null;
    }

    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }

    if (this.ws) {
      this.ws.close();
      this.ws = null;
    }

    this.isConnected = false;
    this.reconnectAttempts = 0;
    this.log('Disconnected from WebSocket');
  }

  /**
   * WebSocket opened
   */
  onWebSocketOpen() {
    console.log('WebSocket connection established');
    this.isConnected = true;
    this.reconnectAttempts = 0;

    // Send connection status to Max
    this.sendToMax({
      type: 'ws_status',
      status: 'connected'
    });

    // Start heartbeat
    this.startHeartbeat();

    // Send queued messages
    this.flushMessageQueue();
  }

  /**
   * WebSocket message received
   */
  onWebSocketMessage(data) {
    try {
      const message = data.toString('utf8');
      this.log('Received from WebSocket:', message);

      // Forward to Max
      this.sendToMax(JSON.parse(message));
    } catch (err) {
      this.error('Error handling WebSocket message:', err);
    }
  }

  /**
   * WebSocket error
   */
  onWebSocketError(error) {
    this.error('WebSocket error:', error.message);

    this.sendToMax({
      type: 'ws_error',
      error: error.message
    });
  }

  /**
   * WebSocket closed
   */
  onWebSocketClose(code, reason) {
    console.log(`WebSocket closed: ${code} - ${reason || 'No reason'}`);
    this.isConnected = false;

    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = null;
    }

    this.sendToMax({
      type: 'ws_status',
      status: 'disconnected',
      code,
      reason: reason?.toString() || ''
    });

    // Auto-reconnect
    this.scheduleReconnect();
  }

  /**
   * Schedule WebSocket reconnection
   */
  scheduleReconnect() {
    if (this.reconnectAttempts >= CONFIG.MAX_RECONNECT_ATTEMPTS) {
      this.error('Max reconnection attempts reached');
      this.sendToMax({
        type: 'ws_error',
        error: 'Max reconnection attempts reached'
      });
      return;
    }

    this.reconnectAttempts++;
    const delay = CONFIG.RECONNECT_INTERVAL * this.reconnectAttempts;

    console.log(`Reconnecting in ${delay}ms (attempt ${this.reconnectAttempts}/${CONFIG.MAX_RECONNECT_ATTEMPTS})`);

    this.sendToMax({
      type: 'ws_status',
      status: 'reconnecting',
      attempt: this.reconnectAttempts,
      delay
    });

    this.reconnectTimer = setTimeout(() => {
      this.connectWebSocket();
    }, delay);
  }

  /**
   * Start heartbeat timer
   */
  startHeartbeat() {
    this.heartbeatTimer = setInterval(() => {
      if (this.isConnected && this.ws && this.ws.readyState === WebSocket.OPEN) {
        this.ws.send(JSON.stringify({ type: 'ping' }));
        this.log('Sent heartbeat');
      }
    }, CONFIG.HEARTBEAT_INTERVAL);
  }

  /**
   * Send message to Max via UDP
   */
  sendToMax(data) {
    try {
      const message = JSON.stringify(data);
      const buffer = Buffer.from(message, 'utf8');

      this.udpSocket.send(buffer, 0, buffer.length, CONFIG.UDP_SEND_PORT, CONFIG.UDP_HOST, (err) => {
        if (err) {
          this.error('Error sending to Max:', err);
        } else {
          this.log('Sent to Max:', message);
        }
      });
    } catch (err) {
      this.error('Error creating message for Max:', err);
    }
  }

  /**
   * Queue message when offline
   */
  queueMessage(message) {
    if (this.messageQueue.length >= this.maxQueueSize) {
      this.messageQueue.shift(); // Remove oldest
      this.log('Message queue full, removed oldest message');
    }

    this.messageQueue.push(message);
  }

  /**
   * Send all queued messages
   */
  flushMessageQueue() {
    if (this.messageQueue.length === 0) {
      return;
    }

    console.log(`Sending ${this.messageQueue.length} queued messages`);

    while (this.messageQueue.length > 0) {
      const message = this.messageQueue.shift();

      if (this.ws && this.ws.readyState === WebSocket.OPEN) {
        this.ws.send(JSON.stringify(message));
      }
    }
  }

  /**
   * Shutdown bridge
   */
  shutdown() {
    console.log('Shutting down WebSocket bridge...');

    this.disconnectWebSocket();

    if (this.udpSocket) {
      this.udpSocket.close();
    }

    console.log('Bridge shutdown complete');
    process.exit(0);
  }
}

// Create and start bridge
const bridge = new WebSocketBridge();

// Handle shutdown signals
process.on('SIGINT', () => bridge.shutdown());
process.on('SIGTERM', () => bridge.shutdown());

// Handle uncaught errors
process.on('uncaughtException', (err) => {
  console.error('Uncaught exception:', err);
  bridge.shutdown();
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled rejection at:', promise, 'reason:', reason);
});

console.log('Production Tracker WebSocket Bridge started');
console.log('Max UDP receive port:', CONFIG.UDP_RECEIVE_PORT);
console.log('Max UDP send port:', CONFIG.UDP_SEND_PORT);
console.log('WebSocket URL:', CONFIG.WS_URL);
console.log('Debug mode:', CONFIG.DEBUG);
console.log('\nWaiting for messages from Max...\n');
