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
# Abort commit if chezmoi sees source/live divergence on a file this commit
# touches. Forces the user to explicitly resolve (apply or re-add) so the
# pre-push re-add cannot silently revert source changes.

# Only check if the commit touches chezmoi-managed paths.
STAGED=$(git diff --cached --name-only | grep -E '^(dot_|private_|empty_|exact_|executable_|symlink_|run_once_)' || true)
if [ -z "$STAGED" ]; then
  exit 0
fi

DIFF=$(chezmoi diff 2>/dev/null)
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
