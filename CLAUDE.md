# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the `dodizzle` Claude Code plugin marketplace. Currently hosts:

- **`claude-md-sync`** — Syncs `~/.claude/CLAUDE.md` across machines via git. Auto-syncs on session start, with manual pull/push commands.
- **`deep-review`** — Read-only PR review that dispatches 12 parallel specialist subagents and never posts to GitHub.

## Architecture

**Marketplace structure:**
- `.claude-plugin/marketplace.json` — marketplace manifest listing available plugins. Bump the root `version` whenever any plugin version changes (minor for new plugins/features, patch for plugin patches).
- `plugins/<name>/` — each plugin in its own directory.
- Plugin entries in `marketplace.json` have only `name`, `description`, `source` — no `version` field.

**Plugin structure follows Claude Code conventions:**
- `.claude-plugin/plugin.json` — manifest with name, version, description, author, keywords
- `commands/*.md` — slash commands with YAML frontmatter (`description`, `argument-hint`, `allowed-tools`)
- `hooks/hooks.json` — event handlers, wrapper format: `{"hooks": {...}}` (only used by plugins that need them — e.g. `claude-md-sync`)
- `scripts/*.sh` — bash scripts invoked by commands and hooks (only used by plugins that need them)
- `README.md` — per-plugin documentation with install + commands

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
