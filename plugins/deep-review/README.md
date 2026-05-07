# deep-review

Read-only PR review that dispatches 12 specialist subagents in parallel and aggregates their findings into a single deduplicated report. Designed never to post to GitHub — the command's `allowed-tools` allowlist explicitly omits every GitHub-write tool, so findings only ever appear in your terminal.

## Installation

```
/plugin install deep-review@dodizzle/marketplace
```

## Commands

### `/deep-review:deep-review`

Orchestrates the parallel review across 12 angles: code quality, silent failures, test coverage, type design, comments, code simplification, API breaking changes / acceptance criteria, security, accessibility / dependencies / dead code, Next.js performance, infrastructure cost, and operational risk. Conditional reviewers (perf, cost, types) are skipped when the diff has no relevant files.

**Usage:**

```
/deep-review:deep-review              # review the PR for the current branch
/deep-review:deep-review 1234         # review PR #1234
/deep-review:deep-review feat/foo     # review the PR associated with branch feat/foo
/deep-review:deep-review --staged     # review uncommitted staged changes vs HEAD
```

The final line of every report is `Posts attempted: 0`. If anything else, the run is considered failed.

## How It Works

**Phase 1 — Resolve target.** Parses the argument into a PR number, branch, or `--staged` mode. Fetches `gh pr view`, `gh pr diff`, and `git log` once and caches the diff in context. Locates any `CLAUDE.md` files in the repo so subagents can reference project-specific rules and explicit endorsements.

**Phase 2 — Parallel fan-out.** Dispatches up to 12 `general-purpose` subagents in a single message with parallel `Task` tool calls. Each subagent receives the cached PR diff, base/head refs, relevant `CLAUDE.md` contents, and one inline specialist brief. Universal preamble forbids edits, GitHub writes, and commits.

**Phase 3 — Aggregate and dedup.** Collects findings as `(severity, file, line, fingerprint, source_brief)`. Deduplicates by `(file, line ±3, fingerprint similarity ≥ ~0.7)` and merges entries that multiple briefs flagged. Conflicts resolve to the higher severity.

**Phase 4 — Output.** Prints a structured report bucketed into Critical / Important / Suggestion / Strengths, with a coverage report showing which briefs ran vs. were skipped (`N/A`). `WOULD-COMMENT:` blocks are formatted exactly as they would appear if posted via `gh pr comment` — so you can mentally simulate posting without ever doing so.

## Why It's Safe

The plugin is **fully standalone**: no scripts, no hooks, no MCP dependencies. Every subagent runs as `general-purpose` with an inline brief. Works on any machine with Claude Code.

The read-only contract has two layers:

1. **Frontmatter allowlist** — Claude Code enforces `allowed-tools` and rejects any tool call outside it. The allowlist contains only `git`-read, `gh`-read, `Glob`, `Grep`, `Read`, and `Task`. No `gh pr comment`, no `gh pr review`, no `gh api`, no `Edit`, no `Write`.
2. **Prose contract** — the orchestrator is instructed to refuse mid-run requests to "post these to the PR" and suggest `/code-review:code-review --comment` instead.
