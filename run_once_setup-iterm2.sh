#!/usr/bin/env bash
# Set up iTerm2 with Catppuccin Mocha profile, Nerd Font, and synced preferences.
# chezmoi run_once_ prefix means this runs once per machine.
# To re-run: chezmoi state delete-bucket --bucket=scriptState && chezmoi apply

set -euo pipefail

DOTFILES_DIR="$(chezmoi source-path 2>/dev/null || echo "$HOME/.local/share/chezmoi")"

# Install iTerm2 if missing
if [ ! -d "/Applications/iTerm.app" ]; then
  echo "Installing iTerm2..."
  brew install --cask iterm2
fi

# Install Nerd Font if missing
if ! ls ~/Library/Fonts/MesloLGSNerdFont* >/dev/null 2>&1 && \
   ! ls ~/Library/Fonts/MesloLGSNerdFontMono* >/dev/null 2>&1; then
  echo "Installing MesloLGS Nerd Font..."
  brew install --cask font-meslo-lg-nerd-font
fi

# Copy exported iTerm2 preferences to the custom prefs folder, substituting
# the __HOME_PLACEHOLDER__ token with the actual $HOME so the plist is
# portable across machines/usernames.
ITERM2_PREFS_DIR="$HOME/.config/iterm2"
mkdir -p "$ITERM2_PREFS_DIR"
sed "s|__HOME_PLACEHOLDER__|$HOME|g" \
  "$DOTFILES_DIR/iterm2/com.googlecode.iterm2.plist" \
  > "$ITERM2_PREFS_DIR/com.googlecode.iterm2.plist"

# Tell iTerm2 to load preferences from the custom folder
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "~/.config/iterm2"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true

echo "iTerm2 setup complete. Open iTerm2 to use it."
echo "Theme: Catppuccin Mocha | Font: MesloLGS Nerd Font Mono 14pt"
