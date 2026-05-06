# Migration & Scrub Procedure

This doc covers two related flows:
1. Multi-machine sync after rewriting git history.
2. The PII-scrub procedure itself (applicable to this repo, your-meta-repo, your-data-repo,
   or any other personal repo with the same `.scrub/` + `~/.config/devkit/`
   conventions).

> **Faster path:** the [`scrub-repo`](dot_claude/skills/scrub-repo/SKILL.md) global
> skill (deployed to `~/.claude/skills/scrub-repo/` via chezmoi) automates the
> procedure below, including discovery, rule drafting with correct ordering,
> the dry-run / `--confirm` / re-add-origin / force-push sequence, and
> multi-machine sync commands. Invoke it inside Claude Code with phrases like
> "scrub this repo" or "remove `<string>` from history". The manual procedure
> below remains the reference for what the skill is doing under the hood.

---

## PII Scrub Procedure

Use this when preparing a repo for public publication, or when removing
PII that was committed by accident at any point in history.

### One-time setup (per machine)
- Install dependencies: `brew install git-filter-repo jq`
- Create `~/.config/devkit/identity.json` if you have not already
  (chezmoi prompts on first apply, or run `~/.claude/scripts/setup-identity.sh`)

### Per-repo scrub

1. **Confirm clean state on every machine.** Every machine that has the repo
   cloned must have a clean working tree and all WIP pushed to GitHub. The
   force-push at the end will diverge from any local clone with uncommitted
   work and that work will be lost.

2. **Note which machine has the latest commits.** Run the scrub on that machine.

3. **In the repo on the chosen machine — fill in scrub config:**

   **`.scrub/replacements.txt`** is required (file-content rules):
   ```bash
   cd <repo>
   cp .scrub/replacements.example.txt .scrub/replacements.txt
   # Edit replacements.txt — fill in your literal PII strings on the LEFT side.
   ```

   **`.scrub/mailmap`** is optional (rewrites Author/Committer email + name):
   ```bash
   cp .scrub/mailmap.example.txt .scrub/mailmap
   # Edit mailmap — one line per identity to collapse:
   #   New Name <new@email> <old@email>
   ```

   **`.scrub/message-replacements.txt`** is optional (rewrites commit-message
   text — most commonly Signed-off-by trailers, which `--mailmap` does NOT
   touch on its own):
   ```bash
   cp .scrub/message-replacements.example.txt .scrub/message-replacements.txt
   # Edit — one line per rule:
   #   old@email==>new@email
   ```

   All three files are gitignored. Only the `.example.txt` siblings are
   committed.

4. **Dry run first** to validate setup:
   ```bash
   ~/.claude/scripts/scrub-pii-history.sh . --dry-run
   ```
   The dry-run reports: LEFT-side content rules, mailmap email mappings (if
   present), message-replacement rules (if present). Verify each looks right.

5. **Run the scrub:**
   ```bash
   ~/.claude/scripts/scrub-pii-history.sh . --confirm
   ```
   The script:
   - Creates `backup/pre-scrub-YYYYMMDD-HHMM` branch
   - Runs `git filter-repo --replace-text .scrub/replacements.txt`
     plus `--mailmap` and `--replace-message` if those files exist
   - Verifies no LEFT-side content string remains in working tree or history
   - Verifies no OLD email from mailmap/message-replacements survives in
     Author/Committer/commit-message fields
   - Prints next-step instructions; does not push

6. **Inspect the rewrite:**
   ```bash
   git log --oneline | head -10
   # SHAs differ from before
   git log -p | grep -iE '<your-PII-pattern>' || echo "clean"
   ```

7. **Force-push:**
   ```bash
   git push --force-with-lease origin main
   ```
   Optionally push the backup branch as a remote safety net:
   ```bash
   git push origin backup/pre-scrub-YYYYMMDD-HHMM
   ```

8. **Realign the local clone with rewritten history:**
   ```bash
   git fetch
   git reset --hard origin/main
   ```

---

## Multi-Machine Sync (after a force-push)

After force-pushing rewritten history, every other machine that has the repo
cloned needs to align its local clone.

> **Do NOT use `git pull` on other machines.** After the force-push, the
> remote history shares no common ancestor with the local clone, and
> `git pull` (which tries to merge) fails with
> `fatal: refusing to merge unrelated histories`. The fix is a hard
> reset, not a merge - see commands below.

### On each remaining machine

For each repo (do them in the same order you scrubbed them):

1. **Verify clean working tree first** — anything uncommitted will be lost
   by the hard reset. If you have local work to preserve, stash it
   (`git stash push -m 'pre-scrub-rescue'`); after the reset, inspect
   `git stash show -p` and cherry-pick what's still worth keeping.
   ```bash
   cd <repo>
   git status --porcelain   # must be empty before continuing
   ```

2. **Fetch and hard-reset (NOT `git pull`):**
   ```bash
   git fetch origin
   git reset --hard origin/main
   ```

3. **Verify alignment:**
   ```bash
   git log --oneline | head -5
   # SHAs match the post-scrub state from the scrub machine
   ```

4. **For dotfiles only** — if `~/.config/devkit/identity.json` does not yet
   exist on this machine, create it:
   - With chezmoi: re-run `chezmoi apply`. The bootstrap script prompts.
   - Without chezmoi: run `~/.claude/scripts/setup-identity.sh`.

5. **For dotfiles only** — re-apply chezmoi so gitconfig and other templated
   files render with this machine's identity values:
   ```bash
   chezmoi apply
   ```

---

## Troubleshooting

**"working tree is dirty"** — commit or stash, then retry.

**"backup branch already exists"** — a previous scrub attempt left a backup.
Inspect it (`git log backup/pre-scrub-...`); if safe, delete with
`git branch -D backup/pre-scrub-...` and re-run.

**"residual matches found" after scrub** — one or more LEFT-side strings
still appear somewhere. The script reports which. Restore from backup:
```bash
git reset --hard backup/pre-scrub-YYYYMMDD-HHMM
```
Add the missed pattern to `.scrub/replacements.txt` and re-run.

**Force-push rejected** — branch protection on GitHub. Disable temporarily,
push, re-enable. Or push to a new branch and switch the default.

**Old commit SHAs still resolve on GitHub after force-push** — GitHub's
internal cache. They become unreachable after their internal GC (timing
varies). For sensitive cleanup, contact GitHub Support to request expedited
GC.
