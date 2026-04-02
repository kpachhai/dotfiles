#!/bin/sh
# Install git hooks for the chezmoi source repo.
# The pre-push hook auto-runs `chezmoi re-add` before every push,
# keeping the source in sync with local edits without manual intervention.

HOOKS_DIR="${HOME}/.local/share/chezmoi/.git/hooks"

cat > "${HOOKS_DIR}/pre-push" << 'EOF'
#!/bin/sh
# Automatically sync modified local dotfiles back to chezmoi source before pushing.
echo "chezmoi: syncing local changes to source..."
chezmoi re-add
git add -u
echo "chezmoi: re-add complete"
EOF

chmod +x "${HOOKS_DIR}/pre-push"
echo "chezmoi pre-push hook installed"
