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
# IMPORTANT: Claude Code keeps TWO copies of the skill files - the version-pinned
# cache copy AND a marketplace clone. Both must be patched; Claude Code loads from
# the marketplace clone, so patching only the cache silently fails to take effect.
#
# Maintainer note: PINNED_VERSION below should match the upstream plugin version
# we translated against. If the installed plugin's version differs, the script
# warns rather than silently overwriting newer files we have not retranslated.

set -euo pipefail

PINNED="$(cat "$(dirname "${BASH_SOURCE[0]}")/PINNED_VERSION")"
PATCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_BASE="${HOME}/.claude/plugins/cache/claude-token-analyzer/claude-token-analyzer"
MARKETPLACE_DIR="${HOME}/.claude/plugins/marketplaces/claude-token-analyzer"

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

# Both targets - the runtime-loaded marketplace clone is what actually matters,
# but we patch the cache copy too so the two stay in sync (avoiding confusion
# during debugging or partial re-patches).
TARGETS=(
  "$PLUGIN_BASE/$INSTALLED_VERSION/skills"
  "$MARKETPLACE_DIR/skills"
)

apply_to_target() {
  local target_dir="$1"
  if [[ ! -d "$target_dir" ]]; then
    echo "skip target (not present): $target_dir" >&2
    return
  fi
  local count=0
  for skill_dir in "$PATCH_DIR/skills"/*/; do
    local skill_name
    skill_name="$(basename "$skill_dir")"
    local src="$skill_dir/SKILL.md"
    local dst="$target_dir/$skill_name/SKILL.md"
    [[ -f "$src" && -d "$target_dir/$skill_name" ]] || continue
    cp "$src" "$dst"
    count=$((count + 1))
  done
  echo "patched $count file(s) in $target_dir"
}

for t in "${TARGETS[@]}"; do
  apply_to_target "$t"
done

echo
echo "Applied English skill patches to plugin v$INSTALLED_VERSION (cache + marketplace clones)."
echo "Restart Claude Code or invoke a CTA command in a NEW session to use the patched skills."
echo "(An already-running session may have the old skills loaded; restart to be sure.)"
