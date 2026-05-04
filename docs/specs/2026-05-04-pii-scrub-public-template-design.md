# PII Scrub & Public-Template Design

**Date:** 2026-05-04
**Scope:** dotfiles, your-meta-repo, your-data-repo
**Status:** Design (pre-implementation)

## Problem

Three personal repos currently hold PII (real name, personal + work emails, employer organization names, GPG signing key, hardcoded user-specific paths, employer-specific terminology). The repos should be publishable as forkable templates that any developer can clone, run, and personalize for themselves. PII must be removed from current files AND from git history. The procedure must be replicable across all three repos and survive a multi-machine personal workflow (personal laptop + work laptop, possibly more).

## Goals

1. **Public-template publishability** — anyone can fork without inheriting the original maintainer's identity.
2. **Unified personalization layer** — a single config location (`~/.config/devkit/identity.json`) consumed by all three repos.
3. **Replicable scrub procedure** — identical workflow per repo, driven by a per-repo `replacements.txt` and a single shared script.
4. **Multi-machine resilience** — original maintainer can sync rewritten history to all their machines without losing personalization.
5. **Audit transparency** — committed `.example` files document the shape of what gets scrubbed; forkers can use them as a model.

## Non-Goals

- Rewriting commit author/committer metadata (commits keep their original `Author` line).
- Removing the GitHub username from the repo URL itself.
- Removing GitHub's cached old commit SHAs (deferred; can file a Support GC request post-hoc if needed).
- Migrating your-meta-repo or your-data-repo to chezmoi (they remain plain git repos).

## Architecture (5 components)

1. **Identity contract** — JSON schema + canonical location, source of truth for the maintainer's identity.
2. **Identity loader** — shell script in dotfiles that reads the JSON and exports env vars, callable from any repo.
3. **PII scrub procedure** — per-repo `replacements.example.txt` (committed) + `replacements.txt` (gitignored) + history rewrite via `git filter-repo --replace-text`.
4. **Scrub script** — single copy in dotfiles, invoked with a target repo path; handles backup, rewrite, verification.
5. **Migration documentation** — `MIGRATION.md` in dotfiles explaining the multi-machine sync flow.

## 1. Identity Contract

**Path:** `~/.config/devkit/identity.json`. XDG-compliant. The `devkit/` directory matches the convention of vendor-named neighbors in `~/.config/` (`gh/`, `git/`, `chezmoi/`, `vercel-plugin/`, etc.) — specific enough that future tools are unlikely to squat the name, generic enough that a forker reads "devkit" and immediately understands "personal developer toolkit configuration."

**Future extensibility (out of scope for this spec, but the directory anticipates it):** the `devkit/` namespace is intentionally broader than identity alone. Categories that may plausibly join later, each as a sibling JSON file, include: `projects.json` (active project registry — could subsume the current `dot_claude/scopes/` pattern), `references.json` (external system pointers like Open Brain URL, Linear workspace, dashboards), `preferences.json` (cross-tool defaults — Claude model, editor, verbosity), and a markdown form of the BYOC working-identity narrative (`working-identity.md`) currently at `~/.claude/working-identity.md`. **None of these are designed or implemented in this spec.** They are listed here only to justify the directory naming choice — flat layout (`devkit/<category>.json`), env-var prefix `DEVKIT_<CATEGORY>_*`, no premature subdirectories. When a future category genuinely outgrows one file, that category alone becomes a subdirectory.

**Schema:**

```json
{
  "full_name": "Your Name",
  "email_personal": "you@example.com",
  "email_work": "",
  "github_username": "your-gh-username",
  "gpg_signing_key": "",
  "work_gh_orgs": []
}
```

| Field             | Required | Used For                                              |
| ----------------- | -------- | ----------------------------------------------------- |
| `full_name`       | yes      | gitconfig `user.name`, skill author fields            |
| `email_personal`  | yes      | gitconfig `user.email` on personal machine            |
| `email_work`      | no       | gitconfig `user.email` on work machine                |
| `github_username` | yes      | path templating, repo references                      |
| `gpg_signing_key` | no       | gitconfig `user.signingkey` (commits unsigned if empty) |
| `work_gh_orgs`    | no       | gitconfig `includeIf` rules for work-org repo paths   |

**Source of truth:** `~/.config/devkit/identity.json` is the single canonical artifact. Chezmoi reads it at apply time via `include` + `fromJson` and uses the values in templated files (gitconfig, etc.) — chezmoi does NOT store its own copy of these values in `~/.config/chezmoi/chezmoi.toml`. This avoids divergence: editing the JSON updates everything on the next `chezmoi apply`.

**Bootstrap (first-time setup, when the JSON file does not yet exist):**
- **dotfiles users (chezmoi):** on first `chezmoi init`, prompts capture each field. The prompts write directly to `~/.config/devkit/identity.json` via a one-shot bootstrap step (either a chezmoi `run_once_` hook script or a `script_` template that writes the JSON if absent). After bootstrap, prompts are not asked again — the JSON file is the source.
- **forkers without chezmoi:** copy `devkit-identity.example.json` from any of the three repos to `~/.config/devkit/identity.json`, edit by hand. dotfiles also ships `setup-identity.sh` that prompts for the same fields and writes the JSON directly.

**Updating values after bootstrap:** edit `~/.config/devkit/identity.json` directly with any text editor, then re-run `chezmoi apply` (in dotfiles) so dependent files like gitconfig regenerate. No re-prompting needed.

**Validation:** identity loader (next section) checks file existence + required fields. Missing → fail loudly with setup pointer, never default silently.

**Committed in each repo:** `devkit-identity.example.json` (placeholder values, schema documentation).

## 2. Identity Loader

**Path:** `~/.claude/scripts/load-identity.sh` (managed by chezmoi at source `dot_claude/scripts/executable_load-identity.sh`).

**Behavior:**
- Reads `~/.config/devkit/identity.json`.
- Exports env vars: `DEVKIT_IDENTITY_FULL_NAME`, `DEVKIT_IDENTITY_EMAIL_PERSONAL`, `DEVKIT_IDENTITY_EMAIL_WORK`, `DEVKIT_IDENTITY_GITHUB_USERNAME`, `DEVKIT_IDENTITY_GPG_SIGNING_KEY`, `DEVKIT_IDENTITY_WORK_GH_ORGS` (space-separated). The `DEVKIT_<CATEGORY>_*` prefix scheme leaves room for future devkit configs (e.g., `DEVKIT_PROJECTS_*` from a future `devkit/projects.json`) without env-var collisions.
- Validates required fields non-empty; missing → print pointer to `~/.config/devkit/identity.json` setup section in dotfiles README, exit 1.
- Idempotent (re-running just re-exports).

**Consumer pattern:**
- Skills/scripts that need identity values: `source ~/.claude/scripts/load-identity.sh` then read the env vars.
- Templates (chezmoi `.tmpl`): use chezmoi data directly, since chezmoi data mirrors the JSON.
- your-meta-repo / your-data-repo: invoke via absolute path; document the dependency in their READMEs ("expects `~/.config/devkit/identity.json`; see dotfiles for setup").

## 3. PII Scrub Procedure

**Per-repo file convention:**
- `.scrub/replacements.example.txt` (committed) — placeholder shape, e.g., `<your-real-name>==>YOUR_NAME`. Documents what categories of PII the repo scrubs.
- `.scrub/replacements.txt` (gitignored via `.scrub/.gitignore`) — actual literal PII strings, used at scrub-time only.
- `.scrub/.gitignore` (committed) — single line `replacements.txt`.

**Format:** `git filter-repo --replace-text` syntax. One rule per line:
```
<find-string>==><replace-string>
```
Use `regex:<pattern>==><replacement>` for regex rules.

**Example `replacements.txt` for dotfiles** (forker-facing template lives in `replacements.example.txt`; this is what the maintainer's local file looks like at scrub-time):

```
YOUR_NAME==>YOUR_NAME
REMOVED-EMAIL==>REMOVED-EMAIL
REMOVED-EMAIL==>REMOVED-EMAIL
REMOVED-GPG-KEY==>REMOVED-GPG-KEY
example.com==>example.com
your-org==>your-org
your-org==>your-org
your-org==>your-org
EVM smart contracts==>EVM smart contracts
$HOME/==>$HOME/
```

**Note:** `kpachhai` (GitHub username) is NOT in the replacements list. It remains in the repo URL and in path strings; this is documented as a non-goal.

## 4. Scrub Script

**Path:** `~/.claude/scripts/scrub-pii-history.sh` (source: `dot_claude/scripts/executable_scrub-pii-history.sh`).

**Usage:** `scrub-pii-history.sh <repo-path> [--confirm] [--dry-run]`

**Behavior:**

1. **Sanity checks:**
   - `<repo-path>/.scrub/replacements.txt` exists and is non-empty.
   - Working tree clean (`git status --porcelain` empty). Refuse otherwise.
   - `git filter-repo` is installed (suggest `brew install git-filter-repo` on failure).

2. **Safety gate:**
   - Refuse to proceed without `--confirm`.
   - `--dry-run` runs everything except the actual `filter-repo` call.

3. **Backup:**
   - Create branch `backup/pre-scrub-$(date +%Y%m%d-%H%M)` pointing at current HEAD.
   - Print the branch name; user can manually push it for off-machine backup if desired.

4. **Rewrite:**
   - Run `git filter-repo --replace-text .scrub/replacements.txt --force`.

5. **Verify:**
   - For each LEFT-side string in `replacements.txt`, run `git log -p --all -S <string>`. Any match = scrub failed; print the offending commit and exit non-zero.
   - Same check against working tree.
   - Print summary: N rules applied, M commits rewritten, 0 PII matches remaining.

6. **Force-push checklist:**
   - Print, but do NOT execute, the next-step commands:
     - `git push --force-with-lease origin main`
     - `git push origin backup/pre-scrub-...`  (optional remote backup)
     - On every other machine: `git fetch && git reset --hard origin/main`
   - Exit 0.

**Never auto-pushes.** Force-push is the user's manual decision.

## 5. Migration Documentation

**Path:** `dotfiles/MIGRATION.md`.

**Contents:** copy-pasteable commands for the multi-machine flow. See section "Multi-Machine Migration Flow" below for the full recipe.

## Per-Repo Changes

### dotfiles

**New files:**
- `MIGRATION.md` — the multi-machine flow.
- `devkit-identity.example.json` — schema example at repo root.
- `.scrub/replacements.example.txt` — scrub shape, repo root.
- `.scrub/.gitignore` — contains `replacements.txt`.
- `dot_claude/scripts/executable_load-identity.sh` — identity loader.
- `dot_claude/scripts/executable_scrub-pii-history.sh` — scrub script.
- `dot_claude/scripts/executable_setup-identity.sh` — non-chezmoi bootstrap (prompts + writes JSON).
- `run_once_after_bootstrap-identity.sh.tmpl` — chezmoi run-once hook (executes once per machine on first apply): if `~/.config/devkit/identity.json` does NOT exist, prompts for fields and writes the file. If it exists, no-op.

**Modified files:**
- `.chezmoi.toml.tmpl` — keep `machine_type` prompt only. Identity prompts are NOT in chezmoi data; they live in `~/.config/devkit/identity.json` via the run-once bootstrap script.
- `dot_gitconfig.tmpl` — read identity values via chezmoi `include` + `fromJson` from `~/.config/devkit/identity.json` at apply time. No literal name/email/key.
- `dot_gitconfig-personal` → `dot_gitconfig-personal.tmpl` — render `email = {{ .email_personal }}`.
- `dot_gitconfig-work` → `dot_gitconfig-work.tmpl` — render `email = {{ .email_work }}`.
- `README.md` — rewrite as fork-and-personalize guide; remove personal framing; document the identity contract + setup steps for chezmoi and non-chezmoi paths.
- `dot_claude/CLAUDE.md` — strip personal name + employer references while keeping all generic role + working-style content. Specifically: line 5 changes from "I'm YOUR_NAME - **Solutions Architect** by role" to "I'm a Solutions Architect by role"; remove employer-specific includeIf-org names from any prose; in Subagents section, change "Smart contracts and EVM smart contracts" to "Smart contracts (EVM)". The Hedging Discipline / Skill Discipline / Session Management / Token Discipline / etc. sections all stay verbatim — they are role-portable.
- `dot_claude/skills/learn-and-improve/SKILL.md` — drop `**Author:** ...` line.
- `dot_claude/skills/working-identity/SKILL.md` — drop `author:` frontmatter field.
- `dot_claude/agents/solidity-engineer.md` — replace 4× "EVM smart contracts" references with generic EVM phrasing (or drop entirely if context-specific).
- `dot_claude/scopes/meta-stack.txt` — remove user-specific paths (`your-org/*`, `kpachhai/*` lines). The committed file becomes either empty (just a comment header) or contains only paths that genuinely apply to any forker. User-specific paths move to `meta-stack.local.txt` (gitignored, machine-local).
- `iterm2/com.googlecode.iterm2.plist` — replace `$HOME` with `$HOME` if the plist supports env-var expansion; otherwise mark this file as a known pre-personalization file in README.
- `.gitignore` — add `replacements.txt` (alongside existing `*.local.*` rule).

### your-meta-repo

(Detailed scan happens at scrub-time for this repo. Generic shape:)

**New files:**
- `.scrub/replacements.example.txt`
- `.scrub/.gitignore`
- `devkit-identity.example.json` (or pointer to dotfiles')
- README section explaining identity dependency.

**Modified files:**
- `README.md` — generic project description, no personal narrative.
- `CLAUDE.md` if present — strip identity, reference `~/.config/devkit/identity.json`.
- Any markdown content with PII — handled in bulk by the scrub via `replacements.txt`.

### your-data-repo

Same shape as your-meta-repo.

## Multi-Machine Migration Flow

(Documented in `dotfiles/MIGRATION.md`.)

### Pre-scrub checklist (run on every machine)

1. `git status` clean in dotfiles, your-meta-repo, your-data-repo.
2. All WIP committed and pushed to GitHub.
3. Note which machine has the most recent commits (do the scrub there).

### Scrub day (on the chosen machine)

For each repo, in order **dotfiles → your-meta-repo → your-data-repo**:

1. `cd <repo>`
2. Copy `.scrub/replacements.example.txt` to `.scrub/replacements.txt`; fill in actual literal PII strings.
3. Run `~/.claude/scripts/scrub-pii-history.sh . --confirm` (use `--dry-run` first if uncertain).
4. Inspect the printed verification summary; backup branch should exist.
5. Force-push: `git push --force-with-lease origin main`
6. Local realign: `git fetch && git reset --hard origin/main` (so local clone matches rewritten history).

For dotfiles specifically, after step 6:
7. Create `~/.config/devkit/identity.json` (chezmoi prompts on first init handle this; or run `~/.claude/scripts/setup-identity.sh`).
8. `chezmoi apply` — regenerates gitconfig with personal data.

### Sync to other machines

For each remaining machine, for each of the three repos:

1. `cd <repo>`
2. `git fetch && git reset --hard origin/main` (replaces local history with rewritten upstream).
3. Verify: `git log --oneline -5` shows new SHAs (different from pre-scrub).

For dotfiles only, additionally:
4. Create `~/.config/devkit/identity.json` on this machine (machine-specific values, e.g., work email on work laptop only).
5. `chezmoi apply`.

### Why `git reset --hard` and not `git pull`?

`git pull` would refuse or merge-conflict because the rewritten history has different SHAs. `reset --hard origin/main` is the correct way to align a local clone with rewritten upstream history. Any uncommitted local changes are LOST — that's why the pre-scrub checklist demands a clean working tree on every machine.

## Verification Gates

**After scrub on each repo:**
- `git log -p --all` piped through `grep -iE 'pachhai|your-org|platform|platform|kiran|REMOVED-GPG-KEY'` returns empty.
- Same grep against the working tree returns empty (excluding `.scrub/replacements.txt` which is gitignored anyway).
- Backup branch `backup/pre-scrub-...` exists.
- `git filter-repo`'s own success messages are clean.

**Before declaring complete on a repo:**
- All `.example` files render correctly when copied + filled in.
- `~/.claude/scripts/load-identity.sh` exits 0 with valid JSON.
- `chezmoi diff` (in dotfiles) shows no surprising changes.

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Force-push destroys history irrecoverably | Backup branch created automatically before scrub; user can also push backup to remote before force-push. |
| Multi-machine clone divergence after force-push | `MIGRATION.md` documents `git reset --hard origin/main` for every machine. Pre-scrub checklist catches WIP first. |
| GPG signatures invalidated on rewritten commits | Accepted — out of scope. Re-signing rewritten history is not worth the complexity. |
| Identity JSON file accidentally committed in your-meta-repo/your-data-repo | `.gitignore` rule + the file lives in `~/.config/`, outside any repo, by convention. |
| Forker forgets to set up identity file before running setup | Identity loader fails loudly with pointer to README setup section. |
| `replacements.txt` itself leaks PII if accidentally committed | `.scrub/.gitignore` committed before `replacements.txt` exists; `.gitignore` rule (`replacements.txt`) is defense-in-depth. |
| Scrub misses a PII string not in `replacements.txt` | Scrub script's verification step greps for sentinel patterns separately from the rules; mismatches fail the run. |

## Open Questions / Deferred

- **Non-chezmoi setup script (`setup-identity.sh`)** — included in the spec; implementation is straightforward (~30 lines). Confirm during implementation if the simpler "copy `.example.json` and edit by hand" path is sufficient.
- **GitHub Support GC request after force-push** — entirely optional; user can decide post-scrub based on whether old SHAs leaking matters for their threat model.
- **iterm2 plist `$HOME` replacement** — depends on whether the plist format supports env-var expansion. If not, the path remains and gets scrubbed via `replacements.txt`; the rendered file on each machine will have the wrong path embedded. Acceptable for a personal preference file; documented as a quirk.

## Implementation Phasing

The implementation plan (next step, via writing-plans) should phase the work as:

1. **Phase 1 — Identity contract + loader** (no destructive changes). Add the new files. Verify chezmoi prompts work, JSON renders, loader exports env vars correctly.
2. **Phase 2 — dotfiles HEAD cleanup** (file edits, no history rewrite). Strip PII from current files, switch gitconfig templates to chezmoi data, update CLAUDE.md/README/skills/agents/scopes. Commit.
3. **Phase 3 — dotfiles scrub script** (no destructive changes; just adding the script). Test against a clone of dotfiles in `--dry-run` mode.
4. **Phase 4 — dotfiles history scrub** (DESTRUCTIVE). Run scrub, force-push, sync other machines.
5. **Phase 5 — your-meta-repo and your-data-repo** (per-repo cleanup + scrub, applying the established procedure).

Phases 1-3 are safe and reversible. Phase 4 onward is destructive and gated by user confirmation at each step.
