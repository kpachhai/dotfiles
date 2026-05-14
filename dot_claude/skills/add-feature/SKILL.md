---
name: add-feature
description: Use BEFORE implementing any new feature or modifying an existing one. Produces a structured implementation checklist covering API design, destructive-operation guardrails, test plan, and documentation requirements. Prevents the common failure modes of shipping untested, undocumented, or dangerous code. Works across any project type.
---

# Add Feature

## Purpose

Every feature addition or modification involves the same recurring decisions:
what the API contract is, whether the operation is destructive, what tests
are needed, and which documentation files to touch. Without a checklist,
each of these gets dropped at least once. This skill makes them explicit
before a single line of code is written.

**This is a global skill** — works across any project type (Python, Go,
TypeScript, Rust, Solidity, etc.).

## When to use

- Adding a new tool, command, endpoint, or function to an existing system.
- Modifying an existing API (changing behavior, adding parameters, changing outputs).
- Removing or deprecating a feature.
- ANY operation that writes, updates, or deletes persistent data.

## When NOT to use

- Pure documentation edits.
- Dependency bumps with no behavior change.
- Cosmetic refactors within a single function.
- Trivial config changes.

---

## Phase 1: Read before touching anything

Before writing any code, read the following from the target repo:

1. **`CLAUDE.md`** (project-level) — coding conventions, pinned invariants,
   things that must not be violated. If the project has them, treat them as
   hard constraints.
2. **The relevant source files** — understand the existing API contract, error
   handling patterns, and data flow before adding to it.
3. **The existing tests for the area you're changing** — understand what is
   already verified so you don't duplicate or contradict it.
4. **`CHANGELOG.md`** — understand how changes have been described in the past;
   follow that style.
5. **`docs/ARCHITECTURE.md`** (or equivalent) — understand where the feature
   fits in the overall component diagram.

Only after reading these should you proceed to Phase 2.

---

## Phase 2: Design — answer these questions before writing code

Write down your answers (in the plan doc, in a comment, or in a note to the
user). Do not skip to implementation without answers.

### 2.1 What is the API contract?

- What are the inputs? What types? What are valid vs invalid values?
- What are the outputs? What does success look like? What does failure look like?
- What errors can be raised? Are they new or reusing existing error types?
- Is this additive (new tool/field/command) or breaking (changes existing behavior)?
  - **Additive is always preferred.** If you must break an existing contract,
    escalate to the user before proceeding — breaking changes are user-visible
    and must be deliberate.

### 2.2 Is this operation destructive?

An operation is **destructive** if it permanently removes, overwrites, or
modifies data in a way that cannot be trivially undone (no "undo" button,
no soft-delete, no version history that the user controls).

Examples of destructive operations: file deletion, database row deletion,
overwriting a file, clearing a cache, revoking a token.

If the answer is **yes**, apply the Destructive Operation Protocol in Phase 3
before continuing to implementation.

### 2.3 What are the affected layers?

List every layer the change touches: storage, API handler, CLI command,
configuration model, external service, documentation, tests. This list becomes
your implementation checklist in Phase 4.

### 2.4 What is the correct implementation order?

Changes should flow from the inside out:
`storage/model → handler/service → CLI/API surface → tests → docs`.

Never write the CLI before the storage layer exists. Never write tests for an
interface that isn't finalized. Never update docs for behavior that isn't
tested.

---

## Phase 3: Destructive operation protocol (skip if not destructive)

If the operation is destructive, ALL of the following guardrails are required.
None are optional. If the project owner explicitly waives one, note it in the
plan with the reason.

### 3.1 Dry-run mode

Every destructive operation must support a dry-run mode that shows what would
happen without doing it. The user can validate the dry-run output before
committing to the real action.

- **CLI**: `--dry-run` flag. Required. Must exit 0 and print a clear summary.
- **MCP/API tool**: a `confirm: bool` parameter with no default. `confirm=False`
  returns a preview; `confirm=True` executes. The tool's description string
  must instruct the AI to call with `confirm=False` first, show the user the
  result, and only call with `confirm=True` after explicit human approval.

### 3.2 Explicit confirmation gate

Dry-run alone is not enough. The user must take a deliberate action to confirm.

- **CLI**: Do not use `y/n` prompts — they are too easy to accept by reflex.
  Require the user to type a specific word (e.g. `"delete"`, `"confirm"`,
  `"overwrite"`) that makes the action explicit. A `--yes` / `--force` flag
  may bypass this for scripted use but must be documented as dangerous.
- **MCP/API**: The `confirm=True` parameter serves this role. The AI MUST
  show the dry-run preview to the human and receive explicit approval before
  calling with `confirm=True`. Document this contract in `CLAUDE.md` or the
  tool description.

### 3.3 Audit log

Every execution of a destructive operation must emit a structured log line at
INFO or WARNING level containing: operation name, resource identifier,
resource metadata (enough to identify what was lost), timestamp, and caller
context (CLI vs MCP, user or agent).

This is the forensic trail that lets an operator answer "what happened and
when" after the fact.

### 3.4 No bulk destructive operations in the initial implementation

The first version of a destructive feature should operate on **one resource
at a time**. Bulk operations (delete all matching X, overwrite all Y) have
much higher blast radius and should be a deliberate follow-up feature with
additional guardrails (confirmation count, dry-run showing full list, rate
limiting).

### 3.5 Recovery path documentation

Document the recovery procedure in the relevant docs file:

- Is there a git history to recover from? Document the `git checkout` command.
- Is there a trash / archive folder? Document how to restore from it.
- Is the operation truly unrecoverable? Say so explicitly in the docs.

---

## Phase 4: Implementation checklist

Work through these in order. Check off each before moving to the next.

- [ ] **Errors**: Add any new error types to the project's errors module.
      Each error should have a stable string code for programmatic handling.
- [ ] **Models/types**: Add input/output types to the project's model layer.
      Use strict validation (Pydantic `extra="forbid"` for inputs,
      `extra="ignore"` for outputs).
- [ ] **Storage/service layer**: Implement the core logic. This layer should
      be independently testable without the CLI or API layer.
- [ ] **API/MCP handler**: Wire the storage layer to the API surface. Apply
      all guardrails from Phase 3 here.
- [ ] **CLI command**: Wire to the CLI. Apply the CLI guardrails from Phase 3.
      Register the command so it appears in `--help`.
- [ ] **Configuration** (if new config fields): Add Pydantic fields with
      sensible defaults. Add to the config reference docs.

At each step: run lint and type-check before moving to the next step.
A type error that compounds across three layers is much harder to debug
than one caught at the storage layer.

---

## Phase 5: Test requirements

Every feature needs tests at three levels. None are optional.

### 5.1 Unit tests

Test the storage/service layer in isolation. Cover:

- **Happy path**: the operation succeeds and produces the expected output.
- **Not-found / empty**: the operation handles missing resources gracefully.
- **Error paths**: each declared error type is raised by the right input.
- **Guardrail enforcement** (if destructive): dry-run mode does NOT modify
  state. Confirm gate is enforced.
- **Audit log emission**: the log line appears in `caplog` (or equivalent).
- **Side effects**: if the operation enqueues sync, calls a coordinator,
  or has other side effects — assert those are called with the right args.

### 5.2 Integration test

One end-to-end test that exercises the full stack:
create resource → perform operation → verify result via a read operation.

For destructive operations specifically:
create → dry-run (verify nothing changed) → confirm → verify resource gone
from all read paths (fetch, search, list).

### 5.3 CLI smoke test

Add to the project's hermetic CLI smoke test file (usually
`tests/test_*_cli_smoke.py`):

- `command --help` exits 0 and lists all flags.
- `command <invalid-input>` exits non-zero with a clear error message.
- `command <valid-input> --dry-run` exits 0 and does NOT modify state.

The smoke test must spawn the actual installed binary via `subprocess`. It
catches wiring bugs (command not registered, wrong exit code) that
handler-level tests miss.

---

## Phase 6: Documentation requirements

Update ALL of the following that apply to this project. Do not skip.

| Doc | What to add |
|---|---|
| `CHANGELOG.md` | Add under `### Added` (new feature) or `### Changed` (modification). Follow existing style. |
| `docs/ARCHITECTURE.md` | Update the API surface table/count. Add the new operation to the relevant data flow diagram. |
| `README.md` | If the feature is user-facing, add it to the tools/commands table. |
| `CLAUDE.md` (project-level) | If the feature has a non-obvious usage contract (e.g. the dry-run-before-confirm protocol), document it here so future AI sessions respect it. |
| Operator guide (if one exists) | Add usage examples including the dry-run workflow for destructive operations. |
| Config reference (if new config fields) | Add each field to the config reference table with its default, valid range, and meaning. |

---

## Phase 7: Verification gate

Before declaring the feature complete, run all of:

```
# Lint
ruff check .              # or project equivalent

# Format
ruff format --check .     # or project equivalent

# Types
mypy                      # or tsc, go vet, cargo check, etc.

# Tests
pytest -q                 # or project equivalent
```

- Check **stderr**, not just exit code. A test suite that exits 0 but emits
  warnings or tracebacks to stderr is not clean.
- Verify the **coverage gate** still passes (if the project enforces one).
- For destructive features: manually run the dry-run path and verify nothing
  is modified before claiming the guardrail works.

Only when all four commands are clean is the feature complete.

---

## Quick reference: checklist summary

```
Phase 1 — Read:    CLAUDE.md, source files, existing tests, CHANGELOG, ARCHITECTURE
Phase 2 — Design:  API contract, additive vs breaking, affected layers, order
Phase 3 — Guards:  (destructive only) dry-run, confirmation gate, audit log, no bulk, recovery docs
Phase 4 — Build:   errors → models → storage → handler → CLI → config (in order)
Phase 5 — Tests:   unit (happy + error + guardrail + side-effects) + integration + CLI smoke
Phase 6 — Docs:    CHANGELOG + ARCHITECTURE + README + CLAUDE.md + operator guide + config ref
Phase 7 — Verify:  lint + format + types + tests (check stderr); manual dry-run check
```
