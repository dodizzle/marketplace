#!/bin/bash
set -euo pipefail

PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
SOURCE_FILE="$PLUGIN_DIR/CLAUDE.md"
TARGET_DIR="$HOME/.claude"
TARGET_FILE="$TARGET_DIR/CLAUDE.md"

# Attempt git pull (warn on failure, don't block session)
cd "$PLUGIN_DIR"
if git remote get-url origin &>/dev/null; then
  if ! git pull --ff-only 2>/dev/null; then
    echo "[claude-md-sync] Warning: git pull failed (network or merge issue). Using local copy." >&2
  fi
else
  echo "[claude-md-sync] No git remote configured. Using local copy." >&2
fi

# Ensure target directory exists
mkdir -p "$TARGET_DIR"

# Copy CLAUDE.md to ~/.claude/
if [ -f "$SOURCE_FILE" ]; then
  cp "$SOURCE_FILE" "$TARGET_FILE"
else
  echo "[claude-md-sync] Warning: No CLAUDE.md found in plugin directory." >&2
fi
