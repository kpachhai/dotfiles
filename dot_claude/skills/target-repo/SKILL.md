---
name: target-repo
description: Manage cross-repo working mode - set, show, or clear the operational target repository for the current Claude session while skills, memory, and CLAUDE.md continue to load from cwd (typically the meta-stack repo like idea-forge). Binding is keyed by Claude session UUID so it survives /clear, quit-and-resume in the same OR a different terminal, and works correctly with multiple concurrent sessions. Lets you start Claude in one repo and operate on any other repo. Usage - /target-repo [path | --clear]
user-invocable: true
---

# Target Repo Mode

## Purpose

Decouple two things that are normally coupled to cwd:

1. **Meta stack** — skills, memory file, CLAUDE.md, agent roster. You usually want these from a single curated repo.
2. **Operational target** — the repo you're actually editing, building, testing, committing. Often a different repo.

This skill lets the user pick a different operational target while keeping the meta stack from cwd. The binding persists across `/clear`, terminal close-and-resume, and concurrent sessions because it's keyed by the Claude session UUID (derived from the most-recently-modified `.jsonl` in `~/.claude/projects/<encoded-cwd>/`).

A SessionStart hook (configured in `~/.claude/settings.local.json`) auto-runs `~/.claude/scripts/target-repo-check.sh --banner` at session start. If a binding exists for the current UUID, the banner announces target mode before any other interaction. No user action required to "remember" the target.

## When to invoke

User-explicit (slash command), three forms:

- `/target-repo <PATH>` — set target to PATH (absolute or `~/`-prefixed)
- `/target-repo` — show current target
- `/target-repo --clear` — clear binding for this session

## Implementation: delegate to the helper

All operations defer to `~/.claude/scripts/target-repo-check.sh`. This is intentional - the helper is the single source of truth for UUID resolution, encoding rules, and binding-file layout. The skill is a thin wrapper that translates slash-command invocations into helper calls.

### Set behavior (`/target-repo <PATH>`)

```bash
~/.claude/scripts/target-repo-check.sh --set "<PATH>"
```

The helper resolves `<PATH>` to absolute (expanding `~/`), verifies it exists as a directory (refuses to create), warns if it's not a git repo, derives the current Claude session UUID, and writes `<PATH>` to `~/.claude/target-repo/<uuid>.md`. Exit code 0 on success, non-zero with error message on failure.

After a successful set, also output the standard banner so the user sees the new state immediately:

```bash
~/.claude/scripts/target-repo-check.sh --banner
```

### Show behavior (`/target-repo` with no args)

```bash
~/.claude/scripts/target-repo-check.sh --get
```

- Empty output → no target set for this session. Respond: "No target set. Operating on cwd."
- Non-empty output → echo the standard banner via `--banner` so the user sees the full contract.

### Clear behavior (`/target-repo --clear`)

```bash
~/.claude/scripts/target-repo-check.sh --clear
```

Removes the binding file for current session. Helper handles missing-file gracefully.

## Standard banner format

(Printed automatically by `--banner`; reproduced here for documentation.)

```
TARGET REPO MODE
  Target  : <absolute path>
  Meta    : <cwd> (skills, memory, CLAUDE.md)
  Edits   : absolute paths under target
  Bash    : prefix with `cd "$TARGET" && ...` or use absolute paths
  Git     : `git -C "$TARGET" ...`
```

## Operational contract when target mode is active

1. **File edits** use absolute paths under `<target>`. Edit tool calls pass an absolute path; do NOT use cwd-relative paths.
2. **Bash commands** either prefix with `cd "<target>" && <command>` or use absolute paths. Absolute paths are preferred per the global Bash discipline, but the `cd` form is acceptable for tools that read config from cwd (npm scripts, build tools that read `package.json` from cwd, etc.).
3. **Git operations** use `git -C "<target>" <subcommand>`. The cwd's own git is not touched unless the task is explicitly about the meta-stack repo.
4. **Memory** (`~/.claude/projects/<encoded-cwd>/.../memory/MEMORY.md`) continues to load from cwd. Intentional - learnings about role, working patterns, and meta-stack accrue to the cwd-anchored memory regardless of which target you're operating on today.
5. **Friction-log + persistent-memory captures** annotate with `(target: <basename of target>)` for retrievability. Example: `[Friction] (target: foo-service) <description>`. Capture mechanics otherwise unchanged - still dual-write to Open Brain + engram + friction-log.
6. **Target's own CLAUDE.md** — if `<target>/CLAUDE.md` exists, read it and layer it on top of cwd's + global CLAUDE.md. Target's CLAUDE.md governs project specifics; cwd's governs identity, workflow, skill discipline. Conflicts: target wins for code in that target.
7. **PII discipline** from cwd's CLAUDE.md still applies. If cwd is a publishable repo with strict PII rules, those rules apply to edits anywhere - including the target.

## Cross-session coverage

| Scenario | Auto-restored? |
|---|---|
| `/clear` in same session | Yes (UUID unchanged) |
| Quit + resume Claude, same terminal tab | Yes |
| Quit + resume Claude, different terminal | Yes |
| Multiple concurrent sessions, only one with target | Yes |
| Multiple concurrent sessions, both with different targets | Yes (each UUID has own binding) |
| Renamed Claude session | Yes (rename is display-only; .jsonl filename stays as UUID) |
| Brand new session, never set | No - user must invoke `/target-repo <path>` once |

## Interactions with other skills

- **dev-orchestrator**: when target mode is active, dev-orchestrator reads project context (CLAUDE.md, milestones, git history) from `<target>` instead of cwd.
- **session-wrap**: PENDING_TASKS.md is written to `<target>/PENDING_TASKS.md`; friction-log entries get `(target: <name>)` annotation.
- **verify-before-done**: verification commands run against `<target>`.
- **comprehension-gate, deep-plan, debug, ship**: all operate on `<target>`.

These skills should invoke `~/.claude/scripts/target-repo-check.sh --get` at entry. If the output is non-empty, scope to that path; otherwise behave as cwd-only.

## Race-condition note

In the rare case of two Claude sessions in the same project starting within milliseconds, `ls -t` may briefly return the wrong session's UUID. Manifest: a session sees the other session's target or no target where one was set. Recovery: run `/target-repo <path>` to rewrite the binding for the correctly-resolved UUID. Sentinel-based bulletproofing is on the TODO list if the race becomes annoying in practice.

## Cleanup

Old binding files accumulate as Claude sessions are deleted but their UUID-keyed `~/.claude/target-repo/<uuid>.md` files remain. There is no automatic GC today. If the directory grows unwieldy, manually clean:

```bash
# List bindings whose UUIDs no longer have a corresponding .jsonl anywhere
for f in ~/.claude/target-repo/*.md; do
  uuid="$(basename "$f" .md)"
  find ~/.claude/projects -name "${uuid}.jsonl" -print -quit | grep -q . || echo "stale: $f"
done
```

A `--gc` mode is on the TODO list.

## See also

- `~/.claude/scripts/target-repo-check.sh` - the helper that does the actual work
- `~/.claude/scripts/pii-patterns.conf` + `~/.claude/scripts/pii-scan.sh` - PII discipline that applies even in target mode
- Global CLAUDE.md "Target Repo Mode" section - the contract for any session
- `~/.claude/friction-log.md` - friction loop, gets target-annotated entries when active
