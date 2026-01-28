#!/bin/bash
set -euo pipefail

PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
REPO_FILE="$PLUGIN_DIR/CLAUDE.md"
LOCAL_FILE="$HOME/.claude/CLAUDE.md"

cd "$PLUGIN_DIR"

# Verify local file exists
if [ ! -f "$LOCAL_FILE" ]; then
  echo "Error: $LOCAL_FILE not found. Nothing to push."
  exit 2
fi

# Check for git remote
if ! git remote get-url origin &>/dev/null; then
  echo "Error: No git remote configured. Add one with:"
  echo "  cd \"$PLUGIN_DIR\" && git remote add origin <url>"
  exit 2
fi

# Fetch remote to check for upstream changes
git fetch origin 2>/dev/null || true

LOCAL_BRANCH=$(git branch --show-current)
UPSTREAM="origin/$LOCAL_BRANCH"

# Check if remote is ahead of local
if git rev-parse "$UPSTREAM" &>/dev/null; then
  LOCAL_HEAD=$(git rev-parse HEAD)
  REMOTE_HEAD=$(git rev-parse "$UPSTREAM")
  MERGE_BASE=$(git merge-base HEAD "$UPSTREAM" 2>/dev/null || echo "none")

  if [ "$MERGE_BASE" != "$REMOTE_HEAD" ] && [ "$LOCAL_HEAD" != "$REMOTE_HEAD" ]; then
    echo "=== Remote has newer changes ==="
    echo ""
    echo "Remote commits not in local:"
    git log --oneline HEAD.."$UPSTREAM"
    echo ""
    echo "Diff between local and remote CLAUDE.md:"
    git diff HEAD.."$UPSTREAM" -- CLAUDE.md 2>/dev/null || echo "(no CLAUDE.md changes in remote)"
    echo ""
    echo "CONFLICT_DETECTED"
    exit 2
  fi
fi

# Copy local file into repo
cp "$LOCAL_FILE" "$REPO_FILE"

# Check if there are actual changes
if git diff --quiet -- CLAUDE.md 2>/dev/null; then
  echo "No changes detected. CLAUDE.md is already in sync."
  exit 0
fi

# Show what changed
echo "Changes to CLAUDE.md:"
git diff -- CLAUDE.md

# Generate commit message with diff summary
DIFF_STAT=$(git diff --stat -- CLAUDE.md | tail -1)
CHANGED_SECTIONS=$(git diff -- CLAUDE.md | grep '^[+-]## ' | sed 's/^[+-]## //' | sort -u | head -3 | tr '\n' ', ' | sed 's/,$//')

if [ -n "$CHANGED_SECTIONS" ]; then
  COMMIT_MSG="chore: update CLAUDE.md — ${CHANGED_SECTIONS}"
else
  COMMIT_MSG="chore: update CLAUDE.md (${DIFF_STAT})"
fi

# Commit and push
git add CLAUDE.md
git commit -m "$COMMIT_MSG"
git push

echo ""
echo "Pushed: $COMMIT_MSG"
