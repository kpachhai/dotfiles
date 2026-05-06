---
name: scrub-repo
description: Use when removing PII (employer brands, real names, emails, hardcoded paths, leaked secrets, internal-only project names) from a git repo's working tree AND its entire history before publishing or sharing. Triggers on "scrub this repo", "remove from git history", "make this public", "wipe leaked secret", "force-push after rewriting", "purge employer name from history". Wraps `~/.claude/scripts/scrub-pii-history.sh` (which uses `git filter-repo --replace-text`) plus the `.scrub/` toolkit. Orchestrates the full workflow: discovery -> working-tree fix -> commit -> dry-run -> confirm -> re-add origin -> force-push -> multi-machine sync notes. Never force-pushes without explicit user authorization.
---

# Scrub Repo

## Purpose

Removing PII from a git repo is a sequence of small steps with sharp edges between them. Miss one and either the scrub fails verification, or worse, the rewritten history still contains the strings you tried to remove. This skill codifies the full workflow that the underlying `scrub-pii-history.sh` script + `.scrub/` toolkit do not orchestrate by themselves.

The script handles the destructive `git filter-repo` step. This skill handles everything around it: discovering what to scrub, fixing the working tree first (the script's verifier requires the post-scrub state to already be in HEAD), drafting `.scrub/replacements.txt` with correct rule ordering, gating the force-push, and giving the user the multi-machine realignment commands.

**This is a global skill** - works against any git repo with public-publication intent.

## When To Use

- Preparing a private repo for first public release
- Removing a string that leaked into an old commit (employer name, real name, email, API key, internal-only project name, hardcoded `/Users/<name>/` path)
- Repository hygiene after switching employers, before forking, or before transferring ownership
- User says "scrub the repo", "remove X from history", "make this public", "force-push after rewriting", "I committed an email by accident"

## When NOT To Use

- The PII is only in HEAD, never in any prior commit. A normal commit + push is enough; do not rewrite history.
- The repo has many active collaborators. Coordinate with them first; force-push will diverge every clone.
- The user wants to *delete files entirely* from history (rather than rewrite text). Use `git filter-repo --invert-paths` directly, not this skill.
- Trivial single-token typo fixes that did not leak anything sensitive.

## Required Tools

- `git-filter-repo` (`brew install git-filter-repo` on macOS)
- `jq` (used by neighboring scripts; `brew install jq`)
- The scrub script at `~/.claude/scripts/scrub-pii-history.sh` (deployed by chezmoi from this repo's `dot_claude/scripts/`)
- The `.scrub/` example files in the target repo (or a sibling, see Step 3)

If any are missing, surface the install commands and stop.

## Process

### Step 1: Confirm scope and pre-flight state

Ask the user, then verify:

1. **What is the scrub target?** Names, emails, employer brands, internal project names, hardcoded paths, leaked secrets, all of the above. Capture the literal strings the user wants gone.
2. **Single-machine or multi-machine?** If the repo is cloned on more than one machine, every other clone needs `git fetch && git reset --hard origin/<branch>` after the force-push. Have the user list those machines so the post-scrub instructions are concrete.
3. **Branch strategy.** Either (a) work directly on `main` (faster, fewer round-trips) or (b) feature branch + PR review then scrub `main`. (a) is fine when the user is the sole maintainer; (b) is safer when others might pull mid-rewrite. Confirm before proceeding.
4. **Backup.** Note the current `HEAD` SHA and confirm the repo has at least one tag or release (the user mentioned today's case: a v0.1.0 tag was their backup before the destructive run).

Verify clean working tree: `git status --porcelain` must be empty before continuing.

### Step 2: Discovery - what is actually in the repo?

Grep the working tree AND history for candidate strings:

```bash
# Working tree (literal strings, case-insensitive):
git grep -nIi -- "<candidate>" || echo "(none in HEAD)"

# History (pickaxe - finds any commit that added or removed the string):
git log --all -p -S "<candidate>" --oneline | head
```

Run this for every string the user named in Step 1. Also run it for common PII patterns the user did NOT name explicitly but might have leaked:

- `kpachhai` and `kiranpachhai` (or whatever appears in `~/.config/devkit/identity.json` `username_personal` / `username_work` fields, if that file exists)
- The user's real name (`identity.json` `full_name`)
- Both personal and work email (`identity.json` `email_personal` / `email_work`)
- GPG signing key fingerprint
- Any `/Users/<name>/` paths
- Any internal-only project, repo, or org names known to the user

Report findings to the user as a candidate list. Ask which to include and whether to add any not found by grep but still worth scrubbing pre-emptively.

### Step 3: Fix the working tree FIRST, then commit

The scrub script's verifier fails if any LEFT-side string in `replacements.txt` still appears in the working tree post-rewrite. So the working tree must already be in the desired post-scrub state before `filter-repo` runs.

For each candidate string, do the working-tree edit:

- File-content edits (most common): use `Edit` / replace_all on the affected files.
- File renames: `git mv old new`. Then update content references inside the renamed files.
- File deletions: `git rm path` for files that should not exist publicly at all (e.g., a personalized profile that was committed by mistake).

If the change is non-trivial, this is the place to invoke `deep-plan` to enumerate every file and rule before touching anything. Today's `team-digest` scrub had ~21 files and 328 occurrences; deep-plan caught risks (rule-ordering, partial-match traps for `Hashgraph`/`hashgraph`) that a one-shot edit pass would have missed.

After the edits, run a final residual check on tracked files only:

```bash
grep -riE 'pattern1|pattern2|pattern3' --include='*.md' --include='*.sh' --include='*.json' . 2>&1 | grep -v '^Binary'
```

When clean, commit with `-S -s`:

```bash
git add -A
git commit -S -s -m "<scope-honest message describing the rename + content scrub>"
```

If working on a feature branch, push it now: `git push -u origin <branch>`. If working directly on main, do not push yet - the next phase will scrub history and force-push will replace whatever is on origin.

### Step 4: Set up `.scrub/` config

If the repo does not have a `.scrub/` directory, copy the examples from the dotfiles repo (or any sibling repo that already has them):

```bash
mkdir -p .scrub
cp ~/repos/github.com/kpachhai/dotfiles/.scrub/replacements.example.txt .scrub/replacements.example.txt
cp ~/repos/github.com/kpachhai/dotfiles/.scrub/message-replacements.example.txt .scrub/message-replacements.example.txt
cp ~/repos/github.com/kpachhai/dotfiles/.scrub/mailmap.example.txt .scrub/mailmap.example.txt
echo '.scrub/' >> .git/info/exclude   # local exclude; the .example files stay tracked, the actual configs are gitignored by .gitignore patterns
```

Author `replacements.txt`. Two ordering rules are load-bearing:

1. **Longer phrases before shorter substrings.** If you scrub `Solutions Architect team` to `team` AND `Solutions Architect` to `team`, list the longer rule FIRST. Otherwise the shorter rule fires first and corrupts the longer match into `team team`.
2. **Case-sensitive by default.** `git filter-repo --replace-text` is literal. To handle both `hashgraph` (lowercase, often org/URL form) and `Hashgraph` (capitalized, often brand mention), write two separate rules. Do NOT assume case-insensitivity.

If author/committer emails or commit-message text need rewriting, also create `.scrub/mailmap` (Author/Committer) and `.scrub/message-replacements.txt` (commit subject + body, including Signed-off-by trailers that mailmap does not touch).

Show the user the final `.scrub/replacements.txt` for sign-off before any rewrite step.

### Step 5: Dry-run

```bash
~/.claude/scripts/scrub-pii-history.sh <repo-path> --dry-run
```

Verify the dry-run output: rule count matches expectation, mailmap mappings render correctly, message-replacements list is right.

If the dry-run fails with `unbound variable: mailmap_args[*]` on macOS bash 3.2, the deployed script is older than the bundled fix. Re-run `chezmoi apply` from the dotfiles repo to refresh, then retry. (The fix changes `${mailmap_args[*]}` to `${mailmap_args[*]:-}` and `"${mailmap_args[@]}"` to `${mailmap_args[@]+"${mailmap_args[@]}"}` for set-u-safe expansion of empty arrays.)

### Step 6: --confirm run

```bash
~/.claude/scripts/scrub-pii-history.sh <repo-path> --confirm
```

The script:
- Creates `backup/pre-scrub-YYYYMMDD-HHMM` branch as a safety net
- Runs `git filter-repo` with the rules (and mailmap / message-replacements if present)
- Strips the `origin` remote (filter-repo's intentional default to prevent accidental push)
- Verifies no LEFT-side string remains in any commit's content or message

If verification fails, the script exits 1 and prints the residual matches. Restore: `git reset --hard backup/pre-scrub-YYYYMMDD-HHMM`. Add the missed pattern to `replacements.txt` and re-run.

### Step 7: Re-add origin

```bash
git remote add origin <ssh-url>     # e.g., git@github.com:<user>/<repo>.git
git fetch origin <branch>            # populate refs/remotes/origin/<branch> for --force-with-lease
```

Without the fetch, `--force-with-lease` will refuse because the local remote-tracking ref does not exist.

### Step 8: PAUSE for force-push authorization

Force-pushing to `main` (or any default branch) is the irreversible step. Stop and confirm with the user explicitly. State:

- The remote SHAs about to be replaced
- The new SHAs that will become the canonical history
- The list of other machines (from Step 1) that will need realignment

Do NOT proceed without explicit "yes push it" from the user, even in auto mode. Per the global rule, force-push is an authorization gate that auto mode does not satisfy.

### Step 9: Force-push

```bash
git push --force-with-lease=<branch>:<old-sha> origin <branch>
```

Pinning the lease to the known old SHA is safer than `--force-with-lease` alone - it means "fail if the remote moved from this exact SHA," which is what we actually want.

Optionally push the backup branch as a remote safety net:

```bash
git push origin backup/pre-scrub-YYYYMMDD-HHMM
```

If the user had a feature branch (Step 1, option b), delete it now:

```bash
git push origin --delete <feature-branch>
git branch -D <feature-branch>
```

### Step 10: Multi-machine sync

For every other machine the user listed in Step 1, give them the exact commands to run on that machine:

```bash
cd <repo>
git status                            # must be clean; uncommitted work will be lost
git fetch
git reset --hard origin/<branch>
git log --oneline | head -3           # verify SHAs match the new post-scrub history
```

For dotfiles specifically: also re-run `chezmoi apply` after the reset so any templated files re-render with this machine's `~/.config/devkit/identity.json` values.

### Step 11: Cleanup (optional, deferred)

Once the user has confirmed the rewrite is good across all machines:

```bash
git branch -D backup/pre-scrub-YYYYMMDD-HHMM             # delete local backup
git push origin --delete backup/pre-scrub-YYYYMMDD-HHMM  # delete remote backup
```

Do NOT do this in the same run as the scrub. The backup is the rollback path; keep it for a few days.

## Anti-Patterns and Gotchas

- **Do not commit `.scrub/replacements.txt`.** The LEFT-side strings in that file are the very PII you are removing. The script's verifier explicitly excludes `.scrub/replacements.txt` from its grep, and `.gitignore` should cover it - but defense-in-depth, also add to `.git/info/exclude`.
- **Do not run scrub on a dirty working tree.** The script refuses, but worth saying. Stash or commit first.
- **Do not skip the dry-run.** It catches malformed rules, missing files, and the bash-3.2 array bug if present. Cheap insurance.
- **Do not use `--force` instead of `--force-with-lease`.** `--force` silently overwrites concurrent pushes from other machines. Always pin the lease.
- **Do not assume the rules are case-insensitive.** They are not. `Hashgraph` and `hashgraph` are different rules.
- **Do not use a regex-prefixed rule unless you've tested it.** The verifier skips regex rules, so a bad regex can leave residuals that the script reports as clean. If the user wants a regex, double-check the post-scrub repo manually with `git log -p | grep` before declaring done.
- **GPG signatures on rewritten commits are stripped by filter-repo.** The script does not re-sign. If signed history is required, run an additional pass:
  `git rebase --exec 'git commit --amend --no-edit -S -s' --root` (slow on large repos; consider whether unsigned historical commits + signed new commits is acceptable).
- **`Hedera`, `Hiero`, `HIP`, `HTS`, `HCS` are NOT PII** per the global PII Discipline rule. Do not scrub these unless the user explicitly asks. They are open-source protocol/spec names.

## Reference

- Manual procedure: [`MIGRATION.md`](../../../MIGRATION.md) in the dotfiles repo - the deep-dive doc this skill automates.
- Underlying script: `~/.claude/scripts/scrub-pii-history.sh` (source: `dot_claude/scripts/executable_scrub-pii-history.sh` in dotfiles).
- Example config: `.scrub/replacements.example.txt`, `.scrub/mailmap.example.txt`, `.scrub/message-replacements.example.txt` in the dotfiles repo.
- Related global skills: `deep-plan` (use it in Step 3 for non-trivial scrubs), `verify-before-done` (use it before Step 8 to confirm the rewrite is clean).

## Source

Operationalized from the workflow we ran on `kpachhai/team-digest` on 2026-05-05. That run revealed (a) the working-tree-first sequencing requirement, (b) the rule-ordering rule for partial overlaps, (c) the case-sensitive `Hashgraph`/`hashgraph` trap, (d) the bash 3.2 empty-array bug in the script (now patched), and (e) the importance of the `--force-with-lease=branch:sha` pin for safety. Each of those became a step in this skill.

---

**Version:** 1.0.0
