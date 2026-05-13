#!/usr/bin/env bash
#
# Install Claude Code MCP servers that need manual setup.
#
# Chezmoi runs plain `run_*` scripts on every `chezmoi apply`. We deliberately
# do NOT use `run_once_*` here because some MCP registrations depend on local
# binaries (e.g. ~/.local/bin/engram) whose presence flips over time as the
# user finishes per-machine bootstrap. A `run_once_*` script is hash-gated and
# would never retry after a skipped-because-binary-not-found path. Running
# every apply is safe because the script is idempotent: `installed()` greps
# `claude mcp list` and skips servers that are already registered. Cost is a
# few `claude mcp list` invocations per apply (<1s total).
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

if ! command -v jq >/dev/null 2>&1; then
  echo "[claude-mcps] 'jq' not found on PATH; skipping permissions sync. Install jq first."
  exit 0
fi

settings_local="${HOME}/.claude/settings.local.json"

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

# Ensure settings.local.json exists with at least an empty permissions block.
_ensure_settings_local() {
  if [[ ! -f "$settings_local" ]]; then
    echo '{"permissions":{"allow":[],"deny":[]}}' > "$settings_local"
  fi
  # Ensure the .permissions.allow array exists even if the file predates it.
  local tmp
  tmp="$(jq 'if .permissions == null then .permissions = {"allow":[],"deny":[]} elif .permissions.allow == null then .permissions.allow = [] else . end' "$settings_local")"
  echo "$tmp" > "$settings_local"
}

# Add a single entry to .permissions.allow if not already present.
allow_permission() {
  local entry="$1"
  _ensure_settings_local
  if jq -e ".permissions.allow | index(\"$entry\")" "$settings_local" >/dev/null 2>&1; then
    return 0  # already present
  fi
  local tmp
  tmp="$(jq ".permissions.allow += [\"$entry\"]" "$settings_local")"
  echo "$tmp" > "$settings_local"
  echo "[claude-mcps] permissions: allowed $entry"
}

# Remove a single entry from .permissions.allow (cleanup for stale entries).
revoke_permission() {
  local entry="$1"
  if [[ ! -f "$settings_local" ]]; then return 0; fi
  if ! jq -e ".permissions.allow | index(\"$entry\")" "$settings_local" >/dev/null 2>&1; then
    return 0  # not present, nothing to do
  fi
  local tmp
  tmp="$(jq ".permissions.allow -= [\"$entry\"]" "$settings_local")"
  echo "$tmp" > "$settings_local"
  echo "[claude-mcps] permissions: revoked stale entry $entry"
}

# --- open-brain (dotfiles-canonical; manage from here, not from claude.ai) -
# Reads the URL from ~/.config/devkit/references.json. The URL embeds a
# Supabase access key, which is why it lives there (gitignored, machine-local)
# and not in this committed file. This block IS the canonical Open Brain
# registration; do NOT also enable the claude.ai-account-synced
# 'My Personal OpenBrain' MCP, otherwise every capture double-writes to the
# same OB1 store (the multi-MCP rule fires both registrations in parallel).
# To disable the claude.ai-managed mirror: claude.ai → Settings → Connectors
# → remove 'My Personal OpenBrain'. Then restart Claude Code.
references_file="${HOME}/.config/devkit/references.json"
open_brain_url=""
if [[ -f "$references_file" ]] && command -v jq >/dev/null 2>&1; then
  open_brain_url="$(jq -r '.open_brain_mcp_url // ""' "$references_file" 2>/dev/null)"
fi
if [[ -n "$open_brain_url" ]]; then
  add_user_http open-brain "$open_brain_url"
  allow_permission "mcp__open-brain__search_thoughts"
  allow_permission "mcp__open-brain__thought_stats"
  allow_permission "mcp__open-brain__list_thoughts"
  allow_permission "mcp__open-brain__capture_thought"
else
  echo "[claude-mcps] open_brain_mcp_url not set in $references_file; skipping open-brain."
  echo "[claude-mcps] To enable: copy devkit-references.example.json to $references_file and fill it in."
  revoke_permission "mcp__open-brain__search_thoughts"
  revoke_permission "mcp__open-brain__thought_stats"
  revoke_permission "mcp__open-brain__list_thoughts"
  revoke_permission "mcp__open-brain__capture_thought"
fi

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
  allow_permission "mcp__engram__search_thoughts"
  allow_permission "mcp__engram__capture_thought"
  allow_permission "mcp__engram__list_thoughts"
  allow_permission "mcp__engram__thought_stats"
  allow_permission "mcp__engram__fetch"
  allow_permission "mcp__engram__summarize_thought"
  allow_permission "mcp__engram__synthesize_thoughts"
else
  echo "[claude-mcps] engram binary not found at $engram_binary; skipping engram MCP."
  echo "[claude-mcps] To enable: install engram via 'uv tool install --editable .'"
  echo "[claude-mcps]   from your engram source clone, then re-run 'chezmoi apply'."
  # Remove stale engram permissions when the binary is not installed.
  revoke_permission "mcp__engram__search_thoughts"
  revoke_permission "mcp__engram__capture_thought"
  revoke_permission "mcp__engram__list_thoughts"
  revoke_permission "mcp__engram__thought_stats"
  revoke_permission "mcp__engram__fetch"
  revoke_permission "mcp__engram__summarize_thought"
  revoke_permission "mcp__engram__synthesize_thoughts"
fi

echo "[claude-mcps] done."
echo ""
echo "[claude-mcps] One-time manual step on this machine:"
echo "  Open a Claude Code session and run:  /effort xhigh"
echo "  Reason: '/effort xhigh' is sticky across sessions but can only be set"
echo "  via the in-session slash command (no CLI flag, no settings key)."
echo "  Per Boris Cherny's Opus 4.7 guidance: xhigh for most tasks, max for the"
echo "  hardest. 'max' is per-session; 'xhigh' persists."
