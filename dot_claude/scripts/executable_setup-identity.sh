#!/usr/bin/env bash
# Interactive setup for ~/.config/devkit/identity.json.
# For users who don't run chezmoi (forkers without dotfiles), or as a
# manual rebootstrap. Refuses to overwrite an existing file.

set -euo pipefail

target="${HOME}/.config/devkit/identity.json"

if [[ -f "$target" ]]; then
    echo "ERROR: $target already exists. Edit it directly, or remove it first." >&2
    exit 1
fi

mkdir -p "$(dirname "$target")"

prompt() {
    local var="$1" question="$2" default="${3:-}"
    local answer
    if [[ -n "$default" ]]; then
        read -r -p "$question [$default]: " answer
        answer="${answer:-$default}"
    else
        read -r -p "$question: " answer
    fi
    printf -v "$var" '%s' "$answer"
}

echo "Setting up $target"
echo "(press Ctrl-C to abort; required fields cannot be empty)"
echo

while [[ -z "${full_name:-}" ]]; do prompt full_name "Full name"; done
while [[ -z "${email_personal:-}" ]]; do prompt email_personal "Personal email"; done
prompt email_work "Work email (blank if none)" ""
while [[ -z "${github_username:-}" ]]; do prompt github_username "GitHub username"; done
prompt gpg_signing_key "GPG signing key (blank if none)" ""

cat > "$target" <<JSON
{
  "full_name": "$full_name",
  "email_personal": "$email_personal",
  "email_work": "$email_work",
  "github_username": "$github_username",
  "gpg_signing_key": "$gpg_signing_key",
  "work_gh_orgs": []
}
JSON

echo
echo "Wrote $target"
echo "Edit it directly to add work_gh_orgs (list of GitHub org names) or change values."
