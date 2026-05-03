#!/usr/bin/env bash
# Export portable-only entries from ~/.claude/working-identity.md as a vendor-agnostic snapshot.
# Filters out entries tagged Portability: sensitive | block. Renders to a versioned file
# under ~/Documents/ (or a directory passed as $1).
#
# Works on both personal machine (where working-identity.md is generated from Open Brain)
# and work machine (where working-identity.md is the canonical store). No Open Brain access
# required - operates purely on the local markdown file.
#
# Usage:
#   ~/.claude/scripts/export-working-identity.sh                # defaults to ~/Documents/
#   ~/.claude/scripts/export-working-identity.sh /tmp           # override output dir
#
# The output file is meant to be paste-able as a system-prompt-style header into any AI
# tool that does not support MCP-native memory access (ChatGPT, Perplexity, Gemini, work AI).

set -euo pipefail

INPUT="$HOME/.claude/working-identity.md"
OUT_DIR="${1:-$HOME/Documents}"

if [ ! -f "$INPUT" ]; then
  echo "error: $INPUT not found - run the working-identity skill to populate it first" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

# Find next version number
N=1
while [ -f "$OUT_DIR/working-identity-portable-v${N}.md" ]; do
  N=$((N + 1))
done
OUTPUT="$OUT_DIR/working-identity-portable-v${N}.md"

GENERATED="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Render the snapshot. The awk block walks ~/.claude/working-identity.md and:
#   - Tracks the current section header (## Domain | ## Workflow | ## Style | ## Artifact)
#   - Emits only list-item lines containing (Portability: portable)
#   - Lazily prints the section header the first time a portable entry is seen in that section
#     (so empty sections do not appear in the output)
#   - Skips everything else - blurb paragraphs, HTML comments, sensitive/block entries
{
  echo "# Working Identity - Portable Snapshot v${N}"
  echo ""
  echo "Vendor-agnostic portable identity export from \`~/.claude/working-identity.md\`."
  echo "Filtered to entries explicitly tagged \`Portability: portable\` only."
  echo "Generated: ${GENERATED}"
  echo ""
  echo "Paste below as a system-prompt-style header into any AI tool that does not support MCP-native memory access (ChatGPT, Perplexity, Gemini, work AI, etc.)."
  echo ""
  echo "---"
  echo ""

  awk '
    /^## (Domain|Workflow|Style|Artifact) *$/ {
      section = $0
      emit_section = 0
      next
    }
    /^- .*\(Portability: portable\)/ {
      if (emit_section == 0) {
        print section
        print ""
        emit_section = 1
      }
      print
      next
    }
    emit_section == 1 && /^$/ {
      print
      emit_section = 2  # one blank line after entries before next section
    }
  ' "$INPUT"

  echo ""
  echo "---"
  echo ""
  echo "_End of portable identity snapshot. \`Portability: sensitive\` and \`Portability: block\` entries were filtered out and remain in \`~/.claude/working-identity.md\` only._"
} > "$OUTPUT"

PORTABLE_COUNT=$(grep -c '^- .*(Portability: portable)' "$INPUT" 2>/dev/null || true)
TOTAL_COUNT=$(grep -c '^- .*(Portability:' "$INPUT" 2>/dev/null || true)
PORTABLE_COUNT=${PORTABLE_COUNT:-0}
TOTAL_COUNT=${TOTAL_COUNT:-0}
SENSITIVE_COUNT=$((TOTAL_COUNT - PORTABLE_COUNT))

echo "wrote: $OUTPUT"
echo "portable entries: ${PORTABLE_COUNT} / total: ${TOTAL_COUNT} (${SENSITIVE_COUNT} sensitive/block filtered out)"
