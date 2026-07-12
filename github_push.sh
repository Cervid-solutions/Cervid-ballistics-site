#!/bin/bash
# Commits and pushes any changed files in this folder to GitHub. Run this any time after
# editing the project files (e.g. after Claude updates CervidBallistics.html).
#
# Usage:
#   chmod +x github_push.sh
#   ./github_push.sh                  (uses an auto-generated commit message)
#   ./github_push.sh "your message"   (uses your own commit message instead)
#
# Requires github_setup.sh to have been run first (this folder needs to already be a git
# repo with 'origin' pointing at your GitHub repository).

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ ! -d .git ]; then
  echo "Error: this folder isn't a git repository yet."
  echo "Run ./github_setup.sh first."
  exit 1
fi

echo "=== Step 1: Syncing deployment copies ==="
# The live site is served from index.html (site root) and Personal/index.html - separate
# copies of CervidBallistics_GeneralRelease.html and CervidBallistics.html, not those files
# themselves, since GitHub Pages only serves a file literally named index.html. Refreshing
# both copies here every time means an edit to the source files can't silently go stale on
# the live site just because someone forgot to re-copy it by hand before pushing.
if [ -f CervidBallistics_GeneralRelease.html ] && [ -f index.html ]; then
  cp CervidBallistics_GeneralRelease.html index.html
  echo "  index.html <- CervidBallistics_GeneralRelease.html"
fi
if [ -f CervidBallistics.html ] && [ -f Personal/index.html ]; then
  cp CervidBallistics.html Personal/index.html
  echo "  Personal/index.html <- CervidBallistics.html"
fi
echo ""

echo "=== Step 2: Staging changes ==="
git add -A
if git diff --cached --quiet; then
  echo "Nothing to commit - all files already match the last commit."
  exit 0
fi
git status --short
echo ""

echo "=== Step 3: Committing ==="
if [ -n "$1" ]; then
  MSG="$1"
else
  MSG="Update Cervid Ballistics files - $(date '+%Y-%m-%d %H:%M')"
fi
git commit -m "$MSG"
echo "  Committed: $MSG"
echo ""

echo "=== Step 4: Pulling any changes made on GitHub since your last push ==="
git pull --rebase origin main
echo ""

echo "=== Step 5: Pushing to GitHub ==="
git push origin main
echo ""
echo "Done. Changes are live on GitHub."
