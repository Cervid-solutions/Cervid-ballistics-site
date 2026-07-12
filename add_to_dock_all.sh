#!/bin/bash
# Runs both add_to_dock.sh and add_to_dock_general_release.sh in sequence, so a single command
# pins both apps to the Dock.
#
# Usage: put this script in the same folder as add_to_dock.sh and
# add_to_dock_general_release.sh, then run:
#   chmod +x add_to_dock_all.sh
#   ./add_to_dock_all.sh
#
# Requires both apps to already be installed (run install.sh and install_general_release.sh,
# or update_all.sh, first). Safe to re-run — each underlying script checks whether its app is
# already pinned before adding it again.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for script in add_to_dock.sh add_to_dock_general_release.sh; do
  if [ ! -f "$SCRIPT_DIR/$script" ]; then
    echo "Error: $script not found next to this script ($SCRIPT_DIR)."
    exit 1
  fi
done

chmod +x "$SCRIPT_DIR/add_to_dock.sh" "$SCRIPT_DIR/add_to_dock_general_release.sh"

echo "############################################"
echo "# Pinning: Cervid Ballistics (main app)"
echo "############################################"
echo ""
"$SCRIPT_DIR/add_to_dock.sh"

echo ""
echo "############################################"
echo "# Pinning: Cervid Ballistics (General Release)"
echo "############################################"
echo ""
"$SCRIPT_DIR/add_to_dock_general_release.sh"

echo ""
echo "Both apps pinned to the Dock."
