#!/usr/bin/env bash
# Refresh the vendored n-agentic-harnesses skill from upstream OB1.
#
# Why vendor? The skill lives upstream at NateBJones-Projects/OB1, but for
# reproducibility across machines we want a pinned copy in dotfiles. This
# script does a clean sync from upstream at the SHA in PINNED_COMMIT.
#
# Usage:
#   ./refresh-from-upstream.sh              # refresh from PINNED_COMMIT
#   COMMIT=<new-sha> ./refresh-from-upstream.sh  # bump the pin and refresh
#
# After running, commit the resulting changes to the vendored skill files.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIN_FILE="$SCRIPT_DIR/PINNED_COMMIT"
SKILL_TARGET="$SCRIPT_DIR/../skills/n-agentic-harnesses"

# Resolve commit: env override > PINNED_COMMIT
COMMIT="${COMMIT:-$(cat "$PIN_FILE" 2>/dev/null || true)}"
if [[ -z "$COMMIT" ]]; then
  echo "ERROR: no PINNED_COMMIT found and COMMIT env not set" >&2
  exit 1
fi

echo "Refreshing n-agentic-harnesses from OB1@$COMMIT"

# Files to vendor (relative to OB1 repo root).
FILES=(
  "skills/n-agentic-harnesses/README.md"
  "skills/n-agentic-harnesses/SKILL.md"
  "skills/n-agentic-harnesses/metadata.json"
  "skills/n-agentic-harnesses/agents/openai.yaml"
  "skills/n-agentic-harnesses/references/01-principles-and-solo-dev-defaults.md"
  "skills/n-agentic-harnesses/references/02-harness-shapes-and-architecture.md"
  "skills/n-agentic-harnesses/references/03-tools-execution-and-permissions.md"
  "skills/n-agentic-harnesses/references/04-state-sessions-and-durability.md"
  "skills/n-agentic-harnesses/references/05-context-memory-and-evaluation.md"
  "skills/n-agentic-harnesses/references/06-agents-and-extensibility.md"
  "skills/n-agentic-harnesses/references/07-ux-observability-and-operations.md"
  "skills/n-agentic-harnesses/references/08-design-and-build-playbook.md"
  "skills/n-agentic-harnesses/references/09-evaluation-and-improvement-playbook.md"
  "skills/n-agentic-harnesses/references/10-example-requests-and-output-patterns.md"
  "skills/n-agentic-harnesses/references/11-codex-translation-notes.md"
  "skills/n-agentic-harnesses/variants/anthropic/SKILL.md"
  "skills/n-agentic-harnesses/variants/codex/SKILL.md"
)

# Wipe then re-fetch (clean sync; catches upstream deletions).
mkdir -p "$SKILL_TARGET"
rm -rf "$SKILL_TARGET"
mkdir -p "$SKILL_TARGET/agents" "$SKILL_TARGET/references" \
         "$SKILL_TARGET/variants/anthropic" "$SKILL_TARGET/variants/codex"

for f in "${FILES[@]}"; do
  rel="${f#skills/n-agentic-harnesses/}"
  url="https://raw.githubusercontent.com/NateBJones-Projects/OB1/${COMMIT}/${f}"
  out="$SKILL_TARGET/$rel"
  mkdir -p "$(dirname "$out")"
  if ! curl -fsSL "$url" -o "$out"; then
    echo "ERROR: failed to fetch $url" >&2
    exit 2
  fi
  echo "fetched: $rel"
done

# Update pin file if user passed a new COMMIT via env.
echo "$COMMIT" > "$PIN_FILE"
echo
echo "Vendored $(echo "${#FILES[@]}") files at SHA $COMMIT"
echo
echo "Next steps:"
echo "  1. cd into dotfiles repo and review git diff"
echo "  2. chezmoi apply --force  (sync to ~/.claude/skills/n-agentic-harnesses)"
echo "  3. git commit + push"
