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
# The header icon image is a separate file the HTML references by relative path, so a copy
# needs to live next to every deployed index.html (root and Personal/) or the icon breaks.
if [ -f cervid-icon-square.jpg ] && [ -f Personal/index.html ]; then
  cp cervid-icon-square.jpg Personal/cervid-icon-square.jpg
  echo "  Personal/cervid-icon-square.jpg <- cervid-icon-square.jpg"
fi
echo ""

echo "=== Step 2: Staging changes ==="
git add -A
if git diff --cached --quiet; then
  # NOTE: this only means there's nothing NEW to commit right now - it does NOT mean
  # everything has already reached GitHub. If a previous run committed successfully but
  # then failed to push (auth hiccup, network blip, etc.), the working tree will look
  # perfectly clean on the next run even though a commit is still sitting here unpushed.
  # Exiting early in that case used to silently strand that commit forever, since every
  # later run would hit this exact same branch and quit before ever reaching Step 4/5.
  # Falling through to the pull/push steps instead means any backlog gets flushed too -
  # and if there's truly nothing to push either, `git push` below just reports
  # "Everything up-to-date" and exits cleanly on its own.
  echo "Nothing new to commit - working tree already matches the last commit."
  echo "Checking whether an earlier commit is still waiting to be pushed..."
else
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
fi
echo ""

echo "=== Step 4: Pulling any changes made on GitHub since your last push ==="
git pull --rebase origin main
echo ""

echo "=== Step 5: Pushing to GitHub ==="
git push origin main
echo ""
echo "Done. Changes are live on GitHub."
