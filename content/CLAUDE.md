# Personal Workflow Rules

These are my personal defaults. Project-level CLAUDE.md files take precedence — always respect a project's existing conventions over these personal rules.

## Git Workflow

- When beginning work in a repo, always ensure you're on the main/default branch and fully up to date (`git pull`) before doing anything else
- Before writing any code, create a feature branch using correct semver-style naming (e.g., `feat/add-login`, `fix/timeout-handling`, `chore/update-deps`)
- Never commit or work directly on main
- Always create a pull request — never push directly to main
- Use Conventional Commits for all commit messages (e.g., `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`)
- Commit messages should be a single line — no multi-line bodies unless explicitly requested
- PR descriptions should be brief — a short summary and bullet points, not essays

## Testing

- Always run the project's test suite before committing and ensure tests pass
- Write tests alongside any new code — features, fixes, and refactors should include corresponding tests

## Code Style

- Prefer small, focused files over large monolithic ones — split when a file takes on multiple responsibilities
- Write defensive code: validate inputs, handle edge cases explicitly, and fail gracefully rather than silently

## Communication

- Explain key decisions and non-obvious choices briefly — skip explanations for straightforward/boilerplate work

## Claude Code Behavior

- When exiting plan mode to execute the plan, default to "accept edits" mode so edits are auto-applied without individual approval
