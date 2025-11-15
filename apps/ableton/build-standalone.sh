#!/bin/bash

# Build standalone executable for WebSocket bridge
# This creates a single .exe file that doesn't require Node.js installation

echo "=================================="
echo "Building Standalone Bridge Executable"
echo "=================================="
echo ""

cd /root/Stemflow/apps/ableton

# Install pkg globally if not installed
if ! command -v pkg &> /dev/null; then
    echo "Installing pkg..."
    npm install -g pkg
fi

# Create package.json for pkg build
cat > package-build.json <<'EOF'
{
  "name": "production-tracker-bridge",
  "version": "1.0.0",
  "main": "websocket-bridge.js",
  "bin": "websocket-bridge.js",
  "dependencies": {
    "ws": "^8.14.2"
  },
  "pkg": {
    "targets": [ "node18-win-x64" ],
    "outputPath": "build"
  }
}
EOF

echo "Building Windows executable..."
pkg websocket-bridge.js --targets node18-win-x64 --output build/ProductionTrackerBridge.exe

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Build successful!"
    echo "Output: build/ProductionTrackerBridge.exe"
    ls -lh build/ProductionTrackerBridge.exe
else
    echo "✗ Build failed"
    exit 1
fi

rm package-build.json
