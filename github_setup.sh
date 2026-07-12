#!/bin/bash
# One-time setup: connects this folder to a GitHub repository and pushes everything in it
# for the first time.
#
# Usage: put this script in the same folder as CervidBallistics.html (and the other project
# files), then run:
#   chmod +x github_setup.sh
#   ./github_setup.sh
#
# Prerequisites (this script does NOT set these up for you):
#   - git installed (macOS ships with it, or run `xcode-select --install` if missing)
#   - You're already able to push to GitHub from this Mac - an SSH key added to your GitHub
#     account, or a saved HTTPS credential (Keychain / GitHub CLI). If `git push` normally
#     asks you to log in when you use it elsewhere, sort that out first - this script doesn't
#     handle GitHub sign-in itself.
#   - A GitHub repository already created (empty is fine, or with an auto-generated
#     README/.gitignore/license - Step 6 below merges either case safely).
#
# Safe to re-run: if this folder is already a git repo, it skips straight past init/remote
# setup to the commit-and-push steps.

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Step 1: Checking for git ==="
if ! command -v git >/dev/null 2>&1; then
  echo "Error: git isn't installed. Install the Xcode Command Line Tools first:"
  echo "  xcode-select --install"
  exit 1
fi
echo "  git found: $(git --version)"
echo ""

echo "=== Step 2: Setting up the local repository ==="
if [ -d .git ]; then
  echo "  This folder is already a git repository - skipping init."
else
  git init
  git branch -M main
  echo "  Initialized a new git repository (branch: main)."
fi
echo ""

echo "=== Step 3: Connecting to your GitHub repository ==="
CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null || echo "")
if [ -n "$CURRENT_REMOTE" ]; then
  echo "  Remote 'origin' already set to: $CURRENT_REMOTE"
else
  echo "  Enter your GitHub repository URL."
  echo "  (On the repo's GitHub page, click 'Code' and copy either link - e.g."
  echo "   https://github.com/yourname/cervid-ballistics.git"
  echo "   or git@github.com:yourname/cervid-ballistics.git)"
  read -p "  Repo URL: " REPO_URL
  if [ -z "$REPO_URL" ]; then
    echo "Error: no URL entered."
    exit 1
  fi
  git remote add origin "$REPO_URL"
  echo "  Added remote 'origin' -> $REPO_URL"
fi
echo ""

echo "=== Step 4: Ignoring macOS junk files ==="
if [ ! -f .gitignore ]; then
  echo ".DS_Store" > .gitignore
  echo "  Created .gitignore (ignores .DS_Store)."
else
  echo "  .gitignore already exists - leaving it as-is."
fi
echo ""

echo "=== Step 5: Committing the project files ==="
git add -A
if git diff --cached --quiet; then
  echo "  Nothing new to commit."
else
  git commit -m "Add Cervid Ballistics project files"
  echo "  Committed."
fi
echo ""

echo "=== Step 6: Reconciling with GitHub (in case the repo already has commits) ==="
git fetch origin
if git show-ref --verify --quiet refs/remotes/origin/main; then
  echo "  origin/main exists - merging it in before pushing."
  git pull origin main --no-rebase --allow-unrelated-histories --no-edit
else
  echo "  origin/main doesn't exist yet (empty repo) - nothing to merge."
fi
echo ""

echo "=== Step 7: Pushing to GitHub ==="
git push -u origin main
echo ""
echo "Done. Your files are now on GitHub, and 'origin/main' is tracked for future pushes."
echo "From now on, just run ./github_push.sh after making changes."
