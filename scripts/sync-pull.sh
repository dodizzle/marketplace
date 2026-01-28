#!/bin/bash
set -euo pipefail

PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
SOURCE_FILE="$PLUGIN_DIR/CLAUDE.md"
TARGET_DIR="$HOME/.claude"
TARGET_FILE="$TARGET_DIR/CLAUDE.md"

cd "$PLUGIN_DIR"

# Check for git remote
if ! git remote get-url origin &>/dev/null; then
  echo "Error: No git remote configured. Add one with:"
  echo "  cd \"$PLUGIN_DIR\" && git remote add origin <url>"
  exit 2
fi

# Show current position before pull
BEFORE=$(git rev-parse HEAD 2>/dev/null || echo "none")

# Pull latest
if ! git pull --ff-only; then
  echo "Error: git pull failed. You may have local commits that diverge from remote."
  echo "Resolve manually in: $PLUGIN_DIR"
  exit 2
fi

AFTER=$(git rev-parse HEAD 2>/dev/null || echo "none")

# Show what changed
if [ "$BEFORE" != "$AFTER" ]; then
  echo "Updated with new commits:"
  git log --oneline "$BEFORE".."$AFTER"
else
  echo "Already up to date."
fi

# Copy to ~/.claude/
mkdir -p "$TARGET_DIR"
if [ -f "$SOURCE_FILE" ]; then
  cp "$SOURCE_FILE" "$TARGET_FILE"
  echo "CLAUDE.md synced to $TARGET_FILE"
else
  echo "Warning: No CLAUDE.md found in plugin directory."
  exit 2
fi
