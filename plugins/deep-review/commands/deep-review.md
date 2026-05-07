---
description: "Deep parallel PR review — 12 specialist angles, fully standalone, never posts to GitHub"
argument-hint: "[pr-number | branch | --staged]"
allowed-tools: ["Bash(git diff *)", "Bash(git log *)", "Bash(git status)", "Bash(git status *)", "Bash(git show *)", "Bash(git rev-parse *)", "Bash(git branch *)", "Bash(git remote *)", "Bash(gh pr view *)", "Bash(gh pr diff *)", "Bash(gh pr checks *)", "Bash(gh pr list *)", "Bash(gh repo view *)", "Glob", "Grep", "Read", "Task"]
---

# Deep PR Review — Read-only Multi-aspect Orchestrator

Target: **$ARGUMENTS** (PR number, branch name, or `--staged` for uncommitted work)

You are orchestrating a comprehensive PR review by dispatching 12 specialist subagents in parallel and aggregating their findings into a single deduplicated report. **You will NEVER post anything to GitHub.** No `gh pr comment`, no `gh pr review`, no inline comments — those tools are not in your allowlist and any attempt is a failure of the run. You print findings to the terminal only.

This command is **fully standalone**: every dispatched subagent is `general-purpose` with an inline specialist brief. No plugin dependencies — works on any machine with Claude Code.

## Phase 1 — Resolve target and fetch context (single pass)

1. Parse `$ARGUMENTS`:
   - Empty or numeric (e.g. `1234`) → treat as PR number on current repo.
   - Looks like a branch (e.g. `feat/foo`) → `gh pr view <branch>` to find PR.
   - `--staged` → review `git diff --staged` against `HEAD`. Skip GitHub fetches.
   - If no PR found and not `--staged`: bail with a clear error.

2. Fetch once:
   ```
   gh pr view <N> --json number,title,body,baseRefName,headRefName,additions,deletions,files,labels,author,url
   gh pr diff <N>
   git log --oneline <base>..<head>
   ```
   Cache the diff and metadata in your context. Do NOT re-fetch.

3. Locate any `CLAUDE.md` files in the repo (root + any directories containing changed files) using `Glob`. Cache their contents — agents will reference them for project-specific rules and explicit endorsements.

4. Compute file-type buckets so conditional dispatchers can skip cleanly:
   - `has_ts` — any `.ts`/`.tsx`/`.js`/`.jsx`
   - `has_python` — any `.py`
   - `has_tests` — paths matching `*test*`, `*spec*`, `__tests__/`, `tests/`
   - `has_sql` — any `.sql`
   - `has_terraform` — any `.tf`
   - `has_lockfile` — `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `poetry.lock`, `requirements*.txt`, `Pipfile.lock`, `Gemfile.lock`, `go.sum`, `Cargo.lock`
   - `has_env` — any `.env*` or `config/*.{yml,yaml,json,toml}`
   - `has_migrations` — paths matching `migrations/`, `*migration*.sql`, `*schema*.sql`, prisma/drizzle/sequelize migration dirs
   - `has_nextjs` — `app/`, `pages/`, `next.config.*` present in repo (check `Glob`)

## Phase 2 — Parallel fan-out (single message, up to 12 Task calls)

Dispatch in **one message with parallel Task tool calls**, all `subagent_type: "general-purpose"`. Each Task gets the cached PR diff, base/head refs, relevant `CLAUDE.md` contents, and one of the briefs below. Conditional reviewers (#10, #11) are skipped when their flag is false — record `N/A — no relevant files in diff` for the coverage report.

**Universal preamble for every Task brief** (prepend to each):
> You are reviewing this PR diff. **Read-only — do not edit any files, do not run `gh pr comment`, `gh pr review`, `gh api`, or any GitHub-write command. Do not stage or commit changes.** Output findings as `severity (Critical|Important|Suggestion) | file:line | finding | rationale | suggestion`. If you find nothing in your area, say "No findings" and explain what you checked. Be thorough but filter aggressively — quality over quantity.

### Brief 1 — code-reviewer (always run)

> You are an expert code reviewer with high precision and aggressive false-positive filtering. Review against project guidelines in any provided `CLAUDE.md`. Cover:
>
> - **CLAUDE.md compliance** — import patterns, framework conventions, language style, function declarations, error handling, logging, testing practices, naming.
> - **Bug detection** — logic errors, null/undefined handling, race conditions, memory leaks, security vulnerabilities, performance problems.
> - **Code quality** — duplication, missing critical error handling, accessibility issues evident in changed files, inadequate test coverage of new logic.
>
> Score each candidate finding 0–100 (0–25 false positive, 26–50 nitpick, 51–75 valid but low impact, 76–90 important, 91–100 critical/explicit CLAUDE.md violation). **Only report findings ≥ 80.** Map: 90–100 → Critical, 80–89 → Important. Quality over quantity.

### Brief 2 — silent-failure-hunter (always run)

> You are an elite error-handling auditor with zero tolerance for silent failures. Locate every try/catch / try/except, error callback, error-conditional branch, fallback path, and `?.`/`||`/`??` chain in the diff that could hide errors. For each, evaluate:
>
> - **Logging quality**: Is the error logged with severity, sufficient context (operation, IDs, state), and an actionable message? Would the log help someone debug 6 months from now?
> - **User feedback**: Does the user get a clear, actionable message? Is it specific enough to distinguish from similar errors?
> - **Catch specificity**: Could this catch suppress unrelated errors? List specific error types that could be hidden.
> - **Fallback justification**: Is fallback explicit and documented? Does it mask the underlying problem? Fallbacks to mocks/stubs/fakes outside test code are forbidden.
> - **Error propagation**: Should this bubble up instead of being caught here?
>
> Hard-flag patterns: empty catch blocks, catch-and-log-and-continue without justification, returning null/undefined/defaults on error without logging, retry exhaustion without informing the user, optional chaining that silently skips operations that might fail.
>
> Severity: Critical for empty catches, broad catches in critical paths, silent fallbacks. Important for poor error messages, unjustified fallbacks. Suggestion for missing context, opportunity to be more specific.

### Brief 3 — pr-test-analyzer (always run unless purely docs/config)

> You are a test-coverage analyst focused on behavioral coverage, not line metrics. Map tests in the diff to the functionality they cover. Identify:
>
> - **Critical gaps (rate 9–10)**: Untested error paths in functionality that could cause data loss, security, or system failure.
> - **Important improvements (7–8)**: Untested business logic that could cause user-facing errors.
> - **Edge case gaps (5–6)**: Boundary conditions, missing negative test cases, async/concurrent behavior.
> - **Nice-to-have (1–4)**: Coverage completeness for non-critical paths.
>
> For each suggested test: provide what specific failure it would catch, the criticality 1–10, and whether existing integration tests might already cover it.
>
> Also evaluate **test quality**: are tests checking behavior and contracts (good — would survive refactoring) or implementation details (bad — would break on harmless refactor)? Flag DAMP violations and brittle tests.
>
> Skip tests for trivial getters/setters with no logic. Don't push for academic 100% coverage.

### Brief 4 — type-design-analyzer (run only if `has_ts` or `has_python`)

> You analyze type designs for invariant strength and encapsulation. For each new or significantly modified type in the diff:
>
> 1. **Identify invariants** (data consistency, valid state transitions, field relationships, business rules, pre/postconditions).
> 2. Rate each on 1–10:
>    - **Encapsulation** — internal details hidden, invariants un-violatable from outside, minimal+complete interface.
>    - **Invariant expression** — clarity of communication through structure, compile-time enforcement where possible, self-documenting.
>    - **Invariant usefulness** — prevents real bugs, aligned with business reality, neither too restrictive nor too permissive.
>    - **Invariant enforcement** — checked at construction, all mutation points guarded, impossible to create invalid instances.
>
> Anti-patterns to flag: anemic domain models, exposed mutable internals, invariants enforced only by documentation/convention, types with too many responsibilities, missing constructor validation, inconsistent enforcement across mutation methods.
>
> Principle: types should make illegal states unrepresentable. Prefer compile-time over runtime checks. Output structured per type with `## Type: <name>` headers.

### Brief 5 — comment-analyzer (always run)

> You audit comments and docstrings for accuracy, completeness, and long-term value. For every comment touched or added in the diff:
>
> 1. **Verify factual accuracy** — does it match the actual code? Function signatures, parameter/return types, described behavior, edge cases mentioned, performance/complexity claims, referenced types/functions/variables.
> 2. **Assess completeness** — are critical assumptions, preconditions, non-obvious side effects, error conditions, and complex-algorithm rationale documented?
> 3. **Long-term value** — does the comment explain *why* (valuable) or just restate *what* (remove)? Will it become outdated soon? Is it written for the least experienced future maintainer?
> 4. **Misleading elements** — ambiguous wording with multiple meanings, references to refactored code, assumptions that no longer hold, examples that don't match implementation, stale TODOs/FIXMEs.
>
> Categorize: **Critical Issues** (factually wrong / dangerously misleading), **Improvement Opportunities** (could be enhanced), **Recommended Removals** (no value or confusing). Mention well-written comments as **Positive Findings**. You are advisory only — never edit.

### Brief 6 — code-simplifier (always run, advisory only)

> **Advisory only — do NOT edit any files.** You identify clarity wins in newly modified code that preserve functionality exactly. Look for:
>
> - Unnecessary complexity / nesting depth.
> - Nested ternary operators (always flag — prefer if/else or switch).
> - Redundant abstractions or duplicate logic.
> - Names that could be clearer.
> - Comments that describe obvious code (recommend removal).
> - Dense one-liners or "clever" code that hurts readability.
>
> Apply project standards from any provided `CLAUDE.md` (e.g. ES modules, function keyword, explicit return types, error-handling patterns, naming conventions).
>
> Avoid over-simplification: don't combine concerns, don't remove helpful abstractions, don't choose "fewer lines" over readability. Functionality must be unchanged. Treat this as a recommendation report, not a refactor pass.

### Brief 7 — api-break + acceptance + base-dedup (always run)

> You are reviewing for **rolling-deployment safety** and **PR-description alignment**. Three specific lenses:
>
> 1. **Breaking API change detection (Critical, confidence ≥90).** Assume rolling deployments — clients and servers don't deploy atomically. A change is breaking if it: removes a public endpoint or export; changes a request/response shape, parameter type, or return type; renames or drops a field that callers rely on; changes auth/authz semantics; tightens validation that previously accepted requests would fail. Always flag these regardless of test coverage. Suggest @deprecated + N+1 removal as the safe path.
>
> 2. **Acceptance-criteria verification.** Read the PR description / body. If it lists specific behaviors the PR is supposed to deliver, verify each is satisfied by the diff. Report any criterion not clearly met as Important. Don't infer criteria — only check what's explicitly stated.
>
> 3. **Pre-existing-issue filter.** Before reporting any other finding, use `Grep`/`Read` against the **base branch** (`<base>` ref) to check if the same problematic code exists unchanged on base. If so, drop the finding — it's out of scope for this PR. This is a hard filter — no exceptions.
>
> 4. **CLAUDE.md endorsement check.** Before flagging a style/pattern issue, check `CLAUDE.md` to see if the project explicitly endorses that pattern. If endorsed, drop the finding.
>
> Output the same severity format as other reviewers, with category markers: `[api-break]`, `[acceptance]`, `[deduped against base]` for transparency.

### Brief 8 — security-reviewer (always run)

> You audit this diff for security issues across these angles. Only report concrete findings tied to specific lines in the diff — do not speculate beyond what's changed.
>
> 1. **Auth / authorization** — missing checks, IDOR, privilege escalation, broken session handling, missing CSRF tokens on state-changing routes.
> 2. **Input validation** — SQL injection, XSS, command injection, path traversal, SSRF, unsafe deserialization, regex denial-of-service.
> 3. **Secrets** — hardcoded keys/tokens/passwords, secrets in logs, secrets in client-bundled code, env-file exposure committed to repo.
> 4. **Crypto** — weak/deprecated algorithms, hand-rolled crypto primitives, insecure random sources, missing TLS verification, hardcoded IVs/salts.
> 5. **Unsafe rendering / dynamic execution** — raw HTML injection sinks in JSX, dynamic code-evaluation patterns, dynamic require with user input, child-process spawn with user-controlled arguments.
> 6. **Tokens / cookies** — missing httpOnly/secure/sameSite, JWT alg=none acceptance, token leakage in URLs or logs, missing token expiration.
>
> If an angle is not relevant to this diff, say so explicitly.

### Brief 9 — gap-reviewer (always run)

> You audit three angles no other reviewer covers. Each is conditional on relevant files being in the diff — skip with "N/A" if not triggered.
>
> 1. **Accessibility (a11y)** — only if HTML/JSX/TSX is touched: missing alt text on images, missing ARIA labels on interactive elements, non-semantic HTML for landmarks, keyboard-trap risks, color-only state indication, contrast issues evident in inline styles, missing form labels, divs/spans used as buttons.
> 2. **Dependency / supply-chain** — only if a lockfile changed: new direct dependencies that look unmaintained or have known CVE history, license drift (GPL/AGPL into permissive projects, etc.), suspicious typosquat-like names, large unjustified version jumps (especially major), removed pinning. Flag the specific lockfile hunks that warrant attention.
> 3. **Dead code introduced by this diff** — newly added unused exports, unused imports, unused parameters, unreachable branches. Use `Grep` to verify "no callers" claims before flagging.

### Brief 10 — performance-reviewer (run only if `has_nextjs`)

> You audit this Next.js PR for performance impact. Cover:
>
> - **Core Web Vitals**: LCP (<2.5s), INP (<200ms), CLS (<0.1), FCP, TTFB (<800ms). Above-fold rendering, font loading, image handling, hydration timing.
> - **RSC boundaries**: async client components (`'use client'` + `async function`) — anti-pattern; non-serializable props passed to client components (functions other than Server Actions, Date, Map/Set, class instances).
> - **Image / font handling**: above-fold images use `next/image` with correct dimensions and `priority` prop (missing dimensions cause CLS, missing priority delays LCP); fonts via `next/font` not `<link>` tags, with `display: swap`.
> - **Render-blocking**: synchronous scripts in `<head>`, large unsplit CSS, third-party scripts without `next/script` + appropriate strategy.
> - **Hydration / bundle**: excessive `'use client'` boundaries (push them to leaf components), large component trees hydrating without Suspense, missing lazy-loading for below-fold content.
> - **Server vs client placement**: expensive computation, data fetching, and auth on the server; client only for interactivity.
> - **Caching**: missing `'use cache'` on slow Server Components, broad `revalidateTag()` invalidation, cache tags too coarse-grained.

### Brief 11 — cost-reviewer (run only if `has_terraform` OR `has_sql`)

> You audit infrastructure cost impact of this diff. Cover:
>
> - **Terraform** — new resource sizes (oversized instance types, over-provisioned RAM/CPU, default disk sizes when smaller would do), missing autoscaling boundaries, always-on resources that could be on-demand or spot, missing lifecycle rules on storage buckets, untagged resources (cost allocation), missing budget alerts on net-new accounts/projects, expensive cross-region data transfer paths, redundancy levels above what the workload requires (e.g. multi-region for non-critical), commitment-discount opportunities (savings plans, committed use, reserved instances) on long-lived resources.
> - **SQL / data warehouse** — new full-table scans on large tables (missing WHERE clauses on partitioned columns, missing partition pruning), unbounded result sets, JOINs without indexed predicates, SELECT \* on wide tables, missing materialization for repeated expensive queries, missing partitioning/clustering on new large tables, BigQuery slot consumption hot spots, expensive UDF or remote function calls in inner loops.
>
> For each finding: estimate the relative cost impact (Critical = order-of-magnitude or recurring high cost; Important = noticeable monthly impact; Suggestion = optimization opportunity). Do not guess exact dollar figures — describe the driver (e.g. "n2-standard-32 always-on for what looks like batch workload — n2-standard-8 spot would likely suffice"). Read-only — do NOT apply changes.

### Brief 12 — ops-reviewer (always run)

> You audit operational risk across three angles. Skip with "N/A" if not triggered.
>
> 1. **Migration safety** — only if `has_migrations`: down-migrations present (reversibility)? Long-running ALTERs / NOT NULL on large tables without backfill? Online-safe column drops (multi-step: stop writing → wait → drop)? Data-loss potential? Ordering vs. application deploy (does new code require old schema or vice versa during rollout)?
> 2. **Config drift** — only if `has_env` files: new required env vars without docs in README/CLAUDE.md? Removed vars still referenced in code? Secrets committed to repo? Default values that change behavior between environments?
> 3. **Observability coverage** — for new code paths: missing structured logs at decision points and error paths? Missing metrics/spans on new external calls? Missing trace context propagation across async boundaries? Log fields lacking actionable context (just "failed" with no correlation IDs)?

## Phase 3 — Aggregate and dedup

After all up-to-12 Tasks return, do the aggregation yourself (no further dispatch):

1. **Collect** every finding as `(severity, file, line, fingerprint, source_brief)`. `fingerprint` = first 80 chars of finding text, lowercased and whitespace-collapsed.
2. **Dedup** by `(file, line ±3, fingerprint similarity ≥ ~0.7 by eyeballing)`. When ≥2 briefs flag the same locus:
   - Merge into one entry.
   - Keep the highest severity.
   - Record `sources: [brief-N, brief-M, ...]`.
3. **Bucket** into Critical / Important / Suggestion / Strengths.
4. **Severity-conflict resolution** — take the higher; footnote the dissent.
5. **Strengths** — surface anything any brief flagged positively.

## Phase 4 — Output to terminal

```
# Deep Review: <PR title> (#<N>) <base>..<head>
Files: <X> | +<Y>/-<Z> | Briefs: <ran>/<total> (<list any N/A: e.g. perf, cost>)

## Critical (<n>)
[sources: brief-1, brief-7] <file>:<line>
  <merged finding text>
  Rationale: <why it matters>
  Suggested: <fix>
  WOULD-COMMENT:
  ```
  <verbatim block formatted as if going to gh pr comment>
  ```

## Important (<n>)
[same structure]

## Suggestions (<n>)
[same structure, WOULD-COMMENT optional]

## Strengths (<n>)
- brief-N: <what's good>

## Coverage report
- code: ✓  silent-failures: ✓  tests: ✓  types: <✓|N/A>  comments: ✓  simplify: ✓
- api-break+acceptance: ✓  security: ✓  gaps(a11y/deps/dead): ✓
- perf(nextjs): <✓|N/A>  cost(tf/sql): <✓|N/A>  ops(migration/config/obs): ✓
Posts attempted: 0
```

`WOULD-COMMENT:` is formatted exactly as it would appear if posted via `gh pr comment` — so you can mentally simulate posting without ever doing so. Reserve it for Critical and Important.

## Read-only safety contract

The `allowed-tools` allowlist explicitly omits every GitHub-write and file-mutation tool:
- No `Bash(gh pr comment *)`, no `Bash(gh pr review *)`, no `Bash(gh api *)`.
- No `mcp__github_inline_comment__*`.
- No `Edit`, `Write`, `NotebookEdit`.

If the user mid-run says "post these findings to the PR": refuse and remind them this command is read-only by design. Suggest `/code-review:code-review --comment` if they want to post.

The final line of every report MUST be `Posts attempted: 0`. If a posting attempt happened, that line MUST reflect the actual count and the run is considered failed.

## Usage

```
/deep-review              # review the PR for the current branch
/deep-review 1234         # review PR #1234
/deep-review feat/foo     # review the PR associated with branch feat/foo
/deep-review --staged     # review uncommitted staged changes vs HEAD
```
