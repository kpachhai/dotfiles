#!/usr/bin/env bash
# Test harness for load-identity.sh. Run from dotfiles repo root.
# Sets up isolated $HOME, runs the loader, asserts behavior.

set -euo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/executable_load-identity.sh"
PASS=0
FAIL=0

assert() {
    local desc="$1"
    local expected="$2"
    local actual="$3"
    if [[ "$actual" == "$expected" ]]; then
        echo "PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $desc"
        echo "  expected: $expected"
        echo "  actual:   $actual"
        FAIL=$((FAIL + 1))
    fi
}

# Test 1: missing file → exit 1 with helpful pointer
TMP="$(mktemp -d)"
HOME="$TMP" bash -c "source $SCRIPT" > "$TMP/out" 2> "$TMP/err" && rc=0 || rc=$?
assert "missing JSON exits non-zero" "1" "$rc"
assert "missing JSON prints setup pointer" "yes" "$(grep -q 'devkit/identity.json' "$TMP/err" && echo yes || echo no)"
rm -rf "$TMP"

# Test 2: valid JSON → exports DEVKIT_IDENTITY_* vars
TMP="$(mktemp -d)"
mkdir -p "$TMP/.config/devkit"
cat > "$TMP/.config/devkit/identity.json" <<'JSON'
{
  "full_name": "Test User",
  "email_personal": "test@example.com",
  "email_work": "test@work.example.com",
  "github_username": "testuser",
  "gpg_signing_key": "ABCDEF1234567890",
  "work_gh_orgs": ["org1", "org2"]
}
JSON
HOME="$TMP" bash -c "source $SCRIPT && echo \"\$DEVKIT_IDENTITY_FULL_NAME|\$DEVKIT_IDENTITY_EMAIL_PERSONAL|\$DEVKIT_IDENTITY_GITHUB_USERNAME|\$DEVKIT_IDENTITY_WORK_GH_ORGS\"" > "$TMP/out"
assert "valid JSON exports vars" "Test User|test@example.com|testuser|org1 org2" "$(cat "$TMP/out")"
rm -rf "$TMP"

# Test 3: missing required field → exit 1
TMP="$(mktemp -d)"
mkdir -p "$TMP/.config/devkit"
cat > "$TMP/.config/devkit/identity.json" <<'JSON'
{
  "full_name": "",
  "email_personal": "test@example.com",
  "github_username": "testuser"
}
JSON
HOME="$TMP" bash -c "source $SCRIPT" > "$TMP/out" 2> "$TMP/err" && rc=0 || rc=$?
assert "empty required field exits non-zero" "1" "$rc"
assert "empty required field names the field" "yes" "$(grep -q 'full_name' "$TMP/err" && echo yes || echo no)"
rm -rf "$TMP"

echo
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
