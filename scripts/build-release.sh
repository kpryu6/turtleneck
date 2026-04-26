#!/bin/bash
set -e

APP_NAME="TurtleNeck"
SCHEME="TurtleNeck"
BUILD_DIR="build"
DMG_NAME="${APP_NAME}.dmg"
VERSION=$(grep MARKETING_VERSION project.yml | head -1 | awk -F'"' '{print $2}')

echo "🐢 Building TurtleNeck v${VERSION}..."

# Clean & build Release
rm -rf "$BUILD_DIR"
xcodebuild -project "${APP_NAME}.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    build

# Find .app
APP_PATH=$(find "$BUILD_DIR" -name "${APP_NAME}.app" -type d | head -1)
if [ -z "$APP_PATH" ]; then
    echo "❌ Build failed: .app not found"
    exit 1
fi

echo "✅ Built: $APP_PATH"

# Create DMG
echo "📦 Creating DMG..."
DMG_DIR="$BUILD_DIR/dmg"
rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"
cp -R "$APP_PATH" "$DMG_DIR/"

# Create Applications symlink
ln -s /Applications "$DMG_DIR/Applications"

# Create DMG
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov -format UDZO \
    "$BUILD_DIR/${APP_NAME}-${VERSION}.dmg"

echo "✅ DMG created: $BUILD_DIR/${APP_NAME}-${VERSION}.dmg"

# Calculate SHA256 for Homebrew
SHA=$(shasum -a 256 "$BUILD_DIR/${APP_NAME}-${VERSION}.dmg" | awk '{print $1}')
echo "🔑 SHA256: $SHA"
echo ""
echo "📋 For Homebrew formula, use:"
echo "   url: https://github.com/YOURUSERNAME/TurtleNeck/releases/download/v${VERSION}/${APP_NAME}-${VERSION}.dmg"
echo "   sha256: $SHA"
