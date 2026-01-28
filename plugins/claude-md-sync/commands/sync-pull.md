---
name: sync-pull
description: Pull the latest CLAUDE.md from the git remote and copy it to ~/.claude/CLAUDE.md
allowed-tools:
  - Bash
---

Pull the latest CLAUDE.md from the remote git repository and install it to `~/.claude/CLAUDE.md`.

Run the sync-pull script:

```bash
bash "$CLAUDE_PLUGIN_ROOT/scripts/sync-pull.sh"
```

If the script exits with an error, report the error message to the user. If it succeeds, confirm what was updated.
