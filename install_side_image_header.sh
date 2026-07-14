#!/bin/bash
# Installs the Cervid Ballistics "Side Image Header" variant as a launchable macOS app —
# separate from the main app and the General Release app, so all three can be installed side
# by side without conflicting. First removes any older Side Image Header installs it finds,
# so you never end up with stale copies of the app or its files lying around.
#
# This variant is a design comparison build: same features as the main app, but the header
# uses a small square photo beside the title instead of the full-width banner-behind-title
# background used by CervidBallistics.html.
#
# Usage: put this script in the same folder as CervidBallistics_SideImageHeader.html and
# cervid-icon-square.jpg, then run:
#   chmod +x install_side_image_header.sh
#   ./install_side_image_header.sh
#
# What it does:
#   1. Searches common locations (plus Spotlight) for existing Side Image Header installs and
#      offers to move them to the Trash (recoverable, not a permanent delete) before continuing.
#      Only looks for Side Image Header installs — the other two apps are left alone.
#   2. Copies CervidBallistics_SideImageHeader.html and cervid-icon-square.jpg to
#      ~/Documents/Cervid Ballistics (Side Image Header)/ (Spotlight-searchable)
#   3. Creates ~/Applications/Cervid Ballistics (Side Image Header).app, a tiny launcher that
#      opens the file in Safari
#
# Safe to re-run any time you have a newer CervidBallistics_SideImageHeader.html to install.

set -e

APP_NAME="Cervid Ballistics (Side Image Header)"
DOC_DIR="$HOME/Documents/Cervid Ballistics (Side Image Header)"
APP_DIR="$HOME/Applications/$APP_NAME.app"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_HTML="$SCRIPT_DIR/CervidBallistics_SideImageHeader.html"
SOURCE_IMG="$SCRIPT_DIR/cervid-icon-square.jpg"

if [ ! -f "$SOURCE_HTML" ]; then
  echo "Error: CervidBallistics_SideImageHeader.html not found next to this script ($SCRIPT_DIR)."
  echo "Place install_side_image_header.sh in the same folder as CervidBallistics_SideImageHeader.html and run again."
  exit 1
fi

echo "=== Step 1: Checking for existing Side Image Header installs ==="
echo ""

FOUND=()

# App bundles in common locations
for dir in "$HOME/Applications" "/Applications" "$HOME/Desktop"; do
  if [ -d "$dir/$APP_NAME.app" ]; then
    FOUND+=("$dir/$APP_NAME.app")
  fi
done

# HTML copies in common locations
for dir in "$DOC_DIR" "$HOME/Documents" "$HOME/Desktop" "$HOME/Downloads"; do
  if [ -f "$dir/CervidBallistics_SideImageHeader.html" ]; then
    FOUND+=("$dir/CervidBallistics_SideImageHeader.html")
  fi
done

# Broader Spotlight search in case a copy was saved somewhere else entirely
while IFS= read -r line; do
  [ -n "$line" ] && FOUND+=("$line")
done < <(mdfind "kMDItemFSName == '$APP_NAME.app'" 2>/dev/null)

while IFS= read -r line; do
  [ -n "$line" ] && FOUND+=("$line")
done < <(mdfind "kMDItemFSName == 'CervidBallistics_SideImageHeader.html'" 2>/dev/null)

# Don't offer to trash the source file we're about to install from
UNIQUE=()
if [ ${#FOUND[@]} -gt 0 ]; then
  while IFS= read -r item; do
    [ -n "$item" ] && [ "$item" != "$SOURCE_HTML" ] && UNIQUE+=("$item")
  done < <(printf "%s\n" "${FOUND[@]}" | sort -u)
fi

if [ ${#UNIQUE[@]} -eq 0 ]; then
  echo "No existing Side Image Header installs found."
else
  echo "Found the following:"
  for item in "${UNIQUE[@]}"; do
    echo "  $item"
  done
  echo ""
  read -p "Move all of these to Trash before installing the new version? [y/N] " CONFIRM
  if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
    for item in "${UNIQUE[@]}"; do
      osascript -e "tell application \"Finder\" to delete POSIX file \"$item\"" >/dev/null 2>&1
      echo "  Trashed: $item"
    done
  else
    echo "Skipped removal — continuing with install (existing files will be overwritten where they conflict)."
  fi
fi

echo ""
echo "=== Step 2: Installing \"$APP_NAME\" ==="
echo ""

# Copy the HTML file into Documents so Spotlight can find it directly too.
mkdir -p "$DOC_DIR"
cp "$SOURCE_HTML" "$DOC_DIR/CervidBallistics_SideImageHeader.html"
echo "  Copied app file to: $DOC_DIR/CervidBallistics_SideImageHeader.html"

# The header thumbnail is a separate file the HTML references by relative path, so it has to
# travel alongside CervidBallistics_SideImageHeader.html wherever it gets installed.
if [ -f "$SOURCE_IMG" ]; then
  cp "$SOURCE_IMG" "$DOC_DIR/cervid-icon-square.jpg"
  echo "  Copied header image to: $DOC_DIR/cervid-icon-square.jpg"
fi

# Build a minimal .app bundle whose only job is to open that file in Safari.
mkdir -p "$HOME/Applications"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.cervidballistics.sideimageheader</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>CervidBallisticsSideImageHeaderLauncher</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

cat > "$APP_DIR/Contents/MacOS/CervidBallisticsSideImageHeaderLauncher" <<LAUNCHER
#!/bin/bash
open -a Safari "$DOC_DIR/CervidBallistics_SideImageHeader.html"
LAUNCHER

chmod +x "$APP_DIR/Contents/MacOS/CervidBallisticsSideImageHeaderLauncher"
echo "  Created app: $APP_DIR"

# The app bundle was just created locally, not downloaded, so it shouldn't carry a
# quarantine flag — but clear it defensively in case macOS still complains on first launch.
xattr -cr "$APP_DIR" 2>/dev/null || true

echo ""
echo "Done. Launch \"$APP_NAME\" from ~/Applications, Spotlight, or Launchpad."
echo "This is a separate app from the main \"Cervid Ballistics\" and \"General Release\" installs —"
echo "all three can coexist, and each keeps its own saved presets (separate localStorage per file)."
echo "If macOS still shows an 'unidentified developer' warning the first time,"
echo "right-click the app in Finder and choose Open."
