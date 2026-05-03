#!/usr/bin/env bash
# Capture a point-in-time snapshot of all skills loaded across the
# Claude Code skill ecosystem. Useful for diffing before/after plugin
# operations, debugging skill drift, or auditing a machine's setup.
#
# Output: ~/.claude/skill-inventory-<date>.txt
# Run when:
#   - Before/after /plugin install or /plugin update
#   - Weekly or monthly as a hygiene check
#   - When debugging "did this skill exist last week?"
set -euo pipefail

OUTDIR="${HOME}/.claude"
DATE="$(date +%Y%m%d-%H%M%S)"
OUT="${OUTDIR}/skill-inventory-${DATE}.txt"

{
  echo "Skill Inventory Snapshot"
  echo "Date: $(date)"
  echo "Host: $(hostname)"
  echo
  echo "===================================================="
  echo "1. Personal skills (~/.claude/skills/)"
  echo "===================================================="
  if [[ -d "${HOME}/.claude/skills" ]]; then
    find "${HOME}/.claude/skills" -maxdepth 2 -name "SKILL.md" -type f 2>/dev/null | sort
  else
    echo "(none)"
  fi
  echo

  echo "===================================================="
  echo "2. Plugin cache skills (~/.claude/plugins/cache/<plugin>/<plugin>/<version>/skills/)"
  echo "===================================================="
  if [[ -d "${HOME}/.claude/plugins/cache" ]]; then
    find "${HOME}/.claude/plugins/cache" -maxdepth 6 -name "SKILL.md" -type f 2>/dev/null | sort
  else
    echo "(none)"
  fi
  echo

  echo "===================================================="
  echo "3. Plugin marketplace skills (~/.claude/plugins/marketplaces/<plugin>/skills/)"
  echo "===================================================="
  if [[ -d "${HOME}/.claude/plugins/marketplaces" ]]; then
    find "${HOME}/.claude/plugins/marketplaces" -maxdepth 4 -name "SKILL.md" -type f 2>/dev/null | sort
  else
    echo "(none)"
  fi
  echo

  echo "===================================================="
  echo "4. Project-local skills (cwd: $(pwd))"
  echo "===================================================="
  find . -path ./node_modules -prune -o -name "SKILL.md" -type f -print 2>/dev/null | sort
  echo

  echo "===================================================="
  echo "5. Plugin manifests + versions"
  echo "===================================================="
  if [[ -d "${HOME}/.claude/plugins/marketplaces" ]]; then
    for f in "${HOME}/.claude/plugins/marketplaces"/*/.claude-plugin/plugin.json; do
      [[ -f "$f" ]] || continue
      name=$(grep -E '"name"' "$f" | head -1 | sed -E 's/.*"name": "([^"]+)".*/\1/')
      version=$(grep -E '"version"' "$f" | head -1 | sed -E 's/.*"version": "([^"]+)".*/\1/')
      echo "  $name @ $version"
    done
  fi
} > "$OUT"

LINES=$(wc -l < "$OUT" | tr -d ' ')
SKILLS=$(grep -c "SKILL.md" "$OUT" || true)
echo "Snapshot written: $OUT"
echo "  $LINES lines, $SKILLS skill files indexed"
echo
echo "To diff against a prior snapshot:"
echo "  diff ${OUTDIR}/skill-inventory-<earlier>.txt $OUT"
