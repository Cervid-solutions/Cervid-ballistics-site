#!/bin/bash
# Pins "Cervid Ballistics (Side Image Header).app" to the Dock.
#
# Usage:
#   chmod +x add_to_dock_side_image_header.sh
#   ./add_to_dock_side_image_header.sh
#
# Requires the app to already be installed (run install_side_image_header.sh first).
# Safe to re-run — it checks whether the app is already pinned before adding it again.

set -e

APP_NAME="Cervid Ballistics (Side Image Header)"
APP_PATH="$HOME/Applications/$APP_NAME.app"

if [ ! -d "$APP_PATH" ]; then
  # Fall back to /Applications in case it was installed system-wide instead.
  if [ -d "/Applications/$APP_NAME.app" ]; then
    APP_PATH="/Applications/$APP_NAME.app"
  else
    echo "Error: \"$APP_NAME.app\" not found in ~/Applications or /Applications."
    echo "Run install_side_image_header.sh first, then try this again."
    exit 1
  fi
fi

if defaults read com.apple.dock persistent-apps 2>/dev/null | grep -q "$APP_PATH"; then
  echo "\"$APP_NAME\" is already pinned to the Dock — nothing to do."
  exit 0
fi

echo "Pinning \"$APP_NAME\" to the Dock..."

defaults write com.apple.dock persistent-apps -array-add "<dict>
  <key>tile-data</key>
  <dict>
    <key>file-data</key>
    <dict>
      <key>_CFURLString</key>
      <string>$APP_PATH</string>
      <key>_CFURLStringType</key>
      <integer>0</integer>
    </dict>
  </dict>
</dict>"

killall Dock

echo "Done. \"$APP_NAME\" should now appear in your Dock."
