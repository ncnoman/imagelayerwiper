#!/bin/bash
set -e

APP_NAME="ImageLayerWiper"
APP_PATH="/Applications/${APP_NAME}.app"
DMG_DIR="/Users/tristan/Documents/imagelayerwiper/dist"
DMG_TMP="${DMG_DIR}/${APP_NAME}-tmp.dmg"
DMG_FINAL="${DMG_DIR}/${APP_NAME}.dmg"
VOLUME_NAME="${APP_NAME}"
STAGING="${DMG_DIR}/staging"

echo "💿 Creating DMG for ${APP_NAME}..."

# Check app exists
if [ ! -d "$APP_PATH" ]; then
    echo "❌ App not found at $APP_PATH. Run package-app.sh first."
    exit 1
fi

# Clean up
rm -rf "$DMG_DIR"
mkdir -p "$STAGING"

# Copy app to staging
cp -R "$APP_PATH" "$STAGING/"

# Create symlink to /Applications for drag-install
ln -s /Applications "$STAGING/Applications"

# Create DMG
hdiutil create -volname "$VOLUME_NAME" \
    -srcfolder "$STAGING" \
    -ov -format UDZO \
    "$DMG_FINAL" 2>&1

# Clean up staging
rm -rf "$STAGING"
rm -f "$DMG_TMP"

echo "✅ DMG created at: $DMG_FINAL"
echo "📦 Size: $(du -h "$DMG_FINAL" | cut -f1)"
