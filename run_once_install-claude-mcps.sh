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
#   - Anything requiring a personal secret (e.g. open-brain Supabase URL) is
#     opt-in via env var so dotfiles stays secret-free.

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

# --- youtube-transcript ----------------------------------------------------
# Pinned to a verified version. Audit verdict: SAFE-WITH-RESTRICTIONS.
# Re-audit index.js and yt-lib/src/fetcher.js before bumping.
add_user youtube-transcript npx -y @fabriqa.ai/youtube-transcript-mcp@1.0.3

# --- open-brain (optional, secret-gated) -----------------------------------
# Set OPEN_BRAIN_MCP_URL in your shell env (NOT in dotfiles) to enable.
# The URL embeds a Supabase access key, which is why it is not committed.
if [[ -n "${OPEN_BRAIN_MCP_URL:-}" ]]; then
  add_user_http open-brain "$OPEN_BRAIN_MCP_URL"
else
  echo "[claude-mcps] OPEN_BRAIN_MCP_URL not set; skipping open-brain. Export it in your shell to enable."
fi

echo "[claude-mcps] done."
