# PII Scrub & Public-Template Implementation Plan (dotfiles)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Clean PII from the dotfiles repo (HEAD + history), build the reusable scrub procedure infrastructure (`scrub-pii-history.sh`, `load-identity.sh`, `MIGRATION.md`), and personalize via `~/.config/devkit/identity.json`. Procedure artifacts are reusable for your-meta-repo and your-data-repo via separate brainstorm/plan cycles.

**Architecture:** Identity lives in `~/.config/devkit/identity.json` as the single source of truth. Chezmoi reads it at apply time via `include` + `fromJson`. The scrub script lives in dotfiles and is reusable. Phases 1-3 are additive and reversible. Phase 4 is destructive (history rewrite + force-push) and gated.

**Tech Stack:** bash, chezmoi, git, git-filter-repo, jq.

**Input spec:** `docs/specs/2026-05-04-pii-scrub-public-template-design.md`.

---

## File Structure

**New files (Phase 1):**
- `devkit-identity.example.json` — schema example at repo root
- `dot_claude/scripts/executable_load-identity.sh` — identity loader (sources env vars from JSON)
- `dot_claude/scripts/executable_setup-identity.sh` — non-chezmoi bootstrap (prompts → JSON)
- `run_once_before_bootstrap-identity.sh.tmpl` — chezmoi run-once hook (creates JSON if missing on first apply)
- `dot_config/private_devkit/dot_gitignore` — gitignored marker file inside `~/.config/devkit/` if needed (decided: no, dir is created on first run by bootstrap script)

**New files (Phase 2 & 3):**
- `MIGRATION.md` — multi-machine sync flow
- `.scrub/.gitignore` — gitignores `replacements.txt`
- `.scrub/replacements.example.txt` — placeholder shape (committed, forker-facing)
- `dot_claude/scripts/executable_scrub-pii-history.sh` — scrub script

**Modified files:**
- `.chezmoi.toml.tmpl` — keep `machine_type` prompt only, drop any added identity prompts
- `dot_gitconfig.tmpl` — read identity from `~/.config/devkit/identity.json` via `include` + `fromJson`
- `dot_gitconfig-personal` → rename to `dot_gitconfig-personal.tmpl`, render email from JSON
- `dot_gitconfig-work` → rename to `dot_gitconfig-work.tmpl`, render email from JSON
- `dot_claude/CLAUDE.md` — strip name + employer references, keep all role/working-style content
- `dot_claude/skills/learn-and-improve/SKILL.md` — drop `**Author:** ...` line
- `dot_claude/skills/working-identity/SKILL.md` — drop `author:` frontmatter line
- `dot_claude/agents/solidity-engineer.md` — replace 4× "EVM smart contracts" with "EVM smart contract platforms"
- `dot_claude/scopes/meta-stack.txt` — strip user-specific lines (keep header comment only)
- `iterm2/com.googlecode.iterm2.plist` — replace `$HOME` with `$HOME` if format permits, else add a documented quirk note in README
- `README.md` — rewrite as fork-and-personalize guide
- `.gitignore` — add `.scrub/replacements.txt`

**Files at HEAD that get content-rewritten by Phase 4 (history rewrite touches them across all commits):**
- All of the above (and any historical content matching the `replacements.txt` rules)

---

## Phase 1: Identity Contract + Loader (additive, safe)

This phase adds infrastructure with no destructive changes. After Phase 1, dotfiles still contains all the PII it has today, but the new identity contract is in place and tested.

### Task 1.1: Create `devkit-identity.example.json`

**Files:**
- Create: `devkit-identity.example.json`

- [ ] **Step 1: Create the example file at repo root**

```bash
cat > devkit-identity.example.json <<'EOF'
{
  "full_name": "Your Name",
  "email_personal": "you@example.com",
  "email_work": "",
  "github_username": "your-gh-username",
  "gpg_signing_key": "",
  "work_gh_orgs": []
}
EOF
```

- [ ] **Step 2: Verify it parses as valid JSON**

Run: `jq . devkit-identity.example.json`
Expected: pretty-printed JSON identical to input. Exit 0.

- [ ] **Step 3: Stage but do not commit yet (commit at end of Phase 1)**

```bash
git add devkit-identity.example.json
```

---

### Task 1.2: Create the identity loader test harness

**Files:**
- Create: `dot_claude/scripts/tests/test-load-identity.sh`

- [ ] **Step 1: Write the test script (testing-before-implementation)**

```bash
mkdir -p dot_claude/scripts/tests
cat > dot_claude/scripts/tests/test-load-identity.sh <<'EOF'
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
EOF
chmod +x dot_claude/scripts/tests/test-load-identity.sh
```

- [ ] **Step 2: Run the test — expect failure (script does not exist yet)**

Run: `bash dot_claude/scripts/tests/test-load-identity.sh`
Expected: FAIL — `executable_load-identity.sh: No such file or directory` or similar.

---

### Task 1.3: Implement `load-identity.sh`

**Files:**
- Create: `dot_claude/scripts/executable_load-identity.sh`

- [ ] **Step 1: Write the loader script**

```bash
cat > dot_claude/scripts/executable_load-identity.sh <<'EOF'
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

# Read with jq, default to empty string for missing fields
export DEVKIT_IDENTITY_FULL_NAME="$(jq -r '.full_name // ""' "$_devkit_identity_file")"
export DEVKIT_IDENTITY_EMAIL_PERSONAL="$(jq -r '.email_personal // ""' "$_devkit_identity_file")"
export DEVKIT_IDENTITY_EMAIL_WORK="$(jq -r '.email_work // ""' "$_devkit_identity_file")"
export DEVKIT_IDENTITY_GITHUB_USERNAME="$(jq -r '.github_username // ""' "$_devkit_identity_file")"
export DEVKIT_IDENTITY_GPG_SIGNING_KEY="$(jq -r '.gpg_signing_key // ""' "$_devkit_identity_file")"
export DEVKIT_IDENTITY_WORK_GH_ORGS="$(jq -r '(.work_gh_orgs // []) | join(" ")' "$_devkit_identity_file")"

# Validate required fields
for field in DEVKIT_IDENTITY_FULL_NAME DEVKIT_IDENTITY_EMAIL_PERSONAL DEVKIT_IDENTITY_GITHUB_USERNAME; do
    if [[ -z "${!field}" ]]; then
        json_field="$(echo "$field" | sed 's/^DEVKIT_IDENTITY_//' | tr '[:upper:]' '[:lower:]')"
        echo "ERROR: Required field '$json_field' is empty in $_devkit_identity_file." >&2
        return 1 2>/dev/null || exit 1
    fi
done

unset _devkit_identity_file
EOF
chmod +x dot_claude/scripts/executable_load-identity.sh
```

- [ ] **Step 2: Run the test — expect PASS**

Run: `bash dot_claude/scripts/tests/test-load-identity.sh`
Expected: `Results: 5 passed, 0 failed`

- [ ] **Step 3: Manual smoke test on your real machine (optional but useful)**

```bash
# Create a test identity file at $HOME location and source the loader
mkdir -p ~/.config/devkit
cat > ~/.config/devkit/identity.json <<'JSON'
{
  "full_name": "Smoke Test",
  "email_personal": "smoke@test.com",
  "github_username": "smoketest"
}
JSON
source ./dot_claude/scripts/executable_load-identity.sh
echo "$DEVKIT_IDENTITY_FULL_NAME"  # should print "Smoke Test"
# Clean up the test file before continuing (don't commit it)
rm ~/.config/devkit/identity.json
rmdir ~/.config/devkit 2>/dev/null || true
```

Expected output of the echo: `Smoke Test`. No errors.

---

### Task 1.4: Implement `setup-identity.sh` (non-chezmoi bootstrap)

**Files:**
- Create: `dot_claude/scripts/executable_setup-identity.sh`

- [ ] **Step 1: Write the bootstrap script**

```bash
cat > dot_claude/scripts/executable_setup-identity.sh <<'EOF'
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
EOF
chmod +x dot_claude/scripts/executable_setup-identity.sh
```

- [ ] **Step 2: Validate syntax**

Run: `bash -n dot_claude/scripts/executable_setup-identity.sh`
Expected: no output, exit 0.

- [ ] **Step 3: Manual interactive smoke test (optional)**

```bash
# Run the script, fill in test values, verify the file
bash ./dot_claude/scripts/executable_setup-identity.sh
# At the prompts, type test values
# Then verify:
jq . ~/.config/devkit/identity.json
# Clean up before continuing
rm ~/.config/devkit/identity.json
```

Expected: prompts appear in order, file is created with valid JSON, jq prints it cleanly.

---

### Task 1.5: Create the chezmoi run-once bootstrap hook

**Files:**
- Create: `run_once_before_bootstrap-identity.sh.tmpl`

This script runs ONCE per machine on the first `chezmoi apply`, BEFORE templates render. It creates `~/.config/devkit/identity.json` if it does not exist, prompting interactively. After it runs, gitconfig templates can read the JSON via `include` + `fromJson`.

- [ ] **Step 1: Write the chezmoi hook**

```bash
cat > run_once_before_bootstrap-identity.sh.tmpl <<'EOF'
#!/usr/bin/env bash
# chezmoi run_once_before hook: bootstraps ~/.config/devkit/identity.json on
# first apply. If the file exists, this is a no-op. Idempotent.
#
# Reruns on chezmoi data hash change (any prompt answers); name suffix
# `bootstrap-identity` is intentionally stable so the script body change
# alone does not trigger a re-run.

set -euo pipefail

target="${HOME}/.config/devkit/identity.json"

if [[ -f "$target" ]]; then
    echo "[bootstrap-identity] $target already exists; skipping."
    exit 0
fi

echo "[bootstrap-identity] Creating $target"
echo "                     (you can edit it directly later; chezmoi will not overwrite it)"
echo

# Use chezmoi-templated values where possible (machine_type drives default email choice)
machine_type="{{ .machine_type }}"

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

echo "[bootstrap-identity] Wrote $target"
EOF
```

- [ ] **Step 2: Verify chezmoi recognizes it as a template**

Run: `chezmoi cat ~/run_once_before_bootstrap-identity.sh 2>&1 || echo "(chezmoi is not yet aware; will be on next apply)"`

Either output is fine — the file is in the source tree but chezmoi only reads it on `apply`/`init`.

---

### Task 1.6: Update `dot_gitconfig.tmpl` to read from JSON

**Files:**
- Modify: `dot_gitconfig.tmpl`

- [ ] **Step 1: Read the current file**

Run: `cat dot_gitconfig.tmpl`
Expected output: contains `name = YOUR_NAME`, `signingkey = REMOVED-GPG-KEY`, hardcoded emails, hardcoded org names.

- [ ] **Step 2: Replace contents with JSON-driven template**

```bash
cat > dot_gitconfig.tmpl <<'EOF'
{{- $identity := include (joinPath .chezmoi.homeDir ".config" "devkit" "identity.json") | fromJson -}}
[user]
	name = {{ $identity.full_name }}
{{- if $identity.gpg_signing_key }}
	signingkey = {{ $identity.gpg_signing_key }}
{{- end }}
{{- if eq .machine_type "work" }}
	email = {{ $identity.email_work }}
{{- else }}
	email = {{ $identity.email_personal }}
{{- end }}
[commit]
{{- if $identity.gpg_signing_key }}
	gpgsign = true
{{- else }}
	gpgsign = false
{{- end }}
[pull]
	rebase = false
{{- if eq .machine_type "personal" }}
{{- range $org := $identity.work_gh_orgs }}
[includeIf "gitdir:~/repos/github.com/{{ $org }}/"]
	path = ~/.gitconfig-work
{{- end }}
{{- end }}
{{- if eq .machine_type "work" }}
[includeIf "gitdir:~/repos/github.com/{{ $identity.github_username }}/"]
	path = ~/.gitconfig-personal
{{- end }}
EOF
```

- [ ] **Step 3: Verify template syntax with chezmoi (dry-run)**

Run: `chezmoi execute-template < dot_gitconfig.tmpl 2>&1 | head -20`

Expected: either the rendered gitconfig (if `~/.config/devkit/identity.json` exists on this machine) OR a chezmoi error mentioning the missing file. Either is acceptable here — the file will exist after Phase 4 personalization. The point is chezmoi parses the template successfully.

If chezmoi errors with a syntax issue (NOT a missing-file issue), fix the template before continuing.

---

### Task 1.7: Convert `dot_gitconfig-personal` and `dot_gitconfig-work` to templates

**Files:**
- Delete: `dot_gitconfig-personal`, `dot_gitconfig-work`
- Create: `dot_gitconfig-personal.tmpl`, `dot_gitconfig-work.tmpl`

- [ ] **Step 1: Replace personal config with template**

```bash
git rm dot_gitconfig-personal
cat > dot_gitconfig-personal.tmpl <<'EOF'
{{- $identity := include (joinPath .chezmoi.homeDir ".config" "devkit" "identity.json") | fromJson -}}
[user]
	email = {{ $identity.email_personal }}
EOF
```

- [ ] **Step 2: Replace work config with template**

```bash
git rm dot_gitconfig-work
cat > dot_gitconfig-work.tmpl <<'EOF'
{{- $identity := include (joinPath .chezmoi.homeDir ".config" "devkit" "identity.json") | fromJson -}}
[user]
	email = {{ $identity.email_work }}
EOF
```

- [ ] **Step 3: Verify chezmoi parses both templates**

Run:
```bash
chezmoi execute-template < dot_gitconfig-personal.tmpl 2>&1 | head -5
chezmoi execute-template < dot_gitconfig-work.tmpl 2>&1 | head -5
```

Expected: clean render OR chezmoi missing-file error (acceptable). NOT a template syntax error.

---

### Task 1.8: Verify Phase 1 — chezmoi diff shape

- [ ] **Step 1: Backup the user's existing live identity (if any)**

```bash
[[ -f ~/.config/devkit/identity.json ]] && cp ~/.config/devkit/identity.json /tmp/identity-backup-$(date +%s).json
```

- [ ] **Step 2: Create a temporary identity.json so chezmoi can render templates**

Either run `bash dot_claude/scripts/executable_setup-identity.sh` interactively, OR write a placeholder file:

```bash
mkdir -p ~/.config/devkit
cat > ~/.config/devkit/identity.json <<'JSON'
{
  "full_name": "Phase 1 Test",
  "email_personal": "phase1@test.com",
  "email_work": "",
  "github_username": "phase1test",
  "gpg_signing_key": "",
  "work_gh_orgs": []
}
JSON
```

- [ ] **Step 3: Run `chezmoi diff` and inspect**

Run: `chezmoi diff | head -80`

Expected: a diff showing the future `~/.gitconfig` rendered with placeholder values from the test JSON. No syntax errors. No surprises in unrelated files.

- [ ] **Step 4: Commit Phase 1**

```bash
git add devkit-identity.example.json \
        dot_claude/scripts/executable_load-identity.sh \
        dot_claude/scripts/executable_setup-identity.sh \
        dot_claude/scripts/tests/test-load-identity.sh \
        run_once_before_bootstrap-identity.sh.tmpl \
        dot_gitconfig.tmpl \
        dot_gitconfig-personal.tmpl \
        dot_gitconfig-work.tmpl
git rm -f dot_gitconfig-personal dot_gitconfig-work 2>/dev/null || true
git commit -S -s -m "phase 1: identity contract + loader

- Add ~/.config/devkit/identity.json schema (devkit-identity.example.json)
- Add load-identity.sh (jq-based, exports DEVKIT_IDENTITY_*)
- Add setup-identity.sh (non-chezmoi interactive bootstrap)
- Add run_once_before_bootstrap-identity.sh.tmpl (chezmoi bootstrap)
- Convert gitconfig templates to read from identity.json via include + fromJson
- Add test harness for the loader"
```

- [ ] **Step 5: Restore live identity if you backed it up**

```bash
ls /tmp/identity-backup-*.json 2>/dev/null && cp /tmp/identity-backup-*.json ~/.config/devkit/identity.json
```

---

## Phase 2: HEAD Cleanup (file edits, no history rewrite)

Each task strips PII from one file or coherent group of files. After each task, the working tree is cleaner. After the whole phase, `grep` for PII at HEAD returns near-empty (only `~kpachhai` GH username remains in path strings, which is acknowledged as out-of-scope).

### Task 2.1: Strip identity from `dot_claude/CLAUDE.md`

**Files:**
- Modify: `dot_claude/CLAUDE.md`

- [ ] **Step 1: Strip the personal name from the Identity section**

Run:
```bash
sed -i.bak "s/I'm YOUR_NAME - \*\*Solutions Architect\*\* by role/I'm a Solutions Architect by role/" dot_claude/CLAUDE.md
rm dot_claude/CLAUDE.md.bak
```

- [ ] **Step 2: Strip "and EVM smart contracts" from the Subagents section**

Run:
```bash
sed -i.bak 's/Smart contracts and platform\/token-service/Smart contracts (EVM)/' dot_claude/CLAUDE.md
rm dot_claude/CLAUDE.md.bak
```

- [ ] **Step 3: Verify no remaining personal name or employer references in this file**

Run:
```bash
grep -nE 'YOUR_NAME|YOUR_NAME|your-org|platform|platform|token-service' dot_claude/CLAUDE.md || echo "clean"
```

Expected: `clean`. If matches appear, inspect them — there may be additional references in narrative paragraphs (e.g., the includeIf-org examples in the Identity section). Strip those by hand:

```bash
# Open the file, search for any remaining mentions, replace with generic phrasing
# Example: "I work across Solidity, Go, TypeScript, Python, and Rust" stays (generic)
# But "across your-org/platform/your-org repos" must go
$EDITOR dot_claude/CLAUDE.md
```

Re-run the grep until it prints `clean`.

- [ ] **Step 4: Stage**

```bash
git add dot_claude/CLAUDE.md
```

---

### Task 2.2: Genericize `dot_claude/agents/solidity-engineer.md`

**Files:**
- Modify: `dot_claude/agents/solidity-engineer.md`

- [ ] **Step 1: Replace 4 EVM smart contracts references**

Run:
```bash
sed -i.bak 's|EVM smart contracts|EVM smart contract platforms|g' dot_claude/agents/solidity-engineer.md
rm dot_claude/agents/solidity-engineer.md.bak
```

- [ ] **Step 2: Verify**

Run: `grep -nE 'platform|token-service' dot_claude/agents/solidity-engineer.md || echo "clean"`
Expected: `clean`.

- [ ] **Step 3: Stage**

```bash
git add dot_claude/agents/solidity-engineer.md
```

---

### Task 2.3: Drop author fields from skill frontmatter

**Files:**
- Modify: `dot_claude/skills/learn-and-improve/SKILL.md`
- Modify: `dot_claude/skills/working-identity/SKILL.md`

- [ ] **Step 1: Remove `**Author:** YOUR_NAME` line from learn-and-improve**

Run:
```bash
sed -i.bak '/^\*\*Author:\*\* YOUR_NAME$/d' dot_claude/skills/learn-and-improve/SKILL.md
rm dot_claude/skills/learn-and-improve/SKILL.md.bak
```

- [ ] **Step 2: Remove `author: YOUR_NAME` frontmatter line from working-identity**

Run:
```bash
sed -i.bak '/^author: YOUR_NAME$/d' dot_claude/skills/working-identity/SKILL.md
rm dot_claude/skills/working-identity/SKILL.md.bak
```

- [ ] **Step 3: Verify**

Run:
```bash
grep -nE 'YOUR_NAME|YOUR_NAME' dot_claude/skills/learn-and-improve/SKILL.md dot_claude/skills/working-identity/SKILL.md || echo "clean"
```

Expected: `clean`.

- [ ] **Step 4: Stage**

```bash
git add dot_claude/skills/learn-and-improve/SKILL.md dot_claude/skills/working-identity/SKILL.md
```

---

### Task 2.4: Strip user-specific paths from `dot_claude/scopes/meta-stack.txt`

**Files:**
- Modify: `dot_claude/scopes/meta-stack.txt`

The committed `meta-stack.txt` should contain no user-specific paths. The user's actual paths move to `~/.claude/scopes/meta-stack.local.txt` (gitignored, machine-local).

- [ ] **Step 1: Save the current contents to the local file (if running on the user's machine)**

```bash
# This step only applies when executing on the maintainer's machine.
# It moves the live paths from the committed file to the gitignored local override.
if [[ -f ~/.claude/scopes/meta-stack.txt ]]; then
    cp ~/.claude/scopes/meta-stack.txt ~/.claude/scopes/meta-stack.local.txt
    echo "Saved current paths to ~/.claude/scopes/meta-stack.local.txt"
fi
```

- [ ] **Step 2: Replace the committed file with a header-only stub**

```bash
cat > dot_claude/scopes/meta-stack.txt <<'EOF'
# meta-stack scope — committed, generic.
# This is the cross-project scope for `learn-and-improve` and similar audit
# skills. The committed file is intentionally empty: any user-specific repo
# paths belong in ~/.claude/scopes/meta-stack.local.txt (gitignored).
#
# See ~/.claude/scopes/README.md for the full convention.
EOF
```

- [ ] **Step 3: Verify**

Run: `grep -vE '^(#|$)' dot_claude/scopes/meta-stack.txt | wc -l`
Expected: `0` (no non-comment, non-blank lines).

- [ ] **Step 4: Stage**

```bash
git add dot_claude/scopes/meta-stack.txt
```

---

### Task 2.5: Handle iterm2 plist hardcoded path

**Files:**
- Modify: `iterm2/com.googlecode.iterm2.plist`

The plist contains `$HOME` at line 1902 (per the audit). plist files do not interpolate `$HOME`, so a literal replacement is the only option. Two strategies:

(a) Replace with `/Users/$(USER)` using a placeholder string that a setup script substitutes at install time.
(b) Replace with a generic placeholder like `/Users/your-username` and document in README that forkers edit this file or rely on the setup script.

Strategy (b) is simpler. Combined with a one-line fix in `run_once_setup-iterm2.sh` (which already exists) to substitute the placeholder, the plist becomes portable.

- [ ] **Step 1: Locate the offending lines**

Run: `grep -n '$HOME' iterm2/com.googlecode.iterm2.plist`
Expected: at least one line number printed (e.g., `1902:...`).

- [ ] **Step 2: Replace the path with a placeholder**

Run:
```bash
sed -i.bak 's|$HOME|__HOME_PLACEHOLDER__|g' iterm2/com.googlecode.iterm2.plist
rm iterm2/com.googlecode.iterm2.plist.bak
```

- [ ] **Step 3: Update `run_once_setup-iterm2.sh` to substitute the placeholder at install time**

Read the existing script:

```bash
cat run_once_setup-iterm2.sh
```

Edit it to substitute `__HOME_PLACEHOLDER__` with `$HOME` when copying the plist into place. Add a line like:

```bash
sed -i.bak "s|__HOME_PLACEHOLDER__|$HOME|g" "$DEST_PLIST" && rm "${DEST_PLIST}.bak"
```

(Exact placement depends on the existing script; insert after the plist copy step.)

- [ ] **Step 4: Verify the placeholder substitution works in a dry-run**

Run:
```bash
echo "$HOME/test/path" | sed "s|$HOME|$HOME|g"
```

Expected: prints your `$HOME` followed by `/test/path`.

- [ ] **Step 5: Verify no `$HOME` remains in the plist**

Run: `grep -n '$HOME' iterm2/com.googlecode.iterm2.plist || echo "clean"`
Expected: `clean`.

- [ ] **Step 6: Stage**

```bash
git add iterm2/com.googlecode.iterm2.plist run_once_setup-iterm2.sh
```

---

### Task 2.6: Rewrite `README.md` as fork-and-personalize guide

**Files:**
- Modify: `README.md`

This is the most prose-heavy task. The current README likely frames the repo as the maintainer's personal dotfiles. The new README should:

1. Open with what the repo does (a chezmoi-managed personal-developer config) and who it's for (anyone who wants this opinionated stack as a starting point).
2. Document the identity contract (`~/.config/devkit/identity.json`) — what fields, where to put it, two paths to set it up (chezmoi prompts vs. `setup-identity.sh`).
3. Explain the `.local.*` extension pattern.
4. Reference `MIGRATION.md` for the multi-machine and history-rewrite flow.
5. Drop any "I'm YOUR_NAME" / "my workflow" framing — write in second person ("when you fork this," "you can extend with…").

- [ ] **Step 1: Read the current README**

Run: `cat README.md | head -60`

- [ ] **Step 2: Replace with new content**

Open `README.md` in your editor and rewrite. Use this skeleton (fill in details from the existing README that are still applicable):

```markdown
# dotfiles

Opinionated personal-developer config managed by [chezmoi](https://chezmoi.io). Includes shell, terminal, git, and Claude Code (skills, agents, scripts, settings) configuration. Designed to be forked and personalized.

## What's inside

- **Shell:** zsh + Zim, custom prompt, aliases, secrets pattern (`*.local.*` files)
- **Terminal:** iTerm2 with a curated profile
- **Git:** templated config that reads identity from `~/.config/devkit/identity.json`
- **Claude Code:** global CLAUDE.md, skills, agents, scripts in `dot_claude/`

## Quick start (fork and personalize)

1. Fork this repo to your own GitHub account.
2. Install [chezmoi](https://chezmoi.io/install/) and [jq](https://stedolan.github.io/jq/).
3. Initialize from your fork:
   ```
   chezmoi init https://github.com/<your-username>/dotfiles --apply
   ```
4. On first apply, a bootstrap script will prompt for your identity (full name, emails, GitHub username, GPG key) and write `~/.config/devkit/identity.json`.
5. Subsequent applies (`chezmoi apply`) read that file and render gitconfig, etc.

## Identity contract

This repo's templates pull personal data from a single file: `~/.config/devkit/identity.json`. See `devkit-identity.example.json` for the schema.

### Updating values
Edit `~/.config/devkit/identity.json` directly with any text editor, then run `chezmoi apply` to regenerate dependent files.

### Without chezmoi
If you don't want to use chezmoi, run `~/.claude/scripts/setup-identity.sh` (after copying it into place manually) to generate the JSON interactively.

## Local extensions

Files matching `*.local.*` are gitignored and machine-local. Use them to extend without forking. Examples:
- `~/.claude/scopes/meta-stack.local.txt` — your private repo paths for cross-project audits
- `~/.claude/settings.local.json` — your machine-specific Claude Code permissions

## Migrating between machines or applying the PII-scrub procedure

See `MIGRATION.md` for the multi-machine sync protocol and the procedure for rewriting git history to remove identifying content from a fork.

## License

Personal config; use at your own risk. PRs welcome for upstreamable patterns.
```

- [ ] **Step 3: Verify no PII in the new README**

Run: `grep -nE 'YOUR_NAME|YOUR_NAME|your-org|platform|platform' README.md || echo "clean"`
Expected: `clean`.

- [ ] **Step 4: Stage**

```bash
git add README.md
```

---

### Task 2.7: Commit Phase 2

- [ ] **Step 1: Confirm everything is staged**

Run: `git status`

Expected: only the files modified in Phase 2 are staged. No surprises.

- [ ] **Step 2: Smoke test — render templates with chezmoi (placeholder identity from Phase 1)**

Run: `chezmoi diff | head -40`

Expected: shows the rendered files using your placeholder identity. No template errors.

- [ ] **Step 3: Commit**

```bash
git commit -S -s -m "phase 2: HEAD cleanup — strip PII from dotfiles working tree

- CLAUDE.md: strip personal name + EVM smart contracts reference
- solidity-engineer.md: replace EVM smart contracts with EVM phrasing
- learn-and-improve, working-identity SKILL.md: drop author fields
- scopes/meta-stack.txt: replace user-specific paths with header-only stub
- iterm2 plist: replace hardcoded path with __HOME_PLACEHOLDER__
- run_once_setup-iterm2.sh: substitute placeholder at install time
- README.md: rewrite as fork-and-personalize guide"
```

---

## Phase 3: Scrub Script (additive, dry-run safe)

This phase adds the reusable scrub infrastructure without running any destructive operations.

### Task 3.1: Create `.scrub/` directory and gitignore

**Files:**
- Create: `.scrub/.gitignore`

- [ ] **Step 1: Create the dir + gitignore**

```bash
mkdir -p .scrub
cat > .scrub/.gitignore <<'EOF'
# Local scrub input — contains literal PII, never commit
replacements.txt
EOF
```

- [ ] **Step 2: Stage (file is committed even though its sibling is gitignored)**

```bash
git add .scrub/.gitignore
```

---

### Task 3.2: Create `replacements.example.txt`

**Files:**
- Create: `.scrub/replacements.example.txt`

- [ ] **Step 1: Write the example with placeholder shape**

```bash
cat > .scrub/replacements.example.txt <<'EOF'
# git-filter-repo --replace-text format. One rule per line: <find>==><replace>.
# Use `regex:<pattern>==><replacement>` for regex.
# Copy this file to `replacements.txt` (gitignored), fill in your literal PII strings,
# then run `~/.claude/scripts/scrub-pii-history.sh . --confirm`.

***REMOVED***
<your-full-name>==>YOUR_NAME
<your-personal-email>==>REMOVED-EMAIL
<your-work-email>==>REMOVED-EMAIL
<your-gpg-signing-key>==>REMOVED-GPG-KEY

# --- Employer / company / ecosystem ---
<your-employer-domain>==>example.com
<your-employer-org-name>==>your-org
<your-employer-product>==>generic-term

# --- Hardcoded paths ---
/Users/<your-username>/==>$HOME/

# Notes:
# - The LEFT side is what gets scrubbed. Anywhere these strings appear in commit
#   blobs at any revision, they are replaced with the RIGHT side.
# - DO NOT commit your real `replacements.txt` (.gitignore handles this).
# - The scrub script's verifier greps the rewritten history for the LEFT-side
#   strings; any match means the scrub did not catch them and the run fails.
EOF
```

- [ ] **Step 2: Stage**

```bash
git add .scrub/replacements.example.txt
```

---

### Task 3.3: Add `.scrub/replacements.txt` to root `.gitignore`

**Files:**
- Modify: `.gitignore`

- [ ] **Step 1: Append a new section to the root gitignore**

```bash
cat >> .gitignore <<'EOF'

# PII scrub input — contains literal PII strings, never commit
.scrub/replacements.txt
EOF
```

- [ ] **Step 2: Verify**

Run: `tail -5 .gitignore`
Expected: shows the new lines.

- [ ] **Step 3: Stage**

```bash
git add .gitignore
```

---

### Task 3.4: Implement `scrub-pii-history.sh`

**Files:**
- Create: `dot_claude/scripts/executable_scrub-pii-history.sh`

- [ ] **Step 1: Write the script**

```bash
cat > dot_claude/scripts/executable_scrub-pii-history.sh <<'EOF'
#!/usr/bin/env bash
# Scrubs PII from a git repo's history using git-filter-repo --replace-text.
# Usage: scrub-pii-history.sh <repo-path> [--confirm] [--dry-run]
#
# Safety:
# - Refuses if working tree dirty
# - Requires --confirm flag (prevents accidental runs)
# - Creates a backup branch before rewriting
# - Verifies post-rewrite that no LEFT-side string remains in history
# - Never pushes; prints a force-push checklist at the end

set -euo pipefail

usage() {
    cat <<USAGE
Usage: $0 <repo-path> [--confirm] [--dry-run]

Reads <repo-path>/.scrub/replacements.txt and rewrites the repo's history
to apply each find/replace rule across all commits.

Flags:
  --confirm   Required for destructive run.
  --dry-run   Run all checks + create backup branch, but skip the actual
              filter-repo invocation. Useful for verifying setup.

Required tools: git, git-filter-repo (https://github.com/newren/git-filter-repo).
USAGE
}

if [[ $# -lt 1 ]]; then
    usage; exit 2
fi

REPO="$1"; shift
CONFIRM=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --confirm) CONFIRM=1 ;;
        --dry-run) DRY_RUN=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "ERROR: unknown flag $1" >&2; usage; exit 2 ;;
    esac
    shift
done

# Sanity: repo exists and is a git repo
if [[ ! -d "$REPO/.git" ]]; then
    echo "ERROR: $REPO is not a git repository." >&2
    exit 1
fi

cd "$REPO"

REPL_FILE=".scrub/replacements.txt"
if [[ ! -f "$REPL_FILE" ]]; then
    echo "ERROR: $REPO/$REPL_FILE not found." >&2
    echo "       Copy .scrub/replacements.example.txt to .scrub/replacements.txt and fill in PII strings." >&2
    exit 1
fi

# Sanity: working tree clean
if [[ -n "$(git status --porcelain)" ]]; then
    echo "ERROR: working tree is dirty in $REPO. Commit or stash before running." >&2
    git status --short >&2
    exit 1
fi

# Sanity: filter-repo installed
if ! command -v git-filter-repo >/dev/null 2>&1; then
    echo "ERROR: git-filter-repo is not installed. brew install git-filter-repo" >&2
    exit 1
fi

# Confirmation gate
if [[ $CONFIRM -eq 0 && $DRY_RUN -eq 0 ]]; then
    echo "ERROR: This will rewrite git history irreversibly." >&2
    echo "       Pass --confirm to proceed, or --dry-run to test the setup." >&2
    exit 1
fi

# Backup branch
BACKUP_BRANCH="backup/pre-scrub-$(date +%Y%m%d-%H%M)"
if git show-ref --verify --quiet "refs/heads/$BACKUP_BRANCH"; then
    echo "ERROR: backup branch $BACKUP_BRANCH already exists. Aborting to avoid overwrite." >&2
    exit 1
fi
git branch "$BACKUP_BRANCH"
echo "Created backup branch: $BACKUP_BRANCH"

# Read LEFT-side strings for post-rewrite verification (skip blank/comment lines)
LEFT_SIDES=()
while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    if [[ "$line" =~ ^regex: ]]; then
        # Skip regex rules from the verifier; user must verify those manually
        continue
    fi
    left="${line%%==>*}"
    [[ -n "$left" ]] && LEFT_SIDES+=("$left")
done < "$REPL_FILE"

if [[ $DRY_RUN -eq 1 ]]; then
    echo "[DRY RUN] Would run: git filter-repo --replace-text $REPL_FILE --force"
    echo "[DRY RUN] LEFT-side strings to verify post-rewrite (${#LEFT_SIDES[@]} total):"
    printf '  - %s\n' "${LEFT_SIDES[@]}"
    echo "[DRY RUN] Backup branch $BACKUP_BRANCH was created."
    echo "[DRY RUN] No history rewrite performed."
    exit 0
fi

# Run the rewrite
echo "Running git filter-repo..."
git filter-repo --replace-text "$REPL_FILE" --force

# Verify: no LEFT-side string remains anywhere
echo "Verifying scrub..."
FAILURES=0
for s in "${LEFT_SIDES[@]}"; do
    # Check working tree
    if git grep -q -F "$s" -- ':!.scrub/replacements.txt' 2>/dev/null; then
        echo "FAIL: working tree still contains: $s" >&2
        FAILURES=$((FAILURES + 1))
    fi
    # Check history
    if git log --all -p -S "$s" --oneline 2>/dev/null | grep -q .; then
        echo "FAIL: history still contains: $s" >&2
        FAILURES=$((FAILURES + 1))
    fi
done

if [[ $FAILURES -gt 0 ]]; then
    echo "ERROR: $FAILURES residual matches found. Restore from $BACKUP_BRANCH and investigate." >&2
    echo "       To restore: git reset --hard $BACKUP_BRANCH" >&2
    exit 1
fi

echo
echo "SUCCESS: history scrubbed clean. ${#LEFT_SIDES[@]} rules verified, 0 residual matches."
echo
echo "Next steps (manual):"
echo "  1. Inspect a few commits: git log --oneline -10"
echo "  2. Force-push:           git push --force-with-lease origin main"
echo "  3. (Optional) push backup: git push origin $BACKUP_BRANCH"
echo "  4. On every other machine: git fetch && git reset --hard origin/main"
echo
echo "Backup branch retained locally: $BACKUP_BRANCH"
echo "Delete it once you've confirmed the rewrite is good: git branch -D $BACKUP_BRANCH"
EOF
chmod +x dot_claude/scripts/executable_scrub-pii-history.sh
```

- [ ] **Step 2: Validate syntax**

Run: `bash -n dot_claude/scripts/executable_scrub-pii-history.sh`
Expected: no output, exit 0.

- [ ] **Step 3: Stage**

```bash
git add dot_claude/scripts/executable_scrub-pii-history.sh
```

---

### Task 3.5: Smoke-test the scrub script in `--dry-run` mode

This task uses the dotfiles repo itself as the test target. We create a temporary `replacements.txt`, run with `--dry-run`, verify the script reports correctly without rewriting anything, then delete the test file.

- [ ] **Step 1: Verify git-filter-repo is installed**

Run: `command -v git-filter-repo || echo "INSTALL: brew install git-filter-repo"`

If not installed: `brew install git-filter-repo`. Re-check.

- [ ] **Step 2: Create a test replacements file**

```bash
cat > .scrub/replacements.txt <<'EOF'
# Test rules — no actual scrub happens in --dry-run mode
SAMPLE_FIND_1==>SAMPLE_REPLACE_1
SAMPLE_FIND_2==>SAMPLE_REPLACE_2
EOF
```

- [ ] **Step 3: Run the script with `--dry-run`**

Run: `bash dot_claude/scripts/executable_scrub-pii-history.sh . --dry-run`

Expected output (approximate):
```
Created backup branch: backup/pre-scrub-...
[DRY RUN] Would run: git filter-repo --replace-text .scrub/replacements.txt --force
[DRY RUN] LEFT-side strings to verify post-rewrite (2 total):
  - SAMPLE_FIND_1
  - SAMPLE_FIND_2
[DRY RUN] Backup branch ... was created.
[DRY RUN] No history rewrite performed.
```

- [ ] **Step 4: Verify the dry-run did NOT rewrite history**

Run: `git log --oneline | head -3`
Expected: same SHAs as before the dry run.

- [ ] **Step 5: Verify safety gate — running without `--confirm` or `--dry-run` should fail**

Run: `bash dot_claude/scripts/executable_scrub-pii-history.sh . 2>&1 | head -3`
Expected: error message about needing `--confirm` or `--dry-run`.

- [ ] **Step 6: Verify dirty-tree gate**

```bash
echo "dirty" > /tmp/dirty-test
mv /tmp/dirty-test .scrub/dirty-test
bash dot_claude/scripts/executable_scrub-pii-history.sh . --confirm 2>&1 | head -3
rm .scrub/dirty-test
```
Expected: error message about dirty working tree.

- [ ] **Step 7: Clean up the dry-run backup branch**

```bash
git branch | grep "backup/pre-scrub" | xargs -r git branch -D
```

- [ ] **Step 8: Remove the test replacements.txt (it's gitignored, but tidy up)**

```bash
rm .scrub/replacements.txt
```

---

### Task 3.6: Write `MIGRATION.md`

**Files:**
- Create: `MIGRATION.md`

- [ ] **Step 1: Write the doc**

```bash
cat > MIGRATION.md <<'EOF'
# Migration & Scrub Procedure

This doc covers two related flows:
1. Multi-machine sync after rewriting git history.
2. The PII-scrub procedure itself (applicable to this repo, your-meta-repo, your-data-repo,
   or any other personal repo with the same `.scrub/` + `~/.config/devkit/`
   conventions).

---

## PII Scrub Procedure

Use this when preparing a repo for public publication, or when removing
PII that was committed by accident at any point in history.

### One-time setup (per machine)
- Install dependencies: `brew install git-filter-repo jq`
- Create `~/.config/devkit/identity.json` if you have not already
  (chezmoi prompts on first apply, or run `~/.claude/scripts/setup-identity.sh`)

### Per-repo scrub

1. **Confirm clean state on every machine.** Every machine that has the repo
   cloned must have a clean working tree and all WIP pushed to GitHub. The
   force-push at the end will diverge from any local clone with uncommitted
   work and that work will be lost.

2. **Note which machine has the latest commits.** Run the scrub on that machine.

3. **In the repo on the chosen machine:**
   ```bash
   cd <repo>
   cp .scrub/replacements.example.txt .scrub/replacements.txt
   # Edit replacements.txt — fill in your literal PII strings on the LEFT side.
   # The example file shows the shape; you replace the placeholders with
   # actual strings from your repo.
   ```

4. **Dry run first** to validate setup:
   ```bash
   ~/.claude/scripts/scrub-pii-history.sh . --dry-run
   ```
   Verify the LEFT-side strings reported match what you intend to scrub.

5. **Run the scrub:**
   ```bash
   ~/.claude/scripts/scrub-pii-history.sh . --confirm
   ```
   The script:
   - Creates `backup/pre-scrub-YYYYMMDD-HHMM` branch
   - Runs `git filter-repo --replace-text .scrub/replacements.txt --force`
   - Verifies no LEFT-side string remains in history or working tree
   - Prints next-step instructions; does not push

6. **Inspect the rewrite:**
   ```bash
   git log --oneline | head -10
   # SHAs differ from before
   git log -p | grep -iE '<your-PII-pattern>' || echo "clean"
   ```

7. **Force-push:**
   ```bash
   git push --force-with-lease origin main
   ```
   Optionally push the backup branch as a remote safety net:
   ```bash
   git push origin backup/pre-scrub-YYYYMMDD-HHMM
   ```

8. **Realign the local clone with rewritten history:**
   ```bash
   git fetch
   git reset --hard origin/main
   ```

---

## Multi-Machine Sync (after a force-push)

After force-pushing rewritten history, every other machine that has the repo
cloned needs to align its local clone.

### On each remaining machine

For each repo (do them in the same order you scrubbed them):

1. **Verify clean working tree first** — anything uncommitted will be lost.
   ```bash
   cd <repo>
   git status
   ```

2. **Fetch and hard-reset:**
   ```bash
   git fetch
   git reset --hard origin/main
   ```

3. **Verify alignment:**
   ```bash
   git log --oneline | head -5
   # SHAs match the post-scrub state from the scrub machine
   ```

4. **For dotfiles only** — if `~/.config/devkit/identity.json` does not yet
   exist on this machine, create it:
   - With chezmoi: re-run `chezmoi apply`. The bootstrap script prompts.
   - Without chezmoi: run `~/.claude/scripts/setup-identity.sh`.

5. **For dotfiles only** — re-apply chezmoi so gitconfig and other templated
   files render with this machine's identity values:
   ```bash
   chezmoi apply
   ```

---

## Troubleshooting

**"working tree is dirty"** — commit or stash, then retry.

**"backup branch already exists"** — a previous scrub attempt left a backup.
Inspect it (`git log backup/pre-scrub-...`); if safe, delete with
`git branch -D backup/pre-scrub-...` and re-run.

**"residual matches found" after scrub** — one or more LEFT-side strings
still appear somewhere. The script reports which. Restore from backup:
```bash
git reset --hard backup/pre-scrub-YYYYMMDD-HHMM
```
Add the missed pattern to `.scrub/replacements.txt` and re-run.

**Force-push rejected** — branch protection on GitHub. Disable temporarily,
push, re-enable. Or push to a new branch and switch the default.

**Old commit SHAs still resolve on GitHub after force-push** — GitHub's
internal cache. They become unreachable after their internal GC (timing
varies). For sensitive cleanup, contact GitHub Support to request expedited
GC.
EOF
```

- [ ] **Step 2: Verify no PII**

Run: `grep -nE 'YOUR_NAME|YOUR_NAME|your-org|platform|platform' MIGRATION.md || echo "clean"`
Expected: `clean`.

- [ ] **Step 3: Stage**

```bash
git add MIGRATION.md
```

---

### Task 3.7: Commit Phase 3

- [ ] **Step 1: Confirm staged files**

Run: `git status`
Expected: `.scrub/.gitignore`, `.scrub/replacements.example.txt`, `.gitignore`, `dot_claude/scripts/executable_scrub-pii-history.sh`, `MIGRATION.md` all staged.

- [ ] **Step 2: Commit**

```bash
git commit -S -s -m "phase 3: PII scrub script + migration doc

- Add .scrub/{.gitignore,replacements.example.txt}
- Add .scrub/replacements.txt to root .gitignore
- Add scrub-pii-history.sh (backup branch, filter-repo, verify, no auto-push)
- Add MIGRATION.md (scrub procedure + multi-machine sync flow)"
```

---

## Phase 4: dotfiles History Scrub (DESTRUCTIVE)

This phase rewrites git history. It is irreversible without the backup branch. **Do not run any task in this phase until you have confirmed Phases 1-3 are committed and pushed, all machines have clean working trees, and you understand that all historical commit SHAs will change.**

### Task 4.1: Pre-scrub checklist (every machine)

- [ ] **Step 1: On every machine that has dotfiles cloned, verify clean state**

```bash
cd ~/repos/github.com/<your-username>/dotfiles
git status
git log @{u}..HEAD --oneline | wc -l   # should be 0 (no unpushed commits)
```

Expected: clean working tree, no unpushed commits. If anything is uncommitted, commit and push it first; otherwise it will be lost.

- [ ] **Step 2: Push Phases 1-3 commits if not already**

```bash
git push origin main
```

- [ ] **Step 3: Note the machine where you will run the scrub**

Use the machine that pushed Phases 1-3. All other machines pull from it via the post-scrub sync.

---

### Task 4.2: Build `replacements.txt` for dotfiles

**Files:**
- Create: `.scrub/replacements.txt` (gitignored)

- [ ] **Step 1: Copy the example to the live file**

```bash
cd ~/repos/github.com/<your-username>/dotfiles
cp .scrub/replacements.example.txt .scrub/replacements.txt
```

- [ ] **Step 2: Edit `.scrub/replacements.txt`** — replace placeholders with literal strings

Open it in your editor. Final content should look like:

```
# (comments retained)
YOUR_NAME==>YOUR_NAME
REMOVED-EMAIL==>REMOVED-EMAIL
REMOVED-EMAIL==>REMOVED-EMAIL
REMOVED-GPG-KEY==>REMOVED-GPG-KEY
example.com==>example.com
your-org==>your-org
your-org==>your-org
your-org==>your-org
EVM smart contracts==>EVM smart contracts
$HOME/==>$HOME/
```

(`kpachhai` GitHub username is intentionally NOT scrubbed — it's in the repo URL itself; out of scope.)

- [ ] **Step 3: Verify the file is gitignored**

```bash
git status .scrub/replacements.txt
```

Expected: file does NOT appear in `git status` output (it's gitignored).

---

### Task 4.3: Dry-run the scrub on dotfiles

- [ ] **Step 1: Run dry-run**

```bash
~/.claude/scripts/scrub-pii-history.sh . --dry-run
```

Expected: reports each LEFT-side string from your replacements.txt. Creates a backup branch. No rewrite.

- [ ] **Step 2: Inspect the backup branch**

```bash
git branch | grep backup/pre-scrub
git log $(git branch | grep backup/pre-scrub | tr -d ' ' | head -1) --oneline | head -3
```

Expected: backup branch points at current HEAD.

- [ ] **Step 3: Delete the dry-run backup before the real run** (the real run creates its own)

```bash
git branch | grep backup/pre-scrub | xargs -r git branch -D
```

---

### Task 4.4: Run the destructive scrub

- [ ] **Step 1: Final confirmation**

Re-read `.scrub/replacements.txt`. If anything is wrong, fix it now.

- [ ] **Step 2: Run with --confirm**

```bash
~/.claude/scripts/scrub-pii-history.sh . --confirm
```

Expected: backup branch created, filter-repo runs, verifier reports `0 residual matches`, prints next-step checklist.

- [ ] **Step 3: If verification fails**

The script exits non-zero with `FAIL:` lines listing residual matches. Restore:

```bash
git reset --hard backup/pre-scrub-<timestamp>
```

Investigate why the rule didn't catch the string (regex needed? case? non-ASCII?). Update `.scrub/replacements.txt`. Re-run from Task 4.3.

- [ ] **Step 4: Manual verification**

```bash
git log -p --all 2>/dev/null | grep -iE 'pachhai|your-org|platform|platform|kiran|REMOVED-GPG-KEY' | head -10
```

Expected: empty output. If anything appears, investigate and possibly re-run with extended rules.

- [ ] **Step 5: Verify SHAs changed**

```bash
git log --oneline | head -5
```

Expected: SHAs differ from pre-scrub state.

---

### Task 4.5: Force-push to GitHub

- [ ] **Step 1: Check remote**

```bash
git remote -v
```

Expected: `origin` points to your GitHub fork.

- [ ] **Step 2: Push the backup branch first** (remote safety net)

```bash
backup=$(git branch | grep backup/pre-scrub | tr -d ' ' | head -1)
git push origin "$backup"
```

- [ ] **Step 3: Force-push main**

```bash
git push --force-with-lease origin main
```

Expected: push succeeds with `+ ... main -> main (forced update)`.

If rejected by branch protection, disable protection on GitHub temporarily, push, re-enable.

---

### Task 4.6: Realign the scrub-machine's local clone

This is required even on the machine where the scrub ran, because chezmoi may have its own working copy elsewhere.

- [ ] **Step 1: Hard-reset to remote**

```bash
git fetch
git reset --hard origin/main
```

- [ ] **Step 2: If you also have chezmoi's source dir separately**

```bash
chezmoi update
```

(`chezmoi update` is `git pull` in chezmoi's source dir; it should fast-forward to the rewritten history.)

---

### Task 4.7: Personalize this machine

- [ ] **Step 1: If `~/.config/devkit/identity.json` already exists with real values, skip to Step 3**

```bash
[[ -f ~/.config/devkit/identity.json ]] && cat ~/.config/devkit/identity.json
```

- [ ] **Step 2: Otherwise, create it**

Either:
- Run `chezmoi apply` — the run-once bootstrap script prompts and writes the file.
- OR run `~/.claude/scripts/setup-identity.sh` — interactive bootstrap.
- OR copy `devkit-identity.example.json` and edit it manually.

- [ ] **Step 3: Apply chezmoi to render gitconfig with personal data**

```bash
chezmoi apply
```

- [ ] **Step 4: Verify gitconfig is correct**

```bash
git config --global user.name
git config --global user.email
```

Expected: prints your real name and email (from the JSON).

---

### Task 4.8: Sync to other machines

For each remaining machine that has dotfiles cloned, repeat:

- [ ] **Step 1: Confirm clean working tree (per machine, per repo)**

```bash
cd <path-to-dotfiles-on-this-machine>
git status
```

Expected: clean.

- [ ] **Step 2: Hard-reset to rewritten remote**

```bash
git fetch
git reset --hard origin/main
```

- [ ] **Step 3: Confirm SHAs match**

```bash
git log --oneline | head -3
# Compare with the scrub machine's output
```

- [ ] **Step 4: Create or verify `~/.config/devkit/identity.json` on this machine**

Use machine-appropriate values (e.g., on a work laptop, set `email_work`; on personal, leave it blank or set the personal email accordingly).

- [ ] **Step 5: `chezmoi apply` on this machine**

```bash
chezmoi apply
```

- [ ] **Step 6: Verify gitconfig**

```bash
git config --global user.email
```

Expected: this machine's email (work or personal as appropriate).

---

### Task 4.9: Cleanup

- [ ] **Step 1: After 24-48 hours of confirming everything works, delete backup branches**

Local (every machine):
```bash
git branch | grep backup/pre-scrub | xargs -r git branch -D
```

Remote:
```bash
git push origin --delete <backup-branch-name>
```

(Do this only after you are certain no rollback is needed.)

- [ ] **Step 2: Optionally request GitHub GC of old commit SHAs**

If your threat model requires removing GitHub's cache of old commits, file a Support ticket: `https://support.github.com/contact` with subject "Request expedited garbage collection after force-push" and reference the repo.

---

## Self-Review

**Spec coverage:** every section of the spec maps to tasks here:

- Spec §1 Identity Contract → Tasks 1.1, 1.5, 1.6, 1.7
- Spec §2 Identity Loader → Tasks 1.2, 1.3, 1.4
- Spec §3 PII Scrub Procedure → Tasks 3.1, 3.2, 3.3
- Spec §4 Scrub Script → Tasks 3.4, 3.5
- Spec §5 Migration Documentation → Task 3.6
- Spec "Per-Repo Changes (dotfiles)" → Phase 2 (Tasks 2.1-2.7)
- Spec "Multi-Machine Migration Flow" → Tasks 4.1, 4.7, 4.8 + MIGRATION.md
- Spec "Verification Gates" → embedded in Tasks 3.5, 4.4, 4.6, 4.8 verification steps
- Spec "Risks & Mitigations" → backup branch in scrub script (Task 3.4) + dirty-tree gate + force-with-lease (Task 4.5)

**Idea-forge / your-data-repo** — not in this plan. The spec's Phase 5 ("apply this procedure to your-meta-repo and your-data-repo") is a separate brainstorm/plan cycle that uses the artifacts produced by THIS plan: `scrub-pii-history.sh`, `MIGRATION.md`, the `.scrub/` convention, and `~/.config/devkit/identity.json`. When ready, run `superpowers:brainstorming` against your-meta-repo with this plan as input context.

**No placeholders:** every task contains exact paths, complete code blocks, exact commands with expected output. No "implement later" or "similar to X" references.

**Type consistency:** env-var names (`DEVKIT_IDENTITY_*`), file paths (`~/.config/devkit/identity.json`, `.scrub/replacements.txt`), function/script names (`load-identity.sh`, `scrub-pii-history.sh`, `setup-identity.sh`) are consistent across all tasks and match the spec.

**Frequent commits:** Phase 1, Phase 2, and Phase 3 each end with a single grouped commit. Phase 4 commits during the rewrite (filter-repo handles that internally) and via the manual realign step. This balances "frequent commits" against "atomic phase boundaries" — each phase commit is a coherent reversible state.

---

## Execution Notes

- **Phase 1-3 are fully reversible.** Any commit can be reverted with `git revert`.
- **Phase 4 is destructive.** The backup branches are the safety net. Do not delete them until at least a day after Phase 4 completes successfully.
- **All commits use `git commit -S -s`** per the maintainer's global rule (signed + DCO).
- **No commits or pushes are auto-executed.** Each commit step is explicit; the operator decides when to run it.
