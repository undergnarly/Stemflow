#!/bin/bash

# Production Tracker WebSocket Bridge Startup Script
# This script starts the WebSocket bridge for the M4L device

echo "=================================="
echo "Production Tracker WebSocket Bridge"
echo "=================================="
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "ERROR: Node.js is not installed!"
    echo "Please install Node.js 14+ from https://nodejs.org"
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 14 ]; then
    echo "ERROR: Node.js version is too old ($(node -v))"
    echo "Please install Node.js 14+ from https://nodejs.org"
    exit 1
fi

echo "Node.js version: $(node -v)"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
    echo ""
fi

# Check for environment variables
if [ -f ".env" ]; then
    echo "Loading environment from .env file..."
    export $(cat .env | grep -v '^#' | xargs)
fi

# Set default WebSocket URL if not set
if [ -z "$WS_URL" ]; then
    export WS_URL="wss://muvs.dev/ws"
fi

echo "WebSocket URL: $WS_URL"
echo "UDP Receive Port: 7400 (from Max)"
echo "UDP Send Port: 7401 (to Max)"
echo ""
echo "Starting bridge..."
echo "Press Ctrl+C to stop"
echo ""

# Start the bridge
node websocket-bridge.js
