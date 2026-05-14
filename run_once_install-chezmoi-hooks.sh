#!/bin/sh
# Install git hooks for the chezmoi source repo.
#
# Two hooks:
#
# 1. pre-commit: abort if chezmoi sees source/live divergence on any file the
#    commit touches under chezmoi-managed paths. Forces explicit resolution
#    (chezmoi apply or chezmoi re-add) before committing. Prevents the silent
#    revert pattern where a stale live file overwrites a source edit during the
#    pre-push re-add step.
#
# 2. pre-push: auto-runs `chezmoi re-add` to capture any live-side edits into
#    source before pushing. Safe because pre-commit ensured live == source for
#    files in this commit.

HOOKS_DIR="${HOME}/.local/share/chezmoi/.git/hooks"
mkdir -p "${HOOKS_DIR}"

# ---------- pre-commit ----------
cat > "${HOOKS_DIR}/pre-commit" << 'EOF'
#!/bin/sh
# Two-layer protection:
# 1. PII scan on staged content (unconditional - applies to any commit).
# 2. chezmoi source/live divergence check (only when commit touches managed paths).

# --- Layer 1: PII scan ---
if [ -x "$HOME/.claude/scripts/pii-scan.sh" ]; then
  if ! "$HOME/.claude/scripts/pii-scan.sh" --staged; then
    cat >&2 <<PIIMSG

ABORT: PII patterns matched in staged content (see findings above).
Fix the content (preferred) or document a false-positive exception before
proceeding. To bypass once (rarely correct), use: git commit --no-verify
PIIMSG
    exit 1
  fi
fi

# --- Layer 2: chezmoi divergence ---
# Only check if the commit touches chezmoi-managed paths.
STAGED=$(git diff --cached --name-only | grep -E '^(dot_|private_|empty_|exact_|executable_|symlink_|run_once_)' || true)
if [ -z "$STAGED" ]; then
  exit 0
fi

DIFF=$(chezmoi diff --exclude=scripts 2>/dev/null)
if [ -z "$DIFF" ]; then
  exit 0
fi

cat >&2 <<MSG

ABORT: chezmoi sees source/live divergence and this commit touches managed files.

Without resolving the divergence, the pre-push hook's chezmoi re-add will
silently overwrite your source changes with the older live state.

Divergence (truncated to 40 lines):
---------------------------------------------------------------
$(echo "$DIFF" | head -40)
---------------------------------------------------------------

Resolve with one of:
  chezmoi apply --force      # source wins; live gets overwritten
  chezmoi re-add             # live wins; source gets overwritten
  chezmoi merge-all          # interactive 3-way merge

Then re-attempt the commit.

(To bypass once - rarely correct - run: git commit --no-verify)
MSG

exit 1
EOF
chmod +x "${HOOKS_DIR}/pre-commit"

# ---------- pre-push ----------
cat > "${HOOKS_DIR}/pre-push" << 'EOF'
#!/bin/sh
# Automatically sync modified local dotfiles back to chezmoi source before pushing.
# Safe because pre-commit ensures live == source for files in each commit.
echo "chezmoi: syncing local changes to source..."
chezmoi re-add
git add -u
echo "chezmoi: re-add complete"
EOF
chmod +x "${HOOKS_DIR}/pre-push"

echo "chezmoi git hooks installed (pre-commit, pre-push)"
