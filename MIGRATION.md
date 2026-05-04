# Migration & Scrub Procedure

This doc covers two related flows:
1. Multi-machine sync after rewriting git history.
2. The PII-scrub procedure itself (applicable to this repo, your-meta-repo, your-data-repo,
   or any other personal repo with the same `.scrub/` + `~/.config/devkit/`
   conventions).

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

3. **In the repo on the chosen machine:**
   ```bash
   cd <repo>
   cp .scrub/replacements.example.txt .scrub/replacements.txt
   # Edit replacements.txt — fill in your literal PII strings on the LEFT side.
   # The example file shows the shape; you replace the placeholders with
   # actual strings from your repo.
   ```

4. **Dry run first** to validate setup:
   ```bash
   ~/.claude/scripts/scrub-pii-history.sh . --dry-run
   ```
   Verify the LEFT-side strings reported match what you intend to scrub.

5. **Run the scrub:**
   ```bash
   ~/.claude/scripts/scrub-pii-history.sh . --confirm
   ```
   The script:
   - Creates `backup/pre-scrub-YYYYMMDD-HHMM` branch
   - Runs `git filter-repo --replace-text .scrub/replacements.txt --force`
   - Verifies no LEFT-side string remains in history or working tree
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

### On each remaining machine

For each repo (do them in the same order you scrubbed them):

1. **Verify clean working tree first** — anything uncommitted will be lost.
   ```bash
   cd <repo>
   git status
   ```

2. **Fetch and hard-reset:**
   ```bash
   git fetch
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
