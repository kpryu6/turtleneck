#!/bin/bash
set -e

echo "🐢 Installing TurtleNeck..."
echo ""

# Homebrew 확인
if ! command -v brew &>/dev/null; then
    echo "📦 Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Apple Silicon 경로 설정
    if [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi

# 설치
echo "📥 Downloading TurtleNeck..."
brew tap kpryu6/turtleneck 2>/dev/null || true
brew install --cask turtleneck

# Gatekeeper 해제
echo "🔓 Allowing TurtleNeck to run..."
xattr -cr /Applications/TurtleNeck.app 2>/dev/null || true

echo ""
echo "✅ TurtleNeck installed successfully!"
echo "🐢 Launching..."
open /Applications/TurtleNeck.app

echo ""
echo "☕ If you like TurtleNeck, support the developer: https://ko-fi.com/kpryu"
