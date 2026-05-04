#!/usr/bin/env bash
# Reads ~/.config/devkit/identity.json and exports DEVKIT_IDENTITY_* env vars.
# Source this file (don't execute): `source ~/.claude/scripts/load-identity.sh`
# Required fields: full_name, email_personal, github_username.
# Optional: email_work, gpg_signing_key, work_gh_orgs (array).

set -eu

_devkit_identity_file="${HOME}/.config/devkit/identity.json"

if [[ ! -f "$_devkit_identity_file" ]]; then
    echo "ERROR: ${_devkit_identity_file} not found." >&2
    echo "Setup: copy devkit-identity.example.json to ${_devkit_identity_file} and fill in your values," >&2
    echo "       or run ~/.claude/scripts/setup-identity.sh to be prompted for them." >&2
    return 1 2>/dev/null || exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "ERROR: jq is required (brew install jq)." >&2
    return 1 2>/dev/null || exit 1
fi

export DEVKIT_IDENTITY_FULL_NAME="$(jq -r '.full_name // ""' "$_devkit_identity_file")"
export DEVKIT_IDENTITY_EMAIL_PERSONAL="$(jq -r '.email_personal // ""' "$_devkit_identity_file")"
export DEVKIT_IDENTITY_EMAIL_WORK="$(jq -r '.email_work // ""' "$_devkit_identity_file")"
export DEVKIT_IDENTITY_GITHUB_USERNAME="$(jq -r '.github_username // ""' "$_devkit_identity_file")"
export DEVKIT_IDENTITY_GPG_SIGNING_KEY="$(jq -r '.gpg_signing_key // ""' "$_devkit_identity_file")"
export DEVKIT_IDENTITY_WORK_GH_ORGS="$(jq -r '(.work_gh_orgs // []) | join(" ")' "$_devkit_identity_file")"

for field in DEVKIT_IDENTITY_FULL_NAME DEVKIT_IDENTITY_EMAIL_PERSONAL DEVKIT_IDENTITY_GITHUB_USERNAME; do
    if [[ -z "${!field}" ]]; then
        json_field="$(echo "$field" | sed 's/^DEVKIT_IDENTITY_//' | tr '[:upper:]' '[:lower:]')"
        echo "ERROR: Required field '$json_field' is empty in $_devkit_identity_file." >&2
        return 1 2>/dev/null || exit 1
    fi
done

unset _devkit_identity_file
