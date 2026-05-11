#!/usr/bin/env bash
#
# Install Claude Code MCP servers that need manual setup.
#
# Chezmoi runs `run_once_*` scripts once per machine. Edit this file (do not
# rename) to add or remove MCPs - chezmoi re-runs on hash change. Idempotent:
# uses `claude mcp list` to skip already-installed servers.
#
# Note on what is NOT here:
#   - claude.ai-managed MCPs (Viator, Drive, Gmail, etc.) sync via OAuth from
#     the claude.ai account; nothing to install locally.
#   - Plugin-bundled MCPs (context7, vercel) come with their plugins.
#   - Anything requiring a personal secret (e.g. Open Brain Supabase URL) is
#     opt-in via ~/.config/devkit/references.json so dotfiles stays
#     secret-free. See devkit-references.example.json at the repo root for
#     the schema. Set the value once on each machine; subsequent applies
#     pick it up automatically.

set -euo pipefail

if ! command -v claude >/dev/null 2>&1; then
  echo "[claude-mcps] 'claude' CLI not found on PATH; skipping MCP install. Install Claude Code first."
  exit 0
fi

installed() {
  claude mcp list 2>/dev/null | grep -qE "^$1:"
}

add_user() {
  local name="$1"; shift
  if installed "$name"; then
    echo "[claude-mcps] $name already installed, skipping."
  else
    echo "[claude-mcps] adding $name..."
    claude mcp add --scope user "$name" -- "$@"
  fi
}

add_user_http() {
  local name="$1"; local url="$2"
  if installed "$name"; then
    echo "[claude-mcps] $name already installed, skipping."
  else
    echo "[claude-mcps] adding $name (HTTP)..."
    claude mcp add --scope user --transport http "$name" "$url"
  fi
}

# --- open-brain ------------------------------------------------------------
# Previously registered here as a local HTTP MCP reading from
# ~/.config/devkit/references.json. Now obsolete: Open Brain auto-syncs via
# the claude.ai account as 'claude.ai My Personal OpenBrain' (same Supabase
# URL, OAuth-managed). Keeping the local registration AS WELL caused every
# capture to fire BOTH MCPs in parallel (per the global multi-MCP rule),
# silently double-writing to the same OB1 store.
#
# If you ever need a local fallback (claude.ai sync disabled, work machine
# without the account, etc.), uncomment the block below and ensure
# 'claude.ai My Personal OpenBrain' is NOT also active.
#
# references_file="${HOME}/.config/devkit/references.json"
# open_brain_url=""
# if [[ -f "$references_file" ]] && command -v jq >/dev/null 2>&1; then
#   open_brain_url="$(jq -r '.open_brain_mcp_url // ""' "$references_file" 2>/dev/null)"
# fi
# if [[ -n "$open_brain_url" ]]; then
#   add_user_http open-brain "$open_brain_url"
# fi

# --- engram (local-first; gated on the engram binary existing) -------------
# Engram is a local stdio MCP server. There is no URL / secret to inject; the
# only requirement is that the `engram` binary is reachable. Install on a
# given machine via `uv tool install --editable .` from your engram source
# clone. Each machine has its own ~/.config/engram/config.yaml pointing at
# its own vault - no cross-machine contamination.
#
# We register with the ABSOLUTE path ($HOME/.local/bin/engram) rather than
# the bare `engram` command, because Claude Code launches MCP subprocesses
# with its own (stripped) PATH that does not source the user's shell rc.
# uv tool install canonically deposits binaries at $HOME/.local/bin so
# hardcoding that path is portable across machines.
engram_binary="$HOME/.local/bin/engram"
if [[ -x "$engram_binary" ]]; then
  add_user engram "$engram_binary" serve
else
  echo "[claude-mcps] engram binary not found at $engram_binary; skipping engram MCP."
  echo "[claude-mcps] To enable: install engram via 'uv tool install --editable .'"
  echo "[claude-mcps]   from your engram source clone, then re-run 'chezmoi apply'."
fi

echo "[claude-mcps] done."
echo ""
echo "[claude-mcps] One-time manual step on this machine:"
echo "  Open a Claude Code session and run:  /effort xhigh"
echo "  Reason: '/effort xhigh' is sticky across sessions but can only be set"
echo "  via the in-session slash command (no CLI flag, no settings key)."
echo "  Per Boris Cherny's Opus 4.7 guidance: xhigh for most tasks, max for the"
echo "  hardest. 'max' is per-session; 'xhigh' persists."
