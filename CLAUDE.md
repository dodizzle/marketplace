# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Claude Code plugin (`claude-md-sync`) that syncs `~/.claude/CLAUDE.md` across machines via git. It auto-syncs on session start and provides commands for manual pull/push.

## Architecture

**Marketplace structure:**
- `.claude-plugin/marketplace.json` — marketplace manifest listing available plugins
- `plugins/<name>/` — each plugin in its own directory

**Plugin structure follows Claude Code conventions (under `plugins/claude-md-sync/`):**
- `.claude-plugin/plugin.json` — manifest with name, version, description
- `commands/*.md` — slash commands with YAML frontmatter (`name`, `description`, `allowed-tools`)
- `hooks/hooks.json` — event handlers (uses wrapper format: `{"hooks": {...}}`)
- `scripts/*.sh` — bash scripts invoked by commands and hooks

**Data flow:**
- `plugins/claude-md-sync/content/CLAUDE.md` is the git-tracked copy of user's personal settings
- On session start, hook pulls from git and copies to `~/.claude/CLAUDE.md`
- Push command copies `~/.claude/CLAUDE.md` → `content/CLAUDE.md`, commits, pushes

## Testing

```bash
# Test plugin locally without modifying global settings
claude --plugin-dir /path/to/this-repo/plugins/claude-md-sync

# Validate shell script syntax
bash -n plugins/claude-md-sync/scripts/sync-pull.sh

# Validate JSON files
python3 -c "import json; json.load(open('plugins/claude-md-sync/hooks/hooks.json'))"
```

## Shell Script Conventions

All scripts in `scripts/` must:
- Use `set -euo pipefail` on line 2
- Use `$CLAUDE_PLUGIN_ROOT` for plugin-relative paths (with fallback: `${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}`)
- Use `$REPO_DIR` (via `git rev-parse --show-toplevel`) for git operations — the plugin dir is nested inside the repo
- Quote all variables
- Exit with code 2 for errors that should be shown to user
