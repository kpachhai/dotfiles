#!/bin/sh
# Bootstrap dotfiles on a new machine.
# Run this from inside the cloned repo. It symlinks the repo for chezmoi,
# installs chezmoi if missing, then walks you through applying the dotfiles.
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

# Show diff before applying so existing dotfiles are not silently overwritten
echo ""
echo "Checking for conflicts with existing dotfiles..."
if chezmoi diff | grep -q '^diff'; then
  echo ""
  echo "The following files differ between this repo and your current dotfiles:"
  chezmoi diff --stat
  echo ""
  echo "Options:"
  echo "  a) Apply repo version for all files (overwrites your local dotfiles)"
  echo "  m) Merge interactively file by file (recommended if you have local changes)"
  echo "  s) Skip - exit now and resolve manually with 'chezmoi diff' and 'chezmoi merge-all'"
  echo ""
  printf "Choose [a/m/s]: "
  read -r choice
  case "$choice" in
    a|A)
      chezmoi apply
      ;;
    m|M)
      chezmoi merge-all
      chezmoi apply
      ;;
    s|S)
      echo ""
      echo "Exiting. When ready:"
      echo "  chezmoi diff        - review what would change"
      echo "  chezmoi merge-all   - merge conflicts interactively"
      echo "  chezmoi apply       - apply after resolving"
      exit 0
      ;;
    *)
      echo "Invalid choice. Exiting without applying."
      exit 1
      ;;
  esac
else
  echo "No conflicts. Applying dotfiles..."
  chezmoi apply
fi

echo ""
echo "Done. Open a new terminal or run: source ~/.zshrc"
