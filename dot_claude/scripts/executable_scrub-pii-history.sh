#!/usr/bin/env bash
# Scrubs PII from a git repo's history using git-filter-repo --replace-text.
# Usage: scrub-pii-history.sh <repo-path> [--confirm] [--dry-run]
#
# Safety:
# - Refuses if working tree dirty
# - Requires --confirm flag (prevents accidental runs)
# - Creates a backup branch before rewriting
# - Verifies post-rewrite that no LEFT-side string remains in history
# - Never pushes; prints a force-push checklist at the end

set -euo pipefail

usage() {
    cat <<USAGE
Usage: $0 <repo-path> [--confirm] [--dry-run]

Reads <repo-path>/.scrub/replacements.txt and rewrites the repo's history
to apply each find/replace rule across all commits.

Flags:
  --confirm   Required for destructive run.
  --dry-run   Run all checks + create backup branch, but skip the actual
              filter-repo invocation. Useful for verifying setup.

Required tools: git, git-filter-repo (https://github.com/newren/git-filter-repo).
USAGE
}

if [[ $# -lt 1 ]]; then
    usage; exit 2
fi

REPO="$1"; shift
CONFIRM=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --confirm) CONFIRM=1 ;;
        --dry-run) DRY_RUN=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "ERROR: unknown flag $1" >&2; usage; exit 2 ;;
    esac
    shift
done

# Sanity: repo exists and is a git repo
if [[ ! -d "$REPO/.git" ]]; then
    echo "ERROR: $REPO is not a git repository." >&2
    exit 1
fi

cd "$REPO"

REPL_FILE=".scrub/replacements.txt"
if [[ ! -f "$REPL_FILE" ]]; then
    echo "ERROR: $REPO/$REPL_FILE not found." >&2
    echo "       Copy .scrub/replacements.example.txt to .scrub/replacements.txt and fill in PII strings." >&2
    exit 1
fi

# Sanity: working tree clean (modified/staged tracked files only — untracked
# files don't affect filter-repo, which only rewrites commit blobs)
if [[ -n "$(git status --porcelain --untracked-files=no)" ]]; then
    echo "ERROR: working tree has staged or modified tracked files in $REPO. Commit or stash before running." >&2
    git status --short --untracked-files=no >&2
    exit 1
fi

# Sanity: filter-repo installed
if ! command -v git-filter-repo >/dev/null 2>&1; then
    echo "ERROR: git-filter-repo is not installed. brew install git-filter-repo" >&2
    exit 1
fi

# Confirmation gate
if [[ $CONFIRM -eq 0 && $DRY_RUN -eq 0 ]]; then
    echo "ERROR: This will rewrite git history irreversibly." >&2
    echo "       Pass --confirm to proceed, or --dry-run to test the setup." >&2
    exit 1
fi

# Backup branch
BACKUP_BRANCH="backup/pre-scrub-$(date +%Y%m%d-%H%M)"
if git show-ref --verify --quiet "refs/heads/$BACKUP_BRANCH"; then
    echo "ERROR: backup branch $BACKUP_BRANCH already exists. Aborting to avoid overwrite." >&2
    exit 1
fi
git branch "$BACKUP_BRANCH"
echo "Created backup branch: $BACKUP_BRANCH"

# Read LEFT-side strings for post-rewrite verification (skip blank/comment lines)
LEFT_SIDES=()
while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    if [[ "$line" =~ ^regex: ]]; then
        # Skip regex rules from the verifier; user must verify those manually
        continue
    fi
    left="${line%%==>*}"
    [[ -n "$left" ]] && LEFT_SIDES+=("$left")
done < "$REPL_FILE"

if [[ $DRY_RUN -eq 1 ]]; then
    echo "[DRY RUN] Would run: git filter-repo --replace-text $REPL_FILE --force"
    echo "[DRY RUN] LEFT-side strings to verify post-rewrite (${#LEFT_SIDES[@]} total):"
    printf '  - %s\n' "${LEFT_SIDES[@]}"
    echo "[DRY RUN] Backup branch $BACKUP_BRANCH was created."
    echo "[DRY RUN] No history rewrite performed."
    exit 0
fi

# Run the rewrite
echo "Running git filter-repo..."
git filter-repo --replace-text "$REPL_FILE" --force

# Verify: no LEFT-side string remains anywhere
echo "Verifying scrub..."
FAILURES=0
for s in "${LEFT_SIDES[@]}"; do
    # Check working tree
    if git grep -q -F "$s" -- ':!.scrub/replacements.txt' 2>/dev/null; then
        echo "FAIL: working tree still contains: $s" >&2
        FAILURES=$((FAILURES + 1))
    fi
    # Check history
    if git log --all -p -S "$s" --oneline 2>/dev/null | grep -q .; then
        echo "FAIL: history still contains: $s" >&2
        FAILURES=$((FAILURES + 1))
    fi
done

if [[ $FAILURES -gt 0 ]]; then
    echo "ERROR: $FAILURES residual matches found. Restore from $BACKUP_BRANCH and investigate." >&2
    echo "       To restore: git reset --hard $BACKUP_BRANCH" >&2
    exit 1
fi

echo
echo "SUCCESS: history scrubbed clean. ${#LEFT_SIDES[@]} rules verified, 0 residual matches."
echo
echo "Next steps (manual):"
echo "  1. Inspect a few commits: git log --oneline -10"
echo "  2. Force-push:           git push --force-with-lease origin main"
echo "  3. (Optional) push backup: git push origin $BACKUP_BRANCH"
echo "  4. On every other machine: git fetch && git reset --hard origin/main"
echo
echo "Backup branch retained locally: $BACKUP_BRANCH"
echo "Delete it once you've confirmed the rewrite is good: git branch -D $BACKUP_BRANCH"
