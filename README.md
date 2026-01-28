# claude-md-sync

Sync your personal `~/.claude/CLAUDE.md` across machines via git. Auto-syncs on session start, with commands to pull and push changes.

## Installation

### Option 1: Clone and use directly

```bash
git clone <your-repo-url> ~/.claude-plugins/claude-md-sync
```

Then add to your Claude Code settings (`~/.claude/settings.json`):

```json
{
  "plugins": [
    "~/.claude-plugins/claude-md-sync"
  ]
}
```

### Option 2: Test locally (development)

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
├── CLAUDE.md            # Your synced CLAUDE.md content
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

## Troubleshooting

**"No git remote configured"**
Run `git remote add origin <url>` in the plugin directory.

**Pull fails on session start**
Network may be unavailable. The plugin warns but still copies the local version.

**Push shows CONFLICT_DETECTED**
Remote has newer commits. Pull first with `/claude-md-sync:sync-pull`, then push again.
