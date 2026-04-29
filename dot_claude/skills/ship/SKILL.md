---
name: ship
description: Active end-to-end completion workflow. Detects the project type, runs tests with stderr discipline, optionally simplifies, and prepares a commit + PR draft. Use when wrapping up a non-trivial implementation. Counterpart to verify-before-done (passive checklist) - this one actually executes the verification.
---

# Ship

## Purpose

Most "I'm done" claims are wrong because verification was skipped. `verify-before-done` produces a checklist; `ship` actually runs the work. The pattern comes from Boris Cherny's `/go` skill - "give Claude a way to verify its work" is "2-3x what you get out of Claude" with Opus 4.7.

This skill is opt-in. Invoke it via `/ship` when you want to close out a task properly. Do not run it for trivial edits.

**This is a global skill** - works across any project.

## When To Use

- After a multi-file change, new feature, bug fix, refactor
- Before declaring "done" on a task
- User says `/ship`, "ship it", "wrap this up", "ready to commit"

## When NOT To Use

- Single-line typo fixes
- Pure exploration or research turns
- The user is mid-task and just wants to checkpoint
- The user explicitly says "just commit, don't verify"

## Process

### Step 1: Detect project type and verification commands

Read the repo to figure out how to verify. In priority order:

1. **`package.json` scripts** - look for `test`, `typecheck`, `lint`, `build`, `check`. Prefer the narrowest that exercises real behavior. If `typecheck` and `test` both exist, run both.
2. **`Cargo.toml`** - `cargo test`, `cargo check`, `cargo clippy`.
3. **`pyproject.toml` / `setup.py`** - `pytest`, `mypy`, `ruff check`.
4. **`go.mod`** - `go test ./...`, `go vet ./...`.
5. **`Makefile`** with `test`, `check`, or `verify` targets.
6. **`.github/workflows/*.yml`** - find the CI command if local scripts are missing; mirror what CI runs.
7. **None of the above** - ask the user how to verify.

For UI / browser work, also plan a visual check: Chrome MCP screenshot, Playwright, or a screenshot the user takes. UI is not done until you have seen it render.

For backend / server work, plan an end-to-end check: start the server, hit a real endpoint, look at the response.

### Step 2: Execute verification with stderr discipline

Run the chosen commands. For each command:

- Capture **stdout AND stderr separately**. Do not collapse them into one stream.
- A test command that exits 0 but writes warnings/errors to stderr is NOT green. Investigate before claiming pass.
- Apply bounds-checks to any numerical output (no percentages > 100%, no negative durations, no rates that violate logical limits).
- For UI: take a screenshot and look at it. Tests passing while the UI is broken is a known failure mode.

If a command fails, stop and surface the failure. Do not continue to commit/PR.

### Step 3: Optional - run /simplify

If the change touches >50 lines of new code, ask the user whether to run `/simplify` (the built-in skill that reviews changed code for reuse, quality, and efficiency). Skip for docs-only changes, config changes, or revisions to recently-simplified code.

### Step 4: Scope-honest commit message draft

Run `git diff --stat` and `git diff --name-only`. Draft a commit message that:

- Reflects ONLY what is in the diff. No aspirational scope. No "and refactored X" if X wasn't refactored.
- Uses imperative mood for the subject line (≤72 chars).
- Body explains the *why*, not the *what* (the diff shows what).
- No "Generated with Claude Code", no "Co-Authored-By: Claude" attribution unless the user explicitly asks.
- Will be signed with `-S -s` (GPG sign + DCO). If GPG is unavailable, fall back to `-s --no-gpg-sign` and tell the user.

Show the user the draft. Do NOT commit yet.

### Step 5: PR draft (only if requested)

If the user wants a PR, draft `gh pr create` with title and body. Body should reflect:
- What changed (one-paragraph summary, not a section header dump)
- What was verified (test command + result + stderr status)
- What was NOT verified (explicit gaps)
- Link to relevant issue if known

Show the draft. Do NOT push or open the PR yet.

### Step 6: Hand off to user

Summarize:
- Verification commands run + their stdout/stderr disposition
- Anything skipped and why
- Commit message draft (from Step 4)
- PR draft if applicable (from Step 5)
- Explicit "5 more minutes" question: what would you check if you had 5 more minutes? Answer it specifically.

The user runs `git commit` and `git push` themselves. This skill never commits or pushes.

## Output Format

Inline in the conversation. Structured sections, but compact. The discipline of running the steps is the artifact, not paperwork.

## Failure Modes This Catches

These come from real past sessions:

| Failure | What got missed | Step that catches it |
|---------|----------------|----------------------|
| Tests passed but stderr leaked warnings | Stdout-only check | Step 2 stderr discipline |
| Disconnect rate exceeded 100% | No bounds check | Step 2 bounds-checks |
| UI shipped with overlapping pieces | No visual verification | Step 2 UI screenshot |
| Commit message overstated scope | Diff vs message not reconciled | Step 4 scope-honest draft |
| Mobile breakpoints broken | "Done" claimed without testing them | Step 6 explicit gaps |
| Claude attribution slipped into commit | Default attribution | Step 4 explicit no-attribution rule |

## Rules

1. **Never commit or push.** Always hand off the draft. The user decides when to actually run `git commit` and `git push`.
2. **Stderr is not optional.** Capture it on every verification command. Empty stderr is fine; unchecked stderr is not.
3. **Scope honesty before commit.** Always run `git diff --stat` and reconcile with the message draft.
4. **The "5 more minutes" question is load-bearing.** Answer it specifically. If the answer is non-trivial, do it before handing off.
5. **One thing at a time.** Do not commit and PR and merge in one breath. Each step waits for explicit user action.

## Anti-Patterns

- **Running this for trivial tasks.** A typo fix doesn't need ship. Use judgment.
- **Faking verification.** "Tests passed" without showing the command and stdout/stderr is a lie. Show evidence.
- **Inflating commit messages.** "added X, fixed Y, refactored Z" when only X was added is exactly the failure this skill exists to prevent.
- **Running commit/push from the skill.** Never. Always hand off.
- **Skipping `/simplify` on large diffs without asking.** Ask, then skip.

## Configurable Behavior

- **Quick mode:** Steps 1, 2, 4 only (skip simplify and PR draft).
- **Full mode:** All six steps.
- **PR mode:** Run all six and prepare the PR draft.
- **Default:** Full mode if the change touches >5 files, otherwise Quick mode.

---

**Version:** 1.0.0
