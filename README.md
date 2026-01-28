# claude-md-sync

Sync your personal `~/.claude/CLAUDE.md` across machines via git. Auto-syncs on session start, with commands to pull and push changes.

## Installation

### Option 1: Clone and use directly

```bash
git clone https://github.com/dodizzle/marketplace.git ~/.claude-plugins/claude-md-sync
```

Then add to your Claude Code settings (`~/.claude/settings.json`):

```json
{
  "plugins": [
    "~/.claude-plugins/claude-md-sync"
  ]
}
```

### Option 2: Install from a marketplace

If this plugin is published to a marketplace, install it directly:

```bash
claude /install claude-md-sync
```

Or add the marketplace URL to your settings first if using a custom marketplace:

```json
{
  "pluginMarketplaces": [
    "https://raw.githubusercontent.com/dodizzle/marketplace/main/marketplace.json"
  ]
}
```

### Option 3: Test locally (development)

```bash
claude --plugin-dir /path/to/claude-md-sync
```

## Setup

After cloning, configure the git remote if you haven't already:

```bash
cd /path/to/claude-md-sync
git remote add origin <your-repo-url>
git push -u origin master
```

## How It Works

### Auto-sync on Session Start

Every time you start Claude Code, the plugin:
1. Pulls the latest `CLAUDE.md` from git (warns if network unavailable)
2. Copies it to `~/.claude/CLAUDE.md`

This happens silently in the background via a `SessionStart` hook.

### Manual Commands

| Command | Description |
|---------|-------------|
| `/claude-md-sync:sync-pull` | Pull latest from git and copy to `~/.claude/CLAUDE.md` |
| `/claude-md-sync:sync-push` | Push local `~/.claude/CLAUDE.md` changes to git |

### Conflict Handling

When pushing, if the remote has newer changes:
1. The plugin shows you a diff between local and remote
2. You choose whether to pull first or force-overwrite

## File Structure

```
claude-md-sync/
├── .claude-plugin/
│   └── plugin.json      # Plugin manifest
├── content/
│   └── CLAUDE.md        # Your synced CLAUDE.md content
├── commands/
│   ├── sync-pull.md     # Pull command
│   └── sync-push.md     # Push command
├── hooks/
│   └── hooks.json       # SessionStart auto-sync hook
└── scripts/
    ├── session-sync.sh  # Auto-sync on session start
    ├── sync-pull.sh     # Pull script
    └── sync-push.sh     # Push script with conflict detection
```

## Multi-Machine Workflow

1. **First machine**: Set up this plugin with your `CLAUDE.md`, push to git
2. **Other machines**: Clone the repo, add to Claude Code plugins
3. **Making changes**: Edit `~/.claude/CLAUDE.md`, then run `/claude-md-sync:sync-push`
4. **Getting changes**: Run `/claude-md-sync:sync-pull` or just start a new session (auto-syncs)

## Publishing to a Marketplace

To make this plugin available via `claude /install`, add it to a marketplace.json file:

### 1. Create or update marketplace.json

```json
{
  "plugins": [
    {
      "name": "claude-md-sync",
      "description": "Sync your personal ~/.claude/CLAUDE.md across machines via git",
      "version": "0.1.0",
      "source": {
        "type": "git",
        "url": "https://github.com/dodizzle/marketplace.git"
      },
      "author": "David O'Dell",
      "keywords": ["claude-md", "sync", "dotfiles", "git"]
    }
  ]
}
```

### 2. Host the marketplace

Push the marketplace.json to a public git repo. The raw URL becomes your marketplace URL:

```
https://raw.githubusercontent.com/dodizzle/marketplace/main/marketplace.json
```

### 3. Users add your marketplace

Users add your marketplace URL to their `~/.claude/settings.json`:

```json
{
  "pluginMarketplaces": [
    "https://raw.githubusercontent.com/dodizzle/marketplace/main/marketplace.json"
  ]
}
```

Then install with:

```bash
claude /install claude-md-sync
```

## Troubleshooting

**"No git remote configured"**
Run `git remote add origin <url>` in the plugin directory.

**Pull fails on session start**
Network may be unavailable. The plugin warns but still copies the local version.

**Push shows CONFLICT_DETECTED**
Remote has newer commits. Pull first with `/claude-md-sync:sync-pull`, then push again.
