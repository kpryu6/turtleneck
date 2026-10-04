#!/bin/bash
# Points the Homebrew cask at a released DMG.
#   scripts/update-homebrew-tap.sh v1.2.0 path/to/homebrew-turtleneck
# Downloads the DMG from the GitHub release, computes its SHA256 and rewrites
# version + sha256 in Casks/turtleneck.rb. Committing/pushing is up to the caller.
set -euo pipefail

TAG="${1:?usage: $0 <tag> <tap-dir>}"
TAP_DIR="${2:?usage: $0 <tag> <tap-dir>}"
REPO="${REPO:-kpryu6/turtleneck}"
VERSION="${TAG#v}"
CASK="$TAP_DIR/Casks/turtleneck.rb"

if [[ ! "$VERSION" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
    echo "❌ Tag must look like v1.2.3 (got '$TAG')" >&2
    exit 1
fi
[ -f "$CASK" ] || { echo "❌ $CASK not found" >&2; exit 1; }

URL="https://github.com/${REPO}/releases/download/${TAG}/TurtleNeck-${VERSION}.dmg"
echo "📥 $URL"
SHA=$(curl -fsSL "$URL" | shasum -a 256 | awk '{print $1}')
# An empty download hashes to this; never write it into the cask
if [ "$SHA" = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" ]; then
    echo "❌ Downloaded an empty file" >&2
    exit 1
fi

sed -i.bak -E \
    -e "s/^([[:space:]]*version )\"[^\"]*\"/\1\"${VERSION}\"/" \
    -e "s/^([[:space:]]*sha256 )\"[0-9a-f]*\"/\1\"${SHA}\"/" \
    "$CASK"
rm -f "$CASK.bak"

grep -q "version \"${VERSION}\"" "$CASK" && grep -q "sha256 \"${SHA}\"" "$CASK" || {
    echo "❌ Failed to update $CASK" >&2
    exit 1
}
echo "✅ Cask -> ${VERSION} (${SHA})"
