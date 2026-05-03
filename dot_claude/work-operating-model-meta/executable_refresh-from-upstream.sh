#!/usr/bin/env bash
# Refresh the vendored work-operating-model skill from upstream OB1.
#
# Same pattern as n-agentic-harnesses-meta/refresh-from-upstream.sh.
#
# Usage (from dotfiles SOURCE dir, not live):
#   ./executable_refresh-from-upstream.sh           # refresh against PINNED_COMMIT
#   COMMIT=<sha> ./executable_refresh-from-upstream.sh   # bump pin and refresh
#
# After running, chezmoi apply to push to ~/.claude/skills/work-operating-model,
# then commit + push the dotfiles diff.
#
# IMPORTANT: This script ONLY refreshes the SKILL file. The recipe (schema +
# MCP server) is deployed separately via your-data-repo/open-brain/README.md procedure.
# When upstream bumps the schema or MCP server, that requires a separate
# your-data-repo-side migration + redeploy, not just a skill refresh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIN_FILE="$SCRIPT_DIR/PINNED_COMMIT"
SKILL_TARGET="$SCRIPT_DIR/../skills/work-operating-model"

COMMIT="${COMMIT:-$(cat "$PIN_FILE" 2>/dev/null || true)}"
if [[ -z "$COMMIT" ]]; then
  echo "ERROR: no PINNED_COMMIT found and COMMIT env not set" >&2
  exit 1
fi

echo "Refreshing work-operating-model skill from OB1@$COMMIT"

FILES=(
  "skills/work-operating-model/SKILL.md"
  "skills/work-operating-model/README.md"
  "skills/work-operating-model/metadata.json"
)

mkdir -p "$SKILL_TARGET"
rm -rf "$SKILL_TARGET"
mkdir -p "$SKILL_TARGET"

for f in "${FILES[@]}"; do
  rel="${f#skills/work-operating-model/}"
  url="https://raw.githubusercontent.com/NateBJones-Projects/OB1/${COMMIT}/${f}"
  out="$SKILL_TARGET/$rel"
  mkdir -p "$(dirname "$out")"
  if ! curl -fsSL "$url" -o "$out"; then
    echo "ERROR: failed to fetch $url" >&2
    exit 2
  fi
  echo "fetched: $rel"
done

echo "$COMMIT" > "$PIN_FILE"
echo
echo "Vendored ${#FILES[@]} skill files at SHA $COMMIT"
echo
echo "Next steps:"
echo "  1. cd into dotfiles repo and review git diff"
echo "  2. chezmoi apply --force"
echo "  3. git commit + push"
echo
echo "If upstream changed the schema or MCP server, ALSO refresh your-data-repo:"
echo "  - Update your-data-repo/open-brain/migrations/005-work-operating-model.sql"
echo "  - Redeploy the work-operating-model-mcp edge function"
echo "  - See your-data-repo/open-brain/README.md for the full procedure"
