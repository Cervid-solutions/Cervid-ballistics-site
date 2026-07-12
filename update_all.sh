#!/bin/bash
# Runs both install.sh and install_general_release.sh in sequence, so a single command
# updates both the main app and the General Release app.
#
# Usage: put this script in the same folder as install.sh, install_general_release.sh,
# CervidBallistics.html, and CervidBallistics_GeneralRelease.html, then run:
#   chmod +x update_all.sh
#   ./update_all.sh
#
# Each underlying script still does its own check for old installs and will ask before
# trashing anything — this file doesn't skip or automate past those prompts.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for script in install.sh install_general_release.sh; do
  if [ ! -f "$SCRIPT_DIR/$script" ]; then
    echo "Error: $script not found next to this script ($SCRIPT_DIR)."
    echo "Make sure install.sh, install_general_release.sh, and both .html files are all in this same folder."
    exit 1
  fi
done

chmod +x "$SCRIPT_DIR/install.sh" "$SCRIPT_DIR/install_general_release.sh"

echo "############################################"
echo "# Updating: Cervid Ballistics (main app)"
echo "############################################"
echo ""
"$SCRIPT_DIR/install.sh"

echo ""
echo "############################################"
echo "# Updating: Cervid Ballistics (General Release)"
echo "############################################"
echo ""
"$SCRIPT_DIR/install_general_release.sh"

echo ""
echo "Both apps updated."
