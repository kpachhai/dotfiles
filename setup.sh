#!/bin/sh
# Bootstrap dotfiles on a new machine.
# Run this from inside the cloned repo. It symlinks the repo for chezmoi,
# installs chezmoi if missing, then applies the dotfiles.
#
# Usage:
#   cd ~/path/to/dotfiles
#   ./setup.sh

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CHEZMOI_SOURCE="${HOME}/.local/share/chezmoi"

# Symlink repo to chezmoi's expected source path
if [ ! -e "$CHEZMOI_SOURCE" ]; then
  mkdir -p "$(dirname "$CHEZMOI_SOURCE")"
  ln -sf "$DOTFILES_DIR" "$CHEZMOI_SOURCE"
  echo "Symlinked $CHEZMOI_SOURCE -> $DOTFILES_DIR"
elif [ "$(readlink "$CHEZMOI_SOURCE")" = "$DOTFILES_DIR" ]; then
  echo "Symlink already in place: $CHEZMOI_SOURCE -> $DOTFILES_DIR"
else
  echo "ERROR: $CHEZMOI_SOURCE already exists and points elsewhere:"
  echo "  $(readlink "$CHEZMOI_SOURCE")"
  echo "Remove it manually and re-run."
  exit 1
fi

# Install chezmoi if missing
if ! command -v chezmoi > /dev/null 2>&1; then
  echo "Installing chezmoi..."
  sh -c "$(curl -fsLS get.chezmoi.io)"
fi

# Apply dotfiles
echo "Applying dotfiles..."
chezmoi apply

echo ""
echo "Done. Open a new terminal or run: source ~/.zshrc"
