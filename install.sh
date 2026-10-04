#!/bin/bash
set -euo pipefail

REPO="kpryu6/turtleneck"
APP="/Applications/TurtleNeck.app"

echo "🐢 Installing TurtleNeck..."
echo ""

if command -v brew &>/dev/null; then
    # Homebrew가 있으면 cask로 설치 (업데이트도 brew upgrade로 가능)
    echo "📥 Installing with Homebrew..."
    brew tap kpryu6/turtleneck 2>/dev/null || true
    brew install --cask turtleneck
else
    # Homebrew가 없으면 GitHub Releases에서 DMG를 직접 받는다
    echo "📥 Downloading the latest release from GitHub..."
    DMG_URL=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
        | grep -o '"browser_download_url": *"[^"]*\.dmg"' | head -1 | cut -d'"' -f4)
    if [ -z "$DMG_URL" ]; then
        echo "❌ Could not find a DMG in the latest release: https://github.com/${REPO}/releases"
        exit 1
    fi

    TMP=$(mktemp -d)
    trap 'hdiutil detach "$TMP/mnt" -quiet 2>/dev/null || true; rm -rf "$TMP"' EXIT

    curl -fL --progress-bar -o "$TMP/TurtleNeck.dmg" "$DMG_URL"
    hdiutil attach "$TMP/TurtleNeck.dmg" -nobrowse -quiet -mountpoint "$TMP/mnt"

    if [ -d "$APP" ]; then
        osascript -e 'quit app "TurtleNeck"' 2>/dev/null || true
        rm -rf "$APP"
    fi
    cp -R "$TMP/mnt/TurtleNeck.app" /Applications/
fi

# 아직 Apple 공증(notarization)을 받지 않은 앱이라 Gatekeeper 격리 속성을 제거해야 열린다
echo "🔓 Allowing TurtleNeck to run (app is not notarized yet)..."
xattr -cr "$APP" 2>/dev/null || true

echo ""
echo "✅ TurtleNeck installed!"
echo "🐢 Launching... (allow camera access when macOS asks)"
open "$APP"

echo ""
echo "☕ If you like TurtleNeck, support the developer: https://ko-fi.com/kpryu"
