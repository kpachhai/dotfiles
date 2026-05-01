#!/usr/bin/env bash
# Apply English-translated CTA skills over the installed claude-token-analyzer plugin.
#
# Prerequisite: the plugin must already be installed via Claude Code:
#   /plugin marketplace add li195111/claude-token-analyzer
#   /plugin install claude-token-analyzer@claude-token-analyzer
#
# Run this AFTER plugin install or AFTER /plugin update.
# Idempotent - re-running just re-applies the same patches.
#
# Maintainer note: PINNED_VERSION below should match the upstream plugin version
# we translated against. If the installed plugin's version differs, the script
# warns rather than silently overwriting newer files we have not retranslated.

set -euo pipefail

PINNED="$(cat "$(dirname "${BASH_SOURCE[0]}")/PINNED_VERSION")"
PATCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_BASE="${HOME}/.claude/plugins/cache/claude-token-analyzer/claude-token-analyzer"

if [[ ! -d "$PLUGIN_BASE" ]]; then
  cat >&2 <<EOF
ERROR: claude-token-analyzer plugin not installed.

Install it first - inside any Claude Code session, run:

  /plugin marketplace add li195111/claude-token-analyzer
  /plugin install claude-token-analyzer@claude-token-analyzer

Then re-run this script.
EOF
  exit 1
fi

# Detect installed version (directory name like "0.1.0" under the plugin base).
INSTALLED_VERSION="$(ls "$PLUGIN_BASE" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n 1)"

if [[ -z "$INSTALLED_VERSION" ]]; then
  echo "ERROR: could not detect installed plugin version under $PLUGIN_BASE" >&2
  exit 2
fi

if [[ "$INSTALLED_VERSION" != "$PINNED" ]]; then
  cat >&2 <<EOF
WARNING: installed plugin version is $INSTALLED_VERSION; patches were translated against $PINNED.

The skill files may have changed upstream. Patches may overwrite legitimate changes
or fail to translate new strings. Recommended actions:

  1. Update the dotfiles patch directory after re-translating against the new version.
  2. Or use the immediate workaround instead - prepend each prompt with
     "Output everything in English."

Aborting to be safe. To force-apply anyway: re-run with FORCE=1
EOF
  if [[ "${FORCE:-0}" != "1" ]]; then
    exit 3
  fi
  echo "FORCE=1 set - applying anyway." >&2
fi

INSTALL_SKILLS_DIR="$PLUGIN_BASE/$INSTALLED_VERSION/skills"

if [[ ! -d "$INSTALL_SKILLS_DIR" ]]; then
  echo "ERROR: expected skills dir not found: $INSTALL_SKILLS_DIR" >&2
  exit 4
fi

# Apply each translated SKILL.md.
COUNT=0
for skill_dir in "$PATCH_DIR/skills"/*/; do
  skill_name="$(basename "$skill_dir")"
  src="$skill_dir/SKILL.md"
  dst="$INSTALL_SKILLS_DIR/$skill_name/SKILL.md"

  if [[ ! -f "$src" ]]; then
    echo "skip: $skill_name (no source SKILL.md in patch dir)" >&2
    continue
  fi

  if [[ ! -d "$INSTALL_SKILLS_DIR/$skill_name" ]]; then
    echo "skip: $skill_name (skill not present in installed plugin)" >&2
    continue
  fi

  cp "$src" "$dst"
  echo "patched: $skill_name/SKILL.md"
  COUNT=$((COUNT + 1))
done

echo
echo "Applied $COUNT English skill patches to plugin v$INSTALLED_VERSION."
echo "Restart Claude Code or invoke a CTA command to use the patched skills."
