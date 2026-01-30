---
name: sync-push
description: Push local ~/.claude/CLAUDE.md changes to the git remote
allowed-tools:
  - Bash
---

Push the user's local `~/.claude/CLAUDE.md` to the plugin's git repository.

Run the sync-push script:

```bash
bash "$CLAUDE_PLUGIN_ROOT/scripts/sync-push.sh"
```

**If the output contains `CONFLICT_DETECTED`:**
Show the user the diff output from the script and explain that the remote has newer changes. Ask them how they want to proceed:
- **Pull first**: Run `bash "$CLAUDE_PLUGIN_ROOT/scripts/sync-pull.sh"` to get remote changes, then they can re-run push
- **Force overwrite**: Run `REPO_DIR=$(cd "$CLAUDE_PLUGIN_ROOT" && git rev-parse --show-toplevel) && cp ~/.claude/CLAUDE.md "$CLAUDE_PLUGIN_ROOT/content/CLAUDE.md" && cd "$REPO_DIR" && git add "$CLAUDE_PLUGIN_ROOT/content/CLAUDE.md" && git commit -m "chore: force-update CLAUDE.md" && git push --force-with-lease`

If the script succeeds, confirm the commit message and that changes were pushed.

If the script reports no changes, let the user know their CLAUDE.md is already in sync.
