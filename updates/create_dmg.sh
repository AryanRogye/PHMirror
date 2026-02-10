#!/bin/bash

set -euo pipefail

APP="Phmirror.app"
DMG="Phmirror-Installer.dmg"
BUILD_TEMP="BUILD-TEMP"
VOLNAME="Phmirror Installer"

if ! [ -d "$APP" ]; then
    echo "$APP Not Found"
    exit 1
fi

if [ -f "$DMG" ]; then
    rm -rf "$DMG"
fi

cleanup() {
    # 1. capture current folder name correctly
    current_dir=$(basename "$(pwd)")

    # 2. If we are inside the temp folder, get out
    if [ "$current_dir" == "$BUILD_TEMP" ]; then
        cd ..
    fi
    
    # 3. If the temp folder exists, delete it
    if [ -d "$BUILD_TEMP" ]; then
        echo "Cleaning up temp files..."
        rm -rf "$BUILD_TEMP"
    fi
}
trap cleanup EXIT

echo "Creating Temp Directory"
mkdir -p "$BUILD_TEMP"


# Use ditto instead of cp -r to preserve bundle metadata/symlinks.
ditto "$APP" "$BUILD_TEMP/$APP"

cd "$BUILD_TEMP"

if ! command -v create-dmg >/dev/null 2>&1; then
    echo "create-dmg is not installed. Install it first: brew install create-dmg"
    exit 1
fi

echo "Creating $DMG"
create-dmg \
    --volname "$VOLNAME" \
    --window-pos 200 120 \
    --window-size 800 400 \
    --icon-size 100 \
    --icon "$APP" 200 190 \
    --hide-extension "$APP" \
    --app-drop-link 600 185 \
    "$DMG" \
    "./"
echo "✅ Done"

# Optional signing: export CODESIGN_IDENTITY="Developer ID Application: Name (TEAMID)"
if [ -n "${CODESIGN_IDENTITY:-}" ]; then
    echo "Signing DMG"
    codesign --force --sign "$CODESIGN_IDENTITY" "$DMG"
    echo "✅ Done"
else
    echo "Skipping DMG signing (CODESIGN_IDENTITY is not set)"
fi

mv "$DMG" ../
cd ..

echo "Build successfully completed: $DMG"
