#!/usr/bin/env bash
# target-repo-check.sh - Manage cross-repo working-mode binding for current Claude session.
#
# Storage: ~/.claude/target-repo/<claude-session-uuid>.md
# UUID resolution: most-recently-modified .jsonl in ~/.claude/projects/<encoded-cwd>/
#
# Encoded cwd: Claude Code replaces both `/` and `.` with `-` in the absolute
# path. E.g., $HOME/repos/github.com/me/foo -> -Users-<name>-repos-github-com-me-foo
# (the literal $HOME expansion supplies /Users/<name> on macOS).
#
# Usage:
#   target-repo-check.sh --get       # print target path if active, empty otherwise
#   target-repo-check.sh --set PATH  # set target for current Claude session
#   target-repo-check.sh --clear     # clear target for current session
#   target-repo-check.sh --banner    # print session-start banner if target active
#
# Race-condition note: in the rare case of two Claude sessions in the same
# project starting within milliseconds, `ls -t` may briefly return the wrong
# session's UUID. Manifest: a session sees the other session's target (or no
# target where one was set). Recovery: run `/target-repo <path>` again to
# rewrite the binding for the now-correctly-resolved UUID. Bulletproofing via
# sentinel cross-check is on the TODO list if the race becomes annoying.

set -euo pipefail

TARGET_DIR="${HOME}/.claude/target-repo"
mkdir -p "$TARGET_DIR"

encode_cwd() {
  local p="${1:-$PWD}"
  p="${p//\//-}"
  p="${p//./-}"
  echo "$p"
}

current_uuid() {
  local encoded project_dir latest
  encoded="$(encode_cwd "$PWD")"
  project_dir="${HOME}/.claude/projects/${encoded}"
  [[ -d "$project_dir" ]] || return 1
  latest="$(ls -t "$project_dir"/*.jsonl 2>/dev/null | head -1)"
  [[ -n "$latest" ]] || return 1
  basename "$latest" .jsonl
}

binding_file_path() {
  local uuid
  uuid="$(current_uuid)" || return 1
  echo "${TARGET_DIR}/${uuid}.md"
}

cmd_get() {
  local f
  f="$(binding_file_path)" || return 0
  [[ -f "$f" ]] || return 0
  cat "$f"
}

cmd_set() {
  local raw="$1" abs
  # Resolve to absolute, expanding ~ if needed
  raw="${raw/#\~/$HOME}"
  abs="$(cd "$raw" 2>/dev/null && pwd -P)" || {
    echo "target-repo: not a valid directory: $1" >&2
    return 2
  }
  if ! git -C "$abs" rev-parse --git-dir >/dev/null 2>&1; then
    echo "target-repo: WARNING: $abs is not a git repo; git operations will fail" >&2
  fi
  local f
  f="$(binding_file_path)" || {
    echo "target-repo: cannot resolve current Claude session UUID" >&2
    echo "target-repo: (no .jsonl in ~/.claude/projects/$(encode_cwd "$PWD")/)" >&2
    return 2
  }
  echo "$abs" > "$f"
  echo "target-repo: set to $abs"
}

cmd_clear() {
  local f
  f="$(binding_file_path)" || return 0
  [[ -f "$f" ]] && rm -f "$f"
  echo "target-repo: cleared"
}

cmd_banner() {
  local target
  target="$(cmd_get)"
  [[ -z "$target" ]] && return 0
  cat <<EOF
TARGET REPO MODE
  Target  : $target
  Meta    : $PWD (skills, memory, CLAUDE.md)
  Edits   : absolute paths under target
  Bash    : prefix with \`cd "\$TARGET" && ...\` or use absolute paths
  Git     : \`git -C "\$TARGET" ...\`
EOF
}

case "${1:-}" in
  --get) cmd_get ;;
  --set) shift; cmd_set "${1:-}" ;;
  --clear) cmd_clear ;;
  --banner) cmd_banner ;;
  *)
    cat >&2 <<EOF
usage: $0 {--get|--set PATH|--clear|--banner}
  --get       print current target if set
  --set PATH  bind current Claude session to PATH
  --clear     remove binding for current Claude session
  --banner    print session-start banner if target active
EOF
    exit 2
    ;;
esac
