#!/bin/bash
set -e

APP_NAME="ImageLayerWiper"
APP_DIR="/Applications/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BINARY="${PROJECT_DIR}/.build/release/${APP_NAME}"

echo "📦 Packaging ${APP_NAME}..."

# Check binary exists
if [ ! -f "$BINARY" ]; then
    echo "❌ Release binary not found. Run 'swift build -c release' first."
    exit 1
fi

# Remove old app bundle if exists
if [ -d "$APP_DIR" ]; then
    echo "🗑  Removing old ${APP_NAME}.app..."
    rm -rf "$APP_DIR"
fi

# Create bundle structure
echo "📁 Creating app bundle..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy binary
cp "$BINARY" "$MACOS_DIR/${APP_NAME}"
chmod +x "$MACOS_DIR/${APP_NAME}"

# Copy Info.plist
cp "${PROJECT_DIR}/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

# Copy app icon
if [ -f "${PROJECT_DIR}/Resources/AppIcon.icns" ]; then
    cp "${PROJECT_DIR}/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
    echo "🎨 App icon installed"
fi

# Create PkgInfo
echo -n "APPL????" > "$CONTENTS_DIR/PkgInfo"

echo "✅ ${APP_NAME}.app installed to /Applications/"
echo "🚀 You can now open it from Finder, Spotlight, or run:"
echo "   open /Applications/${APP_NAME}.app"
