#!/usr/bin/env bash
# engram-autostart.sh - SessionStart hook ensuring the engram MCP daemon is running.
#
# Engram MCP connects via stdio to a per-vault daemon at session-start. If the
# daemon isn't running, the MCP shows "Failed to connect" and capture_thought
# tools become invisible in this session - the silent-fallback failure mode
# where session-wrap captures degrade to single-write (Open Brain only) without
# anyone surfacing the gap.
#
# This hook checks if engram is registered AND failing to connect; if so, it
# attempts to start the daemon detached. The fix takes effect from the NEXT
# full Claude Code restart (the MCP set is frozen at session-start; `/clear`
# alone does NOT re-register MCPs).
#
# Silent unless engram is registered AND failing - safe on machines where
# engram isn't installed or isn't registered.
#
# Vault name: defaults to `engram-vault`. Override by exporting
# ENGRAM_AUTOSTART_VAULT in your shell profile or settings.local.json env.

set -uo pipefail

VAULT_NAME="${ENGRAM_AUTOSTART_VAULT:-engram-vault}"

# Exit silently if jq missing (cannot check registration)
command -v jq >/dev/null 2>&1 || exit 0

# Exit silently if ~/.claude.json missing
[[ -f "${HOME}/.claude.json" ]] || exit 0

# Exit silently if engram is not registered
jq -e '.mcpServers.engram // empty' "${HOME}/.claude.json" >/dev/null 2>&1 || exit 0

# Engram is registered; check connection status via `claude mcp list`.
# Exit silently if claude CLI isn't available (shouldn't happen but be safe).
command -v claude >/dev/null 2>&1 || exit 0

status_line="$(claude mcp list 2>&1 | grep -E '^engram:' || true)"

# If line is missing OR shows ✓ Connected, nothing to do.
if [[ -z "$status_line" ]] || echo "$status_line" | grep -q "✓ Connected"; then
  exit 0
fi

# Engram is registered AND not connected. Try to start the daemon.
echo "[engram-autostart] engram MCP registered but not connected: ${status_line}"

# Locate engram binary (~/.local/bin/engram is the default per-user install location).
engram_bin=""
if [[ -x "${HOME}/.local/bin/engram" ]]; then
  engram_bin="${HOME}/.local/bin/engram"
elif command -v engram >/dev/null 2>&1; then
  engram_bin="$(command -v engram)"
fi

if [[ -z "$engram_bin" ]]; then
  echo "[engram-autostart] engram binary not found (~/.local/bin/engram missing, not in PATH). Cannot auto-start; investigate manually."
  exit 0
fi

echo "[engram-autostart] attempting: ${engram_bin} daemon start --vault ${VAULT_NAME} --detach"
if "$engram_bin" daemon start --vault "$VAULT_NAME" --detach 2>&1 | sed 's/^/[engram-autostart] /'; then
  echo "[engram-autostart] daemon start succeeded. NOTE: the MCP set is frozen at session-start, so engram tools will be available from the NEXT full Claude Code restart (not just /clear)."
else
  echo "[engram-autostart] daemon start failed. Run: ${engram_bin} daemon status --vault ${VAULT_NAME}"
fi

exit 0
