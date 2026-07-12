#!/bin/bash
# Installs Cervid Ballistics as a launchable macOS app — and first removes any older installs
# it finds, so you never end up with stale copies of the app or its HTML lying around.
#
# Usage: put this script in the same folder as CervidBallistics.html, then run:
#   chmod +x install.sh
#   ./install.sh
#
# What it does:
#   1. Searches common locations (plus Spotlight) for existing Cervid Ballistics installs and
#      offers to move them to the Trash (recoverable, not a permanent delete) before continuing.
#   2. Copies CervidBallistics.html to ~/Documents/Cervid Ballistics/ (Spotlight-searchable)
#   3. Creates ~/Applications/Cervid Ballistics.app, a tiny launcher that opens the file in Safari
#
# Safe to re-run any time you have a newer CervidBallistics.html to install.

set -e

APP_NAME="Cervid Ballistics"
DOC_DIR="$HOME/Documents/Cervid Ballistics"
APP_DIR="$HOME/Applications/$APP_NAME.app"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_HTML="$SCRIPT_DIR/CervidBallistics.html"

if [ ! -f "$SOURCE_HTML" ]; then
  echo "Error: CervidBallistics.html not found next to this script ($SCRIPT_DIR)."
  echo "Place install.sh in the same folder as CervidBallistics.html and run again."
  exit 1
fi

echo "=== Step 1: Checking for existing installs ==="
echo ""

FOUND=()

# App bundles in common locations
for dir in "$HOME/Applications" "/Applications" "$HOME/Desktop"; do
  if [ -d "$dir/Cervid Ballistics.app" ]; then
    FOUND+=("$dir/Cervid Ballistics.app")
  fi
done

# HTML copies in common locations
for dir in "$HOME/Documents/Cervid Ballistics" "$HOME/Documents" "$HOME/Desktop" "$HOME/Downloads"; do
  if [ -f "$dir/CervidBallistics.html" ]; then
    FOUND+=("$dir/CervidBallistics.html")
  fi
done

# Broader Spotlight search in case a copy was saved somewhere else entirely
while IFS= read -r line; do
  [ -n "$line" ] && FOUND+=("$line")
done < <(mdfind "kMDItemFSName == 'Cervid Ballistics.app'" 2>/dev/null)

while IFS= read -r line; do
  [ -n "$line" ] && FOUND+=("$line")
done < <(mdfind "kMDItemFSName == 'CervidBallistics.html'" 2>/dev/null)

# Don't offer to trash the source file we're about to install from
UNIQUE=()
if [ ${#FOUND[@]} -gt 0 ]; then
  while IFS= read -r item; do
    [ -n "$item" ] && [ "$item" != "$SOURCE_HTML" ] && UNIQUE+=("$item")
  done < <(printf "%s\n" "${FOUND[@]}" | sort -u)
fi

if [ ${#UNIQUE[@]} -eq 0 ]; then
  echo "No existing installs found."
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
cp "$SOURCE_HTML" "$DOC_DIR/CervidBallistics.html"
echo "  Copied app file to: $DOC_DIR/CervidBallistics.html"

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
    <string>com.local.cervidballistics</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>CervidBallisticsLauncher</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

cat > "$APP_DIR/Contents/MacOS/CervidBallisticsLauncher" <<'LAUNCHER'
#!/bin/bash
open -a Safari "$HOME/Documents/Cervid Ballistics/CervidBallistics.html"
LAUNCHER

chmod +x "$APP_DIR/Contents/MacOS/CervidBallisticsLauncher"
echo "  Created app: $APP_DIR"

# The app bundle was just created locally, not downloaded, so it shouldn't carry a
# quarantine flag — but clear it defensively in case macOS still complains on first launch.
xattr -cr "$APP_DIR" 2>/dev/null || true

echo ""
echo "Done. Launch \"$APP_NAME\" from ~/Applications, Spotlight, or Launchpad."
echo "If macOS still shows an 'unidentified developer' warning the first time,"
echo "right-click the app in Finder and choose Open."
