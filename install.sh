#!/bin/bash
# TurtleNeck installer for macOS
#   curl -fsSL https://raw.githubusercontent.com/kpryu6/turtleneck/main/install.sh | bash
# Installs (or updates to) the latest release from GitHub. No Homebrew needed.
set -euo pipefail

REPO="kpryu6/turtleneck"
APP="/Applications/TurtleNeck.app"

echo "🐢 Installing TurtleNeck..."
echo ""

if [ "$(uname -s)" != "Darwin" ]; then
    echo "❌ This installer is for macOS. On Windows, see https://github.com/${REPO}#windows-beta"
    exit 1
fi
MACOS_MAJOR=$(sw_vers -productVersion | cut -d. -f1)
if [ "$MACOS_MAJOR" -lt 13 ]; then
    echo "❌ TurtleNeck needs macOS 13 (Ventura) or later. You have $(sw_vers -productVersion)."
    exit 1
fi

RELEASE_JSON=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest")
TAG=$(printf '%s' "$RELEASE_JSON" | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)
DMG_URL=$(printf '%s' "$RELEASE_JSON" | grep -o '"browser_download_url": *"[^"]*\.dmg"' | head -1 | cut -d'"' -f4)
if [ -z "$DMG_URL" ]; then
    echo "❌ Could not find a DMG in the latest release: https://github.com/${REPO}/releases"
    exit 1
fi

TMP=$(mktemp -d)
trap 'hdiutil detach "$TMP/mnt" -quiet 2>/dev/null || true; rm -rf "$TMP"' EXIT

echo "📥 Downloading TurtleNeck ${TAG}..."
curl -fL --progress-bar -o "$TMP/TurtleNeck.dmg" "$DMG_URL"
hdiutil attach "$TMP/TurtleNeck.dmg" -nobrowse -quiet -mountpoint "$TMP/mnt"

# Updating: quit the running copy first so it can be replaced
if pgrep -x TurtleNeck >/dev/null; then
    osascript -e 'quit app "TurtleNeck"' 2>/dev/null || pkill -x TurtleNeck || true
    sleep 1
fi

echo "📦 Copying to /Applications..."
if [ -w /Applications ] && { [ ! -e "$APP" ] || [ -w "$APP" ]; }; then
    rm -rf "$APP"
    cp -R "$TMP/mnt/TurtleNeck.app" /Applications/
else
    echo "   (administrator password needed to write to /Applications)"
    sudo rm -rf "$APP"
    sudo cp -R "$TMP/mnt/TurtleNeck.app" /Applications/
fi

# The app is not notarized by Apple yet; clear the quarantine flag so it opens normally
xattr -cr "$APP" 2>/dev/null || true

echo ""
echo "✅ TurtleNeck ${TAG} installed!"
echo "🐢 Launching... allow camera access when macOS asks, then sit up straight to calibrate."
open "$APP"

echo ""
echo "☕ If you like TurtleNeck, support the developer: https://ko-fi.com/kpryu"
